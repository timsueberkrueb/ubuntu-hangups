import QtQuick 2.0
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.0


Page {
    title: i18n.tr("Settings")
    visible: false

    Flickable {
        anchors.fill: parent
        contentHeight: col.height + col.anchors.margins * 2

        Column {
            id: col
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: units.gu(2)
            spacing: units.gu(1)

            Label {
                text: i18n.tr("Chat Background")
                fontSize: "x-large"
            }

            UbuntuShape {
                height: source.height
                width: source.width
                source: Image {
                    id: backgroundImage

                    property bool isDefault: source == Qt.resolvedUrl('../media/default_chat_background.jpg')

                    width: units.dp(256)
                    fillMode: Image.PreserveAspectFit
                    source: Qt.resolvedUrl('../media/default_chat_background.jpg')

                    Component.onCompleted: {
                        py.call('backend.settings_get', ['custom_chat_background'], function callback(value){
                            if (value) {
                                source = value;
                            }
                        });
                    }

                }
            }

            Row {
                spacing: units.gu(1)

                Button {
                    text: i18n.tr("Change")
                    color: UbuntuColors.green
                    onClicked: {
                        importContentPopup.show();
                    }
                }

                Button {
                    text: i18n.tr("Reset default")

                    enabled: !backgroundImage.isDefault

                    onClicked: {

                    }
                }
            }


            Label {
                text: i18n.tr("Cache")
                fontSize: "x-large"
            }

            FlexibleLabel {
                text: i18n.tr("It is recommended to cache images offline so that they only get downloaded once.")
            }

            Row {
                spacing: units.gu(1)

                CheckBox {
                    anchors.verticalCenter: parent.verticalCenter
                    id: cacheImagesCheckbox
                    enabled: false
                    checked: true
                    Component.onCompleted: {
                        py.call('backend.settings_get', ['cache_images'], function callback(value){
                            checked = value;
                            enabled = true;
                        });
                    }

                    onCheckedChanged: {
                        py.call('backend.settings_set', ['cache_images', checked]);
                    }
                }

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: i18n.tr("Cache images")
                }
            }

            Button {
                text: i18n.tr("Clear cache")
                color: UbuntuColors.orange

                onClicked: {
                    PopupUtils.open(clearCacheDialog)
                }
            }

            Label {
                text: i18n.tr("Routine Timer")
                fontSize: "x-large"
            }

            FlexibleLabel {
                text: i18n.tr("Specify the timeout period of the status update routine called periodically in seconds.")
            }

            TextField {
                enabled: false

                inputMethodHints: Qt.ImhDigitsOnly
                validator: IntValidator{}

                Component.onCompleted: {
                    py.call('backend.settings_get', ['check_routine_timeout'], function callback(value){
                        text = value;
                        enabled = true;
                    });
                }

                onTextChanged: {
                    if (text !== "")
                        py.call('backend.settings_set', ['check_routine_timeout', Number(text)]);
                }

            }


        }

    }

    Component {
         id: clearCacheDialog
         Dialog {
             id: dialog
             title: i18n.tr("Clear cache")
             text: i18n.tr("Are you sure to clear the cache? All images will have to be redownloaded.")

             Button {
                 text: i18n.tr("Clear now")
                 color: UbuntuColors.orange
                 onClicked: {
                     enabled = false;
                     cancelButton.enabled = false;
                     dialog.text = i18n.tr("Working ...")
                     py.call('backend.clear_cache', [], function callback() {
                         PopupUtils.close(dialog);
                         PopupUtils.open(cacheClearedDialog);
                     });
                 }
             }

             Button {
                 id: cancelButton
                 text: i18n.tr("Cancel")
                 onClicked: PopupUtils.close(dialog)
             }
         }
    }


    Component {
         id: cacheClearedDialog
         Dialog {
             id: dialog
             title: i18n.tr("Cache cleared")
             text: i18n.tr("The cache was cleared successful. Please restart the application to continue.")
             Button {
                 id: cancelButton
                 color: UbuntuColors.green
                 text: i18n.tr("Okay")
                 onClicked: {
                     PopupUtils.close(dialog)
                     Qt.quit();
                 }
             }
         }
    }

    ImportContentPopup {
        id: importContentPopup
        contentType: ContentType.Pictures
        onItemsImported: {
            var picture = importItems[0];
            var url = picture.url;
            //py.call('backend.send_image', [conv_id, url.toString()]);
        }
    }


}

