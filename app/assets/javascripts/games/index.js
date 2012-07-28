var fade_speed = 'fast';
var max_user_columns = 2;

$(document).ready(function() {
	setTimeout(polling_wrapper, 10000);
	organize_users_default();
});

function polling_wrapper() {
	check_new_users();
	check_game_invitations();
	check_ready_game();
	check_started_game();
	setTimeout(polling_wrapper, 10000);
}

function organize_users_default() {
	organize_users($('.user_checkbox:not(:checked)').parent(), $('.user_checkbox:checked').parent());
}

function organize_users(unchecked_users, checked_users) {
	var user_list = $('#online_user_table');
	user_list.children('.user_row').remove();
	for(var slice_start = 0 ; slice_start < unchecked_users.length ; slice_start += max_user_columns) {
		var current_row = $('<div class="user_row" />');
		user_list.append(current_row);
		current_row.append(unchecked_users.slice(slice_start, slice_start + max_user_columns));
	}

	var checked_user_list = $('#checked_user_list');
	checked_user_list.children('.user_cell').remove();
	for(var i=0 ; i<checked_users.length ; i++)
		checked_user_list.append(checked_users[i]);

	bind_cell_click_handlers();
}

function bind_cell_click_handlers() {
	$('.user_cell label').click(function(click_event) {
		var user_cell = $(click_event.currentTarget).parent();
		var user_checkbox = user_cell.children('.user_checkbox');
		var is_checked = !user_checkbox.is(':checked');
		user_checkbox.attr('checked', is_checked);
		if(is_checked) { 
			$('#checked_user_list').append(click_event.currentTarget);
		} else { 
			organize_users_default();
		}
	});
}

// online user polling
function check_new_users() {
	$.getJSON('users_online.json', function(online_users) {
		var unchecked_users = [], checked_users = [];
		for(var i=0 ; i<online_users.length ; i++) {
			var online_user = online_users[i];
			var existing_user_checkbox = $('.user_checkbox[value="' + online_user.id + '"]:first');
			if(existing_user_checkbox.length != 0) {
				if(existing_user_checkbox.is(':checked'))
					checked_users.push(existing_user_checkbox.parent().get(0));
				else
 					unchecked_users.push(existing_user_checkbox.parent().get(0));
			} else
				unchecked_users.push(new_user_tag_for(online_user));
		}
		organize_users(unchecked_users, checked_users);
	});
}

function new_user_tag_for(online_user) {
	var new_user_tag = $(
		'<div class="user_cell" user_id="' + online_user.id + '">' +
		'	<input class="user_checkbox" id="game_players_attributes_' + online_user.id + '_user_id" name="game[players_attributes][' + online_user.id + '][user_id]" type="checkbox" value="' + online_user.id + '">' +
		'	<label for="game_players_attributes_0_user_id">' + online_user.email + '<\/label>' +
		'<\/div>'
	)[0];
	return new_user_tag;
}

function remove_user_tag(displayed_user) {
	var displayed_user_tag = $(displayed_user).parent();
	displayed_user_tag.fadeOut(fade_speed, function() {
		displayed_user_tag.remove();
	});
}

// game invitation polling
function check_game_invitations() {
	$.getJSON('games/proposed.json', function(games) {
		var current_users_email = $(".profile_link").text();
		for(var game_id in games) {
			var game = games[game_id];
			var should_add_invitation = true;
			$.each($('.game_invite'), function(index, value) {
				var other_game_id = $(value).attr('game_id');
				if(other_game_id == "" + game_id)
					should_add_invitation = false;
			});
			
			if(should_add_invitation) {
				var this_player, players = [];
				for(var player_index in game) {
					var player = game[player_index]
					var players_email = player['email'];
					if(players_email != current_users_email)
						players.push(players_email);
					else
						this_player = player;
				}
				add_game_invitation_tag(this_player, players);
			}
		}
	});
}

function add_game_invitation_tag(this_player, players) {
	var players_string = '';
	for(var i=0 ; i<players.length-1 ; i++)
		players_string += players[i] + ' and ';
	players_string += players[players.length-1];

	var game_invitation_tag =
		'<div class="game_invite" player_id=' + this_player['player_id'] + ' game_id=' + this_player['game_id'] + '>' +
			'<span class="players_text">Play a game with: ' + players_string + '<\/span>' +
			'<button type="button" onclick="accept_game_invitation(' + this_player['player_id'] + ',' + this_player['game_id'] + ')"' + ((this_player.accepted) ? ' disabled="disabled">' : '>') +
				'Accept' +
			'<\/button>' +
			((this_player.accepted) ? '<span class="waiting_text">Waiting for other players to accept...<\/span>' : '') +
		'<\/div>';
	$('#game_invites').append(game_invitation_tag).fadeIn(fade_speed);
}

// ready games polling
function check_ready_game() {
	$.getJSON('games/ready.json', function(ready_game) {
		if(ready_game && $('#start_game_prompt').children().length == 0)
		add_ready_game_prompt(ready_game);
	});
}

function add_ready_game_prompt(ready_game) {
	var players_string = '';
	for(var i=0 ; i<ready_game.other_players.length-1 ; i++)
		players_string += ready_game.other_players[i] + ' and ';
	players_string += ready_game.other_players[ready_game.other_players.length-1];
	
	var start_game_prompt_tag =
		'<span class ="players_text">Begin game with: ' + players_string + '?<\/span>' +
		'<button type="button" onclick="start_game(' + ready_game.game_id + ')">Start<\/button>';
	$('#start_game_prompt').append(start_game_prompt_tag).fadeIn(fade_speed);
}

// started game polling
function check_started_game() {
	$.getJSON('games/started.json', function(game_id) {
		if(game_id)
			window.location.replace('games/' + game_id);
	});
}

// PUT player accept
function accept_game_invitation(player_id, game_id) {	
	$.ajax({
		type: 'PUT',
		url: 'players/' + player_id,
		data: JSON.stringify({ 'player': { 'accepted': true } }),
		contentType: 'application/json',
		dataType: 'json',
		success: function(data) {
			console.log('PUT player update');
			console.log(data);
			disable_game_invitation(data);
		}
	});
}

// PUT game start
function start_game(game_id) {
	$.ajax({
		type: 'PUT',
		url: 'games/' + game_id,
		data: JSON.stringify({ 'game': { 'status': 1 } }), // 1 is currently the value for game, but this is not semantic
		contentType: 'application/json',				   // and I don't think we can extract the constant from the model
		dataType: 'json',								   // alternatively, we could probably GET an action in the controller
		success: function(data) {                          // which manages starting the game on the backend.
			console.log('game should be started');
			window.location.replace('games/' + game_id);
		}
	});		
}

function disable_game_invitation(game_id) {
	var game_invitation = $('.game_invite[game_id=' + game_id + ']');
	game_invitation.children('button[type="button"]').attr('disabled', 'disabled');
	game_invitation.append('<span class="waiting_text">Waiting for other players to accept...</span>')
}
