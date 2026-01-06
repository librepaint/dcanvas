const vexlib = @import("./lib/vexlib.zig");
const Stack = vexlib.Stack;
const Uint8List = vexlib.Uint8List;

import 'dart:typed_data';
import 'dart:math' as Math;
import './CanvasPattern.dart';
import './utils.dart';
import './Canvas.dart';
import './backend/Backend.dart';
import './color.dart';
import './font.dart' show ParsedFont, parseFontString, TextMetrics;
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

const DOMPoint = struct {
    x: f64,
    y: f64,

    fn init(_x: f64, _y: f64) DOMPoint {
        return DOMPoint{
            .x = _x,
            .y = _y
        };
    }

    fn clone(self: *DOMPoint) DOMPoint {
        return DOMPoint{
            .x = self.x,
            .y = self.y
        };
    }

    fn toString() String {
        var out = String.alloc(32);
        out.concat("DOMPoint(");
        out.concat(self.x);
        out.concat(", ");
        out.concat(self.y);
        out.concat(")");
        return out;
    }
}

const ImageData = struct {
    data: Uint8List,
    width: i32,
    height: i32,

    fn init(_data: Uint8List, _width: i32, _height: i32) ImageData {
        return ImageData{
            .data = _data,
            .width = _width,
            .height = _height
        };
    }

    fn withDimensions(width: i32, height: i32) ImageData {
        return ImageData(Uint8List.alloc(width * height * 4), width, height);
    }
};

sealed class FillInfo {}

class CSSColor extends FillInfo {
    int r, g, b;
    double a;
    CSSColor(this.r, this.g, this.b, this.a);
    String toString() {
        return "rgba($r, $g, $b, ${a.toStringAsFixed(2)})";
    }
}

class CanvasGradient extends FillInfo {
    double x0, y0, x1, y1;
    List<CSSColor> colors = [];
    List<double> stops = [];

    CanvasGradient(this.x0, this.y0, this.x1, this.y1);
    
    void addColorStop(double offset, CSSColor color) {
        this.stops.add(offset);
        this.colors.add(color);
    }
}

class CanvasPattern extends FillInfo {
    late Object image;
    late repeat_type_t repetition;
    
    CanvasPattern(Object image, String repetition) {
        this.image = image;
        switch (repetition) {
            case "repeat":
                this.repetition = RepeatType.REPEAT;
            case "repeat-x":
                this.repetition = RepeatType.REPEAT_X;
            case "repeat-y":
                this.repetition = RepeatType.REPEAT_Y;
            case "no-repeat":
                this.repetition = RepeatType.NO_REPEAT;
            default:
                this.repetition = RepeatType.REPEAT;
        }
    }
}

class CanvasState {
    RGBA fill = RGBA(0, 0, 0, 1);
    RGBA stroke = RGBA(0, 0, 0, 1);
    RGBA shadow = RGBA(0, 0, 0, 0);
    double shadowOffsetX = 0.0;
    double shadowOffsetY = 0.0;
    ffi.Pointer<cairo_pattern_t> fillPattern = ffi.nullptr;
    ffi.Pointer<cairo_pattern_t> strokePattern = ffi.nullptr;
    ffi.Pointer<cairo_pattern_t> fillGradient = ffi.nullptr;
    ffi.Pointer<cairo_pattern_t> strokeGradient = ffi.nullptr;
    ffi.Pointer<PangoFontDescription> fontDescription = ffi.nullptr;
    String font = "10px sans-serif";
    cairo_filter patternQuality = cairo_filter.CAIRO_FILTER_GOOD;
    double globalAlpha = 1.0;
    int shadowBlur = 0;
    text_align_t textAlignment = TextAlign.TEXT_ALIGNMENT_LEFT; // TODO default is supposed to be START
    text_baseline_t textBaseline = TextBaseline.TEXT_BASELINE_ALPHABETIC;
    canvas_draw_mode_t textDrawingMode = CanvasDrawMode.TEXT_DRAW_PATHS;
    bool imageSmoothingEnabled = true;

    CanvasState([final CanvasState? orig]) {
        if (orig != null) {
            fill = orig.fill.clone();
            stroke = orig.stroke.clone();
            patternQuality = orig.patternQuality;
            fillPattern = ffi.Pointer.fromAddress(orig.fillPattern.address);
            strokePattern = ffi.Pointer.fromAddress(orig.strokePattern.address);
            fillGradient = ffi.Pointer.fromAddress(orig.fillGradient.address);
            strokeGradient = ffi.Pointer.fromAddress(orig.strokeGradient.address);
            globalAlpha = orig.globalAlpha;
            textAlignment = orig.textAlignment;
            textBaseline = orig.textBaseline;
            shadow = orig.shadow.clone();
            shadowBlur = orig.shadowBlur;
            shadowOffsetX = orig.shadowOffsetX;
            shadowOffsetY = orig.shadowOffsetY;
            textDrawingMode = orig.textDrawingMode;
            fontDescription = pango.pango_font_description_copy(orig.fontDescription);
            font = orig.font;
            imageSmoothingEnabled = orig.imageSmoothingEnabled;
        } else {
            final fontname = "sans".toNativeUtf8();
            fontDescription = pango.pango_font_description_from_string(fontname.cast());
            pango.pango_font_description_set_absolute_size(fontDescription, 10.0 * PANGO_SCALE);
            malloc.free(fontname);
        }
    }
}

const Context2D = struct {
    states: Stack(CanvasState) = undefined,
    state: CanvasState = undefined,
    canvas: Canvas = undefined,
    _context: *cairo_t = null,
    _path: *cairo_path_t = undefined,
    _layout: *PangoLayout = null,

    _fillStyle: FillInfo = CSSColor(0, 0, 0, 1),
    _strokeStyle: FillInfo = CSSColor(0, 0, 0, 1),

    fn alloc(canvas: *Canvas, ctxAttribs: Map(String, Object)) Context2D {
        var this = Context2D{};

        ctx.states = Stack(CanvasState)();
        ctx.state = CanvasState();

        this.canvas = canvas;

        const isImageBackend = canvas.backend().getName() == "image";
        if (isImageBackend) {
            var format: cairo_format = Backend.DEFAULT_FORMAT;

            const pixelFormat = ctxAttribs.get("pixelFormat");
            // if (pixelFormat is String) {
                const utf8PixelFormat: String = pixelFormat;
                if (utf8PixelFormat == "RGBA32") {
                    format = cairo_format.CAIRO_FORMAT_ARGB32;
                } else if (utf8PixelFormat == "RGB24") {
                    format = cairo_format.CAIRO_FORMAT_RGB24;
                } else if (utf8PixelFormat == "A8") {
                    format = cairo_format.CAIRO_FORMAT_A8;
                } else if (utf8PixelFormat == "RGB16_565") {
                    format = cairo_format.CAIRO_FORMAT_RGB16_565;
                } else if (utf8PixelFormat == "A1") {
                    format = cairo_format.CAIRO_FORMAT_A1;
                }
            // }

            // alpha: false forces use of RGB24
            const alpha = ctxAttribs.get("alpha");
            // if (alpha is bool && !alpha) {
            if (!alpha) {
                format = cairo_format.CAIRO_FORMAT_RGB24;
            }

            canvas.backend().setFormat(format);
        }

        _context = canvas.createCairoContext();
        _layout = pango.pango_cairo_create_layout(_context.cast());

        // As of January 2023, Pango rounds glyph positions which renders text wider
        // or narrower than the browser. See #2184 for more information
        const FALSE = 0;
        pango.pango_context_set_round_glyph_positions(pango.pango_layout_get_context(_layout), FALSE);

        states.push(CanvasState());
        state = states.top();
        pango.pango_layout_set_font_description(_layout, state.fontDescription);
    }
};

