## Autoreloader v0.0.1 (Windows only)

Automatically reload chrome tabs if files changes

**Step 1:** Install the file monitor server (Download [setup.exe](https://github.com/autoreloader/autoreloader/blob/master/Setup.exe?raw=true)) 
	
	- Run setup.exe

**Step 2:** Install the [chrome extension](https://chrome.google.com/webstore/detail/innoeeijgleieecngfliphpjchmcobok)

	- Install "autoreloader" on chrome store and install extension
	
**Step 3:** Add folders that you would like to monitor using the "add directory" button.

That's it! Now anytime a new file is added, changed, or removed in the folders you're
monitoring your active tab will automatically reload.

This is an open source app. You can find the full code for Server (Delphi) and Extension (Javascript)
here:

https://github.com/autoreloader/autoreloader

*Pull requests are always welcome!*

P.S. The default server/client port is 2907 (so it must be unblocked in your Windows firewall)

