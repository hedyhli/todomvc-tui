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

        var display = ArrayList(u8).init(std.heap.page_allocator);
        var n: usize = 0;
        for (self.l.items) |todo| {
            if (!todo.complete) n += 1;
        }
        return switch (n) {
            0 => "woohoo! nothing left to do",
            1 => "1 item left",
            else => {
                var buf: [256]u8 = undefined;
                const count = try std.fmt.bufPrint(&buf, "{}", .{n});
                try display.appendSlice(count);
                try display.appendSlice(" items left");
                return display.items;
            },
        };
    }

    ///Update scroll to ensure selected item is visible in viewport.
    pub fn ensure_visible(self: *Todolist) void {
        const cur = self.cur;
        const top = self.scroll_top;
        if (cur < top) {
            self.scroll_top = cur;
        } else if (cur - top >= self.max_items) {
            self.scroll_top = cur - self.max_items + 1;
        }
    }

    ///Ensure newCur, which may be negative or higher than list length, to
    ///either 0 or max index.
    pub fn clamp(self: *Todolist, newCur: i8) usize {
        const max: i8 = @as(i8, @intCast(self.l.items.len - 1));
        const clamped: i8 = if (newCur < 0) 0 else if (newCur > max) max else newCur;
        return @as(usize, @intCast(clamped));
    }

    ///Move current selection by offset and clamp to start or end of list.
    pub fn select_by(self: *Todolist, offset: i8) void {
        const newCur: i8 = @as(i8, @intCast(self.cur)) + offset;
        self.select(self.clamp(newCur));
    }

    ///Set selection index to newCur (must already be clamped!) and ensure
    ///selection is visible in viewport.
    pub fn select(self: *Todolist, newCur: usize) void {
        self.cur = newCur;
        self.ensure_visible();
    }

    fn update(self: *Todolist, ev: Event) void {
        switch (ev) {
            .key_press => |key| {
                if (key.codepoint == vaxis.Key.down or key.matches('j', .{})) {
                    self.select_by(1);
                } else if (key.codepoint == vaxis.Key.up or key.matches('k', .{})) {
                    self.select_by(-1);
                } else if (key.matches('d', .{ .ctrl = true })) {
                    self.select_by(@as(i8, @intCast(self.max_items / 2)));
                } else if (key.matches('u', .{ .ctrl = true })) {
                    self.select_by(-@as(i8, @intCast(self.max_items / 2)));
                } else if (key.codepoint == vaxis.Key.page_down) {
                    self.select_by(@as(i8, @intCast(self.max_items)));
                } else if (key.codepoint == vaxis.Key.page_up) {
                    self.select_by(-@as(i8, @intCast(self.max_items)));
                } else if (key.codepoint == vaxis.Key.space or key.codepoint == vaxis.Key.enter) {
                    self.l.items[self.cur].toggle();
                }
            },
            else => {
                unreachable;
            },
        }
    }

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
            const style: vaxis.Cell.Style = .{ .bg = .{ .index = 240 } };

            var right_padded = ArrayList(u8).init(std.heap.page_allocator);
            try right_padded.appendSlice(item);
            { // Pad spaces to the right of the item display string.
                var j: usize = item.len;
                while (j < win.width) : (j += 1) try right_padded.append(' ');
            }

            _ = try win.printSegment(Segment{ .text = full_spaces.items, .style = style }, .{ .row_offset = row });
            row += 1;
            _ = try win.printSegment(Segment{ .text = right_padded.items, .style = style }, .{ .row_offset = row });
            row += 1;
            _ = try win.printSegment(Segment{ .text = full_spaces.items, .style = style }, .{ .row_offset = row });
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
        const lastInView = todolist.max_items + todolist.scroll_top - 1;
        if (lastInView < last) {
            last = lastInView;
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

const uiSides = 25;
const uiHeaderHeight = 8;
///Includes border
const uiListHeight = 20;
const uiEditWidth = 45;
///Includes border
const uiEditHeight = 5;
///256-color
const uiFocusedColor = 9;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        //fail test; can't try in defer as defer is executed after we return
        if (deinit_status == .leak) {
            log.err("memory leak", .{});
        }
    }
    const alloc = gpa.allocator();

    var tty = try vaxis.Tty.init();
    defer tty.deinit();
    // Use a buffered writer for better performance. There are a lot of writes
    // in the render loop and this can have a significant savings
    var buffered_writer = tty.bufferedWriter();
    const writer = buffered_writer.writer().any();

    var vx = try vaxis.init(alloc, .{
        .kitty_keyboard_flags = .{ .report_events = true },
    });
    defer vx.deinit(alloc, tty.anyWriter());

    var loop: vaxis.Loop(Event) = .{
        .vaxis = &vx,
        .tty = &tty,
    };
    try loop.init();
    try loop.start();
    defer loop.stop();

    try vx.enterAltScreen(writer);

    var inputWig = VaxisInput.init(alloc, &vx.unicode);
    defer inputWig.deinit();

    try vx.setMouseMode(writer, false);

    try buffered_writer.flush();
    // Sends queries to terminal to detect certain features. This should
    // _always_ be called, but is left to the application to decide when
    try vx.queryTerminal(tty.anyWriter(), 1 * std.time.ns_per_s);

    // Model
    var model = Model{ .list = Todolist.new(), .focus = .input };

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
                                try model.list.add(try inputWig.toOwnedSlice());
                                inputWig.clearAndFree();
                            } else {
                                try inputWig.update(.{ .key_press = key });
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
        const win = vx.window();

        // VDOM DIFFING ✨
        win.clear();

        var rows: u32 = 0;

        const mainWin = win.child(.{
            .x_off = uiSides,
            .y_off = 0,
            .width = .{ .limit = win.width - uiSides - uiSides },
            .height = .expand,
        });

        mainWin.setCursorShape(.beam_blink);

        const header = mainWin.child(.{
            .x_off = 0,
            .y_off = 0,
            .width = .expand,
            .height = .{ .limit = uiHeaderHeight },
            .border = .{ .where = .none },
        });

        const headerText = Segment{ .text = "T O D O M V C" };
        const headerLine = vaxis.widgets.alignment.center(header, 13, uiHeaderHeight);
        _ = try headerLine.printSegment(headerText, .{ .row_offset = 4 });

        rows += uiHeaderHeight;

        // Input
        const inputWin = mainWin.child(.{
            .x_off = 0,
            .y_off = rows,
            .width = .expand,
            .height = .{ .limit = 3 },
            .border = .{ .where = .all, .style = .{ .fg = .{ .index = if (model.focus == .input) uiFocusedColor else 255 } } },
        });
        const inputInner = inputWin.child(.{
            .x_off = 1,
            .y_off = 0,
            .border = .{ .where = .none },
        });
        inputWig.draw(inputInner);

        if (model.focus != .input) {
            mainWin.hideCursor();
        }

        rows += 3;

        // List
        const listWin = mainWin.child(.{
            .x_off = 0,
            .y_off = rows,
            .width = .expand,
            .height = .{ .limit = uiListHeight },
            .border = .{ .where = .all, .style = .{ .fg = .{ .index = if (model.focus == .list) uiFocusedColor else 255 } } },
        });

        rows += uiListHeight;
        try model.list.draw(listWin);

        // Itemsleft
        const itemsleftWin = mainWin.child(.{
            .x_off = 0,
            .y_off = rows,
            .width = .expand,
            .height = .{ .limit = 1 },
            .border = .{ .where = .none },
        });

        {
            const itemsleftStr = try model.list.itemsleft();
            var padCount: usize = mainWin.width - itemsleftStr.len;
            var displayStr = ArrayList(u8).init(std.heap.page_allocator);
            while (padCount > 0) : (padCount -= 1) {
                try displayStr.append(' ');
            }
            try displayStr.appendSlice(itemsleftStr);
            _ = try itemsleftWin.printSegment(Segment{ .text = displayStr.items }, .{ .row_offset = 0 });
        }

        // Render the screen
        try vx.render(writer);
        try buffered_writer.flush();
    }
}
