import QtQuick 2.4
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3

Page {
    title: i18n.tr("Conversations")
    visible: false

    flickable: listView

    head.actions: [
        Action {
            iconName: "add"
            text: i18n.tr("Add")
            onTriggered: {
                pageLayout.addPageToNextColumn(conversationsPage, selectUsersPage, {headTitle: i18n.tr("New Conversation"), callback: function callback(users){
                    py.call('backend.create_conversation', [users]);
                }});
            }
        },
        Action {
            iconName: "contact-group"
            text: i18n.tr("Contacts")
            onTriggered: pageLayout.addPageToNextColumn(conversationsPage, contactsPage);
        },
        Action {
            iconName: "settings"
            text: i18n.tr("Settings")
            onTriggered: pageLayout.addPageToNextColumn(conversationsPage, settingsPage);
        },
        Action {
            iconName: "info"
            text: i18n.tr("About")
            onTriggered: pageLayout.addPageToNextColumn(conversationsPage, aboutPage);
        }
    ]

    UbuntuListView {
        id: listView
        anchors.fill: parent
        clip: true

        model: conversationsModel

        delegate: ListItem {
            property QtObject modelData: listView.model.get(index)

            RowLayout {
                id: rowItem
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    right: parent.right
                    leftMargin: units.gu(1)
                    rightMargin: units.gu(1)
                }
                spacing: units.gu(2)

                GroupAvatar {
                    Layout.preferredHeight: height
                    Layout.preferredWidth: width
                    visible: modelData.icon === "unknown/group"
                }

                DefaultUserAvatar {
                    Layout.preferredHeight: height
                    Layout.preferredWidth: width
                    visible: modelData.icon === "unknown/contact"
                    name: modelData.title
                }

                UserAvatar {
                    Layout.preferredHeight: height
                    Layout.preferredWidth: width
                    visible: modelData.icon.lastIndexOf("http", 0) === 0
                    name: modelData.title
                    photoUrl: visible ? modelData.icon : ""
                }

                Column {
                    Layout.fillWidth: true

                    Label {
                        text: modelData.title
                        font.bold: true
                    }

                    Label {
                        text: modelData.statusMessage || (chatModels[modelData.id_].count > 0 ? chatModels[modelData.id_].get(0).text: "")
                        elide: Text.ElideRight
                        width: parent.width
                        color: modelData.statusMessage ? UbuntuColors.green : Theme.palette.normal.baseText
                    }
                }
            }

            Rectangle {
                id: unreadCircle

                visible: modelData.unread_count > 0 || modelData.online

                x: rowItem.x + units.dp(24)
                y: rowItem.y + units.dp(32) - unreadMessagesLabel.height * 0.6

                width: unreadMessagesLabel.paintedWidth + units.gu(1)
                height: width
                color: !modelData.is_quiet ? modelData.online ? UbuntuColors.green : UbuntuColors.blue : UbuntuColors.darkGrey
                radius: width*0.5

                Label {
                    id: unreadMessagesLabel
                    visible: modelData.unread_count > 0
                    anchors.centerIn: parent
                    fontSize: "x-small"
                    color: "white"
                    text: (modelData.unread_count === 5 && chatModels[modelData.id_].count === 5) ? "5+" : modelData.unread_count
                    // Max. 5 messages loaded at startup.
                }
            }

            leadingActions: ListItemActions {
                actions: [
                    Action {
                        text: i18n.tr("Delete")
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
                        text: i18n.tr("About")
                        iconName: "info"
                        onTriggered: pageLayout.addPageToNextColumn(chatPages[modelData.id_].visible ? chatPages[modelData.id_] : conversationsPage, aboutConversationPage, {mData: conversationsModel.get(getConversationModelIndexById(modelData.id_))});
                    },
                    Action {
                        text: i18n.tr("Add users")
                        iconName: "add"
                        enabled: modelData.users.count > 2
                        onTriggered: {
                            var user_ids = [];
                            var users = modelData.users
                            for (var i=0; i<users.count; i++) {
                                user_ids.push(users.get(i).id_.toString());
                            }
                            pageLayout.addPageToNextColumn(chatPages[modelData.id_].visible ? chatPages[modelData.id_] : conversationsPage, selectUsersPage, {headTitle: i18n.tr("Add users"), excludedUsers: user_ids, callback: function onUsersSelected(users){
                                py.call('backend.add_users', [modelData.id_, users]);
                            }});
                        }
                    }
                ]
            }

            onClicked: {
                py.call('backend.entered_conversation', [modelData.id_]);
                pageLayout.addPageToNextColumn(conversationsPage, chatPages[modelData.id_]);
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
                     pageLayout.removePages(chatPages[id_]);
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

