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
        .{ .rect = .{ .x = 90, .y = 100, .width = 70, .height = 60 }, .label = "/", .value = 101 },
        .{ .rect = .{ .x = 170, .y = 100, .width = 70, .height = 60 }, .label = "*", .value = 102 },
        .{ .rect = .{ .x = 250, .y = 100, .width = 60, .height = 60 }, .label = "-", .value = 103 },
        .{ .rect = .{ .x = 10, .y = 170, .width = 70, .height = 60 }, .label = "7", .value = 7 },
        .{ .rect = .{ .x = 90, .y = 170, .width = 70, .height = 60 }, .label = "8", .value = 8 },
        .{ .rect = .{ .x = 170, .y = 170, .width = 70, .height = 60 }, .label = "9", .value = 9 },
        .{ .rect = .{ .x = 250, .y = 170, .width = 60, .height = 130 }, .label = "+", .value = 104 },
        .{ .rect = .{ .x = 10, .y = 240, .width = 70, .height = 60 }, .label = "4", .value = 4 },
        .{ .rect = .{ .x = 90, .y = 240, .width = 70, .height = 60 }, .label = "5", .value = 5 },
        .{ .rect = .{ .x = 170, .y = 240, .width = 70, .height = 60 }, .label = "6", .value = 6 },
        .{ .rect = .{ .x = 10, .y = 310, .width = 70, .height = 60 }, .label = "1", .value = 1 },
        .{ .rect = .{ .x = 90, .y = 310, .width = 70, .height = 60 }, .label = "2", .value = 2 },
        .{ .rect = .{ .x = 170, .y = 310, .width = 70, .height = 60 }, .label = "3", .value = 3 },
        .{ .rect = .{ .x = 250, .y = 310, .width = 60, .height = 130 }, .label = "=", .value = 105 },
        .{ .rect = .{ .x = 10, .y = 380, .width = 150, .height = 60 }, .label = "0", .value = 0 },
        .{ .rect = .{ .x = 170, .y = 380, .width = 70, .height = 60 }, .label = ".", .value = 106 },
    };

    current_input[0] = '0';
    current_input[1] = 0;
    input_len = 1;
    refreshDisplay();

    while (!ray.WindowShouldClose()) {
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
        const text_width = ray.MeasureText(&display_buf[0], 40);
        const clamped_width = @min(text_width, 280);
        ray.DrawText(&display_buf[0], 300 - clamped_width - 10, 30, 40, ray.WHITE);

        for (buttons) |btn| {
            const color = if (btn.value >= 100 and btn.value != 105) ray.ORANGE else if (btn.value == 105) ray.GREEN else ray.LIGHTGRAY;
            ray.DrawRectangleRec(btn.rect, color);
            ray.DrawRectangleLinesEx(btn.rect, 2, ray.DARKGRAY);

            const font_size = 30;
            const text_w = ray.MeasureText(btn.label.ptr, font_size);
            const text_x = @as(i32, @intFromFloat(btn.rect.x)) + @divTrunc(@as(i32, @intFromFloat(btn.rect.width)) - text_w, 2);
            const text_y = @as(i32, @intFromFloat(btn.rect.y)) + @divTrunc(@as(i32, @intFromFloat(btn.rect.height)) - font_size, 2);
            ray.DrawText(btn.label.ptr, text_x, text_y, font_size, ray.BLACK);
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
                const result = calculate(lhs.?, current_op, current_val);
                lhs = result;
                const res_str = std.fmt.bufPrint(current_input[0..], "{d}", .{result}) catch "Error";
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
                const result = calculate(lhs.?, current_op, rhs);

                const res_str = std.fmt.bufPrint(current_input[0..], "{d}", .{result}) catch "Error";
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
        else => {},
    }
}

fn calculate(a: f64, op: Operator, b: f64) f64 {
    return switch (op) {
        .add => a + b,
        .sub => a - b,
        .mul => a * b,
        .div => if (b != 0) a / b else 0,
        .none => b,
    };
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

        if (fresh_input) {
            const slice = std.fmt.bufPrint(&display_buf, "{d} {c}", .{ lhs.?, op_char }) catch "Error";
            display_len = slice.len;
        } else {
            const slice = std.fmt.bufPrint(&display_buf, "{d} {c} {s}", .{ lhs.?, op_char, current_input[0..input_len] }) catch "Error";
            display_len = slice.len;
        }
    } else {
        @memcpy(display_buf[0..input_len], current_input[0..input_len]);
        display_len = input_len;
    }
    display_buf[display_len] = 0;
}
