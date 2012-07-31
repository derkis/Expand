Number.prototype.to_char = function() {
    return String.fromCharCode(this);
}

var GAME_ID;
var TURN_TYPE = {
    PLACE_PIECE: { code: 0, name: 'place_piece' }
};

$(document).ready(function() {
    polling_wrapper();

    // $(".game_cell").hover(
    //     function() {$(this).css("background-color", "gray")}, 
    //     function() {$(this).css("background-color", "white")}
    // );

    $('.enabled').live('click', function(click_event) {
        var cell = $(this);
        send_place_piece_action(
            parseInt(cell.attr('row')), 
            parseInt(cell.attr('column'))
        );
    });
});

$('#game').ready(function() {
    GAME_ID = $('#game').attr('game_id');
});

// polling functions
function polling_wrapper() {
    fetch_game_state();
    setTimeout(polling_wrapper, 15000);
}

function fetch_game_state() {
    $.getJSON(document.URL + '.json', function(game_state) {
        console.log(game_state);
        render_board(game_state.cur_turn.board, game_state.template.width, game_state.template.height);
        render_players(game_state.cur_turn);
    });
}

// server calls

function send_game_update(action) {
    var json_update = { 'game': { 'id': GAME_ID, 'turn': { 'action': action } } };

    $.ajax({
        type: 'PUT',
        url: GAME_ID + '.json',
        data: JSON.stringify(json_update), 
        contentType: 'application/json',                  
        dataType: 'json',                                  
        success: function(response) {                          
            console.log('game update');
            console.log(repsonse);
        }
    });     
}

function send_place_piece_action(row, column) {
    send_game_update({
        'turn_type': TURN_TYPE.PLACE_PIECE.code,
        'row'      : row,
        'column'   : column
    });
}

// board rendering helpers
function render_board(board, num_columns, num_rows) {
    var row = 0, column = 0;
    for(var cell_index=0 ; cell_index < board.length ; cell_index++) {    
        var cell_id = '#cell_' + row + '_' + column;
        render_cell($(cell_id), board[cell_index], row, column);
        
        column = (column + 1) % num_columns;
        if(column == 0) 
            row += 1;
    }
}

function render_cell(cell, cell_type, row, column) {
    switch(cell_type) {
        case 'e':
            // cell.css('background-color', 'gray');
            cell.text((65 + row).to_char() + (column+1));
            break;
        default:
            cell.text(cell_type);
            cell.addClass('enabled');
    }
}

function render_players(current_turn) {
    playerDiv = "#player_" + current_turn.player_id;
    $(playerDiv).css("background-color", "red");
}
