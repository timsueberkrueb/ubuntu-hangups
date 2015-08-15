import QtQuick 2.0
import Ubuntu.Components 1.2

ListItem {
    id: listItem

    property QtObject modelData: listView.model.get(index)
    property bool is_self: modelData.user_is_self

    property color backgroundColor: "white" //is_self ? "#3fb24f" : "white"
    property color foregroundColor: "black "//is_self ? "white" : "black"

    divider.visible: false
    height: rect.height

    trailingActions: ListItemActions {

        actions: [
            Action {
                iconName: "edit-copy"
                enabled: testMimeData.text !== ""
                visible: testMimeData.text !== ""
                onTriggered: {
                    Clipboard.push(testMimeData);
                }
            }
        ]
    }

    onClicked: {
        if (modelData.attachments.count > 0) {
            pageStack.push(viewImagePage, {images: modelData.attachments});
        }
    }

    Component {
        id: imagesListView
        ListView {
            visible: modelData.attachments.count > 0
            width: parent.width
            height: childrenRect.height
            interactive: false

            model:  modelData.attachments

            delegate: UbuntuShape {
                width: parent.width
                height: img.height || units.gu(24)
                backgroundColor: "white"

                source: Image {
                    id: img
                    fillMode: Image.PreserveAspectFit
                    width: parent.width
                    source: url
                }

                ActivityIndicator {
                    anchors.centerIn: parent
                    visible: img.progress != 1.0
                    running: true
                }

            }
        }
    }

    Item {
        id: item
        width: parent.width < units.gu(60) ? parent.width - units.gu(15): units.gu(60) - units.gu(15)
        height: childrenRect.height

        anchors.right: is_self ? parent.right: undefined
        anchors.left: !is_self ? parent.left: undefined

        Row {
            anchors.fill: parent
            height: childrenRect.height
            layoutDirection: is_self ? Qt.RightToLeft: Qt.LeftToRight

            Canvas {
                id: canvas
                width: units.gu(2)
                height: rect.height
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.lineWidth = 1
                    ctx.strokeStyle = backgroundColor
                    ctx.fillStyle = backgroundColor
                    ctx.beginPath()
                    if (!is_self) {
                        ctx.moveTo(width*4/5,height/2)
                        ctx.lineTo(width, height*4/10)
                        ctx.lineTo(width, height*6/10)
                    }
                    else if (is_self) {
                        ctx.moveTo(0,height*4/10)
                        ctx.lineTo(width*1/5,height/2)
                        ctx.lineTo(0, height*6/10)
                    }
                    ctx.closePath()
                    ctx.fill()
                    ctx.stroke()
                }
            }

            Rectangle {
                id: rect
                color: backgroundColor
                radius: units.dp(3)
                height: childrenRect.height
                width: parent.width - canvas.width

                Column {
                    id: col
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: units.gu(1)
                    spacing: units.gu(1)
                    height: childrenRect.height + spacing + 2*anchors.margins

                    Label {
                        id: nameLabel
                        visible: !modelData.user_is_self
                        color: UbuntuColors.green
                        text: modelData.username
                    }

                    FlexibleLabel {
                        id: messageLabel
                        visible: text !== ""
                        onLinkActivated: Qt.openUrlExternally(link)
                        width: parent.width
                        color: foregroundColor
                        text: modelData.text
                    }

                    MimeData {
                        id: testMimeData
                        color: "green"
                        text: messageLabel.text
                    }

                    Item {
                        id: listViewContainer
                        width: parent.width
                        height: childrenRect.height
                    }

                    Component.onCompleted: {
                        if (modelData.attachments.count  > 0) {
                            imagesListView.createObject(listViewContainer, {});
                        }
                    }

                    Row {
                        width: parent.width
                        layoutDirection: Qt.RightToLeft

                        Label {
                            color: UbuntuColors.darkGrey
                            text: modelData.time
                        }
                    }

                }


            }
        }
    }

}
