const std = @import("std");
const expect = std.testing.expect;

const MEMORY_LEN = 4096;
const V_REGISTERS_LEN = 16;
const STACK_LEN = 16;
const FONT_LEN = 5 * 16;
const FONT_ADDR = 0x0050;

const DISPLAY_WIDTH = 64;
const DISPLAY_HEIGHT = 32;

const DEFAULT_PIXEL_OFF = 0x000000FF;
const DEFAULT_PIXEL_ON = 0xFFFFFFFF;

const VxKK = struct { vx: u8, kk: u8 };
const VxVy = struct { vx: u8, vy: u8 };
const VxVyN = struct { vx: u8, vy: u8, n: u8 };

const Instructions = union(enum) {
    CLS,
    RET,
    JP: u16,
    CALL: u16,
    SE_Vx_Byte: VxKK,
    SNE_Vx_Byte: VxKK,
    SE_Vx_Vy: VxVy,
    LD_Vx_Byte: VxKK,
    ADD_Vx_Byte: VxKK,
    LD_Vx_Vy: VxVy,
    OR_Vx_Vy: VxVy,
    AND_Vx_Vy: VxVy,
    XOR_Vx_Vy: VxVy,
    ADD_Vx_Vy: VxVy,
    SUB_Vx_Vy: VxVy,
    SHR_Vx_Vy: VxVy,
    SUBN_Vx_Vy: VxVy,
    SHL_Vx_Vy: VxVy,
    SNE_Vx_Vy: VxVy,
    LD_I_Addr: u16,
    JP_V0_Addr: u16,
    RND_Vx_Byte: VxKK,
    DRW_Vx_Vy_N: VxVyN,
    SKP_Vx: u8,
    SKNP_Vx: u8,
    LD_Vx_DT: u8,
    LD_DT_Vx: u8,
    LD_Vx_K: u8,
    LD_ST_Vx: u8,
    ADD_I_Vx: u8,
    LD_F_Vx: u8,
    LD_B_Vx: u8,
    LD_ArrI_Vx: u8,
    LD_Vx_ArrI: u8,
    UNKNOWN,

    pub fn decode(ins: u16) Instructions {
        const x: u8 = @truncate((ins & 0x0F00) >> 8);
        const y: u8 = @truncate((ins & 0x00F0) >> 4);
        const kk: u8 = @truncate(ins & 0x00FF);
        const nnn: u16 = ins & 0x0FFF;
        const n: u8 = @truncate(ins & 0x000F);

        return switch (ins & 0xF000) {
            0x0000 => switch (ins) {
                0x00E0 => Instructions.CLS,
                0x00EE => Instructions.RET,
                else => Instructions.UNKNOWN,
            },
            0x1000 => Instructions{ .JP = nnn },
            0x2000 => Instructions{ .CALL = nnn },
            0x3000 => Instructions{ .SE_Vx_Byte = .{ .vx = x, .kk = kk } },
            0x4000 => Instructions{ .SNE_Vx_Byte = .{ .vx = x, .kk = kk } },
            0x5000 => switch (ins & 0xF00F) {
                0x5000 => Instructions{ .SE_Vx_Vy = .{ .vx = x, .vy = y } },
                else => Instructions.UNKNOWN,
            },
            0x6000 => Instructions{ .LD_Vx_Byte = .{ .vx = x, .kk = kk } },
            0x7000 => Instructions{ .ADD_Vx_Byte = .{ .vx = x, .kk = kk } },
            0x8000 => switch (ins & 0xF00F) {
                0x8000 => Instructions{ .LD_Vx_Vy = .{ .vx = x, .vy = y } },
                0x8001 => Instructions{ .OR_Vx_Vy = .{ .vx = x, .vy = y } },
                0x8002 => Instructions{ .AND_Vx_Vy = .{ .vx = x, .vy = y } },
                0x8003 => Instructions{ .XOR_Vx_Vy = .{ .vx = x, .vy = y } },
                0x8004 => Instructions{ .ADD_Vx_Vy = .{ .vx = x, .vy = y } },
                0x8005 => Instructions{ .SUB_Vx_Vy = .{ .vx = x, .vy = y } },
                0x8006 => Instructions{ .SHR_Vx_Vy = .{ .vx = x, .vy = y } },
                0x8007 => Instructions{ .SUBN_Vx_Vy = .{ .vx = x, .vy = y } },
                0x800E => Instructions{ .SHL_Vx_Vy = .{ .vx = x, .vy = y } },
                else => Instructions.UNKNOWN,
            },
            0x9000 => switch (ins & 0xF00F) {
                0x9000 => Instructions{ .SNE_Vx_Vy = .{ .vx = x, .vy = y } },
                else => Instructions.UNKNOWN,
            },
            0xA000 => Instructions{ .LD_I_Addr = nnn },
            0xB000 => Instructions{ .JP_V0_Addr = nnn },
            0xC000 => Instructions{ .RND_Vx_Byte = .{ .vx = x, .kk = kk } },
            0xD000 => Instructions{ .DRW_Vx_Vy_N = .{ .vx = x, .vy = y, .n = n } },
            0xE000 => switch (ins & 0xF0FF) {
                0xE09E => Instructions{ .SKP_Vx = x },
                0xE0A1 => Instructions{ .SKNP_Vx = x },
                else => Instructions.UNKNOWN,
            },
            0xF000 => switch (ins & 0xF0FF) {
                0xF007 => Instructions{ .LD_Vx_DT = x },
                0xF00A => Instructions{ .LD_Vx_K = x },
                0xF015 => Instructions{ .LD_DT_Vx = x },
                0xF018 => Instructions{ .LD_ST_Vx = x },
                0xF01E => Instructions{ .ADD_I_Vx = x },
                0xF029 => Instructions{ .LD_F_Vx = x },
                0xF033 => Instructions{ .LD_B_Vx = x },
                0xF055 => Instructions{ .LD_ArrI_Vx = x },
                0xF065 => Instructions{ .LD_Vx_ArrI = x },
                else => Instructions.UNKNOWN,
            },
            else => Instructions.UNKNOWN,
        };
    }
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

    // Display colours (R8G8B8A8)
    display_width: u16 = DISPLAY_WIDTH,
    display_height: u16 = DISPLAY_HEIGHT,
    display_pixel_off: u32 = DEFAULT_PIXEL_OFF,
    display_pixel_on: u32 = DEFAULT_PIXEL_ON,

    rng: std.Random.DefaultPrng,

    pub fn init() System {
        const rng = std.Random.DefaultPrng.init(blk: {
            var seed: u64 = undefined;
            std.crypto.random.bytes(std.mem.asBytes(&seed));
            break :blk seed;
        });
        return std.mem.zeroInit(System, .{ .rng = rng });
    }

    pub fn reset(self: *System) void {
        @memset(self.mem[0..], 0);
        @memset(self.display[0..], self.display_pixel_off);
        @memset(self.v[0..], 0);
        @memset(self.stack[0..], 0);
        @memcpy(self.mem[FONT_ADDR..][0..FONT_LEN], self.font[0..]);

        self.pc = 0x200;
        self.i = 0;
        self.sp = 0;
        self.dt = 0;
        self.st = 0;
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

    pub fn tick(self: *System) void {
        // Fetch the instruction
        const ins_raw = std.mem.readInt(u16, self.mem[self.pc..][0..2], .big);
        std.log.debug("instruction: 0x{X:0>4}, pc=0x{X:0>4}", .{ ins_raw, self.pc });
        // Decode the instruction
        const ins = Instructions.decode(ins_raw);

        self.pc = (self.pc + 2) % 0x0FFF;
        switch (ins) {
            Instructions.CLS => {
                @memset(self.display[0..], self.display_pixel_off);
            },
            Instructions.RET => {
                self.sp -= 1;
                self.pc = self.stack[self.sp];
            },
            Instructions.JP => |nnn| {
                self.pc = (nnn & 0x0FFF);
            },
            Instructions.CALL => |nnn| {
                self.stack[self.sp] = self.pc; // Undo the early increment for the program counter.
                self.sp += 1;
                self.pc = (nnn & 0x0FFF);
            },
            Instructions.SE_Vx_Byte => |i| {
                if (self.v[i.vx] == i.kk) {
                    self.pc = (self.pc + 2) % 0x0FFF;
                }
            },
            Instructions.SNE_Vx_Byte => |i| {
                if (self.v[i.vx] != i.kk) {
                    self.pc = (self.pc + 2) % 0x0FFF;
                }
            },
            Instructions.SE_Vx_Vy => |i| {
                if (self.v[i.vx] == self.v[i.vy]) {
                    self.pc = (self.pc + 2) % 0x0FFF;
                }
            },
            Instructions.LD_Vx_Byte => |i| {
                self.v[i.vx] = i.kk;
            },
            Instructions.ADD_Vx_Byte => |i| {
                const res, _ = @addWithOverflow(self.v[i.vx], i.kk);
                self.v[i.vx] = res;
            },
            Instructions.LD_Vx_Vy => |i| {
                self.v[i.vx] = self.v[i.vy];
            },
            Instructions.OR_Vx_Vy => |i| {
                self.v[i.vx] |= self.v[i.vy];
            },
            Instructions.AND_Vx_Vy => |i| {
                self.v[i.vx] &= self.v[i.vy];
            },
            Instructions.XOR_Vx_Vy => |i| {
                self.v[i.vx] ^= self.v[i.vy];
            },
            Instructions.ADD_Vx_Vy => |i| {
                const res, const carry = @addWithOverflow(self.v[i.vx], self.v[i.vy]);
                self.v[i.vx] = res;
                self.v[0xF] = carry;
            },
            Instructions.SUB_Vx_Vy => |i| {
                const res, const carry = @subWithOverflow(self.v[i.vx], self.v[i.vy]);
                self.v[i.vx] = res;
                self.v[0xF] = carry;
            },
            Instructions.SHR_Vx_Vy => |i| {
                self.v[0xF] = self.v[i.vx] & 0x1;
                self.v[i.vx] >>= 1;
            },
            Instructions.SUBN_Vx_Vy => |i| {
                const res, const carry = @subWithOverflow(self.v[i.vy], self.v[i.vx]);
                self.v[i.vx] = res;
                self.v[0xF] = carry;
            },
            Instructions.SHL_Vx_Vy => |i| {
                self.v[0xF] = (self.v[i.vx] & 0x80) >> 7;
                self.v[i.vx] <<= 1;
            },
            Instructions.SNE_Vx_Vy => |i| {
                if (self.v[i.vx] != self.v[i.vy]) {
                    self.pc = (self.pc + 2) % 0x0FFF;
                }
            },
            Instructions.LD_I_Addr => |nnn| {
                self.i = nnn;
            },
            Instructions.JP_V0_Addr => |nnn| {
                self.pc = (nnn + self.v[0]) % 0x0FFF;
            },
            Instructions.RND_Vx_Byte => |i| {
                const rand = self.rng.random();
                self.v[i.vx] = rand.int(u8) & i.kk;
            },
            Instructions.DRW_Vx_Vy_N => |i| {
                const x_coord: u8 = self.v[i.vx];
                const y_coord: u8 = self.v[i.vy];

                self.v[0xF] = 0; // Clear the VF register.
                for (0..i.n) |y| {
                    var spriteRow: u8 = self.mem[self.i + y];
                    const row = (y_coord + y) % self.display_height;

                    var x: u8 = 0;
                    while (x < 8) : (x += 1) {
                        const spritePixel = (spriteRow & 0x80) >> 7;
                        const col = (x_coord + x) % self.display_width;
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
            Instructions.SKP_Vx => |_| {},
            Instructions.SKNP_Vx => |_| {},
            Instructions.LD_DT_Vx => |vx| {
                self.dt = self.v[vx];
            },
            Instructions.LD_Vx_DT => |vx| {
                self.v[vx] = self.dt;
            },
            Instructions.LD_Vx_K => |_| {},
            Instructions.LD_ST_Vx => |vx| {
                self.st = self.v[vx];
            },
            Instructions.ADD_I_Vx => |_| {},
            Instructions.LD_F_Vx => |_| {},
            Instructions.LD_B_Vx => |vx| {
                const v = self.v[vx];
                const bcd = [_]u8{ v / 100, (v / 10) % 10, v % 10 };
                @memcpy(self.mem[self.i .. self.i + 3], bcd[0..3]);
            },
            Instructions.LD_ArrI_Vx => |vx| {
                // TODO: Check memory boundry.
                @memcpy(self.mem[self.i..][0..vx], self.v[0..vx]);
            },
            Instructions.LD_Vx_ArrI => |vx| {
                // TODO: Check memory boundry.
                @memcpy(self.v[0..vx], self.mem[self.i..][0..vx]);
            },
            Instructions.UNKNOWN => {
                std.log.warn("Unknown instruction: 0x{X:0>4}", .{ins_raw});
            },
        }
    }

    pub fn tickN(self: *System, count: usize) void {
        for (0..count) |_| {
            self.tick();
        }
    }
};

test "cls instruction clears display" {
    const program = [_]u16{
        0x00E0, // CLS
    };

    var sys = System.init();
    sys.loadProgram(program[0..]);

    @memset(sys.display[0..], 1);

    sys.tick();

    try expect(std.mem.allEqual(u32, sys.display[0..], sys.display_pixel_off));
}

test "addition" {
    const program = [_]u16{
        0x7020, // ADD V0, 0x20 ; Test basic addition
        0x7130, // ADD V1, 0x30
        0x7220, // ADD V2, 0x20
        0x8214, // ADD V2, V1
        0x73FF, // ADD V3, 0xFF ; Test overflow is detected.
        0x7410, // ADD V4, 0x10
        0x8344, // ADD V3, V4
    };

    var sys = System.init();
    sys.loadProgram(program[0..]);

    for (program) |_| {
        sys.tick();
    }

    try expect(sys.v[0] == 0x20);
    try expect(sys.v[1] == 0x30);
    try expect(sys.v[2] == 0x50);
    try expect(sys.v[3] == 0x0F);
    try expect(sys.v[15] == 0x01);
}

test "basic load instructions" {
    const program = [_]u16{
        0x60FF, // LD V0, 0xFF
        0x8100, // LD V1, V0
        0xF115, // LD DT, V1
        0xF207, // LD V2, DT
        0xF218, // LD ST, V2
    };

    var sys = System.init();
    sys.loadProgram(program[0..]);

    for (program) |_| {
        sys.tick();
    }

    try expect(sys.v[0] == 0xFF);
    try expect(sys.v[1] == 0xFF);
    try expect(sys.dt == 0xFF);
    try expect(sys.st == 0xFF);
}

test "load bcd" {
    const program = [_]u16{
        0x617B, // LD V1, 123
        0xA400, // LD I, 0x400
        0xF133, // LD B, V1
    };

    var sys = System.init();
    sys.loadProgram(program[0..]);

    for (program) |_| {
        sys.tick();
    }

    try std.testing.expectEqualSlices(
        u8,
        &[_]u8{ 1, 2, 3 },
        sys.mem[0x400..0x403],
    );
}

test "skipping instructions" {
    const program = [_]u16{
        0x61FE, // LD V1, 0xFE
        0x62FE, // LD V2, 0xFE
        0x31FE, // SE V1, 0xFF
        0x63FF, // LD V3, 0xFF
        0x42FF, // SNE V2, 0xFE
        0x63FF, // LD V3, 0xFF
        0x5120, // SE V1, V2
        0x63FF, // LD V3, 0xFF
        0x64FF, // LD V4, 0xFF
        0x9340, // SNE V3, V4
        0x63FF, // LD V3, 0xFF
        0x00E0, // CLS
        0x00E0, // CLS
        0x00E0, // CLS
        0x00E0, // CLS
        0x00E0, // CLS
    };

    var sys = System.init();
    sys.loadProgram(program[0..]);

    for (0..program.len - 4) |_| {
        sys.tick();
    }

    try std.testing.expectEqual(0x00, sys.v[3]);
}

test "jumps and routine calling" {
    const program = [_]u16{
        0x2204, // CALL 0x204
        0x120A, // JP 0x20A
        0x61FF, // LD V1, 0xFF ; routine to set V1 to 0xFF
        0x00EE, // RET
        0x6FFF, // LD VF, 0xFF  ; check RET goes back.
        0x62FF, // LD V2, 0xFF  ; target for JP at 0x202
        0x6012, // LD V0, 0x12  ; Load offset for JP
        0xB200, // JP V0, 0x200
        0x6EFF, // LD VE, 0xFF  ; check JP, V0 works.
        0x63FF, // LD V3, 0xFF  ; target for JP V0
        0x6FFF, // LD VF, 0xFF  ; fail if too many ticks are executed
    };

    var sys = System.init();
    sys.loadProgram(program[0..]);

    for (1..9) |_| {
        sys.tick();
    }

    try std.testing.expectEqual(0xFF, sys.v[1]);
    try std.testing.expectEqual(0xFF, sys.v[2]);
    try std.testing.expectEqual(0xFF, sys.v[3]);

    try std.testing.expectEqual(0x00, sys.v[14]);
    try std.testing.expectEqual(0x00, sys.v[15]);
}

test "bit manipulation instructions" {
    var sys = System.init();
    sys.loadProgram(&[_]u16{
        0x60FF, // LD V0, 0xCC
        0x61CC, // LD V1, 0xFF
        0x8012, // AND V0, V1
        0x62AA, // LD V2, 0xCC
        0x6355, // LD V3, 0x55
        0x8231, // OR V2, V3
        0x64FF, // LD V4, 0xFF
        0x65AA, // LD V5, 0xAA
        0x8453, // XOR V4, V5
    });
    sys.tickN(9);

    try std.testing.expectEqual(0xCC, sys.v[0]);
    try std.testing.expectEqual(0xFF, sys.v[2]);
    try std.testing.expectEqual(0x55, sys.v[4]);

    sys.loadProgram(&[_]u16{
        0x60FF, // LD V0, 0xFF
        0x615E, // LD V1, 0x5F
        0x8006, // SHR V0
        0x8106, // SHR V1
        0x60FF, // LD V0, 0xFF
        0x617F, // LD V1, 0x7F
        0x800E, // SHL V0
        0x810E, // SHL V1
    });

    sys.tickN(3);
    try std.testing.expectEqual(0x7F, sys.v[0]);
    try std.testing.expectEqual(0x01, sys.v[0xF]);
    sys.tick();
    try std.testing.expectEqual(0x2F, sys.v[1]);
    try std.testing.expectEqual(0x00, sys.v[0xF]);
    sys.tickN(3);
    try std.testing.expectEqual(0xFE, sys.v[0]);
    try std.testing.expectEqual(0x01, sys.v[0xF]);
    sys.tick();
    try std.testing.expectEqual(0xFE, sys.v[1]);
    try std.testing.expectEqual(0x00, sys.v[0xf]);
}
