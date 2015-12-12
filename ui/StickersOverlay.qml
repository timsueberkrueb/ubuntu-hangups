import QtQuick 2.4
import QtQuick.Layouts 1.0
import Ubuntu.Components 1.3
import "."

Rectangle {
    id: stickersOverlay
    property int currentStickerSet: 0
    property bool showing: false

    signal stickerTabbed (var imageID)

    onShowingChanged: {
        if (!Stickers.loaded)
            Stickers.load();
    }

    visible: height > 0

    function hide() {
        showing = false;
    }

    function show() {
        Qt.inputMethod.hide();
        showing = true;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.rightMargin: units.dp(8)

        Flickable {
            Layout.fillWidth: true

            contentWidth: row.childrenRect.width + units.dp(64)
            height: units.dp(64)
            Row {
                id: row
                height: parent.height
                Repeater {
                    id: repeater
                    model: Stickers.stickers
                    delegate: Rectangle {
                        color: currentStickerSet === index ? UbuntuColors.lightGrey : "transparent"
                        property url imageSource: modelData !== undefined ? modelData["icon"] : Qt.resolvedUrl("");
                        width: childrenRect.width
                        height: childrenRect.height
                        Image {
                            source: imageSource
                            sourceSize: Qt.size(units.dp(48), units.dp(48))
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                currentStickerSet = index;
                            }
                        }
                    }
                }
            }
        }

        Flickable {
            clip: true
            Layout.fillHeight: true
            Layout.fillWidth: true
            contentHeight: flow.childrenRect.height

            Flow {
                id: flow
                anchors.fill: parent
                Repeater {
                    model: Stickers.stickers.length === 0 ? [] : Stickers.stickers[currentStickerSet]["stickers"]
                    delegate: Image {
                        fillMode: Image.PreserveAspectFit
                        source: modelData["url"];
                        width: units.dp(96)

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                stickerTabbed(modelData["gphoto_id"])
                                hide();
                            }
                        }
                    }
                }
            }
        }
    }

    ActivityIndicator {
        anchors.centerIn: parent
        visible: Object.keys(Stickers.stickers).length === 0
        running: visible
    }

    Rectangle {
        anchors {
            right: parent.right
            top: parent.top
        }
        width: units.dp(64)
        height: units.dp(64)

        Icon {
            anchors.centerIn: parent
            height: units.dp(24)
            width: height
            name: "close"
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    hide();
                }
            }
        }
    }
}
