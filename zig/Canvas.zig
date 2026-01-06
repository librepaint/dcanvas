const CanvasRenderingContext = @import("./CanvasRenderingContext.zig").CanvasRenderingContext;
const Context2D = @import("./CanvasRenderingContext.zig").Context2D;

const Backend = @import("./backend/backend.zig").Backend;

const pango = @import("./backend/backend.zig").pango;
const PangoFontDescription = pango.PangoFontDescription;
const PangoStyle = pango.PangoStyle;

const cairo = @import("./backend/backend.zig").cairo;
const cairo_surface_t = cairo.cairo_surface_t;
const cairo_t = cairo.cairo_t;

const vexlib = @import("./lib/vexlib.zig");
const ArrayList = vexlib.ArrayList;
const String = vexlib.String;
const Map = vexlib.Map;
const Set = vexlib.Set;

//
// FontFace describes a font file in terms of one PangoFontDescription that
// will resolve to it and one that the user describes it as (like @font-face)
//
const FontFace = struct {
    sys_desc: *PangoFontDescription = null,
    user_desc: *PangoFontDescription = null,
    file_path: String = String.alloc(0),
};

const canvas_draw_mode_t = i32;
const CanvasDrawMode = struct {
    const TEXT_DRAW_PATHS: canvas_draw_mode_t = 0;
    const TEXT_DRAW_GLYPHS: canvas_draw_mode_t = 1;
};

var font_face_list: ?ArrayList(FontFace) = null;

const text_align_t = i32;
const TextAlign = struct {
    const TEXT_ALIGNMENT_LEFT: text_align_t = -1;
    const TEXT_ALIGNMENT_CENTER: text_align_t = 0;
    const TEXT_ALIGNMENT_RIGHT: text_align_t = 1;
    // Currently same as LEFT and RIGHT without RTL support:
    const TEXT_ALIGNMENT_START: text_align_t = -2;
    const TEXT_ALIGNMENT_END: text_align_t = 2;
};

const text_baseline_t = i32;
const TextBaseline = struct {
    const TEXT_BASELINE_ALPHABETIC: text_baseline_t = 0;
    const TEXT_BASELINE_TOP: text_baseline_t = 1;
    const TEXT_BASELINE_BOTTOM: text_baseline_t = 2;
    const TEXT_BASELINE_MIDDLE: text_baseline_t = 3;
    const TEXT_BASELINE_IDEOGRAPHIC: text_baseline_t = 4;
    const TEXT_BASELINE_HANGING: text_baseline_t = 5;
};

const Canvas = struct {
    context: ?Context2D,
    _backend: Backend = undefined,

    width: i32,
    height: i32,

    fn init(_width: i32, _height: i32) Canvas {
        var __backend = Backend(_width, _height);
        const out = Canvas{
            .width = _width,
            .height = _height,
            ._backend = __backend
        };
        __backend.setCanvas(out);
        return out;
    }

    fn backend(self: *Canvas) Backend {
        return self._backend;
    }

    fn surface(self: *Canvas) *cairo_surface_t {
        return self._backend.getSurface();
    }


    fn data(self: *Canvas) [*]u8 {
        _=self;
        return cairo.cairo_image_surface_get_data(surface());
    }

    fn stride(self: *Canvas) i32 {
        _=self;
        return cairo.cairo_image_surface_get_stride(surface());
    }

    fn nBytes(self: *Canvas) i32 {
        return self._backend.height * stride();
    }

    fn getWidth(self: *Canvas) i32 {
        return self._backend.width;
    }

    fn getHeight(self: *Canvas) i32 {
        return self._backend.height;
    }

    // 
    // Wrapper around cairo_create()
    // (do not call cairo_create directly, call this instead)
    // 
    fn createCairoContext(self: *Canvas) *cairo_t {
        _=self;
        const ret: *cairo_t = cairo.cairo_create(surface());
        cairo.cairo_set_line_width(ret, 1); // Cairo defaults to 2
        return ret;
    }

    fn getContext(self: *Canvas, ctxType: String, ctxAttribs: ?Map(String, String)) Context2D {
        if (ctxType.equals("2d")) {
            if (self.context == null) {
                if (ctxAttribs == null) {
                    ctxAttribs = Map.alloc();
                }
                self.context = Context2D.alloc(self, ctxAttribs);
            }
            self.context.canvas = self;
            return self.context;
        }
        @panic("Only 2d context are supported");
    }
};

//
// Get a PangoStyle from a CSS string (like "italic")
//
fn getStyleFromCSSString(style: String) PangoStyle {
    var s: PangoStyle = PangoStyle.PANGO_STYLE_NORMAL;

    if (style.isNotEmpty) {
        if (style.equals("italic")) {
            s = PangoStyle.PANGO_STYLE_ITALIC;
        } else if (style.equals("oblique")) {
            s = PangoStyle.PANGO_STYLE_OBLIQUE;
        }
    }

    return s;
}

//
// Given a user description, return a description that will select the
// font either from the system or @font-face
//
fn resolveFontDescription(desc: *const PangoFontDescription) *PangoFontDescription {
    // One of the user-specified families could map to multiple SFNT family names
    // if someone registered two different fonts under the same family name.
    // https://drafts.csswg.org/css-fonts-3/#font-style-matching
    var best = FontFace{};
    const fontDescription = String.usingCString(pango.pango_font_description_get_family(desc));
    const families = fontDescription.split(",");

    var seen_families = Set(String).alloc(4);
    var resolved_families: String = String.alloc(0);
    var first = true;

    if (font_face_list == null) {
        font_face_list = ArrayList(FontFace).alloc(4);
    }

    var i: u32 = 0; while (i < families.len) : (i += 1){
        const family = families.get(i);

        var renamedFamilies: String = String.alloc(0);
        var j: u32 = 0; while (j < font_face_list.len) : (j += 1){
            const ff = font_face_list.get(j);
            var pangofamily = String.usingCString(pango.pango_font_description_get_family(ff.user_desc));
            if (family.toLowerCase().equals(pangofamily.toLowerCase())) {
                const sys_desc_family_name = String.usingCString(pango.pango_font_description_get_family(ff.sys_desc));
                const unseen: bool = !seen_families.contains(sys_desc_family_name);
                const better: bool = best.user_desc == null or pango.pango_font_description_better_match(desc, best.user_desc, ff.user_desc) != 0;

                // Avoid sending duplicate SFNT font names due to a bug in Pango for macOS:
                // https://bugzilla.gnome.org/show_bug.cgi?id=762873
                if (unseen) {
                    seen_families.add(sys_desc_family_name);

                    if (better) {
                        const oldRenamedFamilies = renamedFamilies;
                        renamedFamilies = sys_desc_family_name;
                        renamedFamilies.concat(if (renamedFamilies.isNotEmpty) "," else "");
                        renamedFamilies.concat(oldRenamedFamilies);
                    } else {
                        renamedFamilies.concat(if (renamedFamilies.isNotEmpty) "," else "");
                        renamedFamilies.concat(sys_desc_family_name);
                    }
                }

                if (first and better) best = ff;
            }
        }

        if (resolved_families.isNotEmpty) {
            resolved_families.concat(',');
        }
        resolved_families.concat(if (renamedFamilies.isNotEmpty) renamedFamilies else family);
        first = false;
    }
    
    const ret: *PangoFontDescription = pango.pango_font_description_copy(if (best.sys_desc != null) best.sys_desc else desc);
    pango.pango_font_description_set_family(ret, resolved_families.cstring());

    return ret;
}