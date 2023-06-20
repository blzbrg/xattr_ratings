const std = @import("std");

const xattr = @cImport({
    @cInclude("attr/attributes.h");
});

const DEFAULT_RATING = 0;

const GetRatingError = error{ ParseInt, NonexistantFile, OtherXattr };

fn get_rating(path: [*c]const u8) GetRatingError!i32 {
    var attr_buf = [_]u8{0} ** 100;
    var size: c_int = attr_buf.len;
    const rc = xattr.attr_get(path, "rating", &attr_buf, &size, 0);
    //std.io.getStdOut().writer().print("xattr_get for {s}: rc: {d}, length: {d}, errno: {d}, value: {s}//\n", .{ path, rc, size, std.c._errno().*, attr_buf }) catch unreachable;
    if (rc == 0) {
        return std.fmt.parseInt(i32, attr_buf[0..std.math.absCast(size)], 10) catch return GetRatingError.ParseInt;
    } else {
        // Error
        const e = std.os.errno(rc);
        if (e == std.os.linux.E.NODATA) {
            return DEFAULT_RATING; // Attribute does not exist on this file
        } else if (e == std.os.linux.E.NOENT) {
            return GetRatingError.NonexistantFile;
        } else {
            return GetRatingError.OtherXattr;
        }
    }
}

const Comp = enum { Greater, Lesser };

pub fn main() !void {
    // TODO: handle errors writing to stdout/stderr more gracefully
    const stdout = std.io.getStdOut().writer();
    const stderr = std.io.getStdErr().writer();
    const stdin = std.io.getStdIn().reader();

    // Fetch args
    if (std.os.argv.len != 3) {
        try stderr.print("Expected -g I or -l I\n", .{});
        std.os.exit(1);
    }
    const flag = std.mem.sliceTo(std.os.argv[1], 0);
    const flag_arg = std.mem.sliceTo(std.os.argv[2], 0);

    // Interpret args
    var comp: Comp = undefined;
    if (std.mem.eql(u8, flag, "-g")) {
        comp = Comp.Greater;
    } else {
        comp = Comp.Lesser;
    }
    const fixed = std.fmt.parseInt(i32, flag_arg, 10) catch {
        try stderr.print("Could not parse {s} into integer\n", .{flag_arg});
        std.os.exit(1);
    };

    // TODO: switch to this when newer stdlib is available
    //const buffer = std.io.FixedBufferStream(@TypeOf(underlying)){ .buffer = underlying, .pos = 0 };
    //stdin.streamUntilDelimiter(buffer.writer(), '\n', underlying.len);

    var buffer: [1000]u8 = undefined;

    // TODO: panic on errors such as StreamTooLong (line does not fit in the buffer)

    // Stop on EOF
    while (try stdin.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        buffer[line.len] = 0; // Change the newline character to a NUL
        const maybe_rating = get_rating(&buffer) catch |e| {
            switch (e) {
                GetRatingError.ParseInt => try stderr.print("Unparseable rating for {s}\n", .{line}),
                GetRatingError.NonexistantFile => try stderr.print("File {s} does not really exist\n", .{line}),
                GetRatingError.OtherXattr => try stderr.print("Unrecognized error getting attribute of {s}\n", .{line}),
            }
            continue; // Once we have printed the error, nothing else to do with this file
        };

        const print = switch (comp) {
            .Greater => maybe_rating > fixed,
            .Lesser => maybe_rating < fixed,
        };

        if (print) {
            try stdout.print("Rating for {s}: {d}\n", .{ line, maybe_rating });
        }
    }
}
