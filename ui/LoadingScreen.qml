import QtQuick 2.0
import Ubuntu.Components 1.3
//import Ubuntu.Web 0.2

 Item {
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

        Label {
            id: loadingStatusLabel
            color: UbuntuColors.coolGrey
            text: i18n.tr("Loading, please wait ...")
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: animation.bottom
            anchors.topMargin: units.gu(3) + units.gu(1) * opacity

            function fadeText (text) {
                fadeOutAnimation.running = true;
                fadeOutAnimation.stopped.connect(function () {
                    loadingStatusLabel.text = text;
                    fadeInAnimation.running = true;
                });
            }

            NumberAnimation {
                id: fadeOutAnimation
                target: loadingStatusLabel;
                property: "opacity";
                duration: 500;
                easing.type: Easing.InOutQuad
                from: 1
                to: 0
            }

            NumberAnimation {
                id: fadeInAnimation
                target: loadingStatusLabel;
                property: "opacity";
                duration: 500;
                easing.type: Easing.InOutQuad
                from: 0
                to: 1
            }
        }

    }

}
