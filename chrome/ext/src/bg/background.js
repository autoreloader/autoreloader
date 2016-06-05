(function () {
    var count = 1;
    var ws;
    var wsOpen = false;
    var connectTimeout, reloadTimeout;

    chrome.browserAction.onClicked.addListener(function () {
        if (wsOpen) {
            ws.close();
        } else {
            connect();
        }

        update(false);
    });

    function update(open) {
        chrome.browserAction.setIcon({path: "icons/icon19" + (open ? '-live' : '') + ".png"});
        chrome.browserAction.setBadgeText({text: open ? count.toString() : ''});
    }

    function connect() {
        wsOpen = false;

        try {
            ws = new WebSocket("ws://127.0.0.1:2907/check");

            ws.onopen = function () {
                wsOpen = true;
                console.log("Connection is open..");

                update(true);
            };

            ws.onmessage = function (evt) {
                var msg = evt.data;
                console.log("Message is received: ", msg);

                if (msg == 'change') {
                    clearTimeout(reloadTimeout);
                    reloadTimeout = setTimeout(function () {
                        chrome.tabs.executeScript({
                            code: 'location.reload()'
                        });
                    }, 250);
                }
            };

            ws.onclose = function () {
                wsOpen = false;
                update(false);
                console.log("Connection is closed...");
            };

            ws.onerror = function (e) {
                console.log("errow: ", e);
            }
        } catch (e) {
            wsOpen = false;
            update(false);
            clearTimeout(connectTimeout);
            connectTimeout = setTimeout(connect, 5000);
            console.log("Failed to open socket: ", e);
        }
    }

    chrome.runtime.onInstalled.addListener(function (details) {
        chrome.tabs.create({"url": "https://github.com/autoreloader/autoreloader", "selected": true});
    });
})();