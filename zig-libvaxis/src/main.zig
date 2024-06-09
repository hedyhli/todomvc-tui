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
        for (self.name[0..]) |char| {
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

    fn new() Todolist {
        return Todolist{ .l = ArrayList(Todo).init(std.heap.page_allocator) };
    }

    ///Add new todo by name and select it.
    fn add(self: *Todolist, name: []const u8) !void {
        try self.l.append(Todo{ .name = name, .complete = false });
        self.cur = self.l.items.len - 1;
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

    // Initalize a tty
    var tty = try vaxis.Tty.init();
    defer tty.deinit();

    // Use a buffered writer for better performance. There are a lot of writes
    // in the render loop and this can have a significant savings
    var buffered_writer = tty.bufferedWriter();
    const writer = buffered_writer.writer().any();

    // Initialize Vaxis
    var vx = try vaxis.init(alloc, .{
        .kitty_keyboard_flags = .{ .report_events = true },
    });
    defer vx.deinit(alloc, tty.anyWriter());

    var loop: vaxis.Loop(Event) = .{
        .vaxis = &vx,
        .tty = &tty,
    };
    try loop.init();

    // Start the read loop. This puts the terminal in raw mode and begins
    // reading user input
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
        // log.debug("event: {}", .{event});
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
                } else if (key.matches(vaxis.Key.enter, .{})) {
                    try model.list.add(try inputWig.toOwnedSlice());
                    inputWig.clearAndFree();
                } else {
                    try inputWig.update(.{ .key_press = key });
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
        inputWig.draw(inputWin);

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

        {
            var i: u8 = 0;
            for (model.list.l.items) |todo| {
                _ = try listWin.printSegment(Segment{ .text = try todo.fmt() }, .{ .row_offset = i * 2 });
                i += 1;
            }
        }

        const itemsleftWin = mainWin.child(.{
            .x_off = 0,
            .y_off = rows,
            .width = .expand,
            .height = .{ .limit = 1 },
            .border = .{ .where = .none },
        });

        _ = try itemsleftWin.printSegment(Segment{ .text = "X items left" }, .{ .row_offset = 0 });

        // Render the screen
        try vx.render(writer);
        try buffered_writer.flush();
    }
}
