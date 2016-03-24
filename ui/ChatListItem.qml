import QtQuick 2.4
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3
import Ubuntu.Components.Themes.Ambiance 1.3

Item {
    id: listItem

    width: parent.width
    height: childrenRect.height

    property QtObject modelData: listView.model.get(index)
    property bool is_self: modelData.user_is_self

    property color backgroundColor: "white" //is_self ? "#3fb24f" : "white"
    property color foregroundColor: "black" //is_self ? "white" : "black"

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (modelData.attachments && modelData.attachments.count > 0) {
                pageLayout.addPageToNextColumn(chatPage, viewImagePage, {images: modelData.attachments});
            }
        }
    }

    Component {
        id: attachedImageComponent

        UbuntuShape {
            width: parent.width
            height: img.height || units.gu(24)
            backgroundColor: "white"

            property string url

            source: AnimatedImage {
                id: img
                fillMode: Image.PreserveAspectFit
                width: parent.width
                source: url
            }

            Icon {
                id: imageErrorIcon
                anchors.centerIn: parent
                anchors.margins: units.gu(1)
                name: "dialog-warning-symbolic"
                visible: img.status == Image.Error
                width: units.dp(48)
                height: width
            }

            FlexibleLabel {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: imageErrorIcon.bottom
                anchors.margins: units.gu(1)
                text: i18n.tr("An error occurred while loading the image.")
                visible: img.status == Image.Error
            }


            ActivityIndicator {
                anchors.centerIn: parent
                visible: img.status == Image.Loading
                running: true
            }
        }
    }

    Item {
        id: infoItem
        visible: modelData.type !== "chat/message"
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width < units.gu(60) ? parent.width - units.gu(15): units.gu(60) - units.gu(15)
        height: infoLabel.height + units.gu(2)

        Rectangle {
            anchors.fill: parent
            radius: height * 0.5
            color: "white"

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: switch(modelData.type) {
                    case "chat/rename":
                        return alpha(UbuntuColors.ash, 0.6);
                    case "chat/add":
                        return alpha(UbuntuColors.green, 0.6);
                    case "chat/leave":
                        return alpha(UbuntuColors.red, 0.6);
                    default:
                        return "black";
                }
            }

            Item {
                anchors {
                    fill: parent
                    margins: units.gu(1)
                    leftMargin: units.gu(2)
                    rightMargin: units.gu(2)
                }

                RowLayout {
                    spacing: units.dp(16)
                    anchors.fill: parent

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        width: units.dp(16)
                        height: width
                        color: "white"
                        name: switch(modelData.type) {
                            case "chat/rename":
                                return "edit";
                            case "chat/add":
                                return "add";
                            case "chat/leave":
                                return "next";
                            default:
                                return "black";
                        }

                    }

                    FlexibleLabel {
                        id: infoLabel
                        color: "white"
                        Layout.fillWidth: true
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: units.dp(13)
                        text: switch (modelData.type) {
                              case "chat/rename":
                                  return i18n.tr("Retitled to %1 by %2").arg(modelData.new_name).arg(modelData.username);
                              case "chat/add":
                                  return i18n.tr("%1 added %2").arg(modelData.username).arg(modelData.name);
                              case "chat/leave":
                                  return i18n.tr("%1 left").arg(modelData.name);
                              default:
                                  return "";
                        }
                    }
                }

            }
        }
    }

    Item {
        id: chatItem
        visible: modelData.type === "chat/message"

        width: parent.width < units.gu(60) ? parent.width - units.gu(15): units.gu(60) - units.gu(15)
        height: childrenRect.height

        anchors.right: is_self ? parent.right: undefined
        anchors.left: !is_self ? parent.left: undefined

        Row {
            layoutDirection: is_self ? Qt.RightToLeft: Qt.LeftToRight
            height: childrenRect.height
            width: parent.width

            Item {
                visible: !is_self
                width: units.gu(1)
                height: rect.height
            }

            UserAvatar {
                visible: !is_self && conversationsModel.get(getConversationModelIndexById(convId)).users.count > 2
                anchors.verticalCenter: rect.verticalCenter
                name: visible ? modelData.username : ""
                photoUrl: visible ? modelData.user_photo : ""
            }

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
                    anchors.margins: units.dp(4)
                    anchors.leftMargin: units.dp(8)
                    anchors.rightMargin: units.dp(8)
                    spacing: (units.dp(4))
                    height: childrenRect.height + spacing + 2*anchors.margins

                    Label {
                        id: nameLabel
                        visible: !modelData.user_is_self
                        color: UbuntuColors.green
                        text: modelData.username
                        font.pixelSize: units.dp(13)
                        font.bold: true
                    }

                    Item {
                        width: parent.width
                        height: childrenRect.height

                        FlexibleLabel {
                            id: messageLabel
                            visible: text !== ""
                            onLinkActivated: {
                                Qt.openUrlExternally(link);
                                textAreaTimer.stop();
                            }
                            width: parent.width
                            color: foregroundColor
                            text: modelData.html ? modelData.html : ""
                            font.pixelSize: units.dp(13)

                            MouseArea {
                                id: enableSelectionArea
                                anchors.fill: parent
                                onPressed: {
                                    textAreaTimer.restart();
                                    mouse.accepted = false;
                                }

                                Timer {
                                    id: textAreaTimer
                                    interval: 300
                                    onTriggered: {
                                        messageTextArea.visible = true;
                                        messageTextArea.cursorPosition = messageTextArea.positionAt(enableSelectionArea.mouseX, enableSelectionArea.mouseY)
                                        messageTextArea.selectWord();
                                        messageTextArea.focus = true;
                                        messageLabel.visible = false;
                                    }
                                }
                            }
                        }

                        TextArea {
                            id: messageTextArea
                            anchors.fill: messageLabel
                            visible: false
                            width: parent.width
                            autoSize: true
                            clip: true
                            readOnly: true
                            onLinkActivated: Qt.openUrlExternally(link)
                            text: modelData.html ? modelData.html : ""
                            font.pixelSize: units.dp(13)
                            textFormat: TextEdit.RichText
                            cursorVisible: false

                            style: TextAreaStyle {
                                frameSpacing: 0
                                color: foregroundColor
                                backgroundColor: backgroundColor
                            }

                            onActiveFocusChanged: {
                                if (!activeFocus) {
                                    visible = false;
                                    messageLabel.visible = true;
                                }
                            }
                        }
                    }

                    MimeData {
                        id: textMimeData
                        color: "green"
                        text: modelData.text
                    }

                    Item {
                        id: imageContainer
                        width: parent.width
                        height: childrenRect.height
                    }

                    Row {
                        width: parent.width
                        layoutDirection: Qt.RightToLeft

                        spacing: units.dp(8)

                        Label {
                            visible: is_self
                            text: modelData.sent ? "" : "🕐"
                            //text: modelData.sent ? "✓" : "🕐"
                            font.pixelSize: units.dp(12)
                        }

                        Label {
                            color: UbuntuColors.darkGrey
                            text: modelData.time
                            font.pixelSize: units.dp(12)
                        }
                    }

                    Component.onCompleted: {
                        if (modelData.attachments && modelData.attachments.count  > 0) {
                            attachedImageComponent.createObject(imageContainer, {url: Qt.resolvedUrl(modelData.attachments.get(0).url)});
                        }
                    }
                }
            }
        }
    }
}
