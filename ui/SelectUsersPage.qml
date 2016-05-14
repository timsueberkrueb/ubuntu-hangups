import QtQuick 2.4
import Ubuntu.Components 1.3

Page {
    id: page

    property string headTitle: ""
    property var callback
    property var excludedUsers: []

    signal usersSelected (var users)

    visible: false
    header: HangupsHeader {
        title: headTitle != "" ? headTitle : i18n.tr("Select users")

        flickable: listView

        trailingActionBar.actions: [
           Action {
               id: actionOk
               iconName: "ok"
               onTriggered: {
                   if (listView.selectedModel.length > 0) {
                       var selectedUsers = new Array();
                       for (var i=0; i<listView.selectedModel.length; i++) {
                           var modelIndex = listView.selectedModel[i];
                           var modelData = contactsModel.get(modelIndex);
                           selectedUsers.push(modelData.id_);
                       }
                       usersSelected(selectedUsers);
                   }
                   pageLayout.removePages(selectUsersPage);
               }
           },
           Action {
               iconName: "close"
               onTriggered: {
                   pageLayout.removePages(selectUsersPage);
               }
           }
       ]
    }

    onVisibleChanged : {
        if (!visible) {
            headTitle = ""
            listView.selectedModel = [];
       }
       else {
            // Force redraw
            listView.model = 0;
            listView.model = contactsModel;

       }
    }

    onUsersSelected: {
        callback(users);
    }

    UbuntuListView {
        id: listView
        anchors.fill: parent
        clip: true

        model: contactsModel

        property var selectedModel: []

        delegate: ListItem {
            property QtObject modelData: listView.model.get(index)

            enabled: page.excludedUsers.indexOf(modelData.id_) == -1

            Row {
                id: rowItem
                anchors.fill: parent
                anchors.leftMargin: units.gu(1)
                anchors.rightMargin: units.gu(1)
                spacing: units.gu(2)

                CheckBox {
                    id: selectCheckbox

                    property bool userInitiated

                    anchors.verticalCenter: parent.verticalCenter
                    enabled: page.excludedUsers.indexOf(modelData.id_) == -1
                    checked: listView.selectedModel.indexOf(index) > -1
                    onClicked: userInitiated = true;
                    onCheckedChanged: {
                        if (userInitiated) {
                            if (checked) {
                                listView.selectedModel.push(index);
                            }
                            else {
                                var i = listView.selectedModel.indexOf(index);
                                listView.selectedModel.splice(i, 1);
                            }
                            userInitiated = false;
                        }
                    }
                }

                Icon {
                    id: contactIcon
                    anchors.verticalCenter: parent.verticalCenter
                    height: units.dp(32)
                    width: units.dp(32)
                    visible: !modelData.photo_url
                    name: "contact"
                    color: UbuntuColors.warmGrey
                }

                Image {
                    id: remoteIcon
                    anchors.verticalCenter: parent.verticalCenter
                    visible: modelData.photo_url
                    height: units.dp(32)
                    width: units.dp(32)
                    source: visible ? modelData.photo_url : ""
                }

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.name
                }
            }

            onClicked: {
                selectCheckbox.clicked();
            }

            /*leadingActions: ListItemActions {
                actions: [
                    Action {
                        iconName: "stop"
                    }
                ]
            }*/

            trailingActions: ListItemActions {
                actions: [
                    /*Action {
                        iconName: "compose"
                        onTriggered: {

                        }
                    },*/
                    Action {
                        text: "Google Plus"
                        iconName: "googleplus-symbolic"
                        onTriggered: {
                            Qt.openUrlExternally("https://plus.google.com/u/0/" + modelData.id_ + "/about")
                        }
                    }
                ]
            }
        }
    }

    Label {
        id: loadingLabel
        visible: conversationsModel.count === 0
        text: i18n.tr("No contacts")
        anchors.centerIn: parent
    }
}

