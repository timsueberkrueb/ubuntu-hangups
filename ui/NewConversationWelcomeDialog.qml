import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3

Component {
     Dialog {
         id: dialog
         title: i18n.tr("New Conversation")
         text: i18n.tr("Send a welcoming message to invite the conversations members")

         property string conv_id

         TextField {
             id: messageField
            placeholderText: i18n.tr("Write message")
            text: i18n.tr("Hi there :)")
         }

         Button {
             text: i18n.tr("Send")
             color: UbuntuColors.green
             onClicked: {
                 py.call('backend.send_new_conversation_welcome_message', [conv_id, messageField.text]);
                 PopupUtils.close(dialog);
             }
         }

     }
}
