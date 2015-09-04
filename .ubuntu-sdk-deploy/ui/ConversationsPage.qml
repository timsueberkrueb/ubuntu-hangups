import QtQuick 2.0
import Ubuntu.Components 1.2
import Ubuntu.Components.Popups 1.0

Page {
    title: i18n.tr("Conversations")
    visible: false

    head.actions: [
        Action {
            iconName: "add"
            text: i18n.tr("Add")
            onTriggered: {
                pageStack.push(selectUsersPage, {headTitle: i18n.tr("New Conversation"), callback: function callback(users){
                    py.call('backend.create_conversation', [users]);
                }});
            }
        },
        Action {
            iconName: "contact-group"
            text: i18n.tr("Contacts")
            onTriggered: pageStack.push(contactsPage, {});
        },
        Action {
            iconName: "settings"
            text: i18n.tr("Settings")
            onTriggered: pageStack.push(settingsPage, {});
        },
        Action {
            iconName: "info"
            text: i18n.tr("About")
            onTriggered: pageStack.push(aboutPage, {});
        }
    ]

    UbuntuListView {
        id: listView
        anchors.fill: parent

        model: conversationsModel

        delegate: ListItem {
            property QtObject modelData: listView.model.get(index)

            Row {
                id: rowItem
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: units.gu(1)
                anchors.rightMargin: units.gu(1)
                spacing: units.gu(2)

                Icon {
                    id: contactIcon
                    height: units.dp(32)
                    width: units.dp(32)
                    visible: modelData.icon === "unknown/contact"
                    name: "contact"
                    color: UbuntuColors.warmGrey
                }

                Icon {
                    id: groupIcon
                    height: units.dp(32)
                    width: units.dp(32)
                    name: "contact-group"
                    visible: modelData.icon === "unknown/group"
                    color: UbuntuColors.warmGrey
                }

                Image {
                    id: remoteIcon
                    visible: modelData.icon.lastIndexOf("http", 0) === 0
                    height: units.dp(32)
                    width: units.dp(32)
                    source: visible ? modelData.icon : ""
                }

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.title
                }
            }

            Rectangle {
                id: unreadCircle

                visible: modelData.unread_count > 0

                x: rowItem.x + units.dp(24)
                y: rowItem.y + units.dp(32) - unreadMessagesLabel.height * 0.6

                width: unreadMessagesLabel.paintedWidth + units.gu(1)
                height: width
                color: !modelData.is_quiet ? UbuntuColors.green : UbuntuColors.darkGrey
                radius: width*0.5

                Label {
                    id: unreadMessagesLabel
                    anchors.centerIn: parent
                    fontSize: "x-small"
                    color: "white"
                    text: modelData.unread_count
                }
            }

            leadingActions: ListItemActions {
                actions: [
                    Action {
                        iconName: "delete"
                        onTriggered: {
                            var  dialog = PopupUtils.open(deleteConversationDialog);
                            dialog.id_ = modelData.id_;
                        }
                    }
                ]
            }

            trailingActions: ListItemActions {
                actions: [
                    Action {
                        iconName: "info"
                        onTriggered: pageStack.push(aboutConversationPage, {mData: conversationsModel.get(getConversationModelIndexById(modelData.id_))});
                    },
                    Action {
                        iconName: "add"
                        onTriggered: {
                            var user_ids = [];
                            var users = modelData.users
                            for (var i=0; i<users.count; i++) {
                                user_ids.push(users.get(i).id_.toString());
                            }
                            pageStack.push(selectUsersPage, {headTitle: i18n.tr("Add users"), excludedUsers: user_ids, callback: function onUsersSelected(users){
                                py.call('backend.add_users', [modelData.id_, users]);
                            }});
                        }
                    }
                ]
            }

            onClicked: {
                setCurrentConversation(modelData.id_);
                py.call('backend.entered_conversation', [modelData.id_]);
                pageStack.push(chatPage, {conv_id: modelData.id_, conv_name: modelData.title, first_message_loaded: modelData.first_message_loaded, status_message: modelData.status_message})
                chatPage.listView.positionViewAtEnd();
            }
        }

    }

    Component {
         id: deleteConversationDialog
         Dialog {
             id: dialog
             title: i18n.tr("Delete Conversation")
             text: i18n.tr("Are you really sure to delete this conversation?")

             property string id_

             Button {
                 text: i18n.tr("Delete")
                 color: UbuntuColors.orange
                 onClicked: {
                     py.call('backend.delete_conversation', [id_]);
                     PopupUtils.close(dialog);
                 }
             }

             Button {
                 id: cancelButton
                 text: i18n.tr("Cancel")
                 onClicked: PopupUtils.close(dialog)
             }
         }
    }

    Label {
        id: loadingLabel
        visible: conversationsModel.count === 0
        text: i18n.tr("Nothing here, yet")
        anchors.centerIn: parent
    }

}

