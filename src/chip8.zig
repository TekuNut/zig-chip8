const std = @import("std");
const expect = std.testing.expect;

const MEMORY_LEN = 4096;
const V_REGISTERS_LEN = 16;
const STACK_LEN = 16;

const DISPLAY_WIDTH = 32;
const DISPLAY_HEIGHT = 16;

const VxKK = struct { vx: u8, kk: u8 };
const VxVy = struct { vx: u8, vy: u8 };

const Instructions = union(enum) {
    CLS,
    SE_Vx_Byte: VxKK,
    SNE_Vx_Byte: VxKK,
    ADD_Vx_Byte: VxKK,
    ADD_Vx_Vy: VxVy,
    LD_Vx_Byte: VxKK,
    LD_Vx_Vy: VxVy,
    LD_I_Addr: u16,
    LD_Vx_DT: u8,
    LD_DT_Vx: u8,
    LD_ST_Vx: u8,
    LD_B_Vx: u8,
    LD_ArrI_Vx: u8,
    LD_Vx_ArrI: u8,
    UNKNOWN,

    pub fn decode(ins: u16) Instructions {
        const x: u8 = @truncate((ins & 0x0F00) >> 8);
        const y: u8 = @truncate((ins & 0x00F0) >> 4);
        const kk: u8 = @truncate(ins & 0x00FF);
        const nnn: u16 = ins & 0x0FFF;

        return switch (ins & 0xF000) {
            0x0000 => switch (ins) {
                0x00E0 => Instructions.CLS,
                else => Instructions.UNKNOWN,
            },
            0x3000 => Instructions{ .SE_Vx_Byte = .{ .vx = x, .kk = kk } },
            0x4000 => Instructions{ .SNE_Vx_Byte = .{ .vx = x, .kk = kk } },
            0x6000 => Instructions{ .LD_Vx_Byte = .{ .vx = x, .kk = kk } },
            0x7000 => Instructions{ .ADD_Vx_Byte = .{ .vx = x, .kk = kk } },
            0x8000 => switch (ins & 0xF00F) {
                0x8000 => Instructions{ .LD_Vx_Vy = .{ .vx = x, .vy = y } },
                0x8004 => Instructions{ .ADD_Vx_Vy = .{ .vx = x, .vy = y } },
                else => Instructions.UNKNOWN,
            },
            0xA000 => Instructions{ .LD_I_Addr = nnn },
            0xF000 => switch (ins & 0xF0FF) {
                0xF007 => Instructions{ .LD_Vx_DT = x },
                0xF015 => Instructions{ .LD_DT_Vx = x },
                0xF018 => Instructions{ .LD_ST_Vx = x },
                0xF033 => Instructions{ .LD_B_Vx = x },
                0xF055 => Instructions{ .LD_ArrI_Vx = x },
                0xF065 => Instructions{ .LD_Vx_ArrI = x },
                else => Instructions.UNKNOWN,
            },
            else => Instructions.UNKNOWN,
        };
    }
};

const System = struct {
    mem: [MEMORY_LEN]u8 = [_]u8{0} ** MEMORY_LEN,
    display: [DISPLAY_WIDTH * DISPLAY_HEIGHT]u8 = [_]u8{0} ** (DISPLAY_WIDTH * DISPLAY_HEIGHT),
    stack: [STACK_LEN]u16,
    font: [5 * 16]u8 = [_]u8{
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
    dt: u8 = 0,
    st: u8 = 0,

    pub fn load_program(self: *System, program: []const u16) void {
        for (program, 0..) |ins, idx| {
            var buf = [2]u8{ 0, 0 };
            const addr = 0x200 + idx * 2;
            std.mem.writeInt(u16, &buf, ins, .big);
            std.debug.print("loading instruction: {x:0>4}, idx={d}\n", .{ ins, idx });

            self.mem[addr] = buf[0];
            self.mem[addr + 1] = buf[1];
        }
    }

    pub fn tick(self: *System) void {
        // Fetch the instruction
        const ins_raw = std.mem.readInt(u16, self.mem[self.pc..][0..2], .big);
        std.debug.print("instruction: 0x{X:0>4}, pc=0x{X:0>4}\n", .{ ins_raw, self.pc });
        // Decode the instruction
        const ins = Instructions.decode(ins_raw);

        self.pc += 2;
        switch (ins) {
            Instructions.CLS => {
                @memset(self.display[0..], 0);
            },
            Instructions.SE_Vx_Byte => |i| {
                if (self.v[i.vx] == i.kk) {
                    self.pc += 2;
                }
            },
            Instructions.SNE_Vx_Byte => |i| {
                if (self.v[i.vx] != i.kk) {
                    self.pc += 2;
                }
            },
            Instructions.ADD_Vx_Byte => |i| {
                const res, _ = @addWithOverflow(self.v[i.vx], i.kk);
                self.v[i.vx] = res;
            },
            Instructions.LD_Vx_Byte => |i| {
                self.v[i.vx] = i.kk;
            },
            Instructions.LD_Vx_Vy => |i| {
                self.v[i.vx] = self.v[i.vy];
            },
            Instructions.ADD_Vx_Vy => |i| {
                const res, const carry = @addWithOverflow(self.v[i.vx], self.v[i.vy]);
                self.v[i.vx] = res;
                self.v[15] = carry;
            },
            Instructions.LD_I_Addr => |nnn| {
                self.i = nnn;
            },
            Instructions.LD_DT_Vx => |vx| {
                self.dt = self.v[vx];
            },
            Instructions.LD_Vx_DT => |vx| {
                self.v[vx] = self.dt;
            },
            Instructions.LD_ST_Vx => |vx| {
                self.st = self.v[vx];
            },
            Instructions.LD_B_Vx => |vx| {
                const v = self.v[vx];
                const bcd = [_]u8{ v / 100, (v / 10) % 10, v % 10 };
                @memcpy(self.mem[self.i .. self.i + 3], bcd[0..3]);
            },
            Instructions.LD_ArrI_Vx => |vx| {
                @memcpy(self.mem[self.i..], self.v[0..vx]);
            },
            Instructions.LD_Vx_ArrI => |vx| {
                @memcpy(self.v[0..vx], self.mem[self.i..]);
            },
            Instructions.UNKNOWN => {
                std.debug.print("Uknown instruction: 0x{X:0>4}\n", .{ins_raw});
            },
        }
    }
};

test "cls instruction clears display" {
    const program = [_]u16{
        0x00E0, // CLS
    };

    var sys = std.mem.zeroInit(System, .{});
    sys.load_program(program[0..]);

    @memset(sys.display[0..], 1);

    sys.tick();

    try expect(std.mem.allEqual(u8, sys.display[0..], 0));
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

    var sys = std.mem.zeroInit(System, .{});
    sys.load_program(program[0..]);

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

    var sys = std.mem.zeroInit(System, .{});
    sys.load_program(program[0..]);

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

    var sys = std.mem.zeroInit(System, .{});
    sys.load_program(program[0..]);

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
        0x00E0, // CLS
        0x00E0, // CLS
        0x00E0, // CLS
    };

    var sys = std.mem.zeroInit(System, .{});
    sys.load_program(program[0..]);

    for (0..program.len - 2) |_| {
        sys.tick();
    }

    try std.testing.expectEqual(0x00, sys.v[3]);
}

test "bit manipulation instructions" {}
