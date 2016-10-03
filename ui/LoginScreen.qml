import QtQuick 2.4
import Ubuntu.Components 1.3
import com.canonical.Oxide 1.9

 FocusScope {
    visible: false

    property string usContext: "messaging://"
    property alias loginInfo: infoLabel.text
    property bool loading: false
    property bool error: false

    /*
        Fix for https://github.com/tim-sueberkrueb/ubuntu-hangups/issues/68
    */

    Column {
        anchors {
            fill: parent
            margins: units.gu(2)
        }

        visible: !loading
        spacing: units.gu(2)

        Label {
            text: i18n.tr("Login")
            fontSize: "large"
        }

        FlexibleLabel {
            visible: error
            text: i18n.tr("Failed to authenticate. Please verify your login data again.")
            color: UbuntuColors.red
        }

        TextField {
            id: txtEmail
            placeholderText: "Google email address"
        }

        TextField {
            id: txtPassword
            placeholderText: "Password"
            echoMode: TextInput.Password
        }

        Row {
            spacing: units.gu(2)

            Button {
                text: "Cancel"
                color: UbuntuColors.red
                onClicked: {
                    Qt.quit();
                }
            }

            Button {
                text: "Login"
                color: UbuntuColors.green
                onClicked: {
                    loading = true;
                    error = false;
                    py.call("backend.auth_with_credentials", [txtEmail.text, txtPassword.text], function(result){
                        if (result) {
                            loginScreen.visible = false;
                            loadingScreen.visible = true;
                        }
                        else {
                            loading = false;
                            error = true;
                        }
                    });
                }
            }
        }

        FlexibleLabel {
            text: i18n.tr("In order to use Hangups you need to authenticate this app with Google")
        }

        FlexibleLabel {
            id: infoLabel
            text: i18n.tr("This app uses an inoffical Google Hangouts API called 'Hangups'. You can always deny the access <a href='https://security.google.com/settings/security/permissions'>here</a>.")
            onLinkActivated: Qt.openUrlExternally(link);
        }
    }

    ActivityIndicator {
        id: loadingIndicator
        anchors {
            bottom: loadingInfo.top
            bottomMargin: units.gu(1)
            horizontalCenter: parent.horizontalCenter
        }
        running: loading
        visible: loading
    }

    Label {
        id: loadingInfo
        anchors.centerIn: parent
        text: i18n.tr("Loading, please wait ...")
        visible: loading
    }
}
