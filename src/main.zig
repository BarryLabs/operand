const std = @import("std");
const ray = @cImport({
    @cInclude("raylib.h");
});

const Button = struct {
    rect: ray.Rectangle,
    label: []const u8,
    value: u8,
};

const Operator = enum {
    none,
    add,
    sub,
    mul,
    div,
};

const CalcError = error{
    DivideByZero,
    Overflow,
};

var lhs: ?f64 = null;
var current_op: Operator = .none;
var current_input: [32]u8 = undefined;
var input_len: usize = 0;
var fresh_input: bool = true;
var display_buf: [64]u8 = undefined;
var display_len: usize = 0;

pub fn main() !void {
    const screenWidth = 320;
    const screenHeight = 480;

    ray.InitWindow(screenWidth, screenHeight, "Operand");
    defer ray.CloseWindow();
    ray.SetTargetFPS(60);

    const buttons = [_]Button{
        .{ .rect = .{ .x = 10, .y = 100, .width = 70, .height = 60 }, .label = "C", .value = 100 },
        .{ .rect = .{ .x = 90, .y = 100, .width = 70, .height = 60 }, .label = "+/-", .value = 108 },
        .{ .rect = .{ .x = 170, .y = 100, .width = 70, .height = 60 }, .label = "<-", .value = 107 },
        .{ .rect = .{ .x = 250, .y = 100, .width = 60, .height = 60 }, .label = "/", .value = 101 },

        .{ .rect = .{ .x = 10, .y = 170, .width = 70, .height = 60 }, .label = "7", .value = 7 },
        .{ .rect = .{ .x = 90, .y = 170, .width = 70, .height = 60 }, .label = "8", .value = 8 },
        .{ .rect = .{ .x = 170, .y = 170, .width = 70, .height = 60 }, .label = "9", .value = 9 },
        .{ .rect = .{ .x = 250, .y = 170, .width = 60, .height = 60 }, .label = "*", .value = 102 },

        .{ .rect = .{ .x = 10, .y = 240, .width = 70, .height = 60 }, .label = "4", .value = 4 },
        .{ .rect = .{ .x = 90, .y = 240, .width = 70, .height = 60 }, .label = "5", .value = 5 },
        .{ .rect = .{ .x = 170, .y = 240, .width = 70, .height = 60 }, .label = "6", .value = 6 },
        .{ .rect = .{ .x = 250, .y = 240, .width = 60, .height = 60 }, .label = "-", .value = 103 },

        .{ .rect = .{ .x = 10, .y = 310, .width = 70, .height = 60 }, .label = "1", .value = 1 },
        .{ .rect = .{ .x = 90, .y = 310, .width = 70, .height = 60 }, .label = "2", .value = 2 },
        .{ .rect = .{ .x = 170, .y = 310, .width = 70, .height = 60 }, .label = "3", .value = 3 },
        .{ .rect = .{ .x = 250, .y = 310, .width = 60, .height = 60 }, .label = "+", .value = 104 },

        .{ .rect = .{ .x = 10, .y = 380, .width = 150, .height = 60 }, .label = "0", .value = 0 },
        .{ .rect = .{ .x = 170, .y = 380, .width = 70, .height = 60 }, .label = ".", .value = 106 },
        .{ .rect = .{ .x = 250, .y = 380, .width = 60, .height = 60 }, .label = "=", .value = 105 },
    };

    current_input[0] = '0';
    current_input[1] = 0;
    input_len = 1;
    refreshDisplay();

    while (!ray.WindowShouldClose()) {
        handleKeyboardInput();
        if (ray.IsMouseButtonPressed(ray.MOUSE_LEFT_BUTTON)) {
            const mouse = ray.GetMousePosition();
            for (buttons) |btn| {
                if (ray.CheckCollisionPointRec(mouse, btn.rect)) {
                    handleButton(btn.value);
                }
            }
        }

        ray.BeginDrawing();
        defer ray.EndDrawing();
        ray.ClearBackground(ray.BLACK);

        ray.DrawRectangle(10, 10, 300, 80, ray.DARKGRAY);
        var font_size: i32 = 40;
        var text_width = ray.MeasureText(&display_buf[0], font_size);
        while (text_width > 280 and font_size > 20) {
            font_size -= 2;
            text_width = ray.MeasureText(&display_buf[0], font_size);
        }

        const draw_x = 300 - @min(text_width, 280) - 10;
        const draw_y = 50 - @divTrunc(font_size, 2);

        ray.DrawText(&display_buf[0], draw_x, draw_y, font_size, ray.WHITE);

        for (buttons) |btn| {
            const color = if (btn.value >= 100 and btn.value != 105) ray.ORANGE else if (btn.value == 105) ray.GREEN else ray.LIGHTGRAY;
            ray.DrawRectangleRec(btn.rect, color);
            ray.DrawRectangleLinesEx(btn.rect, 2, ray.DARKGRAY);

            const btn_font_size = 24;
            const text_w = ray.MeasureText(btn.label.ptr, btn_font_size);
            const text_x = @as(i32, @intFromFloat(btn.rect.x)) + @divTrunc(@as(i32, @intFromFloat(btn.rect.width)) - text_w, 2);
            const text_y = @as(i32, @intFromFloat(btn.rect.y)) + @divTrunc(@as(i32, @intFromFloat(btn.rect.height)) - btn_font_size, 2);
            ray.DrawText(btn.label.ptr, text_x, text_y, btn_font_size, ray.BLACK);
        }
    }
}

fn handleButton(value: u8) void {
    switch (value) {
        0...9 => {
            if (fresh_input) {
                input_len = 0;
                fresh_input = false;
            }
            if (input_len < current_input.len - 1) {
                if (input_len == 1 and current_input[0] == '0') {
                    input_len = 0;
                }
                current_input[input_len] = '0' + value;
                input_len += 1;
                current_input[input_len] = 0;
                refreshDisplay();
            }
        },
        100 => {
            lhs = null;
            current_op = .none;
            input_len = 1;
            current_input[0] = '0';
            current_input[1] = 0;
            fresh_input = true;
            refreshDisplay();
        },
        101...104 => {
            const new_op: Operator = switch (value) {
                101 => .div,
                102 => .mul,
                103 => .sub,
                104 => .add,
                else => unreachable,
            };

            const current_val = parseInput();

            if (lhs != null and !fresh_input) {
                const result = calculate(lhs.?, current_op, current_val) catch {
                    @memcpy(current_input[0..3], "Err");
                    input_len = 3;
                    current_input[3] = 0;
                    lhs = null;
                    current_op = .none;
                    fresh_input = true;
                    refreshDisplay();
                    return;
                };
                lhs = result;

                const res_str = formatFloatClean(current_input[0..], result) catch {
                    @memcpy(current_input[0..3], "Err");
                    input_len = 3;
                    current_input[3] = 0;
                    lhs = null;
                    current_op = .none;
                    fresh_input = true;
                    refreshDisplay();
                    return;
                };
                input_len = res_str.len;
                current_input[input_len] = 0;
            } else if (lhs == null) {
                lhs = current_val;
            }

            current_op = new_op;
            fresh_input = true;
            refreshDisplay();
        },
        105 => {
            if (lhs != null and current_op != .none and !fresh_input) {
                const rhs = parseInput();
                const result = calculate(lhs.?, current_op, rhs) catch {
                    @memcpy(current_input[0..3], "Err");
                    input_len = 3;
                    current_input[3] = 0;
                    lhs = null;
                    current_op = .none;
                    fresh_input = true;
                    refreshDisplay();
                    return;
                };

                const res_str = formatFloatClean(current_input[0..], result) catch {
                    @memcpy(current_input[0..3], "Err");
                    input_len = 3;
                    current_input[3] = 0;
                    lhs = null;
                    current_op = .none;
                    fresh_input = true;
                    refreshDisplay();
                    return;
                };
                input_len = res_str.len;
                current_input[input_len] = 0;

                lhs = null;
                current_op = .none;
                fresh_input = true;
                refreshDisplay();
            }
        },
        106 => {
            if (fresh_input) {
                input_len = 0;
                fresh_input = false;
                current_input[0] = '0';
                input_len = 1;
            }
            if (input_len < current_input.len - 1 and !hasDecimal()) {
                current_input[input_len] = '.';
                input_len += 1;
                current_input[input_len] = 0;
                refreshDisplay();
            }
        },
        107 => {
            handleBackspace();
        },
        108 => {
            if (input_len > 0) {
                const is_single_zero = (input_len == 1 and current_input[0] == '0');
                if (!is_single_zero) {
                    if (current_input[0] == '-') {
                        @memcpy(current_input[0 .. input_len - 1], current_input[1..input_len]);
                        input_len -= 1;
                    } else {
                        if (input_len < current_input.len - 1) {
                            var i = input_len;
                            while (i > 0) : (i -= 1) {
                                current_input[i] = current_input[i - 1];
                            }
                            current_input[0] = '-';
                            input_len += 1;
                        }
                    }
                    current_input[input_len] = 0;
                    refreshDisplay();
                }
            }
        },
        else => {},
    }
}

fn handleKeyboardInput() void {
    const shift = ray.IsKeyDown(ray.KEY_LEFT_SHIFT) or ray.IsKeyDown(ray.KEY_RIGHT_SHIFT);
    var handled = false;

    if (shift) {
        if (ray.IsKeyPressed(ray.KEY_EQUAL)) {
            handleButton(104);
            handled = true;
        } else if (ray.IsKeyPressed(ray.KEY_EIGHT)) {
            handleButton(102);
            handled = true;
        }
    }

    if (!handled) {
        const keys = [_]struct { key: c_int, val: u8 }{
            .{ .key = ray.KEY_ZERO, .val = 0 },  .{ .key = ray.KEY_KP_0, .val = 0 },
            .{ .key = ray.KEY_ONE, .val = 1 },   .{ .key = ray.KEY_KP_1, .val = 1 },
            .{ .key = ray.KEY_TWO, .val = 2 },   .{ .key = ray.KEY_KP_2, .val = 2 },
            .{ .key = ray.KEY_THREE, .val = 3 }, .{ .key = ray.KEY_KP_3, .val = 3 },
            .{ .key = ray.KEY_FOUR, .val = 4 },  .{ .key = ray.KEY_KP_4, .val = 4 },
            .{ .key = ray.KEY_FIVE, .val = 5 },  .{ .key = ray.KEY_KP_5, .val = 5 },
            .{ .key = ray.KEY_SIX, .val = 6 },   .{ .key = ray.KEY_KP_6, .val = 6 },
            .{ .key = ray.KEY_SEVEN, .val = 7 }, .{ .key = ray.KEY_KP_7, .val = 7 },
            .{ .key = ray.KEY_EIGHT, .val = 8 }, .{ .key = ray.KEY_KP_8, .val = 8 },
            .{ .key = ray.KEY_NINE, .val = 9 },  .{ .key = ray.KEY_KP_9, .val = 9 },
        };

        for (keys) |k| {
            if (shift and (k.key == ray.KEY_EIGHT or k.key == ray.KEY_EQUAL)) continue;

            if (ray.IsKeyPressed(k.key)) {
                handleButton(k.val);
            }
        }
    }

    if (ray.IsKeyPressed(ray.KEY_ESCAPE)) handleButton(100);
    if (ray.IsKeyPressed(ray.KEY_KP_DIVIDE)) handleButton(101);
    if (ray.IsKeyPressed(ray.KEY_MINUS)) handleButton(103);
    if (ray.IsKeyPressed(ray.KEY_KP_SUBTRACT)) handleButton(103);
    if (ray.IsKeyPressed(ray.KEY_KP_ADD)) handleButton(104);
    if (ray.IsKeyPressed(ray.KEY_ENTER)) handleButton(105);
    if (ray.IsKeyPressed(ray.KEY_KP_ENTER)) handleButton(105);
    if (ray.IsKeyPressed(ray.KEY_PERIOD)) handleButton(106);
    if (ray.IsKeyPressed(ray.KEY_KP_DECIMAL)) handleButton(106);
    if (ray.IsKeyPressed(ray.KEY_BACKSPACE)) handleBackspace();
}

fn handleBackspace() void {
    if (!fresh_input and input_len > 0) {
        input_len -= 1;
        if (input_len == 0) {
            current_input[0] = '0';
            input_len = 1;
        }
        current_input[input_len] = 0;
        refreshDisplay();
    }
}

fn calculate(a: f64, op: Operator, b: f64) CalcError!f64 {
    const value: f64 = switch (op) {
        .add => a + b,
        .sub => a - b,
        .mul => a * b,
        .div => if (b == 0) return error.DivideByZero else a / b,
        .none => b,
    };

    if (!std.math.isFinite(value)) return error.Overflow;

    return value;
}

fn parseInput() f64 {
    return std.fmt.parseFloat(f64, current_input[0..input_len]) catch 0;
}

fn hasDecimal() bool {
    for (current_input[0..input_len]) |c| {
        if (c == '.') return true;
    }
    return false;
}

fn refreshDisplay() void {
    current_input[input_len] = 0;

    if (lhs != null and current_op != .none) {
        const op_char: u8 = switch (current_op) {
            .add => '+',
            .sub => '-',
            .mul => '*',
            .div => '/',
            .none => ' ',
        };

        var lhs_buf: [32]u8 = undefined;
        const lhs_str = formatFloatClean(&lhs_buf, lhs.?) catch {
            display_buf[0..3].* = "Err".*;
            display_len = 3;
            display_buf[3] = 0;
            return;
        };

        if (fresh_input) {
            const slice = std.fmt.bufPrint(&display_buf, "{s} {c}", .{ lhs_str, op_char }) catch "Error";
            display_len = slice.len;
        } else {
            const slice = std.fmt.bufPrint(&display_buf, "{s} {c} {s}", .{ lhs_str, op_char, current_input[0..input_len] }) catch "Error";
            display_len = slice.len;
        }
    } else {
        @memcpy(display_buf[0..input_len], current_input[0..input_len]);
        display_len = input_len;
    }
    display_buf[display_len] = 0;
}

fn formatFloatClean(buf: []u8, value: f64) CalcError![]const u8 {
    if (!std.math.isFinite(value)) return error.Overflow;

    const formatted = std.fmt.bufPrint(buf, "{d:.10}", .{value}) catch std.fmt.bufPrint(buf, "{e:.6}", .{value}) catch return error.Overflow;

    if (std.mem.indexOfScalar(u8, formatted, '.')) |dot_idx| {
        var end = formatted.len;
        while (end > dot_idx + 1 and formatted[end - 1] == '0') {
            end -= 1;
        }
        if (end == dot_idx + 1) end = dot_idx;

        buf[end] = 0;
        return buf[0..end];
    }

    buf[formatted.len] = 0;
    return formatted;
}
