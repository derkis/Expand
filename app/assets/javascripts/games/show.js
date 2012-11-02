//------------------------------------------------------------------------------------------
//
// Lib
//
//------------------------------------------------------------------------------------------
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
var cur_turn_type;
var selected_cell;
var cur_game_state;
var message_temp = null;
var GAME_ID;

//------------------------------------------------------------------------------------------
//
// Initialization
//
//------------------------------------------------------------------------------------------
$(document).ready(document_readyHandler);
$('#game').ready(game_readyHandler);

//------------------------------------------------------------------------------------------
//
// Turn Types
//
//------------------------------------------------------------------------------------------
var TURN_TYPES = {
    
    "000": { 
        name: 'no_action'
    },
    
    "100": { 
        name: 'place_piece',
        message: "Please choose where to place your tile and then click Input",
        get_action: function() {
            return {
                row: selected_cell.attr('row').to_int(),
                column: selected_cell.attr('column').to_int()
            };
        }
    },
    
    "200": {
        name: 'start_company',
        message: "Please choose a company to start",
        get_action: function() {
            // Return the selected company value
            return  {
                        "company_index": $("input[name=company_group]").filter(':checked').val()
                    };
        }
    },
    
    "300": {
        name: 'purchase_stock',
        message: "Choose how many stocks to purchase",
        get_action: function() {
            return  {
                        "stocks_purchased": $("input[name=stock_purchase_group]").filter(':checked').val()
                    }
        }
    },
    
    "400": {
        name: 'trade_stock'
    },
    
    "500": {
        name: 'merge_order'
    }
};

//------------------------------------------------------------------------------------------
//
// Methods
//
//------------------------------------------------------------------------------------------
function polling_wrapper()
{
    load_game_state();

    setTimeout(polling_wrapper, 15000);
}

function load_game_state()
{
    $.getJSON(document.URL + '.json', load_game_state_resultHandler);
}

// server calls
function send_game_update()
{
    var json_update =
        { 'actions': cur_turn_type.get_action() };

    $.ajax(
        {
            type: 'PUT',
            url: GAME_ID + '.json',
            data: JSON.stringify(json_update), 
            contentType: 'application/json',                  
            dataType: 'json',                                  
            success: send_game_update_successHandler
        });     
}

function reset_game()
{
    send_game_update({ 'turn_type' : 'reset' });
}

function render_all(game_state)
{
    render_board(cur_game_state.board, game_state.template.width, game_state.template.height);
    render_players(game_state.cur_data.players);
    render_status(game_state);
    render_message();
    render_turn_button();
}

function render_turn_button()
{
    var turn_button = $('#turn_button');

    if(player_can_act()) 
    {
        turn_button.removeAttr('disabled');
    }
    else
    { 
        turn_button.attr('disabled', 'disabled');
    }
}

function render_board(board, num_columns, num_rows)
{
    $(".debug_string").text(board);

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
    cell.removeClass('empty enabled no_hotel selected');
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

function render_status()
{
    $('.turn_label').text("Turn: " + (cur_game_state.cur_turn_number + 1));
    $('.money').text("$" + cur_game_state.cur_data.players[cur_game_state.cur_player_index]["money"]);
}

function render_players()
{
    $('.player').removeClass('current_player');
    $('.player[player_index=' + cur_game_state.cur_player_index + ']').addClass('current_player');
}

function render_message()
{
    var msg = cur_turn_type.message;

    if (message_temp)
    {
        msg = message_temp;
    }

    $(".message").text(msg);
}

function render_start_company_at(row, column, game_state)
{
    var cell = get_cell_at(row, column)[0];

    adjacents = get_connected_cells(cell, ["no_hotel"]);

    for (key in adjacents)
    {
        can_create_company = true;

        adjacents[key].addClass('highlighted');
    }

    $("#start_company_popup").bPopup({modalClose: false});
}

function player_can_act()
{
    return cur_turn_type != TURN_TYPES.NO_ACTION;
}

function get_cell_char_at(row, column)
{
    return cur_game_state.board.chartAt(row * cur_game_state.template.width + column)
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

function get_connected_cells(cell, classes)
{
    var map = {};
    get_connected_cells_recurse(cell, classes, map);
    return map;
}

function get_connected_cells_recurse(cell, classes, map)
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
            get_connected_cells_recurse(cur_cell[0], classes, map);
        }
    }
}

//------------------------------------------------------------------------------------------
//
// Events
//
//------------------------------------------------------------------------------------------
function load_game_state_resultHandler(game_state)
{
    console.log(game_state);

    cur_game_state = game_state;
    cur_turn_type = TURN_TYPES[cur_game_state.cur_data.state.toString()];

    player_index = game_state.cur_player_index.toString();

    render_all(game_state);

    if (game_state.last_action && game_state.last_action.start_company)
    {
        render_start_company_at(game_state.last_action.place.row, game_state.last_action.place.column, game_state);
    }
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

    if (cur_turn_type == TURN_TYPES.PLACE_PIECE)
    {
        var can_create_company = false;

        if(!player_can_act() || !hasClass(cell, "enabled"))
        {
            return;
        }

        adjacent_cells = get_connected_cells(cell, ["no_hotel"]);

        for (key in adjacent_cells)
        {
            can_create_company = true;

            adjacent_cells[key].addClass('adjacent');
        }

        if (can_create_company)
        {
            message_temp = "Place here to create a new company.";

            render_message();
        }
    }
}

function cell_hoverOutHandler(click_event)
{
    var cell = click_event.currentTarget;

    if (cur_turn_type == TURN_TYPES.PLACE_PIECE)
    {
        if(!player_can_act() || !hasClass(cell, "enabled"))
        {
            return;
        }

        adjacent_cells = get_connected_cells(cell, ["no_hotel"]);

        for (key in adjacent_cells)
        {
            adjacent_cells[key].removeClass('adjacent');
        }

        message_temp = null;

        render_message();
    }
}

function send_game_update_successHandler()
{
    load_game_state();
}

function input_handler()
{
    send_game_update();
}

function start_company_click_handler()
{
    send_game_update();
}