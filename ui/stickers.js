var loadStickerSetsUrl = "https://picasaweb.google.com/data/feed/api/user/108618507921641169817?alt=json&fields=entry[gphoto%3AalbumType!%3D%27ProfilePhotos%27]%28media%3Agroup%28media%3Athumbnail%29%2Clink[%40rel%3D%27http%3A%2F%2Fschemas.google.com%2Fg%2F2005%23feed%27]%29";

var stickers = [];

function load(){
    var req = new XMLHttpRequest();
    req.onreadystatechange = function() {
        if (req.readyState === XMLHttpRequest.DONE) {
            var json = JSON.parse(req.responseText);
            var entries = json["feed"]["entry"];
            var entry, requestStickersUrl, stickerSetThumbnail;
            for (var e=0; e<entries.length; e++) {
                entry = entries[e];
                stickerSetThumbnail = entry["media$group"]["media$thumbnail"][0]["url"];
                requestStickersUrl = entry["link"][0]["href"];
                loadStickerSet(requestStickersUrl, e);
            }
        }
    }
    req.open("GET", loadStickerSetsUrl);
    req.send();
}


function loadStickerSet(url, no) {
    var req = new XMLHttpRequest();
    req.onreadystatechange = function() {
        if (req.readyState === XMLHttpRequest.DONE) {
            var feed = JSON.parse(req.responseText)["feed"];
            var stickerSetTitle = feed["title"]["$t"];
            var entries = feed["entry"];
            var entry;
            var stickerEntries = [];
            for (var e=0; e<entries.length; e++) {
                entry = entries[e];
                stickerEntries.push({
                    "gphoto_id": entry["gphoto$id"]["$t"],
                    "url": entry["media$group"]["media$content"][0]["url"]
                });
            }
            stickers[no] = {
                "title": stickerSetTitle,
                "icon": feed["icon"]["$t"],
                "gphoto_user_id": feed["gphoto$user"]["$t"],
                "stickers": stickerEntries
            }
            WorkerScript.sendMessage({
                "action": "set-stickers",
                "stickers": stickers
            });
        }
    }
    req.open("GET", url);
    req.send();
}

WorkerScript.onMessage = function(message) {
    if (message.action === "load")
        load();
}
