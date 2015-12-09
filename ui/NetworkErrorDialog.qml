import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3

Component {
     Dialog {
         id: dialog
         title: i18n.tr("Network Error")

         property string errorTitle: ""
         property string errorMessage: ""
         property string errorType: ""

         text: i18n.tr("A network error (%1) has occurred: %2 \nPlease make sure that you are connected to a network.").arg(errorType).arg( errorTitle + ' ' + errorMessage)
         Button {
             text: i18n.tr("Close")
             onClicked:  {
                 PopupUtils.close(dialog);
                 Qt.quit();
             }
         }
     }
}
