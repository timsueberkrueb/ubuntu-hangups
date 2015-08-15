import QtQuick 2.0
import Ubuntu.Components 1.2
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

    }

    Audio {
        id: notificationSound
        source: 'notification-sound.wav'
    }

    Python {
        id: py
        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('.'));
            addImportPath(Qt.resolvedUrl('./lib/py'));

            // Actions

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

            setHandler('add-conversation', function(data) {
                console.log("add conversation", data.id_)
                conversationsModel.append(data);
                var chatModel = chatModelComponent.createObject(root);
                chatModels[data.id_] = chatModel;
            });

            setHandler('set-conversation-title', function(conv_id, title, unread_count) {
                console.log("set conversation title of ", conv_id, "to", title)
                conversationsModel.get(getConversationModelIndexById(conv_id)).title = title;
                if (unread_count > conversationsModel.get(getConversationModelIndexById(conv_id)).unread_count) {
                    notificationSound.play();
                }
                conversationsModel.get(getConversationModelIndexById(conv_id)).unread_count = unread_count;
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

            importModule('backend', function(){
                console.log("python loaded");
                call('backend.start')
            });
        }
        onError: console.log('Error: ' + traceback)
    }


}

