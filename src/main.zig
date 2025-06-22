const std = @import("std");
const maple_logger = @import("maple_logger.zig");

pub const std_options = std.Options{
    .log_level = .info,
    .logFn = maple_logger.logFn,
};

const whitespace = "\n\t\r ";
const float = f128;

pub fn cosineSimilarity(first: []float, second: []float) float {
    const numerator = calc: {
        var accumulator: float = 0.0;
        for (0..first.len) |i| accumulator += first[i] * second[i];
        break :calc accumulator;
    };

    const denominator = calc: {
        const left_rms = std.math.sqrt(calc2: {
            var accumulator: float = 0.0;
            for (0..first.len) |i| accumulator += first[i] * first[i];
            break :calc2 accumulator;
        });
        const right_rms = std.math.sqrt(calc2: {
            var accumulator: float = 0.0;
            for (0..second.len) |i| accumulator += second[i] * second[i];
            break :calc2 accumulator;
        });
        break :calc left_rms * right_rms;
    };

    return numerator / denominator;
}

pub fn main() !void {
    const stdin_file = std.io.getStdIn();
    var stdin_buffered = std.io.bufferedReader(stdin_file.reader());
    const stdin = stdin_buffered.reader();

    var input_buffer: [4096]u8 = undefined;
    var line = (try stdin.readUntilDelimiterOrEof(&input_buffer, '\n')).?;

    var it = std.mem.splitScalar(u8, line, ' ');

    const n_str = it.next() orelse return std.log.err("Invalid input: no value for \"n\" provided", .{});
    const m_str = it.next() orelse return std.log.err("Invalid input: no value for \"m\" provided", .{});

    // Number of students.
    const n = std.fmt.parseInt(
        usize,
        std.mem.trim(u8, n_str, whitespace),
        10,
    ) catch return std.log.err("Failed to parse \"{s}\".", .{n_str});

    // Number of interests.
    const m = std.fmt.parseInt(
        usize,
        std.mem.trim(u8, m_str, whitespace),
        10,
    ) catch return std.log.err("Failed to parse \"{s}\"", .{m_str});

    std.log.info(
        "There are {} students with {} interests.",
        .{ n, m },
    );

    // Early exit conditions.
    if (n < 1 or n > 5) return std.log.err(
        "Number of students, excluding Hermione, must be between 1 and 5 (inclusive).",
        .{},
    );
    if (m < 1 or m > 50) return std.log.err(
        "Number of interests must be between 1 and 50 (inclusive).",
        .{},
    );

    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create the student-interests table,
    // including another row for Hermione herself.
    const student_interests = try allocator.alloc([]float, n + 1);
    defer allocator.free(student_interests);
    for (0..student_interests.len) |i| student_interests[i] = try allocator.alloc(float, m);
    defer for (0..student_interests.len) |i| allocator.free(student_interests[i]);

    // Populate the table.
    for (0..n + 1) |student| {
        line = (try stdin.readUntilDelimiterOrEof(&input_buffer, '\n')).?;
        var interest_str_iter = std.mem.splitScalar(
            u8,
            line,
            ' ',
        );

        for (0..m) |interest| {
            if (interest_str_iter.next()) |interest_str| {
                const trimmed = std.mem.trim(
                    u8,
                    interest_str,
                    whitespace,
                );
                student_interests[student][interest] = std.fmt.parseFloat(
                    float,
                    trimmed,
                ) catch return std.log.err(
                    "Failed to parse \"{s}\" into float",
                    .{interest_str},
                );
            } else return std.log.err(
                "Invalid input: expected values for {} interests but only got {}.",
                .{ m, interest },
            );
        }
    }

    std.log.debug("student_interests: {any}.", .{student_interests});

    const stdout = std.io.getStdOut().writer();

    // Calculate cosine similarity.
    for (1..student_interests.len) |student| {
        const similarity = cosineSimilarity(
            student_interests[0],
            student_interests[student],
        );

        try stdout.print("{d:.2}\n", .{similarity});
    }
}

test "truncate floats" {
    const num = @as(
        comptime_float,
        @floatFromInt(
            @as(
                comptime_int,
                @intFromFloat(0.655 * 100.0),
            ),
        ),
    ) / 100.0;

    try std.testing.expectEqual(0.65, num);
}
