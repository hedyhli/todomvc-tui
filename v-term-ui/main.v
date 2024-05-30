import term.ui as tui

struct App {
mut:
	tui &tui.Context = unsafe { nil }
	inputter &Inputter = &Inputter{}
	focus Focus = .input
	message string
	list []Todo
}

struct Inputter {
mut:
	input string
	cursor int
	len int
}

struct Todo {
mut:
	name string
	complete bool
}

enum Focus {
	input
	list
}

fn new_todo(name string) Todo {
	return Todo {
		name: name,
		complete: false,
	}
}

fn itemsleft(todos []Todo) string {
	mut n := 0
	for t in todos {
		if !t.complete {
			n += 1
		}
	}

	match n {
	0 {
		return "woohoo! nothing else to do"
	}
	1 {
		return "1 item left"
	}
	else {
		return "${n} items left"
	}
	}
}

fn (t Todo) format() string {
	if t.complete {
		return "(X) ${t.name}"
	}
	return "( ) ${t.name}"
}

// Clear
fn (mut inp Inputter) reset() {
	inp.input = ""
	inp.len = 0
	inp.cursor = 0
}

fn event(e &tui.Event, x voidptr) {
	mut app := unsafe { &App(x) }

	if e.typ == .key_down && e.code == .c && e.modifiers == .ctrl {
		exit(0)
	}
	if e.typ != .key_down {
		return
	}

	if e.code == .tab {
		app.focus = if app.focus == .input { .list } else { .input }
		return
	}

	if app.focus == .list {
		return
	}

	// Input
	if e.modifiers == .ctrl {
		match e.code {
		.e {
			app.inputter.cursor = app.inputter.len
		}
		.a {
			app.inputter.cursor = 0
		}
		else {
			return
		}
		}
	}
	if e.modifiers != unsafe{nil} {
		return
	}

	if e.code == .right {
		cursor := app.inputter.cursor + 1
		if cursor <= app.inputter.len + 1 {
			app.inputter.cursor = cursor
		}
		return
	}
	if e.code == .left {
		if app.inputter.cursor != 0 {
			app.inputter.cursor = app.inputter.cursor - 1
		}
		return
	}
	if e.code == .enter {
		app.list << new_todo(app.inputter.input)
		app.inputter.reset()
		return
	}
	if e.code == .backspace {
		if app.inputter.cursor == 0 {
			return
		}
		inp := app.inputter.input
		c := app.inputter.cursor
		app.inputter.input = inp[..c-1] + inp[c..]
		app.inputter.len -= 1
		app.inputter.cursor -= 1
		return
	}
	inp := app.inputter.input
	c := app.inputter.cursor
	app.inputter.input = inp[..c] + u8(e.code).ascii_str() + inp[c..]
	app.inputter.len += 1
	app.inputter.cursor += 1
}

// Rectangle with borders
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
	app.tui.draw_text(full / 2 - text.len / 2, y, text)
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

	// Input
	if app.focus == .input {
		app.tui.set_color(r: 200, g: 0, b: 50)
	}
	app.bordered(sides, 10, 3)
	app.tui.reset()
	app.tui.draw_text(sides+2, 11, app.inputter.input)

	// List
	if app.focus == .list {
		app.tui.set_color(r: 200, g: 0, b: 50)
	}
	app.bordered(sides, 13, 18)
	app.tui.reset()

	for i, todo in app.list {
		app.tui.draw_text(sides + 3, 15 + i * 2, todo.format())
	}

	app.right_text(-sides, 13 + 18, itemsleft(app.list))

	app.tui.draw_text(0, 0, app.message)

	app.tui.set_cursor_position(sides + 2 + app.inputter.cursor, 11)

	if app.focus == .input {
		app.tui.show_cursor()
	} else {
		app.tui.hide_cursor()
	}
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
