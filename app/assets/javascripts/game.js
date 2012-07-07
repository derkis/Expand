//= require jquery
//= require jquery_ujs
$(document).ready(function() {

    $(".cell").hover(
        function() {$(this).css("background-color", "gray")}, 
        function() {$(this).css("background-color", "white")}
    );
});
