import QtQuick 2.4
import Ubuntu.Content 1.3
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3


PopupBase {
    id: popup

    property var activeTransfer
    property list<ContentItem> importItems
    property alias contentType: peerPicker.contentType
    signal itemsImported (var importItems)

    Connections {
        target: popup.activeTransfer
        onStateChanged: {
            if (popup.activeTransfer.state === ContentTransfer.Charged) {
                popup.importItems = popup.activeTransfer.items;
                popup.itemsImported(popup.importItems);
            }
        }
    }

    ContentPeerPicker {
        id: peerPicker
        handler: ContentHandler.Source

        onPeerSelected: {
            peer.selectionType = ContentTransfer.Single;
            activeTransfer = peer.request();
            PopupUtils.close(popup);
        }

        onCancelPressed: {
            PopupUtils.close(popup);
        }
    }

    ContentTransferHint {
        id: transferHint
        anchors.fill: parent
        activeTransfer: popup.activeTransfer
    }
}
