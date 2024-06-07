const std = @import("std");
const vaxis = @import("vaxis");
const Cell = vaxis.Cell;
const TextInput = vaxis.widgets.TextInput;
const border = vaxis.widgets.border;

const log = std.log.scoped(.main);

// Message
const Event = union(enum) {
    key_press: vaxis.Key,
    mouse: vaxis.Mouse,
    winsize: vaxis.Winsize,
    focus_in,
    focus_out,
    foo: u8,
};

const uiSides = 25;
const uiHeaderHeight = 10;
///Includes border
const uiListHeight = 20;
const uiEditWidth = 45;
///Includes border
const uiEditHeight = 5;

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

    var inputWig = TextInput.init(alloc, &vx.unicode);
    defer inputWig.deinit();

    try vx.setMouseMode(writer, false);

    try buffered_writer.flush();
    // Sends queries to terminal to detect certain features. This should
    // _always_ be called, but is left to the application to decide when
    try vx.queryTerminal(tty.anyWriter(), 1 * std.time.ns_per_s);

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
                } else if (key.matches(vaxis.Key.enter, .{})) {
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

        const header = mainWin.child(.{
            .x_off = 0,
            .y_off = 0,
            .width = .expand,
            .height = .{ .limit = uiHeaderHeight },
            .border = .{ .where = .none },
        });

        const headerText = vaxis.Segment{ .text = "T O D O M V C" };
        const headerLine = vaxis.widgets.alignment.center(header, 13, uiHeaderHeight);
        _ = try headerLine.printSegment(headerText, .{ .row_offset = 6 });

        rows += uiHeaderHeight;

        // Input
        const inputWin = mainWin.child(.{
            .x_off = 0,
            .y_off = rows,
            .width = .expand,
            .height = .{ .limit = 3 },
            .border = .{ .where = .all },
        });
        inputWig.draw(inputWin);

        rows += 3;

        // List
        const listWin = mainWin.child(.{
            .x_off = 0,
            .y_off = rows,
            .width = .expand,
            .height = .{ .limit = uiListHeight },
            .border = .{ .where = .all },
        });

        rows += uiListHeight;

        _ = try listWin.printSegment(vaxis.Segment{ .text = "hi" }, .{ .row_offset = 0 });

        const itemsleftWin = mainWin.child(.{
            .x_off = 0,
            .y_off = rows,
            .width = .expand,
            .height = .{ .limit = 1 },
            .border = .{ .where = .none },
        });

        _ = try itemsleftWin.printSegment(vaxis.Segment{ .text = "X items left" }, .{ .row_offset = 0 });

        // Render the screen
        try vx.render(writer);
        try buffered_writer.flush();
    }
}
