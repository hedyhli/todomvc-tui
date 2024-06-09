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
const Todo = struct {
    name: []const u8,
    complete: bool,

    ///Toggle the Todo item completion state.
    fn toggle(self: *Todo) void {
        self.complete = !self.complete;
    }

    ///Format for display as a list widget item.
    fn fmt(self: Todo) ![]const u8 {
        var display = ArrayList(u8).init(std.heap.page_allocator);
        if (self.complete) {
            try display.appendSlice("(X) ");
        } else {
            try display.appendSlice("( ) ");
        }
        for (self.name) |char| {
            try display.append(char);
        }
        return display.items;
    }
};

///A list of Todos with current selection and scrolling
const Todolist = struct {
    l: ArrayList(Todo),
    cur: usize = 0,
    ///Scroll offset
    top_idx: usize = 0,

    ///Initialize an empty list with std.heap.page_allocator for ArrayList(Todo).
    fn new() Todolist {
        return Todolist{ .l = ArrayList(Todo).init(std.heap.page_allocator) };
    }

    ///Add new todo by name and select it.
    fn add(self: *Todolist, name: []const u8) !void {
        if (name.len == 0) return;
        try self.l.append(Todo{ .name = name, .complete = false });
        self.cur = self.l.items.len - 1;
    }

    ///The text to display for the itemsleft widget.
    fn itemsleft(self: *Todolist) ![]const u8 {
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

    fn select(self: *Todolist, offset: i8) void {
        const newCur: i8 = @as(i8, @intCast(self.cur)) + offset;
        const max: i8 = @as(i8, @intCast(self.l.items.len - 1));
        self.cur = @as(usize, @intCast(if (newCur < 0) 0 else if (newCur > max) max else newCur));
    }

    fn update(self: *Todolist, ev: Event) void {
        switch (ev) {
            .key_press => |key| {
                if (key.codepoint == vaxis.Key.down or key.matches('j', .{})) {
                    self.select(1);
                } else if (key.codepoint == vaxis.Key.up or key.matches('k', .{})) {
                    self.select(-1);
                } else if (key.codepoint == vaxis.Key.space or key.codepoint == vaxis.Key.enter) {
                    self.l.items[self.cur].toggle();
                }
            },
            else => {
                unreachable;
            },
        }
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

        { // List items
            var i: u8 = 0;
            for (model.list.l.items) |todo| {
                var style: vaxis.Cell.Style = .{};
                if (model.list.cur == i) {
                    style.bg = .{ .index = 240 };
                }
                _ = try listWin.printSegment(Segment{ .text = try todo.fmt(), .style = style }, .{ .row_offset = i * 2 });
                i += 1;
            }
        }

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
            for (itemsleftStr) |char| {
                try displayStr.append(char);
            }
            _ = try itemsleftWin.printSegment(Segment{ .text = displayStr.items }, .{ .row_offset = 0 });
        }

        // Render the screen
        try vx.render(writer);
        try buffered_writer.flush();
    }
}
