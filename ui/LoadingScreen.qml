import QtQuick 2.4
import Ubuntu.Components 1.3

 FocusScope {
    z: 5
    property string statusAuthenticating: i18n.tr("Authenticating ...")
    property string statusCreatingClient: i18n.tr("Creating Hangups client ...")
    property string statusAddingObserver: i18n.tr("Adding client observer ...")
    property string statusLoadingChats: i18n.tr("Loading chats ...")
    property var statusDict: ({
                                  "authenticating": statusAuthenticating,
                                  "creatingClient": statusCreatingClient,
                                  "addingObserver": statusAddingObserver,
                                  "loadingChats": statusLoadingChats
                              })

    function setLoadingStatus (status) {
        loadingStatusLabel.fadeText(statusDict[status]);
    }

    Rectangle {
        anchors.fill: parent
        color: "white"

        AnimatedImage {
            id: animation
            smooth: true
            cache: true
            width: units.dp(95)
            height: width
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            opacity: 0

            Timer {
                id: growTimer
                interval: 1250
                onTriggered: {
                    animation.width = units.dp(95);
                    growTimer.stop()
                    shrinkTimer.start();
                }
            }

            Timer {
                id: shrinkTimer
                interval: 1250
                onTriggered: {
                    animation.width = units.dp(64);
                    shrinkTimer.stop();
                    growTimer.start();
                }
            }

            Behavior on width {
                NumberAnimation { duration: 1250; easing.type: Easing.InOutQuad }
            }

            Component.onCompleted: {
                opacity = 1.0;
                shrinkTimer.start();
            }

            Behavior on opacity {
                NumberAnimation { duration: 1000 }
            }

            source: "../media/loading-animation.gif"
        }

        FadeLabel {
            id: loadingStatusLabel
            color: UbuntuColors.coolGrey
            text: i18n.tr("Loading, please wait ...")
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: animation.bottom
            anchors.topMargin: units.gu(3) + units.gu(1) * opacity
        }

    }

    FadeLabel {
        id: poweredByLabel
        text: "Powered by"

        anchors.bottom: parent.bottom
        anchors.bottomMargin: units.gu(1) + units.gu(1) * opacity
        x: parent.width/2 - width
    }

    FadeLabel {
        font.bold: true

        anchors.left: poweredByLabel.right
        anchors.leftMargin: units.gu(1)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: units.gu(1) + units.gu(1) * opacity

        duration: 200

        Timer {
            interval: 1000
            repeat: true
            running: true
            triggeredOnStart: true

            property string thanksToText: i18n.tr("Thanks to")
            //: This may be the originial text if it sounds good in your language
            property string poweredByText: i18n.tr("Powered by")

            property var texts: [
                [poweredByText, "Python"],
                [poweredByText, "PyOtherSide"],
                [poweredByText, "Hangups"],
                [thanksToText, "Tom Dryer"],
                [thanksToText, "Fabian"],
                [thanksToText, "Sam Hewitt"],
                //: This is the "you all ツ" part of "Thanks to you all ツ"
                [thanksToText, i18n.tr("you all ツ")],
            ]

            property int currentIndex: -1

            onTriggered: {
                currentIndex++;
                if (currentIndex ===  texts.length)
                     currentIndex = 0;
                parent.fadeText(texts[currentIndex][1]);
                if (texts[currentIndex][0] !== poweredByLabel.text)
                    poweredByLabel.fadeText(texts[currentIndex][0])
            }
        }
    }
}
