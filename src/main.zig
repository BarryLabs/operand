//! Operand - A simple calculator (Zig and Raylib)

const std = @import("std");
const ray = @cImport({
    @cInclude("raylib.h");
});

/// Color Scheme Configuration
const Theme = struct {
    name: []const u8,

    background: ray.Color,
    display_bg: ray.Color,
    display_text: ray.Color,

    button_number: ray.Color,
    button_number_text: ray.Color,
    button_operator: ray.Color,
    button_operator_text: ray.Color,
    button_equals: ray.Color,
    button_equals_text: ray.Color,
    button_border: ray.Color,
};

/// Available Themes
const themes = [_]Theme{
    .{
        .name = "Default",
        .background = ray.BLACK,
        .display_bg = ray.DARKGRAY,
        .display_text = ray.WHITE,
        .button_number = ray.LIGHTGRAY,
        .button_number_text = ray.BLACK,
        .button_operator = ray.ORANGE,
        .button_operator_text = ray.BLACK,
        .button_equals = ray.GREEN,
        .button_equals_text = ray.BLACK,
        .button_border = ray.DARKGRAY,
    },
    .{
        .name = "OLED Night",
        .background = .{ .r = 0, .g = 0, .b = 0, .a = 255 },
        .display_bg = .{ .r = 15, .g = 15, .b = 20, .a = 255 },
        .display_text = .{ .r = 0, .g = 255, .b = 128, .a = 255 },
        .button_number = .{ .r = 30, .g = 30, .b = 35, .a = 255 },
        .button_number_text = ray.WHITE,
        .button_operator = .{ .r = 40, .g = 30, .b = 10, .a = 255 },
        .button_operator_text = .{ .r = 255, .g = 200, .b = 100, .a = 255 },
        .button_equals = .{ .r = 0, .g = 100, .b = 50, .a = 255 },
        .button_equals_text = ray.WHITE,
        .button_border = .{ .r = 50, .g = 50, .b = 55, .a = 255 },
    },
    .{
        .name = "Paper",
        .background = .{ .r = 235, .g = 235, .b = 240, .a = 255 },
        .display_bg = ray.WHITE,
        .display_text = ray.BLACK,
        .button_number = ray.WHITE,
        .button_number_text = ray.BLACK,
        .button_operator = .{ .r = 255, .g = 149, .b = 0, .a = 255 },
        .button_operator_text = ray.BLACK,
        .button_equals = .{ .r = 76, .g = 175, .b = 80, .a = 255 },
        .button_equals_text = ray.WHITE,
        .button_border = ray.GRAY,
    },
    .{
        .name = "High Contrast",
        .background = ray.BLACK,
        .display_bg = ray.BLACK,
        .display_text = ray.YELLOW,
        .button_number = ray.WHITE,
        .button_number_text = ray.BLACK,
        .button_operator = ray.YELLOW,
        .button_operator_text = ray.BLACK,
        .button_equals = ray.GREEN,
        .button_equals_text = ray.BLACK,
        .button_border = ray.WHITE,
    },
    .{
        .name = "Catppuccin",
        .background = .{ .r = 30, .g = 30, .b = 46, .a = 255 },
        .display_bg = .{ .r = 49, .g = 50, .b = 68, .a = 255 },
        .display_text = .{ .r = 205, .g = 214, .b = 244, .a = 255 },
        .button_number = .{ .r = 69, .g = 71, .b = 90, .a = 255 },
        .button_number_text = .{ .r = 205, .g = 214, .b = 244, .a = 255 },
        .button_operator = .{ .r = 250, .g = 179, .b = 135, .a = 255 },
        .button_operator_text = .{ .r = 30, .g = 30, .b = 46, .a = 255 },
        .button_equals = .{ .r = 166, .g = 227, .b = 161, .a = 255 },
        .button_equals_text = .{ .r = 30, .g = 30, .b = 46, .a = 255 },
        .button_border = .{ .r = 108, .g = 112, .b = 134, .a = 255 },
    },
    .{
        .name = "Tokyo Night",
        .background = .{ .r = 26, .g = 27, .b = 38, .a = 255 },
        .display_bg = .{ .r = 36, .g = 40, .b = 59, .a = 255 },
        .display_text = .{ .r = 169, .g = 177, .b = 214, .a = 255 },
        .button_number = .{ .r = 65, .g = 72, .b = 104, .a = 255 },
        .button_number_text = .{ .r = 192, .g = 202, .b = 245, .a = 255 },
        .button_operator = .{ .r = 255, .g = 158, .b = 100, .a = 255 },
        .button_operator_text = .{ .r = 26, .g = 27, .b = 38, .a = 255 },
        .button_equals = .{ .r = 122, .g = 162, .b = 247, .a = 255 },
        .button_equals_text = .{ .r = 26, .g = 27, .b = 38, .a = 255 },
        .button_border = .{ .r = 86, .g = 95, .b = 137, .a = 255 },
    },
    .{
        .name = "Cyberpunk",
        .background = .{ .r = 13, .g = 2, .b = 33, .a = 255 },
        .display_bg = .{ .r = 26, .g = 11, .b = 46, .a = 255 },
        .display_text = .{ .r = 0, .g = 240, .b = 255, .a = 255 },
        .button_number = .{ .r = 26, .g = 11, .b = 46, .a = 255 },
        .button_number_text = .{ .r = 0, .g = 240, .b = 255, .a = 255 },
        .button_operator = .{ .r = 255, .g = 0, .b = 255, .a = 255 },
        .button_operator_text = .{ .r = 255, .g = 255, .b = 255, .a = 255 },
        .button_equals = .{ .r = 252, .g = 238, .b = 10, .a = 255 },
        .button_equals_text = .{ .r = 13, .g = 2, .b = 33, .a = 255 },
        .button_border = .{ .r = 0, .g = 240, .b = 255, .a = 255 },
    },
};

var current_theme_idx: usize = 0;
var theme: *const Theme = &themes[0];

fn cycleTheme() void {
    current_theme_idx = (current_theme_idx + 1) % themes.len;
    theme = &themes[current_theme_idx];
    std.debug.print("Theme: {s}\n", .{theme.name});
}

/// Calculator button definition with position, label and internal value
const Button = struct {
    rect: ray.Rectangle,
    label: []const u8,
    value: u8,
};

/// Supported Operations
const Operator = enum {
    none,
    add,
    sub,
    mul,
    div,
};

/// Calculation errors
const CalcError = error{
    DivideByZero,
    Overflow,
};

/// Calculator State
var fresh_input: bool = true;
var lhs: ?f64 = null;
var current_op: Operator = .none;
var current_input: [32]u8 = undefined;
var input_len: usize = 0;
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
        ray.ClearBackground(theme.background);

        ray.DrawRectangle(10, 10, 300, 80, theme.display_bg);
        var font_size: i32 = 40;
        var text_width = ray.MeasureText(&display_buf[0], font_size);
        while (text_width > 280 and font_size > 20) {
            font_size -= 2;
            text_width = ray.MeasureText(&display_buf[0], font_size);
        }

        const draw_x = 300 - @min(text_width, 280) - 10;
        const draw_y = 50 - @divTrunc(font_size, 2);
        ray.DrawText(&display_buf[0], draw_x, draw_y, font_size, theme.display_text);

        for (buttons) |btn| {
            const color_pair = if (btn.value >= 100 and btn.value != 105)
                .{ theme.button_operator, theme.button_operator_text }
            else if (btn.value == 105)
                .{ theme.button_equals, theme.button_equals_text }
            else
                .{ theme.button_number, theme.button_number_text };

            const bg_color = color_pair[0];
            const text_color = color_pair[1];

            ray.DrawRectangleRec(btn.rect, bg_color);
            ray.DrawRectangleLinesEx(btn.rect, 2, theme.button_border);

            const btn_font_size = 24;
            const text_w = ray.MeasureText(btn.label.ptr, btn_font_size);
            const text_x = @as(i32, @intFromFloat(btn.rect.x)) + @divTrunc(@as(i32, @intFromFloat(btn.rect.width)) - text_w, 2);
            const text_y = @as(i32, @intFromFloat(btn.rect.y)) + @divTrunc(@as(i32, @intFromFloat(btn.rect.height)) - btn_font_size, 2);
            ray.DrawText(btn.label.ptr, text_x, text_y, btn_font_size, text_color);
        }
    }
}

/// Process Button Press by Value
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
                    setError();
                    return;
                };
                lhs = result;

                const res_str = formatFloatClean(current_input[0..], result) catch {
                    setError();
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
                    setError();
                    return;
                };

                const res_str = formatFloatClean(current_input[0..], result) catch {
                    setError();
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
        107 => handleBackspace(),
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

/// Handle Keyboard Shortcuts and Numpad Input
fn handleKeyboardInput() void {
    if (ray.IsKeyPressed(ray.KEY_F5)) {
        cycleTheme();
    }

    const ctrl = ray.IsKeyDown(ray.KEY_LEFT_CONTROL) or ray.IsKeyDown(ray.KEY_RIGHT_CONTROL);
    if (ctrl) {
        if (ray.IsKeyPressed(ray.KEY_C)) {
            ray.SetClipboardText(&display_buf[0]);
            return;
        }

        if (ray.IsKeyPressed(ray.KEY_V)) {
            const clip = ray.GetClipboardText();
            if (clip != null) {
                const text = std.mem.span(clip);
                if (text.len > 0) {
                    handlePaste(text);
                }
            }
            return;
        }
    }

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
    if (ray.IsKeyPressed(ray.KEY_SLASH)) handleButton(101);
    if (ray.IsKeyPressed(ray.KEY_KP_DIVIDE)) handleButton(101);
    if (ray.IsKeyPressed(ray.KEY_MINUS)) handleButton(103);
    if (ray.IsKeyPressed(ray.KEY_KP_SUBTRACT)) handleButton(103);
    if (ray.IsKeyPressed(ray.KEY_KP_ADD)) handleButton(104);
    if (ray.IsKeyPressed(ray.KEY_ENTER)) handleButton(105);
    if (ray.IsKeyPressed(ray.KEY_KP_ENTER)) handleButton(105);
    if (ray.IsKeyPressed(ray.KEY_EQUAL)) handleButton(105);
    if (ray.IsKeyPressed(ray.KEY_KP_EQUAL)) handleButton(105);
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

/// Perform One-Step Calculation
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

/// Helper to Set Error State
fn setError() void {
    @memcpy(current_input[0..3], "Err");
    input_len = 3;
    current_input[3] = 0;
    lhs = null;
    current_op = .none;
    fresh_input = true;
    refreshDisplay();
}

/// Update Display Buffer
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

/// Format Floating Numbers
fn formatFloatClean(buf: []u8, value: f64) CalcError![]const u8 {
    if (!std.math.isFinite(value)) return error.Overflow;

    const formatted = std.fmt.bufPrint(buf, "{d:.10}", .{value}) catch
        std.fmt.bufPrint(buf, "{e:.6}", .{value}) catch return error.Overflow;

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

/// Handle Clipboard Pasting
fn handlePaste(text: []const u8) void {
    if (text.len == 0) return;

    if (fresh_input) {
        input_len = 0;
        fresh_input = false;
    }

    for (text) |c| {
        if (input_len >= current_input.len - 1) break;

        switch (c) {
            '0'...'9' => {
                if (input_len == 1 and current_input[0] == '0') {
                    input_len = 0;
                }
                current_input[input_len] = c;
                input_len += 1;
            },
            '.' => {
                if (!hasDecimal()) {
                    if (input_len == 0) {
                        current_input[0] = '0';
                        input_len = 1;
                    }
                    current_input[input_len] = '.';
                    input_len += 1;
                }
            },
            '-' => {
                if (input_len == 0) {
                    current_input[0] = '-';
                    input_len = 1;
                }
            },
            else => {},
        }
    }

    current_input[input_len] = 0;
    refreshDisplay();
}

test "calculations" {
    try std.testing.expectEqual(@as(f64, 5.0), try calculate(2.0, .add, 3.0));
    try std.testing.expectEqual(@as(f64, 2.0), try calculate(5.0, .sub, 3.0));
    try std.testing.expectEqual(@as(f64, 6.0), try calculate(2.0, .mul, 3.0));
    try std.testing.expectEqual(@as(f64, 2.5), try calculate(5.0, .div, 2.0));
}

test "divide by zero" {
    const result = calculate(5.0, .div, 0.0);
    try std.testing.expectError(error.DivideByZero, result);
}

test "formatFloatClean function" {
    var buf: [64]u8 = undefined;

    const result = try formatFloatClean(&buf, 5.0);
    try std.testing.expectEqualStrings("5", result);

    const result2 = try formatFloatClean(&buf, 1.5);
    try std.testing.expectEqualStrings("1.5", result2);
}

test "multiplication overflow" {
    const inf = std.math.inf(f64);
    const result = calculate(1.0, .mul, inf);
    try std.testing.expectError(error.Overflow, result);
}

test "display clearing upon calculation" {
    lhs = 5.0;
    current_op = .add;
    @memcpy(current_input[0..1], "3");
    input_len = 1;
    fresh_input = true;

    handleButton(2);
    try std.testing.expectEqualStrings("2", current_input[0..input_len]);
}

test "paste" {
    input_len = 0;
    fresh_input = true;
    current_input = undefined;

    handlePaste("123.45");

    try std.testing.expectEqual(@as(usize, 6), input_len);
    try std.testing.expectEqualStrings("123.45", current_input[0..input_len]);
}
