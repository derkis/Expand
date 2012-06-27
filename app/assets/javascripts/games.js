$(document).ready(function() {
	setTimeout(polling_wrapper, 10000);
});

function polling_wrapper() {
	check_users();
	check_game_requests();
	setTimeout(polling_wrapper, 10000);
}

function check_users() {
	$.getJSON('users_online.json', function(data) {
		var displayed_users = $('.user_row');
		var new_user_index = displayed_users.length
		var disp_i = 0, online_i = 0;
		var displayed_user, online_user;
		var displayed_uid, online_uid;
		console.log(displayed_users); console.log(data);
		while(disp_i < displayed_users.length && online_i < data.length) {
			displayed_user = displayed_users[disp_i];
			online_user = data[online_i];
			displayed_uid = $(displayed_user).attr("user_id");
			online_uid = online_user.id;
			if(displayed_uid == online_uid) {
				console.log("EQUAL: " + displayed_uid + " " + online_uid);
				disp_i++; online_i++;		
			} else if (displayed_uid > online_uid) {
				console.log("GREATER: " + displayed_uid + " " + online_uid);
				new_user_index = add_user_tag(online_user, displayed_user, new_user_index);
				online_i++;
			} else { // displayed_uid < online_uid
				console.log("LESS: " + displayed_uid + " " + online_uid);
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
			new_user_index = add_user_tag(online_user, last_displayed_user, new_user_index);	
		}
	});
}

function check_game_requests() {
	$.getJSON('proposed_games.json', function(data) {
		console.log(data)
		for(var game in data) {
			
		}
	});
}

function add_user_tag(online_user, displayed_user, new_user_index) {
	var new_user_tag =
		'<tr>' +
		'	<td class="user_row" user_id="' + online_user.id + '">' +
		'	<label for="game_players_attributes_0_user_id">' + online_user.email + '<\/label>' +
		'	<input class="player_checkbox" id="game_players_attributes_' + new_user_index + '_user_id" name="game[players_attributes][' + new_user_index + '][user_id]" type="checkbox" value="' + online_user.id + '">' +
		'	<input class="player_hidden_field" id="game_players_attributes_' + new_user_index + '_user_id" name="game[players_attributes][' + new_user_index + '][game_id]" type="hidden">' +
		'	<\/td>' +
		'<\/tr>'
	if(displayed_user)
		$(displayed_user).parent().before(new_user_tag);
	else
		$('.table_title').after(new_user_tag);

	return ++new_user_index;
}

function remove_user_tag(displayed_user) {
	console.log("removing user: " + displayed_user);
	$(displayed_user).parent().remove();
}