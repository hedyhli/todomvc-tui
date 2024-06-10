const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Executable
    const exe = b.addExecutable(.{
        .name = "todomvc-tui",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const depVaxis = b.dependency("vaxis", .{
        .target = target,
        .optimize = optimize,
        .libxev = false,
        .images = false,
        .nvim = false,
    });
    exe.root_module.addImport("vaxis", depVaxis.module("vaxis"));
    b.installArtifact(exe);

    // Run
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    // TodoMVC TUI does not (yet) use command-line arguments though.
    if (b.args) |args| run_cmd.addArgs(args);
    const run_step = b.step("run", "Run executable");
    run_step.dependOn(&run_cmd.step);

    // Tests
    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/test.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
