Number.prototype.to_char = function() {
    return String.fromCharCode(this);
}

String.prototype.format = function() {
    var args = arguments;
    return this.replace(/{(\d+)}/g, function(match, number) { 
        return typeof args[number] != 'undefined' ? args[number] : match;
    });
};

String.prototype.to_int = function() {
    return parseInt(this);
}

var GAME_ID;
var TURN_TYPES = {
    NO_ACTION:      { code: 000, render: render_no_action_turn },
    PLACE_PIECE:    { code: 100, render: render_place_piece_turn, action_builder: build_place_piece_action },
    START_COMPANY:  { code: 200, render: render_start_company_turn, action_builder: build_start_company_action },
    PURCHASE_STOCK: { code: 300, render: render_purchase_stock_turn, action_builder: build_purchase_stock_action },
    TRADE_STOCK:    { code: 400, render: render_trade_stock_turn, action_builder: build_trade_stock_action },
    MERGE_ORDER:    { code: 500, render: render_merge_order_turn, action_builder: build_merge_order_action }
};

var current_turn_type;
var selected_cell;

$(document).ready(function() {
    polling_wrapper();

    $('.enabled').live('click', function(click_event) {
        var cell = $(this);
        if(selected_cell && selected_cell != cell)
            selected_cell.removeClass('selected');
        selected_cell = cell;
        selected_cell.addClass('selected');
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

        current_turn_type = (function(turn_code) { 
            for(var type_key in TURN_TYPES)
                if(TURN_TYPES[type_key].code == turn_code)
                    return TURN_TYPES[type_key];
        })(game_state.valid_action.code);

        current_turn_type.render();
        render_board(game_state.current_turn.board, game_state.template.width, game_state.template.height);
        render_players(game_state.current_turn);
    });
}

// server calls
function send_game_update(action) {
    var json_update = { 'game': { 'turn': { 'action': action } } };

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

function create_action_and_send_game_update() {
    var action = { 'turn_type' : current_turn_type.code };
    var action_data = current_turn_type.action_builder();

    for(action_attribute in action_data)
        action[action_attribute] = action_data[action_attribute];
    send_game_update(action)
}

function build_place_piece_action() {
    return { 
        'row': selected_cell.attr('row').to_int(), 
        'column': selected_cell.attr('column').to_int()
    };
}

function build_start_company_action() {
    // create_action_and_send_game_update(
    //     TURN_TYPES.CHOOSE_COMPANY,
    //     { 'company': company }
    // );
}

function build_purchase_stock_action() {
    // create_action_and_send_game_update(
    //     TURN_TYPES.PURCHASE_STOCK,
    //     { 'purchases': purchases }
    // );
}

function build_trade_stock_action() {
    // create_action_and_send_game_update(
    //     TURN_TYPES.TRADE_STOCK,
    //     { 'trades': trades }
    // );
}

function build_merge_order_action() {
    // create_action_and_send_game_update(
    //     TURN_TYPES.MERGE_ORDER,
    //     { 'merge_order': merge_order }
    // );
}

// board rendering helpers

function render_no_action_turn() {
    console.log('render no action');
}

function render_place_piece_turn() {
    console.log('render place piece');
    // send_place_piece_action(
    //     parseInt(cell.attr('row')), 
    //     parseInt(cell.attr('column'))
    // );
}

function render_start_company_turn() {

}

function render_purchase_stock_turn() {

}

function render_trade_stock_turn() {

}

function render_merge_order_turn() {

}

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
    var player_index = $('#game').attr('player_index');
    switch(cell_type) {
        case 'e':
            cell.text((65 + row).to_char() + (column+1));
            break;
        case player_index:
            cell.text(cell_type);
            cell.addClass('enabled');
        default:
            cell.text(cell_type);
    }
}

function render_players(current_turn) {
    $('.player[player_id=' + current_turn.player_id + ']').addClass('current_player');
}
