import QtQuick 2.4
import Ubuntu.Content 1.3
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3


PopupBase {
    id: popup

    property var activeTransfer
    property var items: []
    property alias contentType: peerPicker.contentType

    Connections {
        target: activeTransfer
        onStateChanged: {
            console.log("Transfer state changed to " + activeTransfer.state)
        }
    }

    ContentPeerPicker {
        id: peerPicker
        handler: ContentHandler.Destination

        onPeerSelected: {
            for (var i = 0; i < items.length; i++) {
                console.log("Sharing item with name: " + items[i].name + ", url: " + items[i].url)
            }

            activeTransfer = peer.request()
            activeTransfer.items = popup.items
            activeTransfer.state = ContentTransfer.Charged
            PopupUtils.close(popup)
        }

        onCancelPressed: {
            PopupUtils.close(popup)
        }
    }

    ContentTransferHint {
        id: transferHint
        anchors.fill: parent
        activeTransfer: popup.activeTransfer
    }
}
