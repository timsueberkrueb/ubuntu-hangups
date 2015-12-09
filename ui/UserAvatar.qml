import QtQuick 2.4
import Ubuntu.Components 1.3

UbuntuShape {
    property string name
    property string photoUrl: ""

    height: units.dp(32)
    width: units.dp(32)
    backgroundColor: UbuntuColors.lightGrey

    Label {
        visible: photoUrl === "" || photo.status != Image.Ready
        color: "white"
        anchors.centerIn: parent
        text: name[0].toUpperCase()
        font.bold: true
    }

    source: Image {
        id: photo
        source: photoUrl
    }

}
