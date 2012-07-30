chars = ["A","B","C","D","E","F","G","H","I","J","K","L"];

$(document).ready(function() {
    polling_wrapper();

    $(".game_cell").hover(
        function() {$(this).css("background-color", "gray")}, 
        function() {$(this).css("background-color", "white")}
    );
});

function polling_wrapper() {
    $.getJSON(document.URL + '.json', null, function(data) {
        console.log(data)
        renderBoard(data.cur_turn.board, data.template.width, data.template.height);
        renderPlayers(data.cur_turn)
    });

    setTimeout(polling_wrapper, 15000);
}

function renderPlayers(cur_turn)
{
    playerDiv = "#player_" + cur_turn.player_id;
    $(playerDiv).css("background-color", "red");
}

function renderBoard(boardStr, width, height) {
    r = 0;
    c = 0;

    for (chr = 0; chr < boardStr.length; chr++)
    {
        renderCell(r, c, boardStr[chr], $("#cell" + r + "_" + c));

        c++;

        if (c >= width)
        {
            c = 0;
            r++;
        }
    }
}

function renderCell(row, column, type, cell)
{
    switch (type)
    {
        case "e":
            cell.css("background-color", "gray");
            cell.text(chars[r] + (c+1));
        break;
        default:
            cell.text(type);
    }
}
