import QtQuick 2.4
pragma Singleton


QtObject {
    property bool loaded: false

    property var stickers: []

    property WorkerScript stickersWorker: WorkerScript {
        source: Qt.resolvedUrl("stickers.js")
        onMessage: {
            stickers = messageObject.stickers;
        }
    }

    function load() {
        loaded = true;
        stickersWorker.sendMessage({"action": "load"});
    }

}
