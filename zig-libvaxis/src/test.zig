// TDD? Well, I'd rather not have it panic in the middle of the TUI and have
// the terminal not reset into the original state, unable to type anything and
// have to quit and reopen the terminal every time. So, yes.

const std = @import("std");
const e = std.testing.expect;
const eql = std.testing.expectEqual;
const eqlStrings = std.testing.expectEqualStrings;
const main = @import("main.zig");

test "todoitem" {
    var todo = main.Todo.new("todo");
    try eqlStrings(todo.name, "todo");
    try eql(todo.complete, false);
    try eqlStrings(try todo.fmt(), "  ( ) todo");
    todo.toggle();
    try eqlStrings(todo.name, "todo");
    try eql(todo.complete, true); // after toggle
    try eqlStrings(try todo.fmt(), "  (X) todo"); // after toggle
}

test "todolist.add" {
    var list = main.Todolist.new();
    try list.add("1");
    try list.add("2");
    try list.add("3");
    try e(list.l.items.len == 3);
}

test "todolist.select" {
    var list = main.Todolist.new();
    try list.add("1");
    try list.add("2");
    try list.add("3");

    try e(list.cur == 2);
    list.select_by(1);
    try e(list.cur == 2);
    list.select_by(6);
    try e(list.cur == 2);
    list.select_by(-6);
    try e(list.cur == 0);

    try list.add("4");
    try list.add("5");
    try list.add("6");
    try e(list.cur == 5);

    try list.add("7");
    try e(list.cur == 6);
    try e(list.scroll_top == 1);
    list.select_by(-6);
    try e(list.cur == 0);
    try e(list.scroll_top == 0);
}

test "todolist.iterViewport" {
    var list = main.Todolist.new();
    try list.add("1");
    try list.add("2");
    try list.add("3");
    try list.add("4");
    try list.add("5");
    try list.add("6");
    try list.add("7");
    try list.add("8");

    try e(list.scroll_top == 2);

    { // Iter, with starting two items skipped
        var iter = list.iterViewport();
        var i: u8 = 3;
        var count: u8 = 0;
        while (iter.next()) |todo| {
            try eql(i + '0', todo.name[0]);
            count += 1;
            i += 1;
        }
        try eql(list.max_items, count);
    }

    list.select(0);
    try eql(list.scroll_top, 0); // select at 0

    { // Iter, with last two items skipped
        var iter = list.iterViewport();
        var i: u8 = 1;
        var count: u8 = 0;
        while (iter.next()) |todo| {
            try eql(i + '0', todo.name[0]);
            count += 1;
            i += 1;
        }
        try eql(list.max_items, count);
    }
}
