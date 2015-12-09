import QtQuick 2.4
import Ubuntu.Components 1.3

UbuntuShape {
    property string name
    height: units.dp(32)
    width: units.dp(32)
    backgroundColor: UbuntuColors.lightGrey
    Icon {
        id: groupIcon
        anchors.centerIn: parent
        height: units.dp(26)
        width: units.dp(26)
        name: "contact-group"
        color: "white"
    }
}
