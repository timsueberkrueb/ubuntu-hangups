import QtQuick 2.0
import Ubuntu.Components 1.3

Item {
    id: item

    property bool custom_animation: false
    property bool running

    AnimatedImage {
        id: animation
        visible: item.running && custom_animation

        smooth: true
        cache: true
        width: units.dp(48)
        height: width

        source: "../media/loading-animation.gif"
    }

    ActivityIndicator {
        id: activity
        visible: item.running && !custom_animation
        running: visible

    }

}
