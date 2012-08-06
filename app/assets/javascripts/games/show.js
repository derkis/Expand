Number.prototype.to_char = function() {
    return String.fromCharCode(this);
}

var GAME_ID;
var TURN_TYPE = {
    PLACE_PIECE:    { code: 100, name: 'place_piece' },
    START_COMPANY:  { code: 200, name: 'start_company' },
    PURCHASE_STOCK: { code: 300, name: 'puchase_stock' },
    TRADE_STOCK:    { code: 400, name: 'trade_stock' },
    MERGE_ORDER:    { code: 500, name: 'merge_order' },
};

$(document).ready(function() {
    polling_wrapper();

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

function create_action_and_send_game_update(turn_type, action_data) {
    var action = { 'turn_type' : turn_type.code };
    for(action_attribute in action_data)
        action[action_attribute] = action_data[action_attribute];
    send_game_update(action)
}

function send_place_piece_action(row, column) {
    create_action_and_send_game_update(
        TURN_TYPE.PLACE_PIECE, 
        { 'row': row, 'column': column }
    );
}

function send_start_company_action(company) {
    create_action_and_send_game_update(
        TURN_TYPE.CHOOSE_COMPANY,
        { 'company': company }
    );
}

function send_purchase_stock_action(purchases) {
    create_action_and_send_game_update(
        TURN_TYPE.PURCHASE_STOCK,
        { 'purchases': purchases }
    );
}

function send_trade_stock_action(trades) {
    create_action_and_send_game_update(
        TURN_TYPE.TRADE_STOCK,
        { 'trades': trades }
    );
}

function send_merge_order_action(merge_order) {
    create_action_and_send_game_update(
        TURN_TYPE.MERGE_ORDER,
        { 'merge_order': merge_order }
    );
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
            cell.text((65 + row).to_char() + (column+1));
            break;
        default:
            cell.text(cell_type);
            cell.addClass('enabled');
    }
}

function render_players(current_turn) {
    $('.player[player_id=' + current_turn.player_id + ']').addClass('current_player');
}
