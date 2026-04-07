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

var current_input: [32]u8 = undefined;
var input_len: usize = 0;
var first_operand: f64 = 0;
var current_op: Operator = .none;
var should_clear = false;

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

        const text_width = ray.MeasureText(&current_input[0], 40);
        ray.DrawText(&current_input[0], 300 - text_width - 10, 30, 40, ray.WHITE);

        for (buttons) |btn| {
            const color = if (btn.value >= 100) ray.ORANGE else ray.LIGHTGRAY;
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
            if (should_clear) {
                input_len = 0;
                should_clear = false;
            }
            if (input_len < current_input.len - 1) {
                if (input_len == 1 and current_input[0] == '0') {
                    input_len = 0;
                }
                current_input[input_len] = '0' + value;
                input_len += 1;
                current_input[input_len] = 0;
            }
        },
        100 => {
            input_len = 1;
            current_input[0] = '0';
            current_input[1] = 0;
            first_operand = 0;
            current_op = .none;
        },
        101...104 => {
            first_operand = parseInput();
            current_op = switch (value) {
                101 => .div,
                102 => .mul,
                103 => .sub,
                104 => .add,
                else => unreachable,
            };
            should_clear = true;
        },
        105 => {
            const second = parseInput();
            const result = switch (current_op) {
                .add => first_operand + second,
                .sub => first_operand - second,
                .mul => first_operand * second,
                .div => if (second != 0) first_operand / second else 0,
                .none => second,
            };

            var buf: [32]u8 = undefined;
            const result_str = std.fmt.bufPrint(&buf, "{d}", .{result}) catch "Error";

            if (result_str.len < current_input.len) {
                @memcpy(current_input[0..result_str.len], result_str);
                input_len = result_str.len;
                current_input[input_len] = 0;
            }
            current_op = .none;
        },
        106 => {
            if (should_clear) {
                input_len = 0;
                should_clear = false;
            }
            if (input_len < current_input.len - 1 and !hasDecimal()) {
                if (input_len == 0) {
                    current_input[0] = '0';
                    input_len = 1;
                }
                current_input[input_len] = '.';
                input_len += 1;
                current_input[input_len] = 0;
            }
        },
        else => {},
    }
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
