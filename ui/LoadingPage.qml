import QtQuick 2.0
import Ubuntu.Components 1.3
//import Ubuntu.Web 0.2

 Page {
    title: "Hangups"
    visible: false

    property bool hangups_animation: animation.status == Image.Ready

    Rectangle {
        anchors.fill: parent
        color: "white"

        AnimatedImage {
            id: animation
            smooth: true
            cache: true
            width: units.dp(128)
            height: width
            visible: hangups_animation
            anchors.bottom: loadingLabel.top
            anchors.bottomMargin: units.gu(3)
            anchors.horizontalCenter: parent.horizontalCenter


            opacity: 0

            Timer {
                id: growTimer
                interval: 1250
                onTriggered: {
                    animation.width = units.dp(128);
                    growTimer.stop()
                    shrinkTimer.start();
                }
            }


            Timer {
                id: shrinkTimer
                interval: 1250
                onTriggered: {
                    animation.width = units.dp(95);
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

        ActivityIndicator {
            id: activity_indicator
            visible: !hangups_animation
            running: true
            anchors.bottom: loadingLabel.top
            anchors.bottomMargin: units.gu(3)
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Label {
            id: loadingLabel
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.width/2 + animation.width + units.gu(3)
            text: i18n.tr("Loading, please wait ...")
            //anchors.centerIn: parent
        }

    }

}
