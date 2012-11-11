var fade_speed = 75;
var max_user_columns = 4;
var friends_list_base_height;

$(document).ready(function() {
	setTimeout(polling_wrapper, 5000);
	organize_users_default();
	bind_cell_click_handlers();
});

$(window).load(function() {
	var friends_list = $('#friend_user_list');
	friends_list_base_height = $('.panel').height() - $('.title').outerHeight(true) - friends_list.outerHeight(true) + friends_list.height();
	resize_friends_list();
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

	var checked_user_table = $('#checked_user_list').children('.user_table');
	checked_user_table.children('.user_row').remove();
	for(var i=0 ; i<checked_users.length ; i++)
		append_cell_to_table($(checked_users[i]), checked_user_table, false);

	resize_friends_list();
}

function bind_cell_click_handlers() {
	$('.user_cell label').live('click', function(click_event) {
		var cell = $(click_event.currentTarget).parent();
		var checkbox = cell.children('.user_checkbox');
		var is_checked = !checkbox.is(':checked');
		checkbox.attr('checked', is_checked);
		move_cell(cell, is_checked)
	});

	$('.user_cell input').live('click', function(click_event) {
		var checkbox = $(click_event.currentTarget);
		move_cell(checkbox.parent(), checkbox.is(':checked'));
	});
}

function move_cell(cell, is_checked) {
	cell.hide(function() {
		if(is_checked) {
			append_cell_to_table(cell, $('#checked_user_list').children('.user_table'), true);
			resize_friends_list();
		} else {
			var row = cell.parent();
			cell.unwrap();
			organize_users_default();
			cell.show();
		}
	});
}

function append_cell_to_table(cell, table, should_fade_in) {
	var cell_row = $('<div class="user_row" />').append(cell.fadeIn((should_fade_in) ? fade_speed : 0));;
	table.append(cell_row);
}

function resize_friends_list() {
	$('#friend_user_list').css('height', friends_list_base_height - $('#checked_user_list').outerHeight(true));
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
		'<label class="user_cell" user_id="' + online_user.id + '">' +
		'	<input class="user_checkbox" id="game_players_attributes_' + online_user.id + '_user_id" name="game[players_attributes][' + online_user.id + '][user_id]" type="checkbox" value="' + online_user.id + '">' +
		'	<span>' + online_user.email + '<\/span>' +
		'<\/label>'
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
		players_string += '\n' + players[i];
	players_string += players[players.length-1];

	var player_id_and_game_id_params = '' + this_player['player_id'] + ',' + this_player['game_id'];
	var accept_button_options = { 
		click_handler: 'respond_to_game_invitation(' + player_id_and_game_id_params + ',' + true + ')',
		should_disable: this_player.accepted,
		title_text: 'accept'
	};

	var reject_button_options = {
		click_handler: 'respond_to_game_invitation(' + player_id_and_game_id_params + ',' + false + ')',
		title_text: 'reject'
	};
	
	var game_invitation_tag =
		'<div class="game_invite" player_id=' + this_player['player_id'] + ' game_id=' + this_player['game_id'] + '>' +
			'<span class="invite_title">Play a game with: <\/span>' + 
			'<span class="invite_players">' + players_string + '<\/span>' +
			'<div class="invite_buttons">' +
				button_tag_with_options(accept_button_options) +
				button_tag_with_options(reject_button_options) +
			'<\/div>' +
			((this_player.accepted) ? '<span class="waiting_text">Waiting for everyone else...<\/span>' : '') +
		'<\/div>';

	update_game_invitations_with_invite(game_invitation_tag);
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
	
	var start_button_options = {
		click_handler: 'start_game(' + ready_game.game_id + ')',
		title_text: 'start'
	}

	var start_game_prompt_tag =
		'<div class="game_invite">' +
			'<span class="invite_title">Begin game with: <\/span>' + 
			'<span class="invite_players">' + players_string + '<\/span>' +
			'<div class="invite_buttons">' +
				button_tag_with_options(start_button_options) +
			'<\/div>' +
		'<\/div>';

	update_game_invitations_with_invite(start_game_prompt_tag);
}

// started game polling
function check_started_game() {
	$.getJSON('games/started.json', function(game_id) {
		if(game_id)
			window.location.replace('games/' + game_id);
	});
}

// PUT player accept
function respond_to_game_invitation(player_id, game_id, response) {	
	$.ajax({
		type: 'PUT',
		url: 'players/' + player_id,
		data: JSON.stringify({ 'player': { 'accepted': response } }),
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

// shared invitation functions

function update_game_invitations_with_invite(invite_tag) {
	$('#game_invites').children('.game_invite').remove();
	$('#game_invites').append(invite_tag).fadeIn(fade_speed);
}

function button_tag_with_options(options) {
	var button_tag = '<button type="button" class="image_button"';
	if(options.click_handler)
		button_tag += 'onclick="' + options.click_handler + '" ';
	if(options.should_disable)
		button_tag += 'disabled="disabled" ';
	button_tag += '>';

	if(options.title_text)
		button_tag += options.title_text;
	button_tag += '<\/button>';
	
	return button_tag;
}

function disable_game_invitation(game_id) {
	var game_invitation = $('.game_invite[game_id=' + game_id + ']');
	game_invitation.children('button[type="button"]').attr('disabled', 'disabled');
	game_invitation.append('<span class="waiting_text">Waiting for other players to accept...</span>')
}
