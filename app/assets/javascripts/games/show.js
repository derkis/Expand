//------------------------------------------------------------------------------------------
//
// Lib
//
//------------------------------------------------------------------------------------------
function hasClass(element, cls)
{
    var r = new RegExp('\\b' + cls + '\\b');
    return r.test(element.className);
}

function hasClasses(element, classes)
{
    for (var i = 0; i < classes.length; i++)
    {
        var clazz = classes[i];
        var r = new RegExp('\\b' + clazz + '\\b');
        if (!r.test(element.className))
        {
            return false;
        }
    }

    return true;
}

//------------------------------------------------------------------------------------------
//
// Variables
//
//------------------------------------------------------------------------------------------
var player_index = -1;
var current_turn_type;
var selected_cell;
var cur_game_state;

//------------------------------------------------------------------------------------------
//
// Initialization
//
//------------------------------------------------------------------------------------------
$(document).ready(document_readyHandler);
$('#game').ready(game_readyHandler);

Number.prototype.to_char = function()
{
    return String.fromCharCode(this);
}

String.prototype.format = function()
{
    var args = arguments;
    return this.replace(/{(\d+)}/g, function(match, number) { 
        return typeof args[number] != 'undefined' ? args[number] : match;
    });
};

String.prototype.to_int = function() 
{
    return parseInt(this);
}

var GAME_ID;
var TURN_TYPES = {
    
    NO_ACTION: { 
        code: 000,
        name: 'no_action',
        render: render_no_action_turn 
    },
    
    PLACE_PIECE: { 
        code: 100,
        name: 'place_piece',
        render: render_place_piece_turn, 
        build_action: function() {
            return { 
                'row': selected_cell.attr('row').to_int(), 
                'column': selected_cell.attr('column').to_int()
            };
        }
    },
    
    START_COMPANY: { 
        code: 200, 
        name: 'start_company',
        render: render_start_company_turn, 
        build_action: build_start_company_action 
    },
    
    PURCHASE_STOCK: { 
        code: 300,
        name: 'purchase_stock', 
        render: render_purchase_stock_turn, 
        build_action: build_purchase_stock_action 
    },
    
    TRADE_STOCK: { 
        code: 400,
        name: 'trade_stock', 
        render: render_trade_stock_turn, 
        action_builder: build_trade_stock_action 
    },
    
    MERGE_ORDER: { 
        code: 500,
        name: 'merge_order', 
        render: render_merge_order_turn, 
        action_builder: build_merge_order_action 
    }
};

//------------------------------------------------------------------------------------------
//
// Methods
//
//------------------------------------------------------------------------------------------
// polling functions
function polling_wrapper()
{
    fetch_game_state();

    setTimeout(polling_wrapper, 15000);
}

function fetch_game_state()
{
    $.getJSON(document.URL + '.json', fetch_game_state_resultHandler);
}

// server calls
function send_game_update(action)
{
    var json_update = { 'game': { 'turn': { 'action': action } } };

    $.ajax({
        type: 'PUT',
        url: GAME_ID + '.json',
        data: JSON.stringify(json_update), 
        contentType: 'application/json',                  
        dataType: 'json',                                  
        success: send_game_update_successHandler
    });     
}

function create_action_and_send_game_update()
{
    var action = { 'turn_type' : current_turn_type.name };
    var action_data = current_turn_type.build_action();

    for(action_attribute in action_data)
        action[action_attribute] = action_data[action_attribute];
    send_game_update(action)
}

function build_start_company_action()
{
    // create_action_and_send_game_update(
    //     TURN_TYPES.CHOOSE_COMPANY,
    //     { 'company': company }
    // );
}

function build_purchase_stock_action()
{
    // create_action_and_send_game_update(
    //     TURN_TYPES.PURCHASE_STOCK,
    //     { 'purchases': purchases }
    // );
}

function build_trade_stock_action()
{
    // create_action_and_send_game_update(
    //     TURN_TYPES.TRADE_STOCK,
    //     { 'trades': trades }
    // );
}

function build_merge_order_action()
{
    // create_action_and_send_game_update(
    //     TURN_TYPES.MERGE_ORDER,
    //     { 'merge_order': merge_order }
    // );
}

// board rendering helpers

function render_no_action_turn()
{
    console.log('render no action');
}

function render_place_piece_turn()
{
    console.log('render place piece');
    // send_place_piece_action(
    //     parseInt(cell.attr('row')), 
    //     parseInt(cell.attr('column'))
    // );
}

function render_start_company_turn()
{

}

function render_purchase_stock_turn()
{

}

function render_trade_stock_turn()
{

}

function render_merge_order_turn()
{

}

function reset_game()
{
    send_game_update({ 'turn_type' : 'reset' });
}

function render_metadata(game_state)
{
    $('.turn_label').text("Turn: " + game_state.current_turn.number);
}

function render_board(board, num_columns, num_rows)
{
    $('.debug_string').text(board);

    var row = 0, column = 0;
    for(var cell_index=0 ; cell_index < board.length ; cell_index++) {    
        var cell_id = '#cell_' + row + '_' + column;
        render_cell($(cell_id), board[cell_index], row, column);
        
        column = (column + 1) % num_columns;
        if(column == 0) 
            row += 1;
    }
}

function render_cell(cell, cell_type, row, column)
{
    cell.removeClass('empty');
    cell.removeClass('enabled');
    cell.removeClass('no_hotel');
    cell.removeClass('selected');
    cell.text((65 + row).to_char() + (column+1));
    switch(cell_type) {
        case 'e': // empty cell
            cell.addClass('empty')
            break;
        case 'u':
            cell.addClass('no_hotel');
            break;
        case player_index:
            cell.addClass('enabled');
            break;
    }
}

function render_players(current_turn)
{
    $('.player').removeClass('current_player');
    $('.player[player_id=' + current_turn.player_id + ']').addClass('current_player');
}

function player_can_act()
{
    return current_turn_type != TURN_TYPES.NO_ACTION;
}

function get_cell_at(row, column)
{
    return cur_game_state.current_turn.board.chartAt(row * cur_game_state.template.width + column)
}

function get_cell_at(row, column)
{
    return $('#cell_' + row + "_" + column);
}

function get_key(cell)
{
    var row = get_row(cell);
    var col = get_column(cell);
    return row + "_" + col;
}
function get_row(cell)
{
    return parseInt(cell.attributes.row.value)
}

function get_column(cell)
{
    return parseInt(cell.attributes.column.value)
}

function get_adjacent_cells(cell, classes)
{
    var map = {};
    get_adjacent_cells_recurse(cell, classes, map);
    return map;
}

function get_adjacent_cells_recurse(cell, classes, map)
{
    var row = get_row(cell);
    var column = get_column(cell);

    var left = column > 0 ? get_cell_at(row, column - 1) : null;
    var right = column < cur_game_state.template.width - 1 ? get_cell_at(row, column + 1) : null;
    var top = row > 0 ? get_cell_at(row - 1, column) : null;
    var bottom = row < cur_game_state.template.height - 1 ? get_cell_at(row + 1, column) : null;
    var all = [left, right, top, bottom];

    for (var i = 0; i < 4; i++)
    {
        var cur_cell = all[i];

        if (cur_cell && !map[get_key(cur_cell[0])] && hasClasses(cur_cell[0], classes))
        {
            map[get_key(cur_cell[0])] = cur_cell;
            get_adjacent_cells_recurse(cur_cell[0], classes, map);
        }
    }
}

//------------------------------------------------------------------------------------------
//
// Events
//
//------------------------------------------------------------------------------------------
function fetch_game_state_resultHandler(game_state)
{
    console.log(game_state);

    cur_game_state = game_state;

    current_turn_type = (function(turn_code) { 
        for(var type_key in TURN_TYPES)
            if(TURN_TYPES[type_key].code == turn_code)
                return TURN_TYPES[type_key];
    })(game_state.valid_action.code);

    var turn_button = $('#turn_button');

    if(player_can_act()) 
    {
        turn_button.removeAttr('disabled');
    }
    else
    { 
        turn_button.attr('disabled', 'disabled');
    }

    player_index = game_state.current_player_index.toString()
    current_turn_type.render();
    render_board(game_state.current_turn.board, game_state.template.width, game_state.template.height);
    render_players(game_state.current_turn);
    render_metadata(game_state);
}

function document_readyHandler()
{
    polling_wrapper();

    $('.enabled').live('click', enabled_clickHandler);
    $('.cell').hover(cell_hoverOverHandler, cell_hoverOutHandler);
}

function game_readyHandler()
{
    GAME_ID = $('#game').attr('game_id');
}

function enabled_clickHandler(click_event)
{
    if(!player_can_act())
    {
        return;
    }

    var cell = $(this);

    if(selected_cell && selected_cell != cell)
    {
        selected_cell.removeClass('selected');
    }
    selected_cell = cell;
    selected_cell.addClass('selected');
}

function cell_hoverOverHandler(click_event)
{
    var cell = click_event.currentTarget;

    if(!player_can_act() || !hasClass(cell, "enabled"))
    {
        return;
    }

    adjacent_cells = get_adjacent_cells(cell, ["no_hotel"]);

    for (key in adjacent_cells)
    {
        var cur_cell = adjacent_cells[key];

        cur_cell.addClass('adjacent');
    }
}

function cell_hoverOutHandler(click_event)
{
    var cell = click_event.currentTarget;

    if(!player_can_act() || !hasClass(cell, "enabled"))
    {
        return;
    }

    adjacent_cells = get_adjacent_cells(cell, ["no_hotel"]);

    for (key in adjacent_cells)
    {
        var cur_cell = adjacent_cells[key];

        cur_cell.removeClass('adjacent');
    }
}

function send_game_update_successHandler()
{
    fetch_game_state();
}