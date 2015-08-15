import QtQuick 2.0
import Ubuntu.Components 1.2
//import Ubuntu.Web 0.2
import com.canonical.Oxide 1.0

 Page {
    title: "Hangups"
    visible: false

    ActivityIndicator {
        running: true
        anchors.bottom: loadingLabel.top
        anchors.bottomMargin: units.gu(2)
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Label {
        id: loadingLabel
        text: i18n.tr("Loading, please wait ...")
        anchors.centerIn: parent
    }
}
