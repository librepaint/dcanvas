
// import '../Canvas.dart';
const Canvas = @import("../Canvas.zig").Canvas;

const vexlib = @import("../lib/vexlib.zig");
const String = vexlib.String;

pub const cairo = @cImport({
    @cInclude("cairo/cairo.h");
});
const cairo_surface_t = cairo.cairo_surface_t;
const cairo_t = cairo.cairo_t;
const cairo_path_t = cairo.cairo_path_t;
const cairo_pattern_t = cairo.cairo_pattern_t;
const cairo_matrix_t = cairo.cairo_matrix_t;
const cairo_user_data_key_t = cairo.cairo_user_data_key_t;
const cairo_pattern_type = cairo.cairo_pattern_type;
const cairo_extend = cairo.cairo_extend;
const cairo_filter = cairo.cairo_filter;
const cairo_operator = cairo.cairo_operator;
const cairo_line_cap = cairo.cairo_line_cap;
const cairo_line_join = cairo.cairo_line_join;
const cairo_status = cairo.cairo_status_t;
const cairo_pattern_type_t = i32;
const cairo_format = cairo.cairo_format_t;


const pango = @cImport({
    @cInclude("pango-1.0/pango.h");
});
const PangoLib = pango.PangoLib;
const PangoFontDescription = pango.PangoFontDescription;
const PANGO_SCALE = pango.PANGO_SCALE;
const PangoLayout = pango.PangoLayout;
const PangoStyle = pango.PangoStyle;
const PangoWeight = pango.PangoWeight;
const PangoRectangle = pango.PangoRectangle;
const PangoFontMetrics = pango.PangoFontMetrics;

const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
});
const SDL_Window = sdl.SDL_Window;
const SDL_Renderer = sdl.SDL_Renderer;
const SDL_Surface = sdl.SDL_Surface;
const SDL_WINDOWPOS_UNDEFINED = sdl.SDL_WINDOWPOS_UNDEFINED;
const SDL_WindowFlags = sdl.SDL_WindowFlags;
const SDL_RendererFlags = sdl.SDL_RendererFlags;
const SDL_EventType = sdl.SDL_EventType;
const SDL_Event = sdl.SDL_Event;
const SDL_INIT_EVERYTHING = sdl.SDL_INIT_EVERYTHING;
const SDL_BUTTON_LEFT = sdl.SDL_BUTTON_LEFT;
const SDL_BUTTON_MIDDLE = sdl.SDL_BUTTON_MIDDLE;
const SDL_BUTTON_RIGHT = sdl.SDL_BUTTON_RIGHT;

const Backend = struct {
    name: String = "image",
    // String error = "NULL";

    width: i32 = undefined,
    height: i32 = undefined,
    surface: *cairo_surface_t = null,
    canvas: ?Canvas = null,
    format: cairo_format = DEFAULT_FORMAT,

    const DEFAULT_FORMAT: cairo_format = cairo_format.CAIRO_FORMAT_ARGB32;

    fn init(_width: i32, _height: i32) Backend {
        const out = Backend{
            .width = _width,
            .height = _height
        };
        return out;
    }

    fn approxBytesPerPixel(self: *Backend) i32 {
        return switch (self.format) {
            cairo_format.CAIRO_FORMAT_ARGB32, cairo_format.CAIRO_FORMAT_RGB24 => 4,
            cairo_format.CAIRO_FORMAT_RGB16_565 => 2,
            cairo_format.CAIRO_FORMAT_A8, cairo_format.CAIRO_FORMAT_A1 => 1,
            else => 0
        };
    }

    fn setCanvas(self: *Backend, canvas: Canvas) void {
        self.canvas = canvas;
    }

    fn getName(self: *Backend) String {
        return self.name;
    }

    fn createSurface(self: *Backend) *cairo_surface_t {
        self.surface = cairo.cairo_image_surface_create(self.format, self.width, self.height);
        return self.surface;
    }

    fn getSurface(self: *Backend) *cairo_surface_t {
        if (self.surface == null) createSurface();
        return self.surface;
    }

    fn setFormat(self: *Backend, format: cairo_format) void {
        self.format = format;
    }
};
