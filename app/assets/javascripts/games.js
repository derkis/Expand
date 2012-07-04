$(document).ready(function() {
	setTimeout(polling_wrapper, 10000);

    $("cell").click(function(event)
        {$(this).backgroundColor = 0; alert("click fuckers")}
    );
});

function polling_wrapper() {
	check_users();
	check_game_requests();
	setTimeout(polling_wrapper, 10000);
}

function check_users() {
	$.getJSON('users_online.json', function(data) {
		var displayed_users = $('.user_row');
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
				add_user_tag(online_user, displayed_user);
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
			add_user_tag(online_user, last_displayed_user);	
		}
	});
}

function check_game_requests() {
	$.getJSON('proposed_games.json', function(data) {
		console.log(data);
		for(var players in data) {
			add_game_invitation_tag(players);
		}
	});
}

function add_user_tag(online_user, displayed_user) {
	var new_user_tag =
		'<tr>' +
		'	<td class="user_row" user_id="' + online_user.id + '">' +
		'	<label for="game_players_attributes_0_user_id">' + online_user.email + '<\/label>' +
		'	<input class="player_checkbox" id="game_players_attributes_' + online_user.id + '_user_id" name="game[players_attributes][' + online_user.id + '][user_id]" type="checkbox" value="' + online_user.id + '">' +
		'	<input class="player_hidden_field" id="game_players_attributes_' + online_user.id + '_user_id" name="game[players_attributes][' + online_user.id + '][game_id]" type="hidden">' +
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

function add_game_invitation_tag(players) {
	if($('#game_invites').children().length == 0)
		$('#game_invites').append(
			'<button type="button" onclick="accept_game_invitation()">' +
				'Accept' +
			'<\/button>'
		);
	
	// $.ajax({
	//     type: 'POST',
	//     url: url,
	//     data: data,
	//     success: success,
	//     dataType: json
	// });
}

function accept_game_invitation() {
	alert('Should send JSON post');
}