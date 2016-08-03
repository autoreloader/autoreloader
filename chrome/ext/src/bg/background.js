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
				var getHost = function(href) {
					var l = document.createElement("a");
					l.href = href;
					return l.hostname;
				};
				
                console.log("Message is received: ", msg);

                if (msg == 'change') {
                    clearTimeout(reloadTimeout);
                    reloadTimeout = setTimeout(function () {
						count++;
						
						chrome.storage.sync.get(null, function(value) {
							if (value && value.domains) {
								var regex = new RegExp(value.domains.split("\n").join('|'), 'i');
								var reloadTabs = function(tabs) {
									for ( var i = 0; i < tabs.length; i++ ) {									
										if (regex.test(getHost(tabs[i].url))) {
											chrome.tabs.executeScript(tabs[i].tabId, {code: 'location.reload()'});
										}
									}
								};
															
								chrome.tabs.query(value.active === true ? {active: true} : {}, reloadTabs);
							} else {
								chrome.tabs.executeScript({code: 'location.reload()'});
							}
						});
						update(true);
                    }, 250);
                }
            };

            ws.onclose = function () {
                wsOpen = false;
                update(false);
                console.log("Connection is closed...");
            };

            ws.onerror = function (e) {
                console.log("error: ", e);
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
        //chrome.tabs.create({"url": "https://github.com/autoreloader/autoreloader#readme", "selected": true});
    });
})();