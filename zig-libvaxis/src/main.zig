//! Zig implementation of TodoMVC TUI using libvaxis.

const std = @import("std");
const ArrayList = std.ArrayList;
const vaxis = @import("vaxis");
const Cell = vaxis.Cell;
const Segment = vaxis.Segment;
const VaxisInput = vaxis.widgets.TextInput;
const VaxisBorder = vaxis.widgets.border;

const log = std.log.scoped(.main);

// Data ////////////////////////////////////////////////////////////////////
///A single Todo item
pub const Todo = struct {
    name: []const u8,
    complete: bool,

    ///Initialize a new todo by name as an incomplete item
    pub fn new(name: []const u8) Todo {
        return Todo{ .name = name, .complete = false };
    }

    ///Toggle the Todo item completion state.
    pub fn toggle(self: *Todo) void {
        self.complete = !self.complete;
    }

    ///Format for display as a list widget item.
    pub fn fmt(self: Todo) ![]const u8 {
        var display = ArrayList(u8).init(std.heap.page_allocator);
        try display.appendSlice(if (self.complete) "  (X) " else "  ( ) ");
        try display.appendSlice(self.name);
        return display.items;
    }
};

///A list of Todos with current selection and scrolling
pub const Todolist = struct {
    l: ArrayList(Todo),
    ///Index of current selection
    cur: usize = 0,
    ///Scroll offset
    scroll_top: usize = 0,
    ///Number of items at a time in viewport
    max_items: usize = 6,

    ///Initialize an empty list with std.heap.page_allocator for ArrayList(Todo).
    pub fn new() Todolist {
        return Todolist{ .l = ArrayList(Todo).init(std.heap.page_allocator) };
    }

    ///Add new todo by name and select it.
    pub fn add(self: *Todolist, name: []const u8) !void {
        if (name.len == 0) return;
        try self.l.append(Todo.new(name));
        self.select(self.l.items.len - 1);
    }

    ///The text to display for the itemsleft widget.
    pub fn itemsleft(self: *Todolist) ![]const u8 {
        if (self.l.items.len == 0) return "";

        var n: usize = 0;
        for (self.l.items) |todo| {
            if (!todo.complete) n += 1;
        }

        return switch (n) {
            0 => "woohoo! nothing left to do",
            1 => "1 item left",
            else => {
                var buf: [256]u8 = undefined;
                return try std.fmt.bufPrint(&buf, "{} items left", .{n});
            },
        };
    }

    ///Update scroll to ensure selected item is visible in viewport.
    pub fn ensureVisible(self: *Todolist) void {
        const cur = self.cur;
        const top = self.scroll_top;
        if (cur < top) {
            self.scroll_top = cur;
        } else if (cur - top >= self.max_items) {
            self.scroll_top = cur - self.max_items + 1;
        }
    }

    ///Ensure newCur, which may be negative or higher than list length, is
    ///within range, clamping to either 0 or max index.
    pub fn clamp(self: *Todolist, new_cur: i8) usize {
        const max: i8 = @as(i8, @intCast(self.l.items.len - 1));
        const clamped: i8 = if (new_cur < 0) 0 else if (new_cur > max) max else new_cur;
        return @as(usize, @intCast(clamped));
    }

    ///Move current selection by offset and clamp to start or end of list.
    pub fn selectBy(self: *Todolist, offset: i8) void {
        const new_cur: i8 = @as(i8, @intCast(self.cur)) + offset;
        self.select(self.clamp(new_cur));
    }

    ///Set selection index to newCur (must already be clamped!) and ensure
    ///selection is visible in viewport.
    pub fn select(self: *Todolist, new_cur: usize) void {
        self.cur = new_cur;
        self.ensureVisible();
    }

    fn update(self: *Todolist, ev: Event) void {
        switch (ev) {
            .key_press => |key| {
                if (key.codepoint == vaxis.Key.down or key.matches('j', .{})) {
                    self.selectBy(1);
                } else if (key.codepoint == vaxis.Key.up or key.matches('k', .{})) {
                    self.selectBy(-1);
                } else if (key.matches('d', .{ .ctrl = true })) {
                    self.selectBy(@as(i8, @intCast(self.max_items / 2)));
                } else if (key.matches('u', .{ .ctrl = true })) {
                    self.selectBy(-@as(i8, @intCast(self.max_items / 2)));
                } else if (key.codepoint == vaxis.Key.page_down) {
                    self.selectBy(@as(i8, @intCast(self.max_items)));
                } else if (key.codepoint == vaxis.Key.page_up) {
                    self.selectBy(-@as(i8, @intCast(self.max_items)));
                } else if (key.codepoint == vaxis.Key.space or key.codepoint == vaxis.Key.enter) {
                    self.l.items[self.cur].toggle();
                }
            },
            else => {
                unreachable;
            },
        }
    }

    ///Create a new iterator for items currently visible in viewport.
    pub fn iterViewport(self: *Todolist) TodolistIterator {
        return TodolistIterator.new(self);
    }

    ///Draw Todolist items into the given window.
    fn draw(self: *Todolist, win: vaxis.Window) !void {
        if (self.l.items.len == 0) return;

        var full_spaces = ArrayList(u8).init(std.heap.page_allocator);
        { // Repeat spaces for the width of the printable window space.
            var j: u8 = 0;
            while (j < win.width) : (j += 1) try full_spaces.append(' ');
        }

        var row: u8 = 0;
        var i: u8 = @as(u8, @intCast(self.scroll_top));
        var iter = self.iterViewport();

        while (iter.next()) |todo| {
            if (self.cur != i) {
                _ = try win.printSegment(Segment{ .text = try todo.fmt() }, .{ .row_offset = row + 1 });
                row += 3;
                i += 1;
                continue;
            }

            const item = try todo.fmt();

            var right_padded = ArrayList(u8).init(std.heap.page_allocator);
            try right_padded.appendSlice(item);
            { // Pad spaces to the right of the item display string.
                var j: usize = item.len;
                while (j < win.width) : (j += 1) try right_padded.append(' ');
            }

            _ = try win.printSegment(Segment{ .text = full_spaces.items, .style = UI.selected_style }, .{ .row_offset = row });
            row += 1;
            _ = try win.printSegment(Segment{ .text = right_padded.items, .style = UI.selected_style }, .{ .row_offset = row });
            row += 1;
            _ = try win.printSegment(Segment{ .text = full_spaces.items, .style = UI.selected_style }, .{ .row_offset = row });
            row += 1;

            i += 1;
        }
    }
};

const TodolistIterator = struct {
    l: ArrayList(Todo),
    ///Index of l.
    i: usize,
    max_i: usize,

    fn new(todolist: *Todolist) TodolistIterator {
        var last = todolist.l.items.len - 1;
        const last_in_view = todolist.max_items + todolist.scroll_top - 1;
        if (last_in_view < last) {
            last = last_in_view;
        }
        return .{
            .l = todolist.l,
            .i = todolist.scroll_top,
            .max_i = last,
        };
    }

    pub fn next(self: *TodolistIterator) ?Todo {
        if (self.i <= self.max_i) {
            self.i += 1;
            return self.l.items[self.i - 1];
        }
        return null;
    }
};

const Model = struct {
    list: Todolist,
    focus: enum { input, list, editing },
};

// UI //////////////////////////////////////////////////////////////////////
// Message
const Event = union(enum) {
    key_press: vaxis.Key,
    mouse: vaxis.Mouse,
    winsize: vaxis.Winsize,
    focus_in,
    focus_out,
};

///Parameters
const UI = struct {
    const sides = 25;
    ///Number of rows above the header
    const header_margin = 6;
    const header_height = 9;
    ///Includes border
    const list_height = 20;
    const edit_width = 45;
    ///Includes border
    const edit_height = 5;
    ///256-color
    const focused_color = 9;
    const placeholder_style: vaxis.Cell.Style = .{ .fg = .{ .index = 245 } };
    const selected_style: vaxis.Cell.Style = .{ .bg = .{ .rgb = .{ 70, 70, 75 } } };
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) {
            log.err("memory leak", .{});
        }
    }
    const alloc = gpa.allocator();

    // TTY
    var tty = try vaxis.Tty.init();
    defer tty.deinit();
    var buffered_writer = tty.bufferedWriter();
    const writer = buffered_writer.writer().any();

    // Vaxis
    var vx = try vaxis.init(alloc, .{
        .kitty_keyboard_flags = .{ .report_events = true },
    });
    defer vx.deinit(alloc, tty.anyWriter());

    // Loop
    var loop: vaxis.Loop(Event) = .{ .vaxis = &vx, .tty = &tty };
    try loop.init();
    try loop.start();
    defer loop.stop();

    // Initialize TUI
    try vx.enterAltScreen(writer);
    try vx.setMouseMode(writer, false);
    try buffered_writer.flush();
    try vx.queryTerminal(tty.anyWriter(), 1 * std.time.ns_per_s);

    // Initialize widgets and model
    var model = Model{ .list = Todolist.new(), .focus = .input };
    var input_widget = VaxisInput.init(alloc, &vx.unicode);
    defer input_widget.deinit();

    // Update
    while (true) {
        // nextEvent blocks until an event is in the queue
        const event = loop.nextEvent();
        switch (event) {
            .key_press => |key| {
                if (key.matches('c', .{ .ctrl = true })) {
                    break;
                } else if (key.matches('l', .{ .ctrl = true })) {
                    vx.queueRefresh();
                } else if (key.codepoint == vaxis.Key.tab) {
                    model.focus = switch (model.focus) {
                        .input => .list,
                        .list => .input,
                        else => model.focus,
                    };
                } else {
                    switch (model.focus) {
                        .input => {
                            if (key.matches(vaxis.Key.enter, .{})) {
                                try model.list.add(try input_widget.toOwnedSlice());
                                input_widget.clearAndFree();
                            } else {
                                try input_widget.update(.{ .key_press = key });
                            }
                        },
                        .list => {
                            model.list.update(event);
                        },
                        .editing => {},
                    }
                }
            },
            .winsize => |ws| try vx.resize(alloc, tty.anyWriter(), ws),
            else => {},
        }

        // View
        var rows: u32 = 0;

        // VDOM-LIKE DIFFING ✨
        const win = vx.window();
        win.clear();

        const main_win = win.child(.{
            .x_off = UI.sides,
            .y_off = 0,
            .width = .{ .limit = win.width - UI.sides - UI.sides },
            .height = .expand,
        });

        main_win.setCursorShape(.beam_blink);

        const header = main_win.child(.{
            .x_off = 0,
            .y_off = 0,
            .width = .expand,
            .height = .{ .limit = UI.header_height },
            .border = .{ .where = .none },
        });

        const header_text = Segment{ .text = "T O D O M V C" };
        const header_line = vaxis.widgets.alignment.center(header, 13, UI.header_height);
        _ = try header_line.printSegment(header_text, .{ .row_offset = UI.header_margin });

        rows += UI.header_height;

        // Input
        const input_win = main_win.child(.{
            .x_off = 0,
            .y_off = rows,
            .width = .expand,
            .height = .{ .limit = 3 },
            .border = .{ .where = .all, .style = .{ .fg = .{ .index = if (model.focus == .input) UI.focused_color else 255 } } },
        });
        const input_inner = input_win.child(.{
            .x_off = 1,
            .y_off = 0,
            .border = .{ .where = .none },
        });
        if (input_widget.buf.items.len > 0) {
            input_widget.draw(input_inner);
        } else {
            input_inner.showCursor(0, 0);
            _ = try input_inner.printSegment(Segment{ .text = "What needs to be done?", .style = UI.placeholder_style }, .{ .row_offset = 0 });
        }

        if (model.focus != .input) {
            main_win.hideCursor();
        }

        rows += 3;

        // List
        const list_win = main_win.child(.{
            .x_off = 0,
            .y_off = rows,
            .width = .expand,
            .height = .{ .limit = UI.list_height },
            .border = .{ .where = .all, .style = .{ .fg = .{ .index = if (model.focus == .list) UI.focused_color else 255 } } },
        });

        rows += UI.list_height;
        try model.list.draw(list_win);

        // Itemsleft
        const itemsleft_win = main_win.child(.{
            .x_off = 0,
            .y_off = rows,
            .width = .expand,
            .height = .{ .limit = 1 },
            .border = .{ .where = .none },
        });

        {
            const itemsleft_str = try model.list.itemsleft();
            var pad_count: usize = main_win.width - itemsleft_str.len;
            var display = ArrayList(u8).init(std.heap.page_allocator);
            while (pad_count > 0) : (pad_count -= 1) {
                try display.append(' ');
            }
            try display.appendSlice(itemsleft_str);
            _ = try itemsleft_win.printSegment(Segment{ .text = display.items }, .{ .row_offset = 0 });
        }

        // Render the screen
        try vx.render(writer);
        try buffered_writer.flush();
    }
}
