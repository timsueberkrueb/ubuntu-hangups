import QtQuick 2.4
import Ubuntu.Components 1.3

AvatarBase {
    Label {
        color: "white"
        anchors.centerIn: parent
        text: name[0].toUpperCase()
        font.bold: true
    }
}
