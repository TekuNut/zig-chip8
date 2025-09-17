const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

const MEMORY_LEN = 4096;
const V_REGISTERS_LEN = 16;
const STACK_LEN = 16;
const FONT_SPRITE_LEN = 5;
const FONT_LEN = FONT_SPRITE_LEN * 16;
const FONT_ADDR = 0x0050;

const DISPLAY_WIDTH = 64;
const DISPLAY_HEIGHT = 32;

const DEFAULT_PIXEL_OFF = 0x000000FF;
const DEFAULT_PIXEL_ON = 0xFFFFFFFF;

const VxKK = struct { vx: u8, kk: u8 };
const VxVy = struct { vx: u8, vy: u8 };
const VxVyN = struct { vx: u8, vy: u8, n: u8 };

const Instructions = union(enum) {
    OP_00E0,
    OP_00EE,
    OP_1NNN: u16,
    OP_2NNN: u16,
    OP_3XKK: VxKK,
    OP_4XKK: VxKK,
    OP_5XY0: VxVy,
    OP_6XKK: VxKK,
    OP_7XKK: VxKK,
    OP_8XY0: VxVy,
    OP_8XY1: VxVy,
    OP_8XY2: VxVy,
    OP_8XY3: VxVy,
    OP_8XY4: VxVy,
    OP_8XY5: VxVy,
    OP_8XY6: VxVy,
    OP_8XY7: VxVy,
    OP_8XYE: VxVy,
    OP_9XY0: VxVy,
    OP_ANNN: u16,
    OP_BNNN: u16,
    OP_CXKK: VxKK,
    OP_DXYN: VxVyN,
    OP_EX9E: u8,
    OP_EXA1: u8,
    OP_FX07: u8,
    OP_FX15: u8,
    OP_FX0A: u8,
    OP_FX18: u8,
    OP_FX1E: u8,
    OP_FX29: u8,
    OP_FX33: u8,
    OP_FX55: u8,
    OP_FX65: u8,
    OP_UNKNOWN,

    pub fn decode(ins: u16) Instructions {
        const x: u8 = @truncate((ins & 0x0F00) >> 8);
        const y: u8 = @truncate((ins & 0x00F0) >> 4);
        const kk: u8 = @truncate(ins & 0x00FF);
        const nnn: u16 = ins & 0x0FFF;
        const n: u8 = @truncate(ins & 0x000F);

        return switch (ins & 0xF000) {
            0x0000 => switch (ins) {
                0x00E0 => Instructions.OP_00E0,
                0x00EE => Instructions.OP_00EE,
                else => Instructions.OP_UNKNOWN,
            },
            0x1000 => Instructions{ .OP_1NNN = nnn },
            0x2000 => Instructions{ .OP_2NNN = nnn },
            0x3000 => Instructions{ .OP_3XKK = .{ .vx = x, .kk = kk } },
            0x4000 => Instructions{ .OP_4XKK = .{ .vx = x, .kk = kk } },
            0x5000 => switch (ins & 0xF00F) {
                0x5000 => Instructions{ .OP_5XY0 = .{ .vx = x, .vy = y } },
                else => Instructions.OP_UNKNOWN,
            },
            0x6000 => Instructions{ .OP_6XKK = .{ .vx = x, .kk = kk } },
            0x7000 => Instructions{ .OP_7XKK = .{ .vx = x, .kk = kk } },
            0x8000 => switch (ins & 0xF00F) {
                0x8000 => Instructions{ .OP_8XY0 = .{ .vx = x, .vy = y } },
                0x8001 => Instructions{ .OP_8XY1 = .{ .vx = x, .vy = y } },
                0x8002 => Instructions{ .OP_8XY2 = .{ .vx = x, .vy = y } },
                0x8003 => Instructions{ .OP_8XY3 = .{ .vx = x, .vy = y } },
                0x8004 => Instructions{ .OP_8XY4 = .{ .vx = x, .vy = y } },
                0x8005 => Instructions{ .OP_8XY5 = .{ .vx = x, .vy = y } },
                0x8006 => Instructions{ .OP_8XY6 = .{ .vx = x, .vy = y } },
                0x8007 => Instructions{ .OP_8XY7 = .{ .vx = x, .vy = y } },
                0x800E => Instructions{ .OP_8XYE = .{ .vx = x, .vy = y } },
                else => Instructions.OP_UNKNOWN,
            },
            0x9000 => switch (ins & 0xF00F) {
                0x9000 => Instructions{ .OP_9XY0 = .{ .vx = x, .vy = y } },
                else => Instructions.OP_UNKNOWN,
            },
            0xA000 => Instructions{ .OP_ANNN = nnn },
            0xB000 => Instructions{ .OP_BNNN = nnn },
            0xC000 => Instructions{ .OP_CXKK = .{ .vx = x, .kk = kk } },
            0xD000 => Instructions{ .OP_DXYN = .{ .vx = x, .vy = y, .n = n } },
            0xE000 => switch (ins & 0xF0FF) {
                0xE09E => Instructions{ .OP_EX9E = x },
                0xE0A1 => Instructions{ .OP_EXA1 = x },
                else => Instructions.OP_UNKNOWN,
            },
            0xF000 => switch (ins & 0xF0FF) {
                0xF007 => Instructions{ .OP_FX07 = x },
                0xF00A => Instructions{ .OP_FX0A = x },
                0xF015 => Instructions{ .OP_FX15 = x },
                0xF018 => Instructions{ .OP_FX18 = x },
                0xF01E => Instructions{ .OP_FX1E = x },
                0xF029 => Instructions{ .OP_FX29 = x },
                0xF033 => Instructions{ .OP_FX33 = x },
                0xF055 => Instructions{ .OP_FX55 = x },
                0xF065 => Instructions{ .OP_FX65 = x },
                else => Instructions.OP_UNKNOWN,
            },
            else => Instructions.OP_UNKNOWN,
        };
    }
};

pub const KeypadState = enum(u8) {
    UNPRESSED,
    PRESSED,
    RELEASED,
};

pub const OutputState = struct {
    beep: bool,
};

pub const System = struct {
    mem: [MEMORY_LEN]u8 = [_]u8{0} ** MEMORY_LEN,
    display: [DISPLAY_WIDTH * DISPLAY_HEIGHT]u32 = [_]u32{0} ** (DISPLAY_WIDTH * DISPLAY_HEIGHT),
    stack: [STACK_LEN]u16,
    font: [FONT_LEN]u8 = [_]u8{
        0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
        0x20, 0x60, 0x20, 0x20, 0x70, // 1
        0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
        0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
        0x90, 0x90, 0xF0, 0x10, 0x10, // 4
        0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
        0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
        0xF0, 0x10, 0x20, 0x40, 0x40, // 7
        0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
        0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
        0xF0, 0x90, 0xF0, 0x90, 0x90, // A
        0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
        0xF0, 0x80, 0x80, 0x80, 0xF0, // C
        0xE0, 0x90, 0x90, 0x90, 0xE0, // D
        0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
        0xF0, 0x80, 0xF0, 0x80, 0x80, // F
    },

    // Registers
    v: [V_REGISTERS_LEN]u8,
    pc: u16 = 0x200,
    i: u16 = 0,
    sp: u8 = 0,
    dt: u8 = 0,
    st: u8 = 0,

    /// How many ticks are executed before decrementing dt/st.
    tick_speed: u32,

    /// Ticks remaining before decrementing dt/st.
    ticks_remaining: u32,

    // Display colours (R8G8B8A8)
    display_width: u16 = DISPLAY_WIDTH,
    display_height: u16 = DISPLAY_HEIGHT,
    display_pixel_off: u32 = DEFAULT_PIXEL_OFF,
    display_pixel_on: u32 = DEFAULT_PIXEL_ON,

    /// Current keypad state.
    keypad: [16]KeypadState,

    /// If CPU is halted for keypad input.
    keypad_waiting: bool = false,

    /// Which Vx register to save the keypress to.
    keypad_save_to_vx: u8 = 0,

    // Random number generation
    rng: std.Random.DefaultPrng,

    // Quirks
    /// If true, take VX as both input and output for opcodes `8XY6` and `8XYE`. Else use VY for input and output result to VX.
    quirk_shift: bool = false,
    /// If true, FX55 and FX65 will increment I by X. Else I is incremented by (X+1).
    quirk_memory_increment_by_x: bool = false,
    /// If true opcodes `FX55` and `FX65` leaves the `i` register unchanged.
    quirk_memory_leave_i_unchanged: bool = false,
    /// If true, opcode DXYN will wrap around to the other side of the screen when drawing. Else it will clip.
    quirk_wrap: bool = false,
    /// If true, opcode DXYN will wait for vblank (maximum of 60 sprites drawn per second).
    quirk_vblank: bool = true,
    /// If true, opcodes `8XY1`, `8XY2` and `8XY3` will set `VF` to 0 after execution. Else it is left alone (unless `vF` is the parameter `X`).
    quirk_logic: bool = true,

    pub fn init() System {
        return initWithSpeed(12);
    }

    pub fn initWithSpeed(speed: u32) System {
        const rng = std.Random.DefaultPrng.init(blk: {
            var seed: u64 = undefined;
            std.crypto.random.bytes(std.mem.asBytes(&seed));
            break :blk seed;
        });
        return std.mem.zeroInit(System, .{ .rng = rng, .tick_speed = speed, .ticks_remaining = speed });
    }

    pub fn reset(self: *System) void {
        @memset(self.mem[0..], 0);
        @memset(self.display[0..], self.display_pixel_off);
        @memset(self.v[0..], 0);
        @memset(self.stack[0..], 0);
        @memset(self.keypad[0..], .UNPRESSED);
        @memcpy(self.mem[FONT_ADDR..][0..FONT_LEN], self.font[0..]);

        self.pc = 0x200;
        self.i = 0;
        self.sp = 0;
        self.dt = 0;
        self.st = 0;

        self.keypad_waiting = false;
        self.keypad_save_to_vx = 0;
        self.ticks_remaining = self.tick_speed;
    }

    pub fn readProgram(self: *System, input: *std.io.Reader) !void {
        self.reset();
        input.readSliceAll(self.mem[0x200..]) catch |err| switch (err) {
            error.EndOfStream => {},
            else => return err,
        };
    }

    pub fn loadProgram(self: *System, program: []const u16) void {
        self.reset();

        for (program, 0..) |ins, idx| {
            var buf = [2]u8{ 0, 0 };
            const addr = 0x200 + idx * 2;
            std.mem.writeInt(u16, &buf, ins, .big);

            self.mem[addr] = buf[0];
            self.mem[addr + 1] = buf[1];
        }
    }

    pub fn runOp(self: *System, op: u16) void {
        // Decode the instruction
        const ins = Instructions.decode(op);

        self.pc = (self.pc + 2) % 0x0FFF;
        switch (ins) {
            Instructions.OP_00E0 => {
                // CLS: Clear display
                @memset(self.display[0..], self.display_pixel_off);
            },
            Instructions.OP_00EE => {
                // RET: Return from subroutine
                self.sp -= 1;
                self.pc = self.stack[self.sp];
            },
            Instructions.OP_1NNN => |nnn| {
                // JP addr
                self.pc = (nnn & 0x0FFF);
            },
            Instructions.OP_2NNN => |nnn| {
                // CALL addr
                self.stack[self.sp] = self.pc;
                self.sp += 1;
                self.pc = (nnn & 0x0FFF);
            },
            Instructions.OP_3XKK => |i| {
                // SE Vx, byte
                if (self.v[i.vx] == i.kk) {
                    self.pc = (self.pc + 2) % 0x0FFF;
                }
            },
            Instructions.OP_4XKK => |i| {
                // SNE Vx, byte
                if (self.v[i.vx] != i.kk) {
                    self.pc = (self.pc + 2) % 0x0FFF;
                }
            },
            Instructions.OP_5XY0 => |i| {
                // SE Vx, Vy
                if (self.v[i.vx] == self.v[i.vy]) {
                    self.pc = (self.pc + 2) % 0x0FFF;
                }
            },
            Instructions.OP_6XKK => |i| {
                // LD VX, byte
                self.v[i.vx] = i.kk;
            },
            Instructions.OP_7XKK => |i| {
                // ADD Vx, byte
                const res, _ = @addWithOverflow(self.v[i.vx], i.kk);
                self.v[i.vx] = res;
            },
            Instructions.OP_8XY0 => |i| {
                // LD Vx, Vy
                self.v[i.vx] = self.v[i.vy];
            },
            Instructions.OP_8XY1 => |i| {
                // LD OR Vx, Vy
                self.v[i.vx] |= self.v[i.vy];
                if (self.quirk_logic) {
                    self.v[0xF] = 0;
                }
            },
            Instructions.OP_8XY2 => |i| {
                // AND Vx, Vy
                self.v[i.vx] &= self.v[i.vy];
                if (self.quirk_logic) {
                    self.v[0xF] = 0;
                }
            },
            Instructions.OP_8XY3 => |i| {
                // XOR Vx, Vy
                self.v[i.vx] ^= self.v[i.vy];
                if (self.quirk_logic) {
                    self.v[0xF] = 0;
                }
            },
            Instructions.OP_8XY4 => |i| {
                // ADD Vx, Vy
                const res, const carry = @addWithOverflow(self.v[i.vx], self.v[i.vy]);
                self.v[i.vx] = res;
                self.v[0xF] = carry;
            },
            Instructions.OP_8XY5 => |i| {
                // SUB Vx, Vy
                const res, const carry = @subWithOverflow(self.v[i.vx], self.v[i.vy]);
                self.v[i.vx] = res;
                self.v[0xF] = if (carry == 1) 0 else 1;
            },
            Instructions.OP_8XY6 => |i| {
                // SHR Vx, Vy
                if (!self.quirk_shift) {
                    self.v[i.vx] = self.v[i.vy];
                }

                const carry = self.v[i.vx] & 0x1;
                self.v[i.vx] >>= 1;
                self.v[0xF] = carry;
            },
            Instructions.OP_8XY7 => |i| {
                // SUBN Vx, Vy
                const res, const carry = @subWithOverflow(self.v[i.vy], self.v[i.vx]);
                self.v[i.vx] = res;
                self.v[0xF] = if (carry == 1) 0 else 1;
            },
            Instructions.OP_8XYE => |i| {
                // SHL Vx, Vy
                if (!self.quirk_shift) {
                    self.v[i.vx] = self.v[i.vy];
                }

                const res, const carry = @shlWithOverflow(self.v[i.vx], 1);
                self.v[i.vx] = res;
                self.v[0xF] = carry;
            },
            Instructions.OP_9XY0 => |i| {
                // SNE Vx, Vy
                if (self.v[i.vx] != self.v[i.vy]) {
                    self.pc = (self.pc + 2) % 0x0FFF;
                }
            },
            Instructions.OP_ANNN => |nnn| {
                // LD I, addr
                self.i = nnn;
            },
            Instructions.OP_BNNN => |nnn| {
                // JP V0, addr
                self.pc = (nnn + self.v[0]) % 0x0FFF;
            },
            Instructions.OP_CXKK => |i| {
                // RND Vx, byte
                const rand = self.rng.random();
                self.v[i.vx] = rand.int(u8) & i.kk;
            },
            Instructions.OP_DXYN => |i| {
                // DRW Vx, Vy, n
                // If the sprite drawing starts offscreen, it is wrapped regardless of the `quirk_wrap` setting.
                const x_coord: u16 = self.v[i.vx] % self.display_width;
                const y_coord: u16 = self.v[i.vy] % self.display_height;

                self.v[0xF] = 0; // Clear the VF register.
                for (0..i.n) |y| {
                    var spriteRow: u8 = self.mem[self.i + y];
                    var row = (y_coord + y);
                    if (self.quirk_wrap) {
                        row %= self.display_height;
                    } else if (row < 0 or row >= self.display_height) {
                        continue;
                    }

                    var x: u16 = 0;
                    while (x < 8) : (x += 1) {
                        const spritePixel = (spriteRow & 0x80) >> 7;

                        var col = (x_coord + x);
                        if (self.quirk_wrap) {
                            col %= self.display_width;
                        } else if (col < 0 or col >= self.display_width) {
                            continue;
                        }

                        const displayPixel: *u32 = &self.display[row * self.display_width + col];

                        if (spritePixel == 1) {
                            if (displayPixel.* == self.display_pixel_on) {
                                displayPixel.* = self.display_pixel_off;
                                self.v[0xF] = 1;
                            } else {
                                displayPixel.* = self.display_pixel_on;
                            }
                        }

                        spriteRow <<= 1;
                    }
                }
            },
            Instructions.OP_EX9E => |vx| {
                // SKP Vx
                // Skip next instruction if key with the value of Vx is pressed.
                if (self.keypad[self.v[vx]] == .PRESSED) {
                    self.pc += 2;
                }
            },
            Instructions.OP_EXA1 => |vx| {
                // SKNP Vx
                // Skip next instruction if key with the value of Vx is NOT pressed.
                if (self.keypad[self.v[vx]] != .PRESSED) {
                    self.pc += 2;
                }
            },
            Instructions.OP_FX07 => |vx| {
                // LD Vx, DT
                self.v[vx] = self.dt;
            },
            Instructions.OP_FX0A => |vx| {
                // LD Vx, K
                self.keypad_waiting = true;
                self.keypad_save_to_vx = vx;
            },
            Instructions.OP_FX15 => |vx| {
                // LD DT, Vx
                self.dt = self.v[vx];
            },
            Instructions.OP_FX18 => |vx| {
                // LD ST, Vx
                self.st = self.v[vx];
            },
            Instructions.OP_FX1E => |vx| {
                self.i += self.v[vx];
                if (self.i >= 0x1000) {
                    self.v[0xF] = 1;
                    self.i &= 0x0FFF;
                }
            },
            Instructions.OP_FX29 => |vx| {
                // LD F, Vx
                self.i = FONT_ADDR + self.v[vx] * FONT_SPRITE_LEN;
            },
            Instructions.OP_FX33 => |vx| {
                // LD B, Vx
                const v = self.v[vx];
                const bcd = [_]u8{ v / 100, (v / 10) % 10, v % 10 };
                @memcpy(self.mem[self.i .. self.i + 3], bcd[0..3]);
            },
            Instructions.OP_FX55 => |vx| {
                // LD [I], Vx
                // TODO: Check memory boundry.
                @memcpy(self.mem[self.i..][0 .. vx + 1], self.v[0 .. vx + 1]);
                if (!self.quirk_memory_leave_i_unchanged) {
                    self.i += if (self.quirk_memory_increment_by_x) vx else 1 + vx;
                }
            },
            Instructions.OP_FX65 => |vx| {
                // LD Vx, [I]
                // TODO: Check memory boundry.
                @memcpy(self.v[0 .. vx + 1], self.mem[self.i..][0 .. vx + 1]);
                if (!self.quirk_memory_leave_i_unchanged) {
                    self.i += if (self.quirk_memory_increment_by_x) vx else 1 + vx;
                }
            },
            Instructions.OP_UNKNOWN => {
                std.log.warn("Unknown instruction: 0x{X:0>4}", .{op});
            },
        }
    }

    pub fn tick(self: *System) OutputState {
        return self.tickN(1);
    }

    pub fn tickN(self: *System, count: usize) OutputState {
        tick: for (0..count) |_| {
            // Check if dt and st need to be decremented.
            self.ticks_remaining -= 1;
            if (self.ticks_remaining == 0) {
                if (self.dt > 0) {
                    self.dt -= 1;
                }

                if (self.st > 0) {
                    self.st -= 1;
                }

                self.ticks_remaining = self.tick_speed;
            }

            if (self.keypad_waiting) {
                for (0.., self.keypad) |i, state| {
                    if (state == .RELEASED) {
                        // Detect if a key was pressed and then released.
                        self.keypad_waiting = false;
                        self.v[self.keypad_save_to_vx] = @truncate(i);
                        break;
                    }
                } else {
                    continue :tick; // End tick if no key was pressed.
                }
            }

            // Fetch the instruction
            const op = std.mem.readInt(u16, self.mem[self.pc..][0..2], .big);
            // std.log.debug("instruction: 0x{X:0>4}, pc=0x{X:0>4}", .{ op, self.pc });

            self.runOp(op);
        }

        return OutputState{ .beep = self.st > 0 };
    }
};

test "op_00e0" {
    var sys = System.init();
    @memset(sys.display[0..], 1);

    sys.runOp(0x00E0);

    try expect(std.mem.allEqual(u32, sys.display[0..], sys.display_pixel_off));
}

test "op_00ee" {
    var sys = System.init();
    sys.sp = 5;
    sys.stack[4] = 0x567;

    sys.runOp(0x00EE);
    try expect(sys.sp == 4);
    try expect(sys.pc == 0x567);
}

test "op_1nnn" {
    var sys = System.init();
    sys.runOp(0x1789);
    try expect(sys.pc == 0x789);
}

test "op_2nnn" {
    var sys = System.init();
    sys.pc = 0x123;
    sys.sp = 3;
    sys.runOp(0x2789);

    try expect(sys.pc == 0x789);
    try expect(sys.sp == 4);
    try expect(sys.stack[3] == 0x125);
}

test "op_3xkk" {
    {
        var sys = System.init();
        sys.runOp(0x3201);
        try std.testing.expectEqual(0x202, sys.pc);
    }

    {
        var sys1 = System.init();
        sys1.runOp(0x3200);
        try std.testing.expectEqual(0x204, sys1.pc);
    }
}

test "op_4xkk" {
    var sys = System.init();
    sys.runOp(0x4300);
    try std.testing.expectEqual(0x202, sys.pc);

    var sys1 = System.init();
    sys1.runOp(0x4412);
    try std.testing.expectEqual(0x204, sys1.pc);
}

test "op_5xy0" {
    {
        var sys = System.init();
        sys.v[1] = 22;
        sys.runOp(0x5010);
        try std.testing.expectEqual(0x202, sys.pc);
    }
    {
        var sys = System.init();
        sys.runOp(0x5450);
        try std.testing.expectEqual(0x204, sys.pc);
    }
}

test "op_6xkk" {
    var sys = System.init();
    sys.runOp(0x6255);
    try std.testing.expectEqual(0x55, sys.v[2]);
}

test "op_7xkk" {
    var sys = System.init();
    sys.runOp(0x7477);
    try std.testing.expectEqual(0x77, sys.v[4]);
}

test "op_8xy0" {
    var sys = System.init();
    sys.v[2] = 0x45;
    sys.runOp(0x8120);
    try std.testing.expectEqual(0x45, sys.v[1]);
}

test "op_8xy1" {
    var sys = System.init();
    sys.v[1] = 0x40;
    sys.v[3] = 0x08;
    sys.runOp(0x8131);
    try std.testing.expectEqual(0x48, sys.v[1]);
}

test "op_8xy2" {
    var sys = System.init();
    sys.v[4] = 0xF0;
    sys.v[5] = 0x82;
    sys.runOp(0x8452);
    try std.testing.expectEqual(0x80, sys.v[4]);
}

test "op_8xy3" {
    var sys = System.init();
    sys.v[7] = 0x0F;
    sys.v[8] = 0xFF;
    sys.runOp(0x8783);
    try std.testing.expectEqual(0xF0, sys.v[7]);
}

test "op_8xy4" {
    {
        var sys = System.init();
        sys.v[4] = 10;
        sys.v[5] = 20;
        sys.runOp(0x8454);
        try std.testing.expectEqual(30, sys.v[4]);
        try std.testing.expectEqual(0, sys.v[0xF]);
    }

    {
        var sys = System.init();
        sys.v[6] = 255;
        sys.v[7] = 10;
        sys.runOp(0x8674);

        try std.testing.expectEqual(9, sys.v[6]);
        try std.testing.expectEqual(1, sys.v[0xF]);
    }
}

test "op_8xy5" {
    {
        var sys = System.init();
        sys.v[6] = 70;
        sys.v[7] = 50;
        sys.runOp(0x8675);
        try std.testing.expectEqual(20, sys.v[6]);
        try std.testing.expectEqual(1, sys.v[0xF]);
    }
    {
        var sys = System.init();
        sys.v[8] = 0;
        sys.v[9] = 20;
        sys.runOp(0x8895);
        try std.testing.expectEqual(-20, @as(i8, @bitCast(sys.v[8])));
        try std.testing.expectEqual(0, sys.v[0xF]);
    }
}

test "op_8xy6" {
    var sys = System.init();
    sys.v[2] = 0x81;
    sys.runOp(0x8026);
    try std.testing.expectEqual(0x40, sys.v[0]);
    try std.testing.expectEqual(1, sys.v[0xF]);
}

test "op_8xy7" {
    {
        var sys = System.init();
        sys.v[4] = 50;
        sys.v[5] = 30;
        sys.runOp(0x8457);
        try std.testing.expectEqual(-20, @as(i8, @bitCast(sys.v[4])));
        try std.testing.expectEqual(0, sys.v[0xF]);
    }
    {
        var sys = System.init();
        sys.v[0] = 10;
        sys.v[1] = 30;
        sys.runOp(0x8017);
        try std.testing.expectEqual(20, sys.v[0]);
        try std.testing.expectEqual(1, sys.v[0xF]);
    }
}

test "op_8xye" {
    var sys = System.init();
    sys.v[1] = 0x84;
    sys.runOp(0x801E);
    try std.testing.expectEqual(0x08, sys.v[0]);
}

test "op_annn" {
    var sys = System.init();
    sys.runOp(0xA456);
    try std.testing.expectEqual(0x456, sys.i);
}

test "op_bnnn" {
    var sys = System.init();
    sys.v[0] = 0x25;
    sys.runOp(0xB200);

    try std.testing.expectEqual(0x225, sys.pc);
}

test "op_cxkk" {
    var sys = System.init();
    sys.runOp(0xC000);
    try std.testing.expectEqual(sys.v[0], 0);
}

test "op_dxyn" {}

test "op_ex9e" {
    var sys = System.init();
    sys.v[2] = 4;
    sys.keypad[4] = .PRESSED;
    sys.runOp(0xE29E);

    try std.testing.expectEqual(0x204, sys.pc);
}

test "op_exa1" {
    var sys = System.init();
    sys.v[6] = 4;
    sys.runOp(0xE6A1);

    try std.testing.expectEqual(0x204, sys.pc);
}

test "op_fx07" {
    var sys = System.init();
    sys.dt = 200;
    sys.runOp(0xF207);

    try std.testing.expectEqual(200, sys.v[2]);
}

test "op_fx0a" {
    var sys = System.init();
    sys.mem[0x202] = 0x00;
    sys.mem[0x203] = 0xE0; // Suppress illegal instructions warning.
    sys.runOp(0xF30A);
    sys.tickN(4);
    try expectEqual(0x202, sys.pc);

    // Press key
    sys.keypad[4] = .RELEASED;
    sys.tick();
    try expectEqual(0x204, sys.pc);
    try expectEqual(4, sys.v[3]);
}

test "op_fx15" {
    var sys = System.init();
    sys.v[4] = 100;
    sys.runOp(0xF415);

    try std.testing.expectEqual(100, sys.v[4]);
}

test "op_fx18" {
    var sys = System.init();
    sys.v[6] = 50;
    sys.runOp(0xF618);

    try std.testing.expectEqual(50, sys.v[6]);
}

test "op_fx1e" {
    var sys = System.init();
    sys.v[5] = 0x10;
    sys.runOp(0xF51E);
    try std.testing.expectEqual(0x10, sys.i);
}

test "op_fx29" {
    var sys = System.init();
    sys.v[5] = 9;
    sys.runOp(0xF529);
    try std.testing.expectEqual(0x50 + 9 * 5, sys.i);
}

test "op_fx33" {
    var sys = System.init();
    sys.i = 0x600;
    sys.v[2] = 123;
    sys.runOp(0xF233);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 1, 2, 3 }, sys.mem[0x600..0x603]);
}

test "op_fx55" {
    var sys = System.init();
    sys.i = 0x800;
    @memcpy(sys.v[0..4], &[_]u8{ 2, 4, 8, 16 });
    sys.runOp(0xF455);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 2, 4, 8, 16, 0 }, sys.mem[0x800..0x805]);
}

test "op_fx65" {
    var sys = System.init();
    sys.i = 0x600;
    @memcpy(sys.mem[0x600..0x604], &[_]u8{ 10, 20, 30, 40 });
    sys.runOp(0xF465);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 10, 20, 30, 40, 0 }, sys.v[0..5]);
}
