import QtQuick 2.0
import Ubuntu.Components 1.2
//import Ubuntu.Web 0.2
import com.canonical.Oxide 1.0
import Ubuntu.OnlineAccounts 0.1
import Ubuntu.OnlineAccounts.Client 0.1


 Page {
    title: i18n.tr("Authenticate with Google")
    visible: false

    property string usContext: "messaging://"
    property var refreshToken
    property var accessToken

    Column {
        id: infoContainer
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: units.gu(2)
        spacing: units.gu(1)
        height: childrenRect.height + units.gu(1)

        visible: height !== 0 && opacity !== 0

        Behavior on height {
            NumberAnimation {duration: 100}
        }

        Behavior on opacity {
            NumberAnimation {duration: 90}
        }

        function hide() {
            height = 0;
        }

        FlexibleLabel {
            text: i18n.tr("In order to use Hangups you need to authenticate this app with Google")
        }

        Row {
            anchors.margins: units.gu(1)
            spacing: units.gu(1)
            width: parent.width

            Button {
                text: i18n.tr("About")
                color: UbuntuColors.blue
                onClicked: pageStack.push(aboutPage)
            }

            Button {
                text: i18n.tr("Got it")
                color: UbuntuColors.green
                onClicked: {
                    infoContainer.hide();
                }
            }


        }

    }

    Item {
        id: loginContainer
        anchors.top: infoContainer.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        AccountServiceModel {
          id: accounts
          applicationId: "ubuntu-hangups.timsueberkrueb_Hangups"
          provider : "google"
        }

        Setup {
          id: setup
          applicationId: accounts.applicationId
          providerId: "google"
        }

        UbuntuListView {
            id: accountsView
            anchors.fill: parent
            model: accounts
            spacing: units.gu(2)
            delegate: ListItem {
                width: parent.width
                id: rect

                Row {
                    anchors.fill: parent
                    spacing: units.gu(2)
                    anchors.margins: units.gu(2)

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "google"
                        width: units.dp(32)
                        height: units.dp(32)
                    }

                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: model.displayName
                    }
                }

                AccountService {
                    id: accountService
                    objectHandle: model.accountServiceHandle
                    onAuthenticated: {
                        console.log(JSON.stringify(reply))
                        successLabel.text = reply.toString()
                        refreshToken = reply.RefreshToken;
                        accessToken = reply.AccessToken;
                        accountsView.visible = false;
                        finishedIcon.opacity = 1;
                    }
                    onAuthenticationError: {
                        console.log("Authentication failed, code " + error.code); l.text="Authentication failed, code "  +error.code.toString() + ' -> \n”' + error.message }
                }

                onClicked: {
                    accountService.authenticate();
                }
            }

            Button {
                anchors.centerIn: parent
                visible: accounts.count === 0
                text: "Authorize a Google account"
                color: UbuntuColors.green
                onClicked: setup.exec()
            }

        }

    }

    Rectangle {
        id: finishedIcon
        opacity: 0
        Behavior on opacity {
            NumberAnimation { duration: 1000 }
        }

        Behavior on y {
            SmoothedAnimation { duration: 1000 }
        }

        anchors.horizontalCenter: parent.horizontalCenter
        y: if (opacity === 1) {parent.height/2 - height} else { parent.height/2 - height/2 }

        width: if (parent.width<=256) { parent.width/2 } else { 256/2 }
        height: width
        color: UbuntuColors.green
        border.color: UbuntuColors.warmGrey
        border.width: 1
        radius: width*0.5

        Icon {
             anchors.centerIn: parent
             width: parent.width/2
             height: width
             name: "ok"
             color: "white"
        }
    }

    Label {
        id: successLabel
        opacity: if (finishedIcon.opacity === 1) { 1 } else { 0 }
        Behavior on opacity {
            NumberAnimation { duration: 1000 }
        }

        anchors.top: finishedIcon.bottom
        anchors.topMargin: units.gu(2)
        anchors.horizontalCenter: parent.horizontalCenter

        text: i18n.tr("Welcome to Hangups!")
        fontSize: "large"
    }

    Button {
        opacity: if (finishedIcon.opacity === 1) { 1 } else { 0 }
        Behavior on opacity {
            NumberAnimation { duration: 1000 }
        }

        anchors.top: successLabel.bottom
        anchors.topMargin: units.gu(2)
        anchors.horizontalCenter: parent.horizontalCenter
        text: i18n.tr("Get started")
        color: UbuntuColors.green
        onClicked: {
            pageStack.clear();
            pageStack.push(loadingPage);
            py.call('backend.auth_with_code', [refreshToken, accessToken]);
        }

    }

}
