import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import QtMultimedia 5.4
import io.thp.pyotherside 1.4
import "ui"


MainView {
    id: root

    objectName: "mainView"
    applicationName: "ubuntu-hangups.timsueberkrueb"
    automaticOrientation: true

    // automatically anchor items to keyboard that are anchored to the bottom
    anchorToKeyboard: true

    width: 720
    height: 540

    property ListModel conversationsModel: ListModel {}
    property ListModel contactsModel: ListModel {}
    property bool debugEvents: true
    property var chatPages: ({})
    property var chatModels: ({})

    function getConversationModelIndexById(conv_id) {
        for (var i=0; i<conversationsModel.count; i++) {
            if (conversationsModel.get(i).id_ === conv_id) {
                return i;
            }
        }
        return false;
    }

    function debugEvent() {
        if (debugEvents) {
            var s = "";
            for (var a=0; a<arguments.length; a++)
                s += arguments[a] + (a < arguments.length-1 ? " " : "")
            console.debug(s);
        }
    }


    Component {
        id: chatModelComponent
        ListModel {}
    }

    Component {
        id: chatPageComponent
        ChatPage {}
    }

    NetworkErrorDialog {
        id: networkErrorDialog
    }

    LoadingScreen {
        id: loadingScreen
        anchors.fill: parent
    }

    AdaptivePageLayout {
        id: pageLayout
        primaryPage: conversationsPage
        anchors.fill: parent
        visible: false
        layouts: [
            PageColumnsLayout {
                when: pageLayout.width > units.gu(80)
                PageColumn {
                    minimumWidth: units.gu(20)
                    maximumWidth: units.gu(60)
                    preferredWidth: units.gu(40)
                }
                PageColumn {
                    fillWidth: true
                }
            },
            PageColumnsLayout {
                when: true
                PageColumn {
                    minimumWidth: units.gu(20)
                    fillWidth: true
                }
            }
       ]

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

        SelectUsersPage {
            id: selectUsersPage
        }
    }

    LoginScreen {
        z: 5
        id: loginScreen
        anchors.fill: parent
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
                loadingScreen.visible = false;
                loginScreen.visible = true;
                pageLayout.visible = false;
            });

            setHandler('show-conversations-page', function() {
                debugEvent("show-conversations-page")
                loadingScreen.visible = false;
                pageLayout.visible = true;
            });

            setHandler('move-conversation-to-top', function(conv_id){
                debugEvent('move-conversation-to-top ', conv_id)
                conversationsModel.move(getConversationModelIndexById(conv_id), 0, 1);
            });

            setHandler('add-conversation', function(data, sound) {
                debugEvent("add conversation", data.id_)
                conversationsModel.append(data);
                var chatModel = chatModelComponent.createObject(root);
                chatModels[data.id_] = chatModel;

                var chatPage = chatPageComponent.createObject(null, {convId: data.id_, chatModel: chatModel, convName: data.title, firstMessageLoaded: data.first_message_loaded, statusMessage: data.statusMessage, loaded: data.loaded});
                chatPages[data.id_] = chatPage;

                if (sound)
                    notificationSound.play();
            });

            setHandler('delete-conversation', function(conv_id) {
                debugEvent("delete conversation", conv_id)
                conversationsModel.remove(getConversationModelIndexById(conv_id));
            });


            setHandler('set-conversation-title', function(conv_id, title, unread_count, statusMessage) {
                debugEvent("set conversation title of ", conv_id, "to", title, "|", statusMessage)
                conversationsModel.get(getConversationModelIndexById(conv_id)).title = title;
                conversationsModel.get(getConversationModelIndexById(conv_id)).statusMessage = statusMessage;

                var chatPage = chatPages[conv_id];
                chatPage.convName = title;

                if (chatPage.visible ||
                        (aboutConversationPage.visible && aboutConversationPage.mData.id_ == conv_id)) {
                    py.call("backend.read_messages", [conv_id]);
                    chatPage.statusMessage = statusMessage;
                }
                else {
                    if (unread_count > conversationsModel.get(getConversationModelIndexById(conv_id)).unread_count && !conversationsModel.get(getConversationModelIndexById(conv_id)).is_quiet) {
                        notificationSound.play();
                    }
                    conversationsModel.get(getConversationModelIndexById(conv_id)).unread_count = unread_count;
                }
            });

            setHandler('set-conversation-is-quiet', function(conv_id, is_quiet) {
                debugEvent("set conversation is quiet ", conv_id, is_quiet)
                conversationsModel.get(getConversationModelIndexById(conv_id)).is_quiet = is_quiet;
            });

            setHandler('set-conversation-status', function(conv_id, statusMessage, typers){
                debugEvent('set-conversation-status of', conv_id)

                var chatPage = chatPages[conv_id];

                if (typers) {
                    if (typers.length === 1) {
                        statusMessage = i18n.tr("%1 is typing ...").arg(typers[0]);
                    }
                    else if (typers.length > 1) {
                        var t = ""
                        for (var i=0; i<typers.length; i++) {
                            t += typers[i] + ', '
                        }
                        t = t.slice(0, t.length-2);
                        statusMessage = i18n.tr('%1 are typing ...').arg(t);
                    }
                }
                chatPage.statusMessage = statusMessage;
                conversationsModel.get(getConversationModelIndexById(conv_id)).statusMessage = statusMessage;
            });

            setHandler('set-conversation-online', function(conv_id, online){
                debugEvent('set-conversation-online of', conv_id)
                conversationsModel.get(getConversationModelIndexById(conv_id)).online = online;
                chatPages[conv_id].convOnline = online;
            });

            setHandler('add-conversation-message', function(conv_id, data, insert_mode) {
                debugEvent('add-conversation-message to ', conv_id, data.type)

                var chatPage = chatPages[conv_id];

                if (insert_mode === "bottom") {
                    chatModels[conv_id].insert(0, data);
                    if (chatPage.visible) {
                        if (chatPage.listView.isAtBottomArea)
                            chatPage.listView.positionViewAtBeginning();
                    }
                }
                else if (insert_mode === "top") {
                    chatModels[conv_id].append(data);
                    chatPage.pullToRefresh.refreshing = false;
                    if (chatPage.visible && !chatPage.pullToRefreshLoading) {
                        chatPage.listView.positionViewAtBeginning();
                    }
                }
            });

            setHandler('clear-conversation-messages', function(conv_id){
                debugEvent('clear-conversation-messages of ', conv_id)
                chatModels[conv_id].clear();
            });

            setHandler('set-conversation-users', function(conv_id, users){
                debugEvent('set-conversation-users of ', conv_id, users)
                var users_model = conversationsModel.get(getConversationModelIndexById(conv_id)).users;
                users_model.clear();
                for (var i=0; i<users.length; i++) {
                    users_model.append(users[i]);
                }
            });

            setHandler('add-contact', function(data) {
                debugEvent("add contact", data.name)
                contactsModel.append(data);
            });

            setHandler('set-loading-status', function(status) {
                debugEvent("set-loading-status", status)
                loadingScreen.setLoadingStatus(status);
            });

            // Events

            setHandler('on-message-sent', function(conv_id){
                debugEvent('on-message-sent', conv_id);
            });

            setHandler('on-first-message-loaded', function(conv_id){
                debugEvent('on-first-message-loaded')

                var chatPage = chatPages[conv_id];

                conversationsModel.get(getConversationModelIndexById(conv_id)).firstMessageLoaded = true;
                chatPage.firstMessageLoaded = true;
                chatPage.pullToRefresh.refreshing = false;

            });

            setHandler('on-new-conversation-created', function(conv_id){
                debugEvent('on-new-conversation-created');
                var dialog = PopupUtils.open(newConversationWelcomeDialog);
                dialog.conv_id = conv_id;

            });

            setHandler('on-conversation-loaded', function(conv_id){
                debugEvent('on-conversation-loaded');

                var chatPage = chatPages[conv_id];

                conversationsModel.get(getConversationModelIndexById(conv_id)).loaded = true;
                if (chatPage.visible) {
                    chatPage.loaded = true;
                }
            });

            setHandler('on-more-messages-loaded', function(conv_id){

                var chatPage = chatPages[conv_id];

                debugEvent('on-more-messages-loaded of ', conv_id);
                if (chatPage.visible) {
                    chatPage.pullToRefresh.refreshing = false;
                    chatPage.pullToRefreshLoading = false;
                }
            });

            setHandler('on-chat-background-changed', function(custom){
                debugEvent('on-chat-background-changed', custom);
                settingsPage.setChatBackround(custom);
            });


            setHandler('remove-dummy-message', function(conv_id, local_id) {
                debugEvent('remove-dummy-message')
                var model = chatModels[conv_id];

                for (var i=model.count; i>0; i--) {
                    if (model.get(i-1).local_id === local_id) {
                        model.remove(i-1);
                        break;
                    }
                }

            });

            importModule('backend', function(){
                console.log("python loaded");
                call('backend.start');

                // Load stickers
                console.log("loading stickers")
                call('backend.settings_get', ['load_stickers_on_start'], function callback(value){
                    if (value)
                        Stickers.load();
                });
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

