var visible_popover = null;
var signin_button = '#signin_button';
var signin_popover = '#signin_form';
var signup_button = '#signup_button';
var signup_popover = '#signup_form';

$(document).ready(function() {

	// popover setup
	$('.title').load(function() { // wait for image to load
		set_popover_position(signin_button, signin_popover);
		set_popover_position(signup_button, signup_popover);
		fade_in_popover_if_necessary(signin_popover);
	});

	// handlers for showing popovers 
	$(signin_button).mouseenter(function() {
		fade_in_popover_if_necessary(signin_popover);
	});
	$(signup_button).mouseenter(function() {
		fade_in_popover_if_necessary(signup_popover);
	});

	/* handlers for hiding popovers
	$('body').click(function() {
		if(visible_popover) {
			$(visible_popover).fadeOut('fast');
			visible_popover = null;
		}
	})

	$('.popover').click(function(event) {
		return false;
	});
	*/
	
});

function set_popover_position(button, popover) {
	var popover_position = $(button).offset();
	popover_position.left += $(button).outerWidth(); // $('.title').outerWidth() + 
	popover_position.top -= get_popover_height(popover) / 2 - $(button).outerHeight() / 2;
	popover_position.top -= $('#mainbar').offset().top + $('.buttons').position().top;
	$(popover).css({ 'left': popover_position.left, 'top': popover_position.top });
}

function get_popover_height(popover) {
	var border_size = $(popover).css('border-image-slice').split(" "); // [top, right, bottom, left]
	var shadow_size = border_size[2] - border_size[0];
	return $(popover).outerHeight() - shadow_size;
}

function fade_in_popover_if_necessary(popover) {
	if(visible_popover != popover) {
		$(visible_popover).fadeOut('fast');
		$(popover).fadeIn('fast');
		$(popover).css({ 'display': 'inline-block' });
		visible_popover = popover;
	}
}
