const std = @import("std");
const rl = @import("raylib");
const cnst = @import("../constants.zig");
const State = @import("../state.zig").State;
// const TextDrawer = @import("text-drawer.zig").TextDrawer;
// const StatDrawer = @import("stat-drawer.zig").StatDrawer;
var ch_buff_arr: [17]u8 = undefined;
var ch_buffer = std.heap.FixedBufferAllocator.init(&ch_buff_arr);

var logp: bool = false;

pub const Drawer = struct {
    const font_path = "./resources/NotoSansSymbols-VariableFont_wght.ttf";
    const font_size = 64;
    state: *State,
    font: rl.Font,
    ch_size: rl.Vector2,

    pub fn init(state: *State) Drawer {
        var chars: [cnst.chars.len]i32 = undefined;
        @memcpy(chars[0..], cnst.chars[0..]);
        const font = rl.loadFontEx(font_path, font_size, chars[0..]) catch unreachable;
        // rl.setTextureFilter(font.texture, .trilinear);
        const ch_size = rl.measureTextEx(font, "a", font_size, 1);

        return Drawer{
            .state = state,
            .font = font,
            .ch_size = ch_size,
            // .text_drawer = TextDrawer.init(state),
            // .stat_drawer = StatDrawer.init(state),
        };
    }

    pub fn draw(self: Drawer) void {
        switch (self.state.state) {
            .exercise => {
                rl.setTargetFPS(0);
                rl.enableEventWaiting();
            },
            else => {
                rl.setTargetFPS(120);
                rl.disableEventWaiting();
            },
        }
        rl.clearBackground(cnst.background_color);
        self.state.smbls[0] = cnst.chars[405];
        for (self.state.smbls, 0..) |_, i| {
            if (i == 0) continue;
            std.debug.print("symbols {any}\n", .{self.state.smbls});
            const newSmbl = self.state.getNextSml(self.state.smbls[0..i]);
            self.state.smbls[i] = newSmbl;
        }
        for (self.state.smbls, 0..) |ch, i| {
            var text: [4]u8 = undefined;
            const n = std.unicode.utf8Encode(@intCast(ch), &text) catch unreachable;
            ch_buffer.reset();
            const t = std.mem.Allocator.dupeZ(ch_buffer.allocator(), u8, text[0..n]) catch unreachable;
            const point = rl.Vector2.init(10 + @as(f32, @floatFromInt(i * font_size)), 2);
            const color = cnst.text_color;
            rl.drawTextEx(self.font, t, point, font_size, 1, color);
        }
    }
};
