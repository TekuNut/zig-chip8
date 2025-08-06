const std = @import("std");
const expect = std.testing.expect;

const MEMORY_LEN = 4096;
const V_REGISTERS_LEN = 16;
const STACK_LEN = 16;

const DISPLAY_WIDTH = 32;
const DISPLAY_HEIGHT = 16;

const Instructions = union(enum) {
    SYS: u8,
    CLS: void,
    RET: void,
    JP: u8,
    CALL: u8,
    SE_Vx_Byte: void,
};

const System = struct {
    const Self = @This();

    mem: [MEMORY_LEN]u8,
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

    pub fn tick(self: *Self) void {
        // Fetch the instruction
        const ins_raw = std.mem.readInt(u16, self.mem[self.pc..][0..2], .big);
        std.debug.print("instruction: 0x{X:0>4}, pc=0x{X:0>4}\n", .{ ins_raw, self.pc });
        // Decode the instruction
        // TODO
        //

        // Execute the instruction.
        if (ins_raw == 0x00E0) {
            @memset(self.display[0..], 0);
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
