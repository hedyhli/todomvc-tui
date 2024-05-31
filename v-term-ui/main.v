import term.ui as tui

struct App {
mut:
	tui      &tui.Context = unsafe { nil }
	inputter &Inputter    = &Inputter{}
	focus    Focus        = .input
	list     []Todo
	sel      int
	initial  bool = true
	// Index of first list item to show
	list_offset int
	editing bool
	// Inputter instance for editing todo names
	editor  &Inputter = &Inputter{}
}

struct Inputter {
mut:
	input  string
	cursor int
	len    int
}

enum InputAction {
	enter
	escape
	@none
}

fn (mut inp Inputter) clamp_cursor(offset int) {
	mut new := inp.cursor + offset
	if new < 0 {
		new = 0
	}
	if new > inp.input.len {
		new = inp.input.len
	}
	inp.cursor = new
}

fn (mut inp Inputter) left() {
	inp.clamp_cursor(-1)
}

fn (mut inp Inputter) right() {
	inp.clamp_cursor(1)
}

// Clear
fn (mut inp Inputter) reset() {
	inp.input = ''
	inp.len = 0
	inp.cursor = 0
}

// Insert
fn (mut inp Inputter) insert(ch string) {
	inp.input = inp.input[..inp.cursor] + ch + inp.input[inp.cursor..]
	inp.len += 1
	inp.cursor += 1
}

fn (mut inp Inputter) handle_key(e &tui.Event) InputAction {
	if e.modifiers == .ctrl {
		match e.code {
			.e {
				inp.cursor = inp.len
			}
			.a {
				inp.cursor = 0
			}
			else {
				return .@none
			}
		}
	}

	if e.modifiers == .alt || e.modifiers == .ctrl {
		return .@none
	}

	if e.code == .home {
		inp.cursor = 0
		return .@none
	}
	if e.code == .end {
		inp.cursor = inp.len
	}
	if e.code == .right {
		inp.right()
		return .@none
	}
	if e.code == .left {
		inp.left()
		return .@none
	}
	if e.code == .enter {
		return .enter
	}
	if e.code == .backspace {
		// delete left
		if inp.cursor == 0 {
			return .@none
		}
		inp.input = inp.input[..inp.cursor - 1] + inp.input[inp.cursor..]
		inp.len -= 1
		inp.cursor -= 1
		return .@none
	}
	if e.code == .delete {
		// delete right
		if inp.cursor == inp.input.len {
			return .@none
		}
		inp.input = inp.input[..inp.cursor] + inp.input[inp.cursor+1..]
		inp.len -= 1
		return .@none
	}
	if e.code == .escape {
		return .escape
	}
	// insert
	keycode := u8(e.code)
	if (keycode >= 32 && keycode <= 64) || (keycode >= 91 && keycode <= 126) {
		if e.modifiers == .shift && (keycode >= 97 && keycode <= 122) {
			inp.insert((keycode - 32).ascii_str())
		} else {
			inp.insert(keycode.ascii_str())
		}
	}
	return .@none
}

struct Todo {
mut:
	name     string
	complete bool
}

enum Focus {
	input
	list
}

fn Todo.new(name string) Todo {
	return Todo{
		name: name
		complete: false
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
			return 'woohoo! nothing else to do'
		}
		1 {
			return '1 item left'
		}
		else {
			return '${n} items left'
		}
	}
}

fn (t Todo) format() string {
	if t.complete {
		return '(X) ${t.name}'
	}
	return '( ) ${t.name}'
}

fn (mut app App) update_scroll() {
	// 8: max items in a list
	if app.sel - app.list_offset >= 8 {
		app.list_offset = app.sel - 8 + 1
	} else if app.sel - app.list_offset < 0 {
		app.list_offset = app.sel
	}
}

fn event(e &tui.Event, x voidptr) {
	mut app := unsafe { &App(x) }

	if e.typ == .key_down && e.code == .c && e.modifiers == .ctrl {
		exit(0)
	}
	if e.typ != .key_down {
		return
	}

	if app.editing {
		match app.editor.handle_key(e) {
			.enter {
				app.list[app.sel].name = app.editor.input
				app.editing = false
			}
			.escape {
				app.editing = false
			}
			else {}
		}
		return
	}

	if e.code == .tab {
		app.focus = if app.focus == .input { .list } else { .input }
		return
	}

	if app.focus == .list {
		if e.modifiers != unsafe { nil } {
			return
		}
		if e.code == .down || e.code == .j {
			app.sel += if app.sel != app.list.len - 1 { 1 } else { 0 }
			app.update_scroll()
			return
		}
		if e.code == .up || e.code == .k {
			app.sel -= if app.sel != 0 { 1 } else { 0 }
			app.update_scroll()
			return
		}
		if e.code == .space || e.code == .enter {
			app.list[app.sel].complete = !app.list[app.sel].complete
			return
		}
		if e.code == .e {
			app.editing = true
			app.editor.input = app.list[app.sel].name
			app.editor.cursor = app.editor.input.len
			return
		}
		return
	}

	// Input
	match app.inputter.handle_key(e) {
		.enter {
			app.list << Todo.new(app.inputter.input)
			app.initial = false
			app.inputter.reset()
		}
		else {}
	}
}

// Rectangle with borders of fixed height, top margin, and side margin
fn (mut app App) bordered(sides int, top int, height int) {
	full_w := app.tui.window_width

	bot := top + height - 1

	// top
	app.tui.draw_text(sides, top, '┌')
	for i in sides + 1 .. (full_w - sides) {
		app.tui.draw_text(i, top, '─')
	}
	app.tui.draw_text(full_w - sides, top, '┐')

	// sides
	for j in top + 1 .. bot {
		app.tui.draw_text(sides, j, '│')
		app.tui.draw_text(full_w - sides, j, '│')
	}

	// bottom
	app.tui.draw_text(sides, bot, '└')
	for i in sides + 1 .. (full_w - sides) {
		app.tui.draw_text(i, bot, '─')
	}
	app.tui.draw_text(full_w - sides, bot, '┘')
}

// Bordered rectangle positioned in x and y center.
fn (mut app App) make_modal(width int, height int) {
	full_w := app.tui.window_width
	full_h := app.tui.window_height

	// Box
	x := full_w / 2 - width / 2
	y := full_h / 2 - height / 2
	app.bordered(x, y, height)

	// fill background
	for i in x + 1 .. x + width + 1 {
		for j in y + 1 .. y + height - 1 {
			app.tui.draw_text(i, j, ' ')
		}
	}

	// Label
	app.tui.draw_text(x + 2, y + 1, "New name:")

	// Input
	app.bordered(x + 2, y + 2, 3)
	app.tui.draw_text(x + 4, y + 3, app.editor.input)

	// Hint
	app.right_text(x + width, y + height - 2, "enter/esc")

	app.tui.show_cursor()
	app.tui.set_cursor_position(x + 4 + app.editor.cursor, y + 3)
}

// Draw horizontally center-aligned text at y
fn (mut app App) centered_text(y int, text string) {
	full := app.tui.window_width
	app.tui.draw_text(full / 2 - text.len / 2, y, text)
}

// Draw right-aligned text at x position right (can be negative) and at y
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

	if app.editing {
		app.tui.set_color(r: 100, g: 100, b: 100)
	}

	app.centered_text(7, 'T O D O M V C')

	// Input
	if app.focus == .input && !app.editing {
		app.tui.set_color(r: 200, g: 0, b: 50)
	}
	app.bordered(sides, 10, 3)
	if !app.editing {
		app.tui.reset()
	}
	if app.inputter.len == 0 {
		app.tui.set_color(r: 90, g: 90, b: 100)
		app.tui.draw_text(sides + 2, 11, "What needs to be done?")
		app.tui.reset()
	} else {
		app.tui.draw_text(sides + 2, 11, app.inputter.input)
	}

	// List
	if app.focus == .list && !app.editing {
		app.tui.set_color(r: 200, g: 0, b: 50)
	}
	app.bordered(sides, 13, 19)
	if !app.editing {
		app.tui.reset()
	}

	for i, todo in app.list {
		if i < app.list_offset {
			continue
		}
		if i == app.sel && !app.editing {
			app.tui.set_bg_color(r: 100, g: 100, b: 100)
		}
		app.tui.draw_text(sides + 3, 15 + (i - app.list_offset) * 2, todo.format())
		if !app.editing {
			app.tui.reset()
		}
		if i - app.list_offset == 7 {
			break
		}
	}

	// Itemsleft
	if !app.initial {
		app.right_text(-sides, 13 + 19, itemsleft(app.list))
	}

	if !app.editing {
		app.tui.set_cursor_position(sides + 2 + app.inputter.cursor, 11)
		if app.focus == .input {
			app.tui.show_cursor()
		} else {
			app.tui.hide_cursor()
		}
	} else {
		app.tui.reset()
		app.tui.set_bg_color(r: 0, b: 0, g: 0)
		app.make_modal(60, 7)
	}

	app.tui.reset()
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
