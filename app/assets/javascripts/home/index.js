var visible_popover = null;
var signin_button = '#signin_button';
var signin_popover = '#signin_form';
var signup_button = '#signup_button';
var signup_popover = '#signup_form';
var popover_vertical_offset = 25;

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

	 // handlers for hiding popovers
	$('body').click(function() {
		if(visible_popover) {
			$(visible_popover).fadeOut('fast');
			visible_popover = null;
		}
	})

	$('.popover').click(function(event) {
		return false;
	});
	
});

function set_popover_position(button, popover) {
	button = $(button);
	var popover_position = button.position();
	var popover_size = get_popover_size(popover);
	popover_position.left -= (popover_size.width - button.width()) / 2;
	if(popover == '#signin_form')
		popover_position.top -= popover_size.height + popover_vertical_offset;
	else
		popover_position.top += button.outerHeight() + popover_vertical_offset;

	$(popover).css({ 'left': popover_position.left, 'top': popover_position.top });
}

function get_popover_size(popover) {
	popover = $(popover);
	var border_top 		= parseInt(popover.css('border-top-width'), 10);
	var border_right 	= parseInt(popover.css('border-right-width'), 10);
	var border_bottom 	= parseInt(popover.css('border-bottom-width'), 10);
	var border_left 	= parseInt(popover.css('border-left-width'), 10);
	var bottom_shadow_size	= border_bottom - border_top;
	var left_shadow_size 	= border_left - border_right;
	return {
		'height': popover.outerHeight() - bottom_shadow_size,
		'width'	: popover.outerWidth() - left_shadow_size
	};
}

function fade_in_popover_if_necessary(popover) {
	if(visible_popover != popover) {
		$(visible_popover).fadeOut('fast');
		$(popover).fadeIn('fast');
		$(popover).css({ 'display': 'inline-block' });
		visible_popover = popover;
	}
}
