const std = @import("std");

pub fn logFn(
    comptime level: std.log.Level,
    comptime scope: @Type(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    _ = scope;

    const level_prefix = comptime blk: {
        var buf: [8]u8 = undefined;
        const capitalized = std.ascii.upperString(&buf, level.asText());
        break :blk "[" ++ capitalized ++ "] ";
    };

    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();
    const stderr = std.io.getStdErr().writer();
    nosuspend stderr.print(level_prefix ++ format ++ "\n", args) catch return;
}
