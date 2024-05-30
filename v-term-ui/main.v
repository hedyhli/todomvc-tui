import term.ui as tui

struct App {
mut:
tui &tui.Context = unsafe { nil }
focus Focus = .input
}

enum Focus {
	input
	list
}

fn event(e &tui.Event, x voidptr) {
	if e.typ == .key_down && e.code == .c && e.modifiers == .ctrl {
		exit(0)
	}
	if e.typ == .key_down && e.code == .q {
		exit(0)
	}
}

/// Rectangel with borders
fn (mut app App) bordered(sides int, top int, height int) {
	full_w := app.tui.window_width
	full_h := app.tui.window_height

	bot := top + height - 1

	app.tui.draw_text(sides, top, "┌")
	for i in sides+1..(full_w - sides) {
		app.tui.draw_text(i, top, "─")
	}
	app.tui.draw_text(full_w - sides, top, "┐")

	for j in top + 1 .. (bot) {
		app.tui.draw_text(sides, j, "│")
		app.tui.draw_text(full_w - sides, j, "│")
	}

	app.tui.draw_text(sides, bot, "└")
	for i in sides+1..(full_w - sides) {
		app.tui.draw_text(i, bot, "─")
	}
	app.tui.draw_text(full_w - sides, bot, "┘")
}

fn (mut app App) centered_text(y int, text string) {
	full := app.tui.window_width
	len := utf8_str_visible_length(text)
	app.tui.draw_text(full / 2 - len / 2, y, text)
}

fn (mut app App) right_text(right int, y int, text string) {
	mut x := right
	full := app.tui.window_width
	if right <= 0 {
		x = full + right
	}
	len := utf8_str_visible_length(text)
	app.tui.draw_text(x - len, y, text)
}

fn frame(x voidptr) {
	mut app := unsafe { &App(x) }

	app.tui.clear()

	sides := 25
	app.tui.reset()
	app.centered_text(7, "T O D O M V C")

	if app.focus == .input {
		app.tui.set_color(r: 200, g: 0, b: 50)
	}
	app.bordered(sides, 10, 3)
	app.tui.reset()

	if app.focus == .list {
		app.tui.set_color(r: 200, g: 0, b: 50)
	}
	app.bordered(sides, 13, 18)

	app.tui.reset()
	app.right_text(-sides, 13 + 18, "X items left")

	app.tui.set_cursor_position(sides + 2, 11)
	app.tui.flush()
}

fn main() {
	mut app := &App{}
	app.tui = tui.init(
		user_data: app
		event_fn: event
		frame_fn: frame
		hide_cursor: false
	)
	app.tui.run()!
}
