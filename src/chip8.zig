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
    SYS: u8,
    CLS,
    RET,
    JP: u8,
    CALL: u8,
    ADD_Vx_Byte: VxKK,
    ADD_Vx_Vy: VxVy,
    LD_Vx_Byte: VxKK,
    LD_Vx_Vy: VxVy,
    SE_Vx_Byte,
    UNKNOWN,
};

const System = struct {
    const Self = @This();

    mem: [MEMORY_LEN]u8 = [_]u8{0} ** MEMORY_LEN,
    display: [DISPLAY_WIDTH * DISPLAY_HEIGHT]u8 = [_]u8{0} ** (DISPLAY_WIDTH * DISPLAY_HEIGHT),
    stack: [STACK_LEN]u16,

    // Registers
    v: [V_REGISTERS_LEN]u8,
    pc: u16 = 0x200,
    i: u16 = 0,
    dt: u8 = 0,
    st: u8 = 0,

    pub fn load_program(self: *Self, program: []const u16) void {
        for (program, 0..) |ins, idx| {
            var buf = [2]u8{ 0, 0 };
            const addr = 0x200 + idx * 2;
            std.mem.writeInt(u16, &buf, ins, .big);
            std.debug.print("loading instruction: {x:0>4}, idx={d}\n", .{ ins, idx });

            self.mem[addr] = buf[0];
            self.mem[addr + 1] = buf[1];
        }
    }

    pub fn decode(ins: u16) Instructions {
        const x: u8 = @truncate((ins & 0x0F00) >> 8);
        const y: u8 = @truncate((ins & 0x00F0) >> 4);
        const kk: u8 = @truncate(ins & 0x00FF);

        return switch (ins & 0xF000) {
            0x0000 => switch (ins) {
                0x00E0 => Instructions.CLS,
                else => Instructions.UNKNOWN,
            },
            0x6000 => Instructions{ .LD_Vx_Byte = .{ .vx = x, .kk = kk } },
            0x7000 => Instructions{ .ADD_Vx_Byte = .{ .vx = x, .kk = kk } },
            0x8000 => switch (ins & 0xF00F) {
                0x8000 => Instructions{ .LD_Vx_Vy = .{ .vx = x, .vy = y } },
                0x8004 => Instructions{ .ADD_Vx_Vy = .{ .vx = x, .vy = y } },
                else => Instructions.UNKNOWN,
            },
            else => Instructions.UNKNOWN,
        };
    }

    pub fn tick(self: *Self) void {
        // Fetch the instruction
        const ins_raw = std.mem.readInt(u16, self.mem[self.pc..][0..2], .big);
        std.debug.print("instruction: 0x{X:0>4}, pc=0x{X:0>4}\n", .{ ins_raw, self.pc });
        // Decode the instruction
        const ins = Self.decode(ins_raw);

        switch (ins) {
            Instructions.CLS => {
                @memset(self.display[0..], 0);
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
            else => {
                std.debug.print("Uknown instruction: 0x{X:0>4}\n", .{ins_raw});
            },
        }

        self.pc += 2;
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

test "load instructions" {
    const program = [_]u16{
        0x60FF, // LD V0, 0xFF
        0x8100, // LD V1, V0
    };

    var sys = std.mem.zeroInit(System, .{});
    sys.load_program(program[0..]);

    for (program) |_| {
        sys.tick();
    }

    try expect(sys.v[0] == 0xFF);
    try expect(sys.v[1] == 0xFF);
}

test "bit manipulation instructions" {}
