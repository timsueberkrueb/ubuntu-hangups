import QtQuick 2.4
import Ubuntu.Components 1.3

Page {
    title: i18n.tr("Contacts")
    visible: false

    UbuntuListView {
        id: listView
        anchors.fill: parent

        model: contactsModel

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
                    visible: !modelData.photo_url
                    name: "contact"
                    color: UbuntuColors.warmGrey
                }

                Image {
                    id: remoteIcon
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

