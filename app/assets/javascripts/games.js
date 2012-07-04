$(document).ready(function() {
	setTimeout(polling_wrapper, 10000);
});

function polling_wrapper() {
	check_users();
	check_game_invitations();
	setTimeout(polling_wrapper, 10000);
}

// online user polling
function check_users() {
	$.getJSON('users_online.json', function(data) {
		var displayed_users = $('.user_row');
		var displayed_user, online_user;
		var disp_i = 0, online_i = 0;
		while(disp_i < displayed_users.length && online_i < data.length) {
			displayed_user = displayed_users[disp_i];
			online_user = data[online_i];
			var displayed_uid = $(displayed_user).attr("user_id");
			var online_uid = online_user.id;
			if(displayed_uid == online_uid) {
				disp_i++; online_i++;		
			} else if (displayed_uid > online_uid) {
				add_user_tag(online_user, displayed_user);
				online_i++;
			} else { // displayed_uid < online_uid
				remove_user_tag(displayed_user);
				disp_i++;
			}
		}
		
		for( ; disp_i < displayed_users.length ; disp_i++) {
			displayed_user = displayed_users[disp_i];
			remove_user_tag(displayed_user);
		}
		
		var last_displayed_user = displayed_users[displayed_users.length-1];	
		for( ; online_i < data.length ; online_i++) {
			online_user = data[online_i];
			add_user_tag(online_user, last_displayed_user);	
		}
	});
}

function add_user_tag(online_user, displayed_user) {
	var new_user_tag =
		'<tr>' +
		'	<td class="user_row" user_id="' + online_user.id + '">' +
		'		<label for="game_players_attributes_0_user_id">' + online_user.email + '<\/label>' +
		'		<input class="player_checkbox" id="game_players_attributes_' + online_user.id + '_user_id" name="game[players_attributes][' + online_user.id + '][user_id]" type="checkbox" value="' + online_user.id + '">' +
		'	<\/td>' +
		'<\/tr>'
	if(displayed_user)
		$(displayed_user).parent().before(new_user_tag);
	else
		$('.table_title').after(new_user_tag);
}

function remove_user_tag(displayed_user) {
	$(displayed_user).parent().remove();
}

// game invitation polling
function check_game_invitations() {
	$.getJSON('proposed_games.json', function(games) {
		var current_users_email = $(".profile_link").text();
		for(var game_id in games) {
			var game = games[game_id];
			var should_add_invitation = true;
			$.each($('.game_invite'), function(index, value) {
				var game_id2 = $(value).attr('game_id');
				if(game_id2 == "" + game_id)
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
			'Play a game with: ' + players_string + 
			'<button type="button" onclick="accept_game_invitation(' + this_player['player_id'] + ')">' +
				'Accept' +
			'<\/button>' +
		'<\/div>';
	$('#game_invites').append(game_invitation_tag);
}

// POST player accept
function accept_game_invitation(player_id) {
	console.log('POST for ' + player_id);
	
	$.ajax({
		type: 'PUT',
		url: 'players/' + player_id,
		data: JSON.stringify({ 'player': { 'accepted': true } }),
		contentType: 'application/json',
		dataType: "json",
		success: function(data) {
			console.log('PUT player update');
			console.log(data);
		}
	});
}