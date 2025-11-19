const std = @import("std");
const rl = @import("raylib");
const assert = std.debug.assert;
const cnst = @import("constants.zig");
const TypedState = @import("common_enums.zig").TypedState;
const unicode = std.unicode;

var exer_buff_arr: [cnst.max_characters_test * 8]u8 = undefined;
var exer_buff = std.heap.FixedBufferAllocator.init(&exer_buff_arr);
var typed_buff_arr: [cnst.max_characters_test * 8]u8 = undefined;
var typed_buff = std.heap.FixedBufferAllocator.init(&typed_buff_arr);

var typed_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
var symbol_stats_da = std.heap.DebugAllocator(.{}).init;
var symbol_stats_allocator = symbol_stats_da.allocator();

var sml: [cnst.char_len][cnst.char_len]u32 = [_][cnst.char_len]u32{[_]u32{2} ** cnst.char_len} ** cnst.char_len;
const font_size = 32;
const font_path = "./resources/NotoSansSymbols-VariableFont_wght.ttf";

const StateType = enum {
    load,
    exercise_init,
    exercise,
    exercise_finalyze,
    stats,
};

pub const State = struct {
    state: StateType = .exercise_init,
    smbls: [10]i32,

    pub fn init(state: StateType) State {
        std.debug.print("started init\n", .{});
        var chars: [cnst.chars.len]i32 = undefined;
        @memcpy(chars[0..], cnst.chars[0..]);
        const font = rl.loadFontEx(font_path, font_size, chars[0..]) catch unreachable;
        // for (sml, 0..) |s, i| {
        //     for (s, 0..) |_, j| {
        //         sml[i][j] = 0;
        //     }
        // }
        for (cnst.chars, 0..) |chi, i| {
            for (cnst.chars, 0..) |chj, j| {
                var res: u32 = 0;
                const gli = rl.getGlyphInfo(font, chi);
                const glj = rl.getGlyphInfo(font, chj);
                if (gli.value == 0x2013) break;
                if (glj.value == 0x2013) continue;
                var imgi = rl.imageCopy(gli.image);
                var imgj = rl.imageCopy(glj.image);
                rl.imageResize(&imgi, font_size, font_size);
                rl.imageResize(&imgj, font_size, font_size);
                var ii: usize = 0;
                while (ii < imgi.width) {
                    var jj: usize = 0;
                    while (jj < imgi.height) {
                        const ci = rl.getImageColor(imgi, @intCast(ii), @intCast(jj));
                        const cj = rl.getImageColor(imgj, @intCast(ii), @intCast(jj));
                        const b: f64 = @floatFromInt(if (ci.a > cj.a) ci.a - cj.a else cj.a - ci.a);
                        res += @intFromFloat(@sqrt(b * b));
                        jj += 1;
                    }
                    ii += 1;
                }
                if (i % 10 == 0 and j % 1000 == 0) {
                    std.debug.print("symbol#{d}:{d}\n", .{ i, j });
                }
                // if (res != 0) {
                //     std.debug.print("symbol#{d}:{d} res {d}\n", .{ i, j, res });
                // }
                sml[i][j] = res;
                sml[j][i] = res;
            }
        }

        return State{
            .state = state,
            .smbls = [_]i32{0} ** 10,
        };
    }

    fn getDiff(i: usize, j: usize) u32 {
        return sml[i][j];
    }

    pub fn getNextSml(self: *State, chrs: []i32) i32 {
        var chars: [cnst.chars.len]i32 = undefined;
        @memcpy(chars[0..], cnst.chars[0..]);
        const font = rl.loadFontEx(font_path, font_size, chars[0..]) catch unreachable;
        std.debug.print("get next sml {any}\n", .{chrs});
        _ = self;
        var diff: u32 = 0;
        var newdiff: u32 = 0;
        var newSmbN: usize = undefined;
        jlab: for (sml, 0..) |_, j| {
            const gl = rl.getGlyphInfo(font, cnst.chars[j]);
            if (gl.value == 0x2013) continue;
            newdiff = 0;
            for (chrs) |c| {
                var i: usize = 0;
                for (cnst.chars, 0..) |cc, ii| {
                    if (cc == c) {
                        i = ii;
                        break;
                    }
                }
                if (i == j) continue :jlab;
                if (c != cnst.chars[i]) unreachable;
                // std.debug.print("i == {d}, j=={d} diff={d}\n", .{ i, j, sml[i][j] });
                // std.debug.print("diffArray {any}\n", .{sml[i][0..1000]});
                newdiff += sml[i][j];
            }
            if (newdiff == 0) continue;
            if (newdiff > diff) {
                diff = newdiff;
                newSmbN = j;
            }
        }
        return cnst.chars[newSmbN];
    }
};
