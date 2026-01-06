const CSSColor = @import("./CanvasRenderingContext.zig").CSSColor;

fn rgba(r: i32, g: i32, b: i32, a: f32) CSSColor {
    return CSSColor(r, g, b, a);
}

fn rgb(r: i32, g: i32, b: i32) CSSColor {
    return CSSColor(r, g, b, 1.0);
}

