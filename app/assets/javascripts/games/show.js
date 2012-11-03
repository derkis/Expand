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

String.prototype.is_int = function() 
{
    return !isNaN(parseInt(this));
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

var stock_purchased_by_abbr = {};
var stock_purchased_total = 0;

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
            // Close the start company popup if it is open
            $("#start_company_popup").bPopup().close();
            
            // Return the selected company value
            return  {
                        company_abbr: $("input[name=company_group]").filter(':checked').val(),
                        row: cur_game_state.last_action.row,
                        column: cur_game_state.last_action.column
                    };
        },
        render: function(game_state) {
            render_start_company_at(game_state.last_action.row, game_state.last_action.column, game_state);
        }
    },
    
    "300": {
        name: 'purchase_stock',
        message: "Choose how many stocks to purchase",
        get_action: function() {
            ret =  {"stocks_purchased": {}}

            for (var key in cur_game_state.cur_data.companies)
            {
                var count = parseInt($("input[name=stock_purchase_group_" + key + "]").filter(':checked').val());

                if (count)
                {
                    ret["stocks_purchased"][key] = count;
                }
            }

            return ret;
        },
        render: function(game_state) {
            render_purchase_stock(game_state);
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
    render_popups();
    render_turn_button();
}

function render_popups()
{
    // Here we pouplate the values of the companies in the radio buttons for
    // purchase stock popup (e.g. Luxor for 1 stock at size 2 is $200)
    for (var key in cur_game_state.cur_data.companies)
    {
        var company = get_company(key);
        var div_company_stock_purchase = $(".company_stock_purchased[company_abbr='" + key + "']");

        if (company.size)
        {
            div_company_stock_purchase.show();
        }
        else
        {
            div_company_stock_purchase.hide();
        }
    }
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
        default:
            if (cell_type.is_int())
            {
                // This is someone else's tile! Don't show it.
            }
            else
            {
                // This needs to be the color of the chain it belongs to:
                cell.css("background-color", get_company(cell_type)["color"]);
                cell.text(get_company(cell_type)["abbr"].toUpperCase());
            }
    }
}

function render_status()
{
    $('.turn_label').text("Turn: " + (cur_game_state.cur_turn_number + 1));
    $('.money').text("$" + get_cur_money());
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

function render_purchase_stock(game_state)
{
    $("#purchase_stock_popup").bPopup({modalClose: false});
}

function render_stock_purchase_selection()
{
    var stock_purchased_cost = 0;

    // Clear out all to zeros unless there is something specified to be 
    // purchased for a particular company.
    for (var key in cur_game_state.cur_data.companies)
    {
        var div_company_stock_purchased_total = $(".company_stock_purchased_total[company_abbr='" + key + "']");
        var div_company_stock_purchased_cost = $(".company_stock_purchased_cost[company_abbr='" + key + "']");

        if (stock_purchased_by_abbr[key])
        {
            div_company_stock_purchased_total.text(stock_purchased_by_abbr[key]);

            var cost = (get_company_stock_cost_for(key) * stock_purchased_by_abbr[key]);
            var cost_string = "- $" + cost.toString();
            div_company_stock_purchased_cost.text(cost_string);

            stock_purchased_cost += cost;
        }
        else
        {
            div_company_stock_purchased_total.text("0");
            div_company_stock_purchased_cost.text("$0");
        }
    }

    var div_stock_purchased_total = $(".stock_purchased_total");
    div_stock_purchased_total.text(stock_purchased_total);

    var div_stock_purchased_cost = $(".stock_purchased_cost");
    div_stock_purchased_cost.text("$" + stock_purchased_cost);

    var div_stock_purchased_money_after = $(".stock_purchased_money_after");
    div_stock_purchased_money_after.text("$" + (get_cur_money() - stock_purchased_cost));
}

function get_cur_money()
{
    return cur_game_state.cur_data.players[cur_game_state.user_player_index]["money"];
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

function get_company(company_abbr)
{
    for (var key in cur_game_state.cur_data.companies)
    {
        if (key == company_abbr)
        {
            return cur_game_state.cur_data.companies[key]
        }
    }
}

function get_company_value_for(company_abbr)
{
    // 1) Find the company
    var company = get_company(company_abbr);

    // 2) Loop through value rows (cost / size)
    for (var i = 0; i < company.value.length; i++)
    {
        var row = company.value[i];

        // 3) Return the previous row when we find a row that has a count
        //    greater than the current company size.
        if (row.size > company.size && i > 0)
        {
            return company.value[i - 1];
        }
    }

    return company.value[0];
}

function get_company_stock_cost_for(company_abbr)
{
    return get_company_value_for(company_abbr)["cost"];
}

function calc_stock_purchased_total()
{
    stock_purchased_total = 0;

    for (var key in stock_purchased_by_abbr)
    {
        stock_purchased_total += stock_purchased_by_abbr[key];
    }
}

function add_stock_for(company_abbr)
{
    if (stock_purchased_by_abbr[company_abbr] != null)
    {
        if (stock_purchased_by_abbr[company_abbr] < cur_game_state.cur_data.stock_purchase_limit)
        {
            stock_purchased_by_abbr[company_abbr]++;
        }
    }
    else
    {
        stock_purchased_by_abbr[company_abbr] = 1;
    }

    calc_stock_purchased_total();

    render_stock_purchase_selection();
}

function sub_stock_for(company_abbr)
{
    if (stock_purchased_by_abbr[company_abbr] != null)
    {
        stock_purchased_by_abbr[company_abbr]--;
    }

    if (stock_purchased_by_abbr[company_abbr] <= 0)
    {
        delete stock_purchased_by_abbr[company_abbr];
    }

    calc_stock_purchased_total();  

    render_stock_purchase_selection();
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

    TURN_TYPES[game_state.cur_data.state.toString()].render(game_state);
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

function purchase_stock_click_handler()
{
    send_game_update();
}