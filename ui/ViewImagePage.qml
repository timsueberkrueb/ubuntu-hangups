import QtQuick 2.0

import QtQuick 2.0
import Ubuntu.Components 1.2
import Ubuntu.Content 1.0
import Ubuntu.Components.Popups 1.0

Page {
    id: viewImagePage
    title: i18n.tr("Image")
    visible: false

    property var images
    property var dialog

    onImagesChanged: {
        source = images.get(0).url;
    }
    property alias source: img.source
    property url image_filename


    function shareImage() {
        PopupUtils.open(downloadProgressDialog);
        py.call('backend.cache_get_image', [source.toString()], function callback (filename){
            image_filename = Qt.resolvedUrl(filename);
            PopupUtils.close(dialog);
            contentPopup.show();
        });
    }

    head.actions: [
        Action {
            iconName: "save"
            text: i18n.tr("Save")
            onTriggered: {
                shareImage();
            }
        },
        Action {
            iconName: "share"
            text: i18n.tr("Share")
            onTriggered: {
                shareImage();
            }
        }
    ]

    Flickable {
        anchors.fill: parent
        contentWidth: img.width

        Image {
            id: img
            fillMode: Image.PreserveAspectFit
            height: img.sourceSize.height >  parent.height ? parent.height : img.sourceSize.height
        }

        PinchArea {
            anchors.fill: parent
            pinch.target: img
            pinch.minimumRotation: 0
            pinch.maximumRotation: 0
            pinch.minimumScale: 0.1
            pinch.maximumScale: 10
            pinch.dragAxis: Pinch.XAndYAxis
       }

    }

    ExportContentPopup {
        id: contentPopup
        contentType: ContentType.Pictures
        property var c: ContentItem {
            url: image_filename
        }
        items: [c]
    }

    Component {
         id: downloadProgressDialog
         Dialog {
             title: i18n.tr("Retrieving image")
             text: i18n.tr("Retrieving image, please wait ...")

             ProgressBar {
                indeterminate: true
             }

             Component.onCompleted: dialog = this;
         }
    }
}
