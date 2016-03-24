import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Content 1.3
import QtQuick.Layouts 1.0
import QtGraphicalEffects 1.0

Page {
    id: chatPage
    title: convName || "Chat"
    visible: false

    property string convName
    property string convId
    property string statusMessage: ""
    property bool firstMessageLoaded: false
    property bool loaded: false

    property alias listView: listView
    property alias pullToRefresh: pullToRefresh

    property bool initialMessagesLoaded: false
    property bool pullToRefreshLoading: false

    property alias chatModel: listView.model

    flickable: listView

    onActiveChanged: {
        if (!active) {
            pullToRefreshLoading = false;
            py.call('backend.left_conversation', [convId]);
        }
        else {
            if (!loaded) {
                listView.positionViewAtEnd();
                py.call('backend.load_conversation', [convId])
            }
            conversationsModel.get(getConversationModelIndexById(convId)).unread_count = 0;
        }
    }

    head.actions: [
        Action {
            iconName: "info"
            text: i18n.tr("Info")
            onTriggered: pageLayout.addPageToNextColumn(chatPage, aboutConversationPage, {mData: conversationsModel.get(getConversationModelIndexById(convId))})
        },
        Action {
            iconName: "add"
            text: i18n.tr("Add")
            property var userModel: conversationsModel.get(getConversationModelIndexById(convId)).users
            enabled: userModel.count > 2
            onTriggered: {
                var user_ids = [];
                for (var i=0; i<userModel.count; i++) {
                    user_ids.push(userModel.get(i).id_.toString());
                }
                pageLayout.addPageToNextColumn(chatPage, selectUsersPage, {headTitle: i18n.tr("Add users"), excludedUsers: user_ids, callback: function onUsersSelected(users){
                    py.call('backend.add_users', [convId, users]);
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
            visible: statusMessage == ""
        }

        Label {
            width: parent.width
            anchors.top: parent.top
            text: title
            fontSize: "large"
            elide: Text.ElideRight
            visible: statusMessage != ""
        }

        Label {
            width: parent.width
            opacity: statusMessage != "" ? 1.0: 0
            color: UbuntuColors.green
            anchors.bottom: parent.bottom
            text: statusMessage
            elide: Text.ElideRight
            Behavior on opacity {
                NumberAnimation { duration: 500 }
            }
        }
    }

    Image {
        anchors.fill: parent
        source: settingsPage.backgroundImage.source
    }

    UbuntuListView {
        id: listView

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: bottomContainer.top

        verticalLayoutDirection: ListView.BottomToTop

        clip: true

        property bool isAtBottomArea: contentHeight*(1-(listView.visibleArea.yPosition + listView.visibleArea.heightRatio)) < listView.height

        spacing: units.gu(1)
        delegate: ChatListItem {}

        header: Component {
            Item {
                height: units.gu(5)
                width: parent.width
            }
        }

        footer: Component {
            Item {
                height: units.gu(5)
                width: parent.width

                ActivityIndicator {
                    running: !loaded
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        PullToRefresh {
            id: pullToRefresh
            width: parent.width

            enabled: !firstMessageLoaded

            content: Item {
                height: parent.height
                width: height

                Label {
                    anchors.centerIn: parent
                    color: "white"
                    text: !pullToRefresh.releaseToRefresh ? i18n.tr("Pull to load more") : i18n.tr("Release to load more")
                }

            }

            onRefresh: {
                refreshing = true;
                pullToRefreshLoading = true;
                py.call('backend.load_more_messages', [convId]);
            }
        }

        UbuntuShape {
            id: btnScrollToBottom
            backgroundColor: "black"
            property double maxOpacity: 0.5
            width: units.dp(32)
            opacity: !listView.isAtBottomArea ? 0.5 : 0
            visible: opacity !== 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.InOutQuad
                }
            }
            height: width
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: units.gu(1)

            Icon {
                anchors.centerIn: parent
                width: units.dp(24)
                height: width
                name: "down"
                color: "white"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: listView.positionViewAtBeginning();
            }
        }

    }

    Rectangle {
        id: bottomContainer
        visible: !stickersOverlay.visible
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        height: units.gu(6)

        color: "white"

        RowLayout {
            anchors {
                fill: parent
                leftMargin: units.dp(16)
                rightMargin: units.dp(16)
            }
            spacing: units.dp(8)

            TextField {
                id: messageField
                placeholderText: i18n.tr("Write a message")
                Layout.fillWidth: true

                onAccepted: {
                    if (messageField.text !== "") {
                        py.call('backend.send_message', [convId, messageField.text]);
                        messageField.text = "";
                        py.call('backend.set_typing', [convId, "stopped"]);
                        pausedTypingTimer.stop();
                        stoppedTypingTimer.stop();
                    }
                }

                Timer {
                    id: pausedTypingTimer
                    interval: 1500
                    onTriggered: {
                        py.call('backend.set_typing', [convId, "paused"]);
                        stoppedTypingTimer.start();
                    }
                }

                Timer {
                    id: stoppedTypingTimer
                    interval: 3000
                    onTriggered: py.call('backend.set_typing', [convId, "stopped"]);
                }

                onTextChanged: {
                    py.call('backend.set_typing', [convId, "typing"]);
                    pausedTypingTimer.stop();
                    stoppedTypingTimer.stop();
                    pausedTypingTimer.start();
                }
            }

            Icon {
                name: "attachment"
                width: height
                height: messageField.height

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        PopupUtils.open(attachmentPopover, parent)
                    }
                }

            }

            Image {
                id: sendIcon
                visible: false
                source: Qt.resolvedUrl("../media/google-md-send-icon.svg")
                width: messageField.height
                height: messageField.height
                sourceSize: Qt.size(width, height)
            }

            ColorOverlay {
                width: sendIcon.width
                height: sendIcon.height
                source: sendIcon
                color: UbuntuColors.blue

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        Qt.inputMethod.commit();
                        Qt.inputMethod.hide();
                        if (messageField.text !== "") {
                            py.call('backend.send_message', [convId, messageField.text]);
                            messageField.text = "";
                            py.call('backend.set_typing', [convId, "stopped"]);
                            pausedTypingTimer.stop();
                            stoppedTypingTimer.stop();
                        }
                    }

                }
            }

        }

    }

    Component {
        id: attachmentPopover
        Popover {
            id: popover
            Column {
                id: containerLayout
                anchors {
                    left: parent.left
                    top: parent.top
                    right: parent.right
                }
                ListItem {
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: units.dp(16)
                        spacing: units.dp(8)

                        Icon {
                            name: 'insert-image'
                            width: units.dp(24)
                            height: width
                        }

                        Label {
                            text: i18n.tr("Send image")
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            PopupUtils.close(popover);
                            importContentPopup.show();
                        }
                    }
                }
                ListItem {
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: units.dp(16)
                        spacing: units.dp(8)

                        Icon {
                            name: 'other-actions'
                            width: units.dp(24)
                            height: width
                        }

                        Label {
                            text: i18n.tr("Send sticker")
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            stickersOverlay.show();
                            PopupUtils.close(popover);
                        }
                    }
                }
            }
        }
    }

    StickersOverlay {
        id: stickersOverlay

        onStickerTabbed: {
            py.call("backend.send_sticker", [convId, imageID]);
        }

        anchors {
            left: parent.left
            bottom: parent.bottom
            right: parent.right
        }

        height: showing ? Math.min(parent.height*(1/2), units.dp(356)) : 0

        Behavior on height {
            NumberAnimation {
                duration: 200
            }
        }
    }

    ImportContentPopup {
        parent: root
        id: importContentPopup
        contentType: ContentType.Pictures
        onItemsImported: {
            var picture = importItems[0];
            var url = picture.url;
            py.call('backend.send_image', [convId, url.toString()]);
        }
    }
}
