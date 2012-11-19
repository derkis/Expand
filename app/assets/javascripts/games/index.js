// http://stackoverflow.com/questions/610406/javascript-equivalent-to-printf-string-format/
String.prototype.format = function() {
  var args = arguments;
  return this.replace(/{(\d+)}/g, function(match, number) { 
    return typeof args[number] != 'undefined' ? args[number] : match;
  });
};

var fade_speed = 75;
var max_user_columns = 4;
var friends_list_base_height;
var polling_speed = 5000

var game_state = {
	proposed: 0, ready: 1, starting: 2, started: 3, finished: 4, canceled: 5
}

$(document).ready(function() {
	setTimeout(polling_wrapper, polling_speed);
	organize_users_default();
	bind_cell_click_handlers();
	update_game_invite_with_state(game_invite_state.no_invites);
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
	setTimeout(polling_wrapper, polling_speed);
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
	other_panels_height = $('#checked_user_list').outerHeight(true) + $('#game_invites').outerHeight(true);
	$('#friend_user_list').css('height', friends_list_base_height - other_panels_height);
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

// games polling
function check_game_invitations() {
	$.getJSON('games/proposed.json', function(games) {
		// use the first game and just hope order is consistent D:
		// if it ends up jacking shit up i'll have to go back into the query 
		// and return an ordered collection instead
		for(var game_id in games) {
			var current_users_email = $(".profile_link").text();
			var game = games[game_id];

			var this_player, players = [];
			for(var player_index in game) {
				var player = game[player_index]
				var players_email = player['email'];
				if(players_email != current_users_email)
					players.push(players_email);
				else
					this_player = player;
			}

			show_game_invite_for_players(this_player, players);
			// so we can fall through safely if there is nothing in the object
			// yes, I feel bad about all of this
			return; 
		}	
		
		update_game_invite_with_state(game_invite_state.no_invites);
	});
}

function check_ready_game() {
	$.getJSON('games/ready.json', function(ready_game) {
		if(ready_game)
			show_ready_game_prompt_for_game(ready_game);
	});
}

function check_started_game() {
	$.getJSON('games/started.json', function(game_id) {
		if(game_id)
			window.location.replace('games/' + game_id);
	});
}

// game/player model updating
function respond_to_game_invitation(player_id, game_id, did_accept) {
	$.ajax({
		type: 'PUT',
		url: 'players/' + player_id,
		data: JSON.stringify({ 'canceled': !did_accept, 'player': { 'accepted': did_accept } }),
		contentType: 'application/json',
		dataType: 'json',
		success: function(data) {
			did_send_response_to_game_invite(data, did_accept);
		}
	});
}

function start_or_cancel_game(game_id, should_start) {
	$.ajax({
		type: 'PUT',
		url: 'games/' + game_id,
		data: JSON.stringify({ 'game': { 'status': game_state.starting } }),
		contentType: 'application/json',
		dataType: 'json',								   
		success: function(data) {
			window.location.replace('games/' + game_id);
		}
	});		
}

// show various invitation types
function show_game_invite_for_players(this_player, players) {
	var players_string = players_string_from_array(players, '\n', '');
	var player_id = this_player['player_id'], game_id = this_player['game_id'];

	var game_invite_options = {
		players: players_string,
		accept_handler: function() { respond_to_game_invitation(player_id, game_id, true) },
		reject_handler: function() { respond_to_game_invitation(player_id, game_id, false) },
		should_disable: this_player.accepted === "t"
	}

	update_game_invite_with_state(game_invite_state.proposed_game, game_invite_options);
}

function show_ready_game_prompt_for_game(ready_game) {
	var players_string = players_string_from_array(ready_game.other_players, '', ' and ');
	
	var start_game_options = {
		players: players_string,
		accept_handler: function() { start_or_cancel_game(ready_game.game_id, true) },
		reject_hanlder: function() { start_or_cancel_game(ready_game.game_id, false) },
		accept_title: 'start',
		reject_title: 'cancel'
	}
	
	update_game_invite_with_state(game_invite_state.start_game, start_game_options);
}

function players_string_from_array(players, player_prefix, player_suffix) {
	var players_string = '';
	for(var i=0 ; i<players.length-1 ; i++)
		players_string += '{0}{1}{2}'.format(player_prefix, players[i], player_suffix);
	players_string += players[players.length-1];
	return players_string;
}

// invite button callback
function did_invite_players() {

}

// shared game invite functions
function did_send_response_to_game_invite(game_id, did_accept) {
	var game_invites_container = $('#game_invites')
	if(did_accept) {
		var game_invite = game_invites_container.children('.game_invite');
		game_invite.children('.invite_buttons').children('.accept_button').attr('disabled', 'disabled');
		game_invite.children('.waiting_text').text(proposed_waiting_text);
	} else {
		update_game_invite_with_state(game_invite_state.no_invites);
	}
}

// game invite state/content updating
var current_state;
var proposed_waiting_text = 'waitng for other players to accept...'
var game_invite_state = { 
	no_invites: { id: 0, style_class:'game_invite no_invites' },
	proposed_game: { id: 1, style_class:'game_invite proposed_game' },
	start_game: { id: 2, style_class:'game_invite start_game'}
}

function update_game_invite_with_state(state, options) {
	current_state = state;
	
	var game_invite = $('.game_invite');
	var game_invite_title = game_invite.children('.invite_title');
	var game_invite_waiting_text = game_invite.children('.waiting_text');

	game_invite.removeClass().addClass(state.style_class);
	game_invite.children('.waiting_text').text('');

	switch(state.id) {
		case game_invite_state.no_invites.id:
			game_invite_title.text('You have no invites');
			break;
		case game_invite_state.proposed_game.id:
			game_invite_title.text('Play a game with:');
			if(options.should_disable)
				game_invite_waiting_text.text(proposed_waiting_text);
			update_game_invite_for_active_state(game_invite, state, options);
			break;
		case game_invite_state.start_game.id:
			game_invite_title.text('Start game with:');
			update_game_invite_for_active_state(game_invite, state, options);
			break;
	}

	resize_friends_list();
}

function update_game_invite_for_active_state(game_invite, state, options) {
	game_invite.children('.invite_players').text(options.players);
	
	var invite_buttons = game_invite.children('.invite_buttons');
	var accept_button = invite_buttons.children('.accept_button');
	var reject_button = invite_buttons.children('.reject_button');

	accept_button.off('click').on('click', options.accept_handler);
	accept_button.text(options.accept_title || 'accept');

	reject_button.off('click').on('click', options.reject_handler);
	reject_button.text(options.reject_title || 'reject');

	if(options.should_disable) {
		accept_button.attr('disabled', 'disabled');
	} else {
		accept_button.removeAttr('disabled');
	}
}
