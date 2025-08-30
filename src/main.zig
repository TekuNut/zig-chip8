const std = @import("std");
const zig8 = @import("zig8");
const rl = @import("raylib");

pub fn main() anyerror!void {
    const screenWidth = 800;
    const screenHeight = 600;

    rl.initWindow(screenWidth, screenHeight, "zig8 - Chip8 Emulator");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var sys = std.mem.zeroInit(zig8.System, .{});

    const paused = true;

    // Main loop
    while(!rl.windowShouldClose()) {
        // Update
        if(!paused) {
            sys.tick();
        }

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.black);

        rl.drawText("Load ROM...", 190, 200 + @as(i32, @intFromFloat(50.0 * @sin(rl.getTime()))), 40, .light_gray);
    }
}


