import QtQuick 2.0
import Ubuntu.Components 1.2
import Ubuntu.Content 1.1
import QtGraphicalEffects 1.0

Page {
    id: chatPage
    title: conv_name || "Chat"
    visible: false

    property string conv_name
    property string conv_id
    property string status_message: ""
    property bool first_message_loaded: false
    property bool loaded: false

    property alias listView: listView
    property alias pullToRefresh: pullToRefresh

    property bool initialMessagesLoaded: false

    onActiveChanged: {
        if (!active) {
            py.call('backend.left_conversation', [conv_id]);
        }
        else {
            listView.positionViewAtEnd();
            if (!loaded) {
                py.call('backend.load_conversation', [conv_id])
            }
        }
    }

    head.actions: [
        Action {
            iconName: "info"
            text: i18n.tr("Info")
            onTriggered: pageStack.push(aboutConversationPage, {mData: conversationsModel.get(getConversationModelIndexById(conv_id))})
        },
        Action {
            iconName: "add"
            text: i18n.tr("Add")
            onTriggered: {
                var user_ids = [];
                var users = conversationsModel.get(getConversationModelIndexById(conv_id)).users;
                for (var i=0; i<users.count; i++) {
                    user_ids.push(users.get(i).id_.toString());
                }
                pageStack.push(selectUsersPage, {headTitle: i18n.tr("Add users"), excludedUsers: user_ids, callback: function onUsersSelected(users){
                    py.call('backend.add_users', [conv_id, users]);
                }});
            }
        }
    ]

    head.contents: Item {
        height: units.gu(5)
        width: parent ? parent.width - units.gu(2) : undefined
        Label {
            width: parent.width
            anchors.verticalCenter: parent.verticalCenter
            text: title
            fontSize: "x-large"
            elide: Text.ElideRight
            visible: status_message == ""
        }

        Label {
            width: parent.width
            anchors.top: parent.top
            text: title
            fontSize: "large"
            elide: Text.ElideRight
            visible: status_message != ""
        }

        Label {
            width: parent.width
            opacity: status_message != "" ? 1.0: 0
            color: UbuntuColors.green
            anchors.bottom: parent.bottom
            text: status_message
            elide: Text.ElideRight
            Behavior on opacity {
                NumberAnimation { duration: 500 }
            }
        }
    }

    UbuntuListView {
        id: listView

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: bottomContainer.top

        model: currentChatModel
        spacing: units.gu(1)
        delegate: ChatListItem {}

        // Workaround for "positionViewAtEnd" not scrolling to the very bottom

        header: Component {
            Item {
                height: units.gu(5)
                width: parent.height
            }
        }


        footer: Component {
            Item {
                height: units.gu(5)
                width: parent.height

                Row {
                    visible: !loaded
                    anchors.fill: parent
                    anchors.margins: units.gu(2)
                    spacing: units.gu(2)

                    ActivityIndicator {
                        running: !loaded
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Label {
                        text: i18n.tr("Loading messages ...")
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

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
                    py.call('backend.set_typing', [conv_id, "stopped"]);
                    pausedTypingTimer.stop();
                    stoppedTypingTimer.stop();
                }
            }

            Timer {
                id: pausedTypingTimer
                interval: 1500
                onTriggered: {
                    py.call('backend.set_typing', [conv_id, "paused"]);
                    stoppedTypingTimer.start();
                }
            }

            Timer {
                id: stoppedTypingTimer
                interval: 3000
                onTriggered: py.call('backend.set_typing', [conv_id, "stopped"]);
            }

            onTextChanged: {
                py.call('backend.set_typing', [conv_id, "typing"]);
                pausedTypingTimer.stop();
                stoppedTypingTimer.stop();
                pausedTypingTimer.start();
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

        Image {
            id: sendIcon

            property bool send_icon_clicked: false

            anchors.top: parent.top
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: units.gu(1)
            anchors.rightMargin: units.gu(2)
            anchors.leftMargin: units.gu(2)

            source: Qt.resolvedUrl("../media/google-md-send-icon.svg")
            width: height
            height: parent.height - units.gu(1)

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    Qt.inputMethod.commit();
                    Qt.inputMethod.hide();
                    if (messageField.text !== "") {
                        py.call('backend.send_message', [conv_id, messageField.text]);
                        messageField.text = "";
                        py.call('backend.set_typing', [conv_id, "stopped"]);
                        pausedTypingTimer.stop();
                        stoppedTypingTimer.stop();
                    }
                }

            }

        }

        ColorOverlay {
            anchors.fill: sendIcon
            source: sendIcon
            color: UbuntuColors.blue
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
