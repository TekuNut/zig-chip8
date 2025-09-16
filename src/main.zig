const std = @import("std");
const zig8 = @import("zig8");
const rl = @import("raylib");
const clap = @import("clap");

pub fn main() anyerror!void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    const screenWidth = 800;
    const screenHeight = 600;

    var ticks_per_frame: u32 = 15;

    // Specify the parameters for the program.
    const params = comptime clap.parseParamsComptime(
        \\-h, --help             Display this help and exit.
        \\ -r, --rom   <str>     ROM file to load on startup.
        \\ -s, --speed <u32>     Number of ticks to run per frame.
        \\ -d, --debug           Start with debug mode on.
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

    // Setup mapping between platform keyboard and CHIP8 keypad.
    var keypad_mapping = std.AutoHashMap(u8, rl.KeyboardKey).init(gpa.allocator());
    defer keypad_mapping.deinit();

    try keypad_mapping.put(0, .x);
    try keypad_mapping.put(1, .one);
    try keypad_mapping.put(2, .two);
    try keypad_mapping.put(3, .three);
    try keypad_mapping.put(4, .q);
    try keypad_mapping.put(5, .w);
    try keypad_mapping.put(6, .e);
    try keypad_mapping.put(7, .a);
    try keypad_mapping.put(8, .s);
    try keypad_mapping.put(9, .d);
    try keypad_mapping.put(0xA, .z);
    try keypad_mapping.put(0xB, .c);
    try keypad_mapping.put(0xC, .four);
    try keypad_mapping.put(0xD, .r);
    try keypad_mapping.put(0xE, .f);
    try keypad_mapping.put(0xF, .v);

    rl.initWindow(screenWidth, screenHeight, "zig8 - Chip8 Emulator");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var sys = zig8.System.init();

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
    var debug = res.args.debug != 0;

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

        // Check if any CHIP8 keys have been pressed and set them.
        var key_iterator = keypad_mapping.iterator();
        while (key_iterator.next()) |entry| {
            if (rl.isKeyReleased(entry.value_ptr.*)) {
                sys.keypad[entry.key_ptr.*] = .RELEASED;
            } else if (rl.isKeyDown(entry.value_ptr.*)) {
                sys.keypad[entry.key_ptr.*] = .PRESSED;
            } else {
                sys.keypad[entry.key_ptr.*] = .UNPRESSED;
            }
        }

        // Update
        if (!paused) {
            if (debug and debug_step) {
                sys.tick();
            } else if (!debug) {
                sys.tickN(sys.tick_speed);
            }
        }

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.fromInt(sys.display_pixel_off));

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
