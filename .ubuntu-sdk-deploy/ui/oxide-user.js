
oxide.addMessageHandler("GET_HTML", function (msg) {
    var event = new CustomEvent("QMLmessage", {detail: msg.args});
    document.dispatchEvent(event);
    msg.reply({html: document.documentElement.innerHTML});
});

oxide.addMessageHandler("GET_AUTH_CODE", function (msg) {
    var event = new CustomEvent("QMLmessage", {detail: msg.args});
    document.dispatchEvent(event);
    msg.reply({code: document.getElementById("code").value});
});
