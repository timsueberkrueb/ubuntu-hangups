import QtQuick 2.4
import Ubuntu.Components 1.3

Page {
    title: i18n.tr("About Conversation")
    visible: false
    property var mData

    onActiveChanged: {
        if (active) {
            isQuietCheckbox.checked = mData.is_quiet;
            listView.model = mData.users;
        }
    }

    Column {
        id: col
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: units.gu(2)
        spacing: units.gu(1)

        Label {
            text: i18n.tr("Settings")
            fontSize: "x-large"
        }

        Row  {
            spacing: units.gu(1)

            TextField {
                id: conversationNameField
                text: mData.title
            }

            Button {
                id: renameButton
                text: i18n.tr("Rename")
                color: UbuntuColors.green
                enabled: conversationNameField.text !== mData.title
                onClicked: {
                    py.call('backend.rename_conversation', [mData.id_, conversationNameField.text]);
                }
            }
        }

        Row {
            spacing: units.gu(1)

            CheckBox {
                property bool userInitiated: false
                anchors.verticalCenter: parent.verticalCenter
                id: isQuietCheckbox
                onClicked: {
                    userInitiated = true;
                }
                onCheckedChanged: {
                    if (userInitiated) {
                        py.call('backend.set_conversation_quiet', [mData.id_, checked]);
                        userInitiated = false;
                    }
                }
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: i18n.tr("Quiet")
            }
        }

        Label {
             text: i18n.tr("Users")
             fontSize: "x-large"
        }

    }

    UbuntuListView {
        id: listView

        anchors.top: col.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        clip: true

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
                    text: modelData.is_self ? modelData.full_name + " (you)" : modelData.full_name
                }
            }

        }

    }

}
