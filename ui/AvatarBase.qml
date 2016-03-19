import QtQuick 2.4
import Ubuntu.Components 1.3

UbuntuShape {
    property string name
    height: units.dp(32)
    width: units.dp(32)
    backgroundColor: getIconColor(name, colors)

    property var colors: ["#6b9362", "#4d8fac", "#bb7796", "#b95754", "#ffa565", "#f7bb7d", "#bda928"]

    function getIconColor(name, colors) {
        /*
           Code derived from Dekko (https://launchpad.net/dekko)
           Thanks to Dan Chapman.
        */
        var tmp = 0;
        for (var i = 0; i < name.length; i++) {
            tmp += name.charCodeAt(i);
        }
        return colors[tmp % colors.length];
    }
}
