import QtQuick 2.0
import Ubuntu.Components 1.2
import Ubuntu.Content 1.1

Page {
    id: chatPage
    title: conv_name || "Chat"
    visible: false

    property string conv_name
    property string conv_id
    property bool first_message_loaded: false

    property alias listView: listView
    property alias pullToRefresh: pullToRefresh

    head.actions: [
        Action {
            iconName: "info"
            text: i18n.tr("Info")
            onTriggered: pageStack.push(aboutConversationPage, {mData: conversationsModel.get(getConversationModelIndexById(conv_id))})
        }
        /*Action {
            iconName: "add"
            text: i18n.tr("Add")
        }*/
    ]

    UbuntuListView {
        id: listView
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: bottomContainer.top
        anchors.bottomMargin: units.gu(1)
        anchors.topMargin: units.gu(1)

        model: currentChatModel
        spacing: units.gu(1)
        delegate: ChatListItem {}

        PullToRefresh {
            id: pullToRefresh
            width: parent.width

            enabled: !first_message_loaded

            content: Item {
                height: parent.height
                width: height

                Label {
                    anchors.centerIn: parent
                    text: !pullToRefresh.releaseToRefresh ? i18n.tr("Pull to load more") : i18n.tr("Release to load more")
                }

            }

            onRefresh: {
                refreshing = true;
                py.call('backend.load_more_messages', [conv_id]);
            }
        }
    }

    Rectangle {
        id: bottomContainer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        height: units.gu(6)

        color: "white"

        TextField {
            id: messageField

            anchors.left: parent.left
            anchors.top: parent.top
            anchors.right: attachmentIcon.left
            anchors.bottom: parent.bottom
            anchors.margins: units.gu(1)

            placeholderText: i18n.tr("Write a message")

            onAccepted: {
                if (messageField.text !== "") {
                    py.call('backend.send_message', [conv_id, messageField.text]);
                    messageField.text = "";
                }
            }
        }

        Icon {
            id: attachmentIcon

            anchors.top: parent.top
            anchors.right: sendIcon.left
            anchors.bottom: parent.bottom
            anchors.margins: units.gu(1)
            anchors.rightMargin: units.gu(2)
            anchors.leftMargin: units.gu(2)

            name: 'insert-image'
            width: height
            height: parent.height - units.gu(1)

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    importContentPopup.show();
                }

            }

        }

        Icon {
            id: sendIcon

            anchors.top: parent.top
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: units.gu(1)
            anchors.rightMargin: units.gu(2)
            anchors.leftMargin: units.gu(2)

            source: Qt.resolvedUrl("../media/fontawesome-paper-plane-blue.png")
            width: height
            height: parent.height - units.gu(1)

            Component.onCompleted: {console.log(UbuntuColors.blue)}

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (messageField.text !== "") {
                        py.call('backend.send_message', [conv_id, messageField.text]);
                        messageField.text = "";
                    }
                }

            }

        }

    }

    ImportContentPopup {
        id: importContentPopup
        contentType: ContentType.Pictures
        onItemsImported: {
            var picture = importItems[0];
            var url = picture.url;
            py.call('backend.send_image', [conv_id, url.toString()]);
        }
    }

}
