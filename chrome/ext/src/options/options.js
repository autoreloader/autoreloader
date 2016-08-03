function saveChanges() {
	var domains = document.getElementById('domains').value;
	var active = document.getElementById('active').checked;
	
	chrome.storage.sync.set({'domains': domains, 'active': active}, function() { alert('Settings saved!'); });
		
	return false;
}

document.forms[0].onsubmit = saveChanges;
chrome.storage.sync.get(null, function(value) {
	document.getElementById('domains').value = value.domains;
	document.getElementById('active').checked = value.active === true;
});