import QtQuick 2.0
import Ubuntu.Components 1.2
 import Ubuntu.Components.Popups 1.0
import QtMultimedia 5.2
import io.thp.pyotherside 1.4
import "ui"


MainView {
    id: root

    objectName: "mainView"
    applicationName: "ubuntu-hangups.timsueberkrueb"
    automaticOrientation: true

    // automatically anchor items to keyboard that are anchored to the bottom
    anchorToKeyboard: true

    // Set theme
    Component.onCompleted: Theme.name = "theme"

    width: units.dp(540*3/4)
    height: units.dp(960*3/4)

    property ListModel conversationsModel: ListModel {}
    property ListModel contactsModel: ListModel {}

    Component {
        id: chatModelComponent
        ListModel {}
    }

    property var chatModels: ({})
    property var currentChatModel


    function setCurrentConversation (conv_id) {
        currentChatModel = chatModels[conv_id];
    }

    function getConversationModelIndexById(conv_id) {
        for (var i=0; i<conversationsModel.count; i++) {
            if (conversationsModel.get(i).id_ === conv_id) {
                return i;
            }
        }
        return false;
    }

    NetworkErrorDialog {
        id: networkErrorDialog
    }

    PageStack {
        id: pageStack
        Component.onCompleted: push(loadingPage)

        LoadingPage {
            id: loadingPage
        }

        LoginPage {
            id: loginPage
        }

        ContactsPage {
            id: contactsPage
        }

        ConversationsPage {
            id: conversationsPage
        }

        AboutConversationPage {
            id: aboutConversationPage
        }

        ViewImagePage {
            id: viewImagePage
        }

        AboutPage {
            id: aboutPage
        }

        SettingsPage {
            id: settingsPage
        }

        ChatPage {
            id: chatPage
        }

        SelectUsersPage {
            id: selectUsersPage
        }

    }

    Audio {
        id: notificationSound
        source: 'media/notification-sound.wav'
    }

    Python {
        id: py
        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('.'));
            addImportPath(Qt.resolvedUrl('./lib/py'));

            // Actions

            setHandler('show-network-error', function(error_type, error_title, error_message) {
                var dialog = PopupUtils.open(networkErrorDialog);
                dialog.errorType = error_type.toString();
                dialog.errorTitle = error_title.toString();
                dialog.errorMessage = error_message.toString();
            });

            setHandler('show-login-page', function() {
                pageStack.clear();
                pageStack.push(loginPage);
            });

            setHandler('show-conversations-page', function() {
                pageStack.clear();
                pageStack.push(conversationsPage);
            });

            setHandler('move-conversation-to-top', function(conv_id){
                console.log('move-conversation-to-top ', conv_id)
                conversationsModel.move(getConversationModelIndexById(conv_id), 0, 1);
            });

            setHandler('add-conversation', function(data, sound) {
                console.log("add conversation", data.id_)
                conversationsModel.append(data);
                var chatModel = chatModelComponent.createObject(root);
                chatModels[data.id_] = chatModel;
                if (sound)
                    notificationSound.play();
            });

            setHandler('delete-conversation', function(conv_id) {
                console.log("delete conversation", conv_id)
                conversationsModel.remove(getConversationModelIndexById(conv_id));
            });


            setHandler('set-conversation-title', function(conv_id, title, unread_count, status_message) {
                console.log("set conversation title of ", conv_id, "to", title, "|", status_message)
                conversationsModel.get(getConversationModelIndexById(conv_id)).title = title;
                conversationsModel.get(getConversationModelIndexById(conv_id)).status_message = status_message;

                if (pageStack.currentPage == chatPage && chatPage.conv_id == conv_id) {
                    py.call("backend.read_messages", [conv_id]);
                    chatPage.title = title;
                    chatPage.status_message = status_message;
                }
                else {
                    if (unread_count > conversationsModel.get(getConversationModelIndexById(conv_id)).unread_count) {
                        notificationSound.play();
                    }
                    conversationsModel.get(getConversationModelIndexById(conv_id)).unread_count = unread_count;
                }
            });

            setHandler('set-conversation-status', function(conv_id, status_message, typers){
                console.log('set-conversation-status of', conv_id)
                if (pageStack.currentPage == chatPage && chatPage.conv_id == conv_id) {
                    if (typers) {
                        if (typers.length === 1) {
                            status_message = i18n.tr("%1 is typing ...").arg(typers[0]);
                        }
                        else if (typers.length > 1) {
                            var t = ""
                            for (var i=0; i<typers.length; i++) {
                                t += typers[i] + ', '
                            }
                            t = t.slice(0, t.length-2);
                            status_message = i18n.tr('%1 are typing ...').arg(t);
                        }
                    }
                    chatPage.status_message = status_message;
                }
            });

            setHandler('add-conversation-message', function(conv_id, data, insert_mode){
                console.log('add-conversation-message to ', conv_id, data.text)
                if (insert_mode === "bottom") {
                    chatModels[conv_id].append(data);
                    if (pageStack.currentPage === chatPage && chatPage.conv_id === conv_id) {
                        pageStack.currentPage.listView.positionViewAtEnd();
                    }
                }
                else if (insert_mode === "top") {
                    chatModels[conv_id].insert(0, data);
                    chatPage.pullToRefresh.refreshing = false;
                }
            });

            setHandler('clear-conversation-messages', function(conv_id){
                console.log('clear-conversation-messages of ', conv_id)
                chatModels[conv_id].clear();
            });

            setHandler('set-conversation-users', function(conv_id, users){
                console.log('set-conversation-users of ', conv_id, users)
                var users_model = conversationsModel.get(getConversationModelIndexById(conv_id)).users;
                users_model.clear();
                for (var i=0; i<users.length; i++) {
                    users_model.append(users[i]);
                }
            });

            setHandler('add-contact', function(data) {
                console.log("add contact", data.name)
                contactsModel.append(data);
            });

            // Events

            setHandler('on-message-sent', function(conv_id){
                console.log('on-message-sent', conv_id);
            });

            setHandler('on-more-messages-loaded', function(conv_id){
                console.log('on-more-messages-loaded')
            });

            setHandler('on-first-message-loaded', function(conv_id){
                console.log('on-first-message-loaded')
                conversationsModel.get(getConversationModelIndexById(conv_id)).first_message_loaded = true;
                if (chatPage.conv_id === conv_id){
                    chatPage.first_message_loaded = true;
                    chatPage.pullToRefresh.refreshing = false;
                }

            });

            setHandler('on-new-conversation-created', function(conv_id){
                console.log('on-new-conversation-created');
                var dialog = PopupUtils.open(newConversationWelcomeDialog);
                dialog.conv_id = conv_id;

            });

            importModule('backend', function(){
                console.log("python loaded");
                call('backend.start')
            });
        }
        onError: {
            console.log('Error: ' + traceback);
            var dialog = PopupUtils.open(errorDialog);
            dialog.traceback = traceback;
        }
    }


    NewConversationWelcomeDialog {
        id: newConversationWelcomeDialog
    }

    Component {
         id: errorDialog
         Dialog {
             id: dialog
             title: i18n.tr("Error")

             property string traceback: ""

             text: i18n.tr("An error has occured: %1").arg(traceback)

             property string id_

             Button {
                 id: cancelButton
                 text: i18n.tr("Close")
                 onClicked: PopupUtils.close(dialog)
             }
         }
    }
}

