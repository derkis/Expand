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
        render(data.cur_turn.board, data.template.width, data.template.height);
    });
    
    setTimeout(polling_wrapper, 15000);
}

function render(board, width, height) {
    r = 0
    c = 0
    for (chr = 0; chr < board.length; chr++)
    {
        cellID = "#cell" + r + "_" + c;

        $(cellID).text(chars[r] + (c+1));

        c++;
        if (c >= width)
        {
            c = 0;
            r++;
        }
    }
}
