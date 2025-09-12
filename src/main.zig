const std = @import("std");
const zig8 = @import("zig8");
const rl = @import("raylib");
const clap = @import("clap");

pub fn main() anyerror!void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    const screenWidth = 800;
    const screenHeight = 600;

    var ticks_per_frame: u32 = 7;

    // Specify the parameters for the program.
    const params = comptime clap.parseParamsComptime(
        \\-h, --help             Display this help and exit.
        \\ -r, --rom   <str>     ROM file to load on startup.
        \\ -s, --speed <u32>     Number of ticks to run per frame.
    );

    // Initialize diagnostics to report useful errors. Parse the command params into `res`.
    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .diagnostic = &diag,
        .allocator = gpa.allocator(),
    }) catch |err| {
        try diag.reportToFile(.stderr(), err);
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0)
        std.debug.print("--help\n", .{});
    if (res.args.speed) |s| {
        ticks_per_frame = s;
    }

    rl.initWindow(screenWidth, screenHeight, "zig8 - Chip8 Emulator");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var sys = zig8.System.init(0);

    sys.reset();
    if (res.args.rom) |r| {
        std.log.debug("Opening ROM file: {s}", .{r});
        var file = std.fs.cwd().openFile(r, .{ .mode = .read_only }) catch |err| {
            std.log.debug("Failed to open ROM file: {s} ({})", .{ r, err });
            return err;
        };
        defer file.close();

        var read_buf: [512]u8 = undefined;
        var reader = file.reader(&read_buf);

        std.log.debug("Loading ROM: {s}", .{r});
        sys.readProgram(&reader.interface) catch |err| {
            std.log.err("Failed to load ROM: {s} ({})", .{ r, err });
            return;
        };
    }

    var paused = false;
    var debug = true;

    var display = rl.Image.genColor(@as(i32, sys.display_width), @as(i32, sys.display_height), .black);
    const display_texture = try rl.Texture2D.fromImage(display);

    // Main loop
    while (!rl.windowShouldClose()) {
        // Input
        if (rl.isKeyPressed(.p)) {
            paused = !paused;
        }

        if (rl.isKeyPressed(.f5)) {
            debug = !debug;
        }

        const debug_step = rl.isKeyPressed(.f1);

        // Update
        if (!paused) {
            if (debug and debug_step) {
                sys.tick();
            } else if (!debug) {
                sys.tickN(ticks_per_frame);
            }
        }

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.black);

        // Copy the chip8 display into the image.
        for (0.., sys.display) |i, pixel| {
            const x: i32 = @intCast(i % sys.display_width);
            const y: i32 = @intCast(i / sys.display_width);
            const color = rl.Color.fromInt(pixel);
            display.drawPixel(x, y, color);

            rl.updateTexture(display_texture, display.data);
        }

        // Transfer the display image into a texture and render it scaled up.
        const display_src_rect = rl.Rectangle.init(0, 0, @floatFromInt(display_texture.width), @floatFromInt(display_texture.height));
        const display_dst_rect = rl.Rectangle.init(0, 0, @floatFromInt(rl.getRenderWidth()), @floatFromInt(rl.getRenderHeight()));
        rl.drawTexturePro(display_texture, display_src_rect, display_dst_rect, rl.Vector2.zero(), 0.0, .white);
    }
}
