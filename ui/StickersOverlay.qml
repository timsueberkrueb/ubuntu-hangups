import QtQuick 2.4
import QtQuick.Layouts 1.0
import Ubuntu.Components 1.3
import "stickerset.js" as StickerSet

Rectangle {
    id: stickersOverlay
    property string currentStickerSet: "Callouts_Internet"
    property bool showing: false
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

        RowLayout {
            height: units.dp(64)
            Layout.fillWidth: true

            Row {
                Layout.fillWidth: true

                Repeater {
                    id: repeater
                    model: Object.keys(StickerSet.tabs)
                    delegate: Rectangle {
                        color: currentStickerSet === modelData ? UbuntuColors.lightGrey : "transparent"
                        property url imageSource: StickerSet.tabs[modelData];
                        width: childrenRect.width
                        height: childrenRect.height
                        Image {
                            source: imageSource
                            sourceSize: Qt.size(units.dp(48), units.dp(48))
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                currentStickerSet = modelData;
                            }
                        }
                    }
                }

            }

            Icon {
                name: "close"
                height: units.dp(24)
                width: height
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        hide();
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
                    model: StickerSet.stickers[currentStickerSet]
                    delegate: Image {
                        fillMode: Image.PreserveAspectFit
                        source: modelData
                        width: units.dp(96)
                    }
                }
            }
        }
    }
}
