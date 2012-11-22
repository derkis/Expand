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

Object.size = function(obj) {
    var size = 0, key;
    for (key in obj) {
        if (obj.hasOwnProperty(key)) size++;
    }
    return size;
};

//------------------------------------------------------------------------------------------
//
// Variables
//
//------------------------------------------------------------------------------------------
var cur_turn_type;
var selected_cell;
var cur_game_state;
var message_temp = null;
var GAME_ID;
var temp_player_index = -1;

var stock_purchased_by_abbr = {};
var stock_purchased_total = 0;
var stock_purchased_cost = 0;

var stock_split_count = 0;
var stock_sell_count = 0;
var stock_sell_cost = 0;

var data_sent = false;

var first_load = true;

var merge_order_rendered = false;

var merge_order_custom = null;

var end_game = false;

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
    
    "0": { 
        name: 'no_action'
    },
    
    "100": { 
        name: 'place_piece',
        message: "Choose where to place your tile...",
        get_action: function() {
            return {
                row: selected_cell.attr('row').to_int(),
                column: selected_cell.attr('column').to_int()
            };
        },
        after_action: function() {

        },
        render: function(game_state) {
            render_stock_option_chooser(false)
            render_merge_company_chooser(false);
            render_merge_order_chooser(false);
            render_button("Place", false);
        },
        turn_label: function() {
            return is_my_turn() ? "Place a tile..." : active_player_name() + " is placing a tile";
        }
    },
    
    "200": {
        name: 'start_company',
        message: "Please choose a company to start",
        get_action: function() {
            // Return the selected company value
            return  {
                        company_abbr: $("input[name=company_group]").filter(':checked').val(),
                        row: cur_game_state.last_action.row,
                        column: cur_game_state.last_action.column
                    };
        },
        after_action: function() {
            // Close the start company popup if it is open
            $("#start_company_popup").bPopup().close();
            $("input[name=company_group]").attr("checked", false);
        },
        render: function(game_state) {
            render_button("Start", false);
            render_stock_option_chooser(false);
            render_merge_order_chooser(false);
            render_merge_company_chooser(false);
            render_start_company_at(game_state.last_action.row, game_state.last_action.column, game_state);
        },
        turn_label: function() {
            return is_my_turn() ? "Start a company..." : active_player_name() + " is choosing a company to start";
        }
    },
    
    "300": {
        name: 'purchase_stock',
        message: "Choose how many stocks to purchase",
        get_action: function() {
            return {"stocks_purchased": stock_purchased_by_abbr};
        },
        after_action: function() {
            stock_purchased_by_abbr = {};
            stock_purchased_total = 0;
            stock_purchased_cost = 0;
        },
        render: function(game_state) {
            render_stock_option_chooser(false);
            render_merge_company_chooser(false);
            render_merge_order_chooser(false);
            
            render_button("End Turn", true);
        },
        turn_label: function() {
            return is_my_turn() ? "Purchase stocks and end turn..." : active_player_name() + " is purchasing stocks and ending the turn";
        }
    },
    
    "500": {
        name: 'merge_choose_company',
        message: "Choose what company is acquired in this merger",
        get_action: function()
        {
            return {company_abbr: $("input[name=merge_choice]").filter(':checked').val()};
        },
        after_action: function()
        {
        },
        render: function(game_state)
        {
            render_merge_company_chooser(true);
            render_button("Purchase", false);
        },
        turn_label: function() {
            return is_my_turn() ? "Choose an acquiring company..." : active_player_name() + " is choosing acquiring company";
        }
    },
    "520": {
        name: 'merge_choose_order',
        message: "",
        get_action: function()
        {
            return  {
                    merge_order: merge_order_custom ? merge_order_custom : cur_game_state.cur_data.merge_state.merge_order
                    };
        },
        after_action: function()
        {
            merge_order_custom = null;
        },
        render: function(game_state)
        {
            render_merge_order_chooser(true);
            render_stock_option_chooser(false);
            render_merge_company_chooser(false);
            render_button("Purchase", false);
        },
        turn_label: function() {
            return is_my_turn() ? "Choose merge order... " : active_player_name() + " is choosing merge order";
        }
    },

    "550": {
        name: 'merge_choose_stock_options',
        message: "Choose what you wish to do with your stock for this merger",
        get_action: function()
        {
            return {
                        stock_split: stock_split_count,
                        stock_sold: stock_sell_count
                    };
        },
        after_action: function()
        {
            stock_split_count = 0;
            stock_sell_count = 0;
            stock_sell_cost = 0;
        },
        render: function(game_state)
        {
            render_stock_option_chooser(cur_game_state.cur_data.merge_state.stock_option_player_index == cur_game_state.user_player_index || cur_game_state.debug_mode)
            render_merge_company_chooser(false);
            render_merge_order_chooser(false);
            render_button("Purchase", false);
        },
        turn_label: function() {
            return is_my_turn() ? "Choose stock options... " : active_player_name() + " is choosing merge stock options";
        }
    },
    "600": {
        name: 'game_over',
        message: "The game has ended!",
        get_action: function()
        {
            return {};
        },
        after_action: function()
        {
        },
        render: function(game_state)
        {
            $("#forfeit_button").hide();
            $("#lobby_button").show();

            render_stock_option_chooser(false)
            render_merge_company_chooser(false);
            render_merge_order_chooser(false);
            render_button("Place", false);
        },
        turn_label: function() {
            return "Game Over. " + cur_game_state.cur_data.winner + " wins!";
        }
    },
    "700": {
        name: 'forfeit',
        message: "The game has ended!",
        get_action: function()
        {
            return {};
        },
        after_action: function()
        {
        },
        render: function(game_state)
        {
            $("#forfeit_button").hide();
            $("#lobby_button").show();

            render_stock_option_chooser(false)
            render_merge_company_chooser(false);
            render_merge_order_chooser(false);
            render_button("Place", false);
        },
        turn_label: function() {
            return cur_game_state.cur_data["forfeited_by"] + " Forfeited. " + cur_game_state.cur_data.winner + " wins!";
        }
    }
};

//------------------------------------------------------------------------------------------
//
// Methods
//
//------------------------------------------------------------------------------------------
function active_player_name()
{
    return cur_game_state.players[get_active_player_index()].user.email;
}

function get_active_player_index()
{
    if (cur_game_state.cur_data["merge_state"] && cur_game_state.cur_data["merge_state"]["stock_option_player_index"] >= 0)
    {
        return cur_game_state.cur_data["merge_state"]["stock_option_player_index"];
    }

    return cur_game_state.cur_player_index;
}

function get_player_index()
{
    if (temp_player_index != -1)
    {
        return temp_player_index;
    }

    if (cur_game_state.debug_mode)
    {
        // If we are in debug mode and we are currently choosing stock options, we want to 
        // display the data for the current player choosing stock options.
        if (cur_game_state.cur_data["merge_state"] && cur_game_state.cur_data["merge_state"]["stock_option_player_index"] >= 0)
        {
            return cur_game_state.cur_data["merge_state"]["stock_option_player_index"];
        }

        return cur_game_state.cur_player_index;
    }

    return cur_game_state.user_player_index;
}

function polling_wrapper()
{
    $.getJSON(document.URL + '.json', function (game_state) {
        load_game_state_resultHandler(game_state);
        setTimeout(polling_wrapper, 2000);
    });
}

function load_game_state()
{
    $.getJSON(document.URL + '.json', load_game_state_resultHandler);
}

// server calls
function send_game_update(custom)
{
    if (!is_my_turn() && custom && !custom["forfeit"])
    {
        return;
    }

    var json_update = custom ? 
                        {
                            'actions': custom
                        } :
                        {
                            'actions': cur_turn_type.get_action(),
                        };

    json_update["actions"]["end_game"] = end_game;
    end_game = false;

    data_sent = true;

    $.ajax(
        {
            type: 'PUT',
            url: GAME_ID + '.json',
            data: JSON.stringify(json_update), 
            contentType: 'application/json',                  
            dataType: 'json',                                  
            success: send_game_update_successHandler
        });

     cur_turn_type.after_action();
}

function reset_game()
{
    send_game_update({ 'turn_type' : 'reset' });
}

function render_all(game_state)
{
    $("#lobby_button").hide();

    render_board();
    render_players(game_state.cur_data.players);
    render_status();
    render_notifications();
    render_message();
    render_stock();
    render_stock_purchasing();
    render_company_start();
    render_companies();
    render_turn_button();
}

function render_companies()
{
    for (var key in cur_game_state.cur_data.companies)
    {
        var company = cur_game_state.cur_data.companies[key];
        var div_company_data_name = $(".company_data_name[company_abbr='" + key + "']");
        var div_company_data_stock_count = $(".company_data_stock_count[company_abbr='" + key + "']");
        var div_company_data_value = $(".company_data_value[company_abbr='" + key + "']");
 
        div_company_data_name.text(company.name);
        div_company_data_stock_count.text(company["stock_count"]);
        div_company_data_value.text("$" + get_company_stock_cost_for(key));
    }
}

function render_button(text, show)
{
    if (!show)
    {
        $("#turn_button").hide();
    }
    else
    {
        $("#turn_button").show();
        $("#turn_button").attr("value", text);
    }
}

function render_merge_company_chooser(show)
{
    if (!show)
    {
        $(".merge_company_chooser").hide();
    }
    else
    {
        // Here we only want to show all those companies that are available
        // for this merger, we want to hide every other one
        companies = cur_game_state.cur_data.merge_state.companies_to_merge;

        for (var key in cur_game_state.cur_data.companies)
        {
            var div_merge_company = $(".merge_company[company_abbr='" + key + "']");
            div_merge_company.hide();
        }

        for (var key in companies)
        {
            var div_merge_company = $(".merge_company[company_abbr='" + key + "']");
            div_merge_company.show();
        }

        $(".merge_company_chooser").show();
    }
}

function render_merge_order_chooser(show)
{
    if (!show)
    {
        $(".merge_company_order_chooser").hide();
    }
    else
    {
        cur_merge_order = merge_order_custom ? merge_order_custom : cur_game_state.cur_data.merge_state.merge_order;

        html = "";

        for (var i = 0; i < cur_merge_order.length; i ++)
        {
            company = get_company(cur_merge_order[i]);

            html += "<div style='color:"
                    + company.color + ";'>"
                    + (i + 1).toString()
                    + ": "
                    + company.name
                    + "<button type='button' index='"+i+"' name='order_choice' onclick='merge_order_down_handler(event)'>v</button>"
                    + "<button type='button' index='"+i+"' name='order_choice' onclick='merge_order_up_handler(event)'>^</button></div>";
        }

        $(".merge_company_order_content").html(html);
        $(".merge_company_order_chooser").show();
    }
}

function render_stock_option_chooser(show)
{
    if (!show)
    {
        $(".merge_company_stock_option_chooser").hide();
    }
    else
    {
        // We want to show the company we are currently picking stock options for
        var div_stock_company_from = $(".stock_company_from");
        var div_stock_company_to = $(".stock_company_to");
        var company_from = get_company(cur_game_state.cur_data.merge_state.cur_company_options);
        var company_to = get_company(cur_game_state.cur_data.merge_state.company_abbr);

        div_stock_company_from.text(company_from.name);
        div_stock_company_from.css("color", company_from.color);

        div_stock_company_to.text(company_to.name);
        div_stock_company_to.css("color", company_to.color);

        $(".merge_company_stock_option_chooser").show();

        render_stock_option_chooser_counts();
    }
}

function render_stock_option_chooser_counts()
{
    var company_from = get_company(cur_game_state.cur_data.merge_state.cur_company_options);
    var company_to = get_company(cur_game_state.cur_data.merge_state.company_abbr);

    // Get the total number of stock available for the company in question
    var stock_count = get_player(cur_game_state.cur_data.merge_state.stock_option_player_index).stock_count[cur_game_state.cur_data.merge_state.cur_company_options];
    
    var stock_keep_count = stock_count - stock_split_count - stock_sell_count;
    var stock_gain_count = stock_split_count / 2;

    var div_stock_split_count = $(".stock_split_count");
    var div_stock_sell_count = $(".stock_sell_count");
    var div_stock_keep_count = $(".stock_keep_count");
    var div_stock_keep_company = $(".stock_keep_company");
    var div_stock_gain_count = $(".stock_gain_count");
    var div_stock_gain_company = $(".stock_gain_company");

    div_stock_split_count.text(stock_split_count);
    div_stock_sell_count.text(stock_sell_count);
    div_stock_keep_count.text(stock_keep_count);
    div_stock_gain_count.text(stock_gain_count);
    
    div_stock_keep_company.text(company_from.name);
    div_stock_keep_company.css("color", company_from.color);

    div_stock_gain_company.text(company_to.name);
    div_stock_gain_company.css("color", company_to.color);
}

function render_stock() 
{
    var total_assets = get_cur_money() - stock_purchased_cost + stock_sell_cost;

    for (var key in cur_game_state.cur_data.companies)
    {
        var company = cur_game_state.cur_data.companies[key];
        var div_player_stock_in_company = $(".player_stock_in_company[company_abbr='" + key + "']");
        var div_player_stock_in_company_value = $(".player_stock_in_company_value[company_abbr='" + key + "']");
        var div_player_stock_in_company_main = $(".player_stock_in_company_main[company_abbr='" + key + "']");
        var div_player_stock_in_company_lbl = $(".player_stock_in_company_lbl[company_abbr='" + key + "']");

        if (company.size > 0 || get_cur_stock_in(key) > 0)
        {
            stock_being_purchased = (!isNaN(stock_purchased_by_abbr[key]) ? stock_purchased_by_abbr[key] : 0);
            div_player_stock_in_company_main.show();
            div_player_stock_in_company.text(get_cur_stock_in(key) + stock_being_purchased );
            value = (get_cur_stock_in(key) + stock_being_purchased) * get_company_value_for(key).cost;
            if (company.size > 0)
            {
                total_assets += value;
                div_player_stock_in_company_value.text("$" + value)
            }
            else
            {
                div_player_stock_in_company_value.text("N/A")
            }
            
            div_player_stock_in_company_lbl.text(company.name);
        }
        else
        {
            div_player_stock_in_company_main.hide();
        }
    }

    var div_total_assets = $(".total_assets");
    div_total_assets.text("$" + total_assets);
}

function render_company_start()
{
    for (var key in cur_game_state.cur_data.companies)
    {
        var company = cur_game_state.cur_data.companies[key];
        var div_company_to_start = $(".company_to_start[company_abbr='" + key + "']");

        if (company.size)
        {
            div_company_to_start.hide();
        }
        else
        {
            div_company_to_start.show();
        }
    }
}

function render_stock_purchasing()
{
    $(".endgame_button").hide();

    for (var key in cur_game_state.cur_data.companies)
    {
        var company = get_company(key);
        var div_company_stock_purchased = $(".company_stock_purchased[company_abbr='" + key + "']");

        if (company.size > 0 && cur_game_state.cur_data.state == 300 && is_my_turn())
        {
            div_company_stock_purchased.show();

            if (cur_game_state.can_end_game)
            {
                $(".endgame_button").show();
            }
        }
        else
        {
            div_company_stock_purchased.hide();
        }
    }
}

function render_turn_button()
{
    var turn_button = $('#turn_button');

    if(player_can_act()) 
    {
        turn_button.show();
    }
    else
    { 
        turn_button.hide();
    }
}

var company_cells_marked = {};

function render_board()
{
    board = cur_game_state.board;
    num_columns = cur_game_state.template.width;
    num_rows = cur_game_state.template.height;

    $(".debug_string").text(board);

    company_cells_marked = {};

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
    // Clear out all the cell's current styling
    cell.removeClass('empty enabled no_hotel selected highlighted adjacent blocked');
    cell.css("background-color", "");
    cell.text((65 + row).to_char() + (column+1));

    player_index = get_player_index().toString();

    switch(cell_type) {
        case '!': // empty cell
            cell.addClass('blocked');
            cell.text("");
            break;
        case 'e': // empty cell
            cell.addClass('empty');
            break;
        case 'u':
            cell.addClass('no_hotel');
            cell.text("");
            break;
        case '+':
            cell.addClass('enabled');
            cell.text("Merge");
            break;
        case player_index:
            cell.addClass('enabled');
            cell.text("*");
            break;
        default:
            if (cell_type.is_int())
            {
                // This is someone else's tile! Don't show that it is their tile
            }
            else
            {
                // This needs to be the color of the chain it belongs to:
                cell.css("background-color", get_company(cell_type)["color"]);

                if (!company_cells_marked[cell_type])
                {
                    company_cells_marked[cell_type] = true;
                    cell.text(get_company(cell_type)["abbr"].toUpperCase() + " (" + get_company(cell_type)["size"] + ")");
                }
                else
                {
                    cell.text("");
                }
            }
    }
}

function get_turn_text()
{
    return cur_turn_type.turn_label();
}

function render_status()
{
    document.title = "Expand: " + get_turn_text();

    $('.turn_label').text("Turn " + (cur_game_state.cur_turn_number + 1) + ": " + get_turn_text());
    $('.money').text("$" + (get_cur_money() - stock_purchased_cost + stock_sell_cost));
    var txt = $(".player[player_index='" + get_player_index() + "']").text();
    $('.player_status_lbl').text(txt);
}

function render_notifications()
{
    var div_messages = $('.messages');

    var notifications_text = "";

    if (cur_game_state.cur_data.notifications)
    {
        last_num = 0;

        for (var i = 0; i < cur_game_state.cur_data.notifications.length; i++)
        {
            notification = cur_game_state.cur_data.notifications[i];

            notifications_text += "</br>" + (last_num == notification.turn_number ? "" : "<span style='color:#AAAAAA;'>Turn " + notification.turn_number + "</span> :") + notification.message;

            last_num = notification.turn_number;
        }
    }

    if (first_load || div_messages[0].scrollTop == div_messages[0].scrollHeight)
    {
        div_messages.html(notifications_text);
        div_messages.scrollTop(div_messages[0].scrollHeight);
    }
    else
    {
        div_messages.html(notifications_text);
    }
}

function render_players()
{
    $('.player').removeClass('current_player');
    $('.player[player_index=' + cur_game_state.cur_player_index + ']').addClass('current_player');
}

function render_message()
{
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

function get_cur_stock_in(company_abbr)
{
    var val = cur_game_state.cur_data.players[get_player_index()]["stock_count"][company_abbr];

    if (cur_game_state.cur_data.merge_state)
    {
        if (company_abbr == cur_game_state.cur_data.merge_state.company_abbr)
        {
            val = isNaN(val) ? stock_split_count / 2 : val + stock_split_count / 2;
        }

        if (company_abbr == cur_game_state.cur_data.merge_state.cur_company_options)
        {
            val = isNaN(val) ? -(stock_split_count + stock_sell_count) : val - (stock_split_count + stock_sell_count);
        }
    }

    return isNaN(val) ? 0 : val;
}

function get_cur_money()
{
    return cur_game_state.cur_data.players[get_player_index()]["money"];
}

function player_can_act()
{
    return cur_turn_type != TURN_TYPES.NO_ACTION;
}

function player_can_place_piece()
{
    return cur_turn_type == TURN_TYPES["100"];
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

function get_player(player_index)
{
    return cur_game_state.cur_data.players[player_index]
}

function get_company_value_for(company_abbr)
{
    // 1) Find the company
    var company = get_company(company_abbr);
    var i = 0;

    // 2) Loop through value rows (cost / size)
    for (; i < company.value.length; i++)
    {
        var row = company.value[i];

        // 3) Return the previous row when we find a row that has a count
        //    greater than the current company size.
        if (row.size > company.size && i > 0)
        {
            return company.value[i - 1];
        }
    }

    if (i == company.value.length)
    {
        return company.value[company.value.length - 1];
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
    stock_purchased_cost = 0;

    for (var key in stock_purchased_by_abbr)
    {
        stock_purchased_total += stock_purchased_by_abbr[key];
        stock_purchased_cost += get_company_stock_cost_for(key) * stock_purchased_by_abbr[key];
    }
}

function add_stock_for(company_abbr)
{
    // Will this exceed the limit of stocks purchasable in a turn?
    if (stock_purchased_total == cur_game_state.cur_data.stock_purchase_limit)
    {
        return;
    }

    // Will this bankrupt the player?
    if (get_cur_money() - stock_purchased_cost - get_company_stock_cost_for(company_abbr) < 0)
    {
        return;
    }

    // Will this exceed the number of stock available for the company?
    if (cur_game_state.cur_data.companies[company_abbr]["stock_count"] == 0)
    {
        return;
    }

    if (stock_purchased_by_abbr[company_abbr])
    {
        if (cur_game_state.cur_data.companies[company_abbr]["stock_count"] - stock_purchased_by_abbr[company_abbr] - 1 < 0)
        {
            return;
        }
    }

    if (stock_purchased_by_abbr[company_abbr] != null)
    {
        stock_purchased_by_abbr[company_abbr]++;   
    }
    else
    {
        stock_purchased_by_abbr[company_abbr] = 1;
    }

    calc_stock_purchased_total();

    render_stock();
    render_status();
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

    render_stock();
    render_status();
}

function is_my_turn()
{
    if (!cur_game_state)
    {
        return false;
    }

    if (cur_game_state.debug_mode)
    {
        return true;
    }

    if (cur_game_state.cur_data.merge_state && cur_game_state.cur_data.merge_state.stock_option_player_index >= 0)
    {
        return cur_game_state.cur_data.merge_state.stock_option_player_index == cur_game_state.user_player_index;
    }

    return cur_game_state.user_player_index == cur_game_state.cur_player_index;
}
//------------------------------------------------------------------------------------------
//
// Events
//
//------------------------------------------------------------------------------------------
function load_game_state_resultHandler(game_state)
{
    // If we have outbound data and are waiting for a result on an action we have taken, we don't
    // want to update the screen for an interval until that data is processed or else it might
    // throw up a popup or something that we just finished using (e.g. the start company popup)
    if (data_sent)
    {
        return;
    }

    cur_game_state = game_state;

    if (cur_game_state.cur_data["forfeited_by"])
    {
    }

    cur_turn_type = TURN_TYPES[cur_game_state.cur_data.state.toString()];

    render_all(game_state);

    if (is_my_turn())
    {
        TURN_TYPES[game_state.cur_data.state.toString()].render(game_state);
    }
    else
    {
        render_stock_option_chooser(false)
        render_merge_company_chooser(false);
        render_merge_order_chooser(false);
        render_button("Place", false);
    }

    first_load = false;
}

function document_readyHandler()
{
    polling_wrapper();

    $('.enabled').live('click', enabled_clickHandler);
    $('.cell').hover(cell_hoverOverHandler, cell_hoverOutHandler);
    $('.player').hover(player_hoverOverHandler, player_hoverOutHandler);
}

function game_readyHandler()
{
    GAME_ID = $('#game').attr('game_id');
}

function enabled_clickHandler(click_event)
{
    if(!is_my_turn() || !player_can_place_piece())
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

    send_game_update();
}

function cell_hoverOverHandler(click_event)
{
    if (!is_my_turn())
    {
        return;
    }

    var cell = click_event.currentTarget;

    if (cur_turn_type == TURN_TYPES["100"])
    {
        var can_create_company = false;

        if(!hasClass(cell, "enabled"))
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

    if (cur_turn_type == TURN_TYPES["100"])
    {
        if(!hasClass(cell, "enabled"))
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

function player_hoverOverHandler(click_event)
{
    if (!cur_game_state.debug_mode)
    {
        return;
    }

    var cell = click_event.currentTarget;

    temp_player_index = parseInt(cell.getAttribute("player_index"));

    render_status();
    render_stock();
    render_board();
}

function player_hoverOutHandler(click_event)
{
    if (!cur_game_state.debug_mode)
    {
        return;
    }
    
    temp_player_index = -1;

    render_status();
    render_stock();
    render_board();
}

function send_game_update_successHandler()
{
    data_sent = false;

    load_game_state();
}

function input_handler()
{
    send_game_update();
}

function end_game_handler()
{
    end_game = true;
    send_game_update();
}

function back_handler()
{
    send_game_update({previous_turn: true});
}

function next_handler()
{
    send_game_update({next_turn: true});
}

function forfeit_handler()
{
    $("#forfeit_popup").bPopup({modalClose: false});
}

function forfeit_confirm_handler()
{
    send_game_update({forfeit: true});
    $("#forfeit_popup").bPopup().close();
}

function forfeit_disconfirm_handler()
{
    $("#forfeit_popup").bPopup().close();
}

function start_company_click_handler()
{
    company_chosen = $("input[name=company_group]").filter(':checked').val();
    if (company_chosen && company_chosen != "")
    {
        send_game_update();
    }
}

function purchase_stock_click_handler()
{
    send_game_update();
}

function lobby_click_handler()
{
    window.location = "../../portal";
}

function sub_stock_split_handler()
{
    stock_split_count-=2;

    if (stock_split_count < 0)
    {
        stock_split_count = 0
    }

    render_stock();
    render_stock_option_chooser_counts();
}

function add_stock_split_handler()
{
    // Don't allow the user to split more stock than is possible
    var company_to = get_company(cur_game_state.cur_data.merge_state.company_abbr)
    var stock_in = get_player(cur_game_state.cur_data.merge_state.stock_option_player_index).stock_count[cur_game_state.cur_data.merge_state.cur_company_options];

    if (company_to.stock_count - ((stock_split_count / 2) + 1) < 0)
    {
        return;
    }

    if (stock_in - stock_sell_count - stock_split_count - 2 < 0)
    {
        return;
    }

    stock_split_count+=2;

    render_stock();
    render_stock_option_chooser_counts();
}

function sub_stock_sell_handler()
{
    if (stock_sell_count - 1 < 0)
    {
        return;
    }

    stock_sell_count--;

    stock_sell_cost = stock_sell_count * get_company_stock_cost_for(cur_game_state.cur_data.merge_state.cur_company_options);

    render_status();
    render_stock();
    render_stock_option_chooser_counts();
}

function add_stock_sell_handler()
{
    var stock_in = get_player(cur_game_state.cur_data.merge_state.stock_option_player_index).stock_count[cur_game_state.cur_data.merge_state.cur_company_options];

    if (stock_in - stock_sell_count - stock_split_count - 1 < 0)
    {
        return;
    }

    stock_sell_count++;

    stock_sell_cost = stock_sell_count * get_company_stock_cost_for(cur_game_state.cur_data.merge_state.cur_company_options);

    render_status();
    render_stock();
    render_stock_option_chooser_counts();
}

function merge_order_down_handler(event)
{
    cur_merge_order = merge_order_custom ? merge_order_custom : cur_game_state.cur_data.merge_state.merge_order;

    index = parseInt(event.currentTarget.getAttribute("index"));

    edge_case = index == cur_merge_order.length-1;
    temp = edge_case ? cur_merge_order[0] : cur_merge_order[index + 1];
    cur_merge_order[edge_case ? 0 : index + 1] = cur_merge_order[index];
    cur_merge_order[index] = temp;

    merge_order_custom = cur_merge_order;

    render_merge_order_chooser(true);
}

function merge_order_up_handler(event)
{
    cur_merge_order = merge_order_custom ? merge_order_custom : cur_game_state.cur_data.merge_state.merge_order;

    index = parseInt(event.currentTarget.getAttribute("index"));

    edge_case = index == 0;
    temp = edge_case ? cur_merge_order[cur_merge_order.length - 1] : cur_merge_order[index - 1];
    cur_merge_order[edge_case ? cur_merge_order.length - 1 : index - 1] = cur_merge_order[index];
    cur_merge_order[index] = temp;

    merge_order_custom = cur_merge_order;

    render_merge_order_chooser(true);
}

function lobby_handler()
{
    document.URL = "/portal";
}