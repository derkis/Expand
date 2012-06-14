# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$(document).ready(function() {
	setTimeout(updateLobby, 10000);
});

function updateLobby() {
	var last_update = $('.online_user:last-child').attr('data-time');
	setTimeout(updateLobby, 10000);
}