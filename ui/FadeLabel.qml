import QtQuick 2.4
import Ubuntu.Components 1.3


Label {
    id: label

    function fadeText (text) {
        fadeOutAnimation.running = true;
        fadeOutAnimation.stopped.connect(function () {
            label.text = text;
            fadeInAnimation.running = true;
        });
    }

    property int duration: 500

    NumberAnimation {
        id: fadeOutAnimation
        target: label;
        property: "opacity";
        duration: duration;
        easing.type: Easing.InOutQuad
        from: 1
        to: 0
    }

    NumberAnimation {
        id: fadeInAnimation
        target: label;
        property: "opacity";
        duration: duration;
        easing.type: Easing.InOutQuad
        from: 0
        to: 1
    }
}
