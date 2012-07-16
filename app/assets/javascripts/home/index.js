var signin_popover_visible = false;

$(document).ready(function() {

	// signin popover setup
	var signin_popover_position = $('.signin_button').offset();
	console.log('signin_popover_position: ' + signin_popover_position.left + ' ' + signin_popover_position.top);
	$('.title').load(function() { // wait for image to load
		signin_popover_position.left += $('.title').outerWidth() + $('.signin_button').outerWidth();
		signin_popover_position.top -= $('.signin_popover').outerHeight() / 2 - $('.signin_button').outerHeight() / 2;
		signin_popover_position.top -= $('#mainbar').offset().top;
		$('.signin_popover').css({ 'left': signin_popover_position.left, 'top': signin_popover_position.top });
	});

	// handlers for hiding popovers
	$('body').click(function() {
		if(signin_popover_visible) {
			$('.signin_button').attr('src', 'assets/signin_button.png');
			$('.signin_popover').fadeOut(50);
			signin_popover_visible = false;
		}
	})

	$('.signin_popover').click(function(event) {
		return false;
	});

	// handlers for showing popovers 
	$('.signin_button').mouseenter(function() {
		console.log(signin_popover_position);
		if(!signin_popover_visible) {
			$('.signin_button').attr('src', 'assets/signin_button_hover.png');
			$('.signin_popover').fadeIn('fast');
			signin_popover_visible = true;
		}
	});

});