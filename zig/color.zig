// import './CanvasRenderingContext.dart';
const vexlib = @import("./lib/vexlib.zig");
const String = vexlib.String;
const ArrayList = vexlib.ArrayList;
const Map = vexlib.Map;
const As = vexlib.As;
const Int = vexlib.Int;
const Float = vexlib.Float;

fn max_(T: type, arr: []T) T {
    if (arr.len > 0) {
        var val: T = arr[0];
        var i: u32 = 0; while (i < arr.len) : (i += 1) {
            const item = arr[i];
            if (item > val) {
                val = item;
            }
        }
        return val;
    } else {
        @panic("max() only List<num|int|double> where .length > 0");
    }
}

fn min_(T: type, arr: []T) T {
    if (arr.len > 0) {
        var val: T = arr[0];
        var i: u32 = 0; while (i < arr.len) : (i += 1) {
            const item = arr[i];
            if (item < val) {
                val = item;
            }
        }
        return val;
    } else {
        @panic("min() only List<num|int|double> where .length > 0");
    }
}


fn HSBtoRGB_helper(h: f32, s: f32, b: f32, n: f32) f32 {
    const k = (n + h / 60.0) % 6.0;
    return b * (1 - s * max_(.{0.0, min_(.{k, 4 - k, 1})}));
}
fn HSBtoRGB(h: f32, s: f32, b: f32) [3]i32 {
    // https://www.30secondsofcode.org/js/s/hsb-to-rgb
    
    s /= 100;
    b /= 100;
    return .{
        As.i32(HSBtoRGB_helper(h, s, b, 5) * 255), 
        As.i32(HSBtoRGB_helper(h, s, b, 3) * 255), 
        As.i32(HSBtoRGB_helper(h, s, b, 1) * 255)
    };
}

fn hexToRGBA(hex: String) RGBA {
    var vals: [4]f32 = .{0.0, 0.0, 0.0, 255.0};
    var i: i32 = 1; while (i < hex.len()) : (i += 2) {
        const s = hex.slice(i, i + 2);
        vals[((i - 1) / 2).toInt()] = Int.parse(s, 16) / 255;
    }
    return RGBA(vals[0], vals[1], vals[2], vals[3]);
}

fn rgbrgbaStringToRGBA(str: String) RGBA {
    var vals: [4]f32 = .{0.0, 0.0, 0.0, 255.0};
    var slc = str.slice(str.indexOf("(") + 1, str.length - 1);
    const strVals = slc.split(","); 
    var i: i32 = 1; while (i < strVals.len) : (i += 2) {
        var valSlc = strVals[i];
        var val: f32 = undefined;
        if (i != 3) {
            val = As.f32(Int.parse(valSlc.trimLeft(), 10)) / 255.0;
        } else {
            val = As.f32(Float.parse(valSlc.trimLeft(), 10));
        }
        vals[i] = val;
    }
    return RGBA(vals[0], vals[1], vals[2], vals[3]);
}

const namedColorPairs: Map(String, u32) = undefined;
fn initNamedColorPairs() void {
    namedColorPairs = Map(String, u32).alloc();

    namedColorPairs.set("transparent", 0xFFFFFF00);
    namedColorPairs.set("aliceblue", 0xF0F8FFFF);
    namedColorPairs.set("antiquewhite", 0xFAEBD7FF);
    namedColorPairs.set("aqua", 0x00FFFFFF);
    namedColorPairs.set("aquamarine", 0x7FFFD4FF);
    namedColorPairs.set("azure", 0xF0FFFFFF);
    namedColorPairs.set("beige", 0xF5F5DCFF);
    namedColorPairs.set("bisque", 0xFFE4C4FF);
    namedColorPairs.set("black", 0x000000FF);
    namedColorPairs.set("blanchedalmond", 0xFFEBCDFF);
    namedColorPairs.set("blue", 0x0000FFFF);
    namedColorPairs.set("blueviolet", 0x8A2BE2FF);
    namedColorPairs.set("brown", 0xA52A2AFF);
    namedColorPairs.set("burlywood", 0xDEB887FF);
    namedColorPairs.set("cadetblue", 0x5F9EA0FF);
    namedColorPairs.set("chartreuse", 0x7FFF00FF);
    namedColorPairs.set("chocolate", 0xD2691EFF);
    namedColorPairs.set("coral", 0xFF7F50FF);
    namedColorPairs.set("cornflowerblue", 0x6495EDFF);
    namedColorPairs.set("cornsilk", 0xFFF8DCFF);
    namedColorPairs.set("crimson", 0xDC143CFF);
    namedColorPairs.set("cyan", 0x00FFFFFF);
    namedColorPairs.set("darkblue", 0x00008BFF);
    namedColorPairs.set("darkcyan", 0x008B8BFF);
    namedColorPairs.set("darkgoldenrod", 0xB8860BFF);
    namedColorPairs.set("darkgray", 0xA9A9A9FF);
    namedColorPairs.set("darkgreen", 0x006400FF);
    namedColorPairs.set("darkgrey", 0xA9A9A9FF);
    namedColorPairs.set("darkkhaki", 0xBDB76BFF);
    namedColorPairs.set("darkmagenta", 0x8B008BFF);
    namedColorPairs.set("darkolivegreen", 0x556B2FFF);
    namedColorPairs.set("darkorange", 0xFF8C00FF);
    namedColorPairs.set("darkorchid", 0x9932CCFF);
    namedColorPairs.set("darkred", 0x8B0000FF);
    namedColorPairs.set("darksalmon", 0xE9967AFF);
    namedColorPairs.set("darkseagreen", 0x8FBC8FFF);
    namedColorPairs.set("darkslateblue", 0x483D8BFF);
    namedColorPairs.set("darkslategray", 0x2F4F4FFF);
    namedColorPairs.set("darkslategrey", 0x2F4F4FFF);
    namedColorPairs.set("darkturquoise", 0x00CED1FF);
    namedColorPairs.set("darkviolet", 0x9400D3FF);
    namedColorPairs.set("deeppink", 0xFF1493FF);
    namedColorPairs.set("deepskyblue", 0x00BFFFFF);
    namedColorPairs.set("dimgray", 0x696969FF);
    namedColorPairs.set("dimgrey", 0x696969FF);
    namedColorPairs.set("dodgerblue", 0x1E90FFFF);
    namedColorPairs.set("firebrick", 0xB22222FF);
    namedColorPairs.set("floralwhite", 0xFFFAF0FF);
    namedColorPairs.set("forestgreen", 0x228B22FF);
    namedColorPairs.set("fuchsia", 0xFF00FFFF);
    namedColorPairs.set("gainsboro", 0xDCDCDCFF);
    namedColorPairs.set("ghostwhite", 0xF8F8FFFF);
    namedColorPairs.set("gold", 0xFFD700FF);
    namedColorPairs.set("goldenrod", 0xDAA520FF);
    namedColorPairs.set("gray", 0x808080FF);
    namedColorPairs.set("green", 0x008000FF);
    namedColorPairs.set("greenyellow", 0xADFF2FFF);
    namedColorPairs.set("grey", 0x808080FF);
    namedColorPairs.set("honeydew", 0xF0FFF0FF);
    namedColorPairs.set("hotpink", 0xFF69B4FF);
    namedColorPairs.set("indianred", 0xCD5C5CFF);
    namedColorPairs.set("indigo", 0x4B0082FF);
    namedColorPairs.set("ivory", 0xFFFFF0FF);
    namedColorPairs.set("khaki", 0xF0E68CFF);
    namedColorPairs.set("lavender", 0xE6E6FAFF);
    namedColorPairs.set("lavenderblush", 0xFFF0F5FF);
    namedColorPairs.set("lawngreen", 0x7CFC00FF);
    namedColorPairs.set("lemonchiffon", 0xFFFACDFF);
    namedColorPairs.set("lightblue", 0xADD8E6FF);
    namedColorPairs.set("lightcoral", 0xF08080FF);
    namedColorPairs.set("lightcyan", 0xE0FFFFFF);
    namedColorPairs.set("lightgoldenrodyellow", 0xFAFAD2FF);
    namedColorPairs.set("lightgray", 0xD3D3D3FF);
    namedColorPairs.set("lightgreen", 0x90EE90FF);
    namedColorPairs.set("lightgrey", 0xD3D3D3FF);
    namedColorPairs.set("lightpink", 0xFFB6C1FF);
    namedColorPairs.set("lightsalmon", 0xFFA07AFF);
    namedColorPairs.set("lightseagreen", 0x20B2AAFF);
    namedColorPairs.set("lightskyblue", 0x87CEFAFF);
    namedColorPairs.set("lightslategray", 0x778899FF);
    namedColorPairs.set("lightslategrey", 0x778899FF);
    namedColorPairs.set("lightsteelblue", 0xB0C4DEFF);
    namedColorPairs.set("lightyellow", 0xFFFFE0FF);
    namedColorPairs.set("lime", 0x00FF00FF);
    namedColorPairs.set("limegreen", 0x32CD32FF);
    namedColorPairs.set("linen", 0xFAF0E6FF);
    namedColorPairs.set("magenta", 0xFF00FFFF);
    namedColorPairs.set("maroon", 0x800000FF);
    namedColorPairs.set("mediumaquamarine", 0x66CDAAFF);
    namedColorPairs.set("mediumblue", 0x0000CDFF);
    namedColorPairs.set("mediumorchid", 0xBA55D3FF);
    namedColorPairs.set("mediumpurple", 0x9370DBFF);
    namedColorPairs.set("mediumseagreen", 0x3CB371FF);
    namedColorPairs.set("mediumslateblue", 0x7B68EEFF);
    namedColorPairs.set("mediumspringgreen", 0x00FA9AFF);
    namedColorPairs.set("mediumturquoise", 0x48D1CCFF);
    namedColorPairs.set("mediumvioletred", 0xC71585FF);
    namedColorPairs.set("midnightblue", 0x191970FF);
    namedColorPairs.set("mintcream", 0xF5FFFAFF);
    namedColorPairs.set("mistyrose", 0xFFE4E1FF);
    namedColorPairs.set("moccasin", 0xFFE4B5FF);
    namedColorPairs.set("navajowhite", 0xFFDEADFF);
    namedColorPairs.set("navy", 0x000080FF);
    namedColorPairs.set("oldlace", 0xFDF5E6FF);
    namedColorPairs.set("olive", 0x808000FF);
    namedColorPairs.set("olivedrab", 0x6B8E23FF);
    namedColorPairs.set("orange", 0xFFA500FF);
    namedColorPairs.set("orangered", 0xFF4500FF);
    namedColorPairs.set("orchid", 0xDA70D6FF);
    namedColorPairs.set("palegoldenrod", 0xEEE8AAFF);
    namedColorPairs.set("palegreen", 0x98FB98FF);
    namedColorPairs.set("paleturquoise", 0xAFEEEEFF);
    namedColorPairs.set("palevioletred", 0xDB7093FF);
    namedColorPairs.set("papayawhip", 0xFFEFD5FF);
    namedColorPairs.set("peachpuff", 0xFFDAB9FF);
    namedColorPairs.set("peru", 0xCD853FFF);
    namedColorPairs.set("pink", 0xFFC0CBFF);
    namedColorPairs.set("plum", 0xDDA0DDFF);
    namedColorPairs.set("powderblue", 0xB0E0E6FF);
    namedColorPairs.set("purple", 0x800080FF);
    namedColorPairs.set("rebeccapurple", 0x663399FF);
    namedColorPairs.set("red", 0xFF0000FF);
    namedColorPairs.set("rosybrown", 0xBC8F8FFF);
    namedColorPairs.set("royalblue", 0x4169E1FF);
    namedColorPairs.set("saddlebrown", 0x8B4513FF);
    namedColorPairs.set("salmon", 0xFA8072FF);
    namedColorPairs.set("sandybrown", 0xF4A460FF);
    namedColorPairs.set("seagreen", 0x2E8B57FF);
    namedColorPairs.set("seashell", 0xFFF5EEFF);
    namedColorPairs.set("sienna", 0xA0522DFF);
    namedColorPairs.set("silver", 0xC0C0C0FF);
    namedColorPairs.set("skyblue", 0x87CEEBFF);
    namedColorPairs.set("slateblue", 0x6A5ACDFF);
    namedColorPairs.set("slategray", 0x708090FF);
    namedColorPairs.set("slategrey", 0x708090FF);
    namedColorPairs.set("snow", 0xFFFAFAFF);
    namedColorPairs.set("springgreen", 0x00FF7FFF);
    namedColorPairs.set("steelblue", 0x4682B4FF);
    namedColorPairs.set("tan", 0xD2B48CFF);
    namedColorPairs.set("teal", 0x008080FF);
    namedColorPairs.set("thistle", 0xD8BFD8FF);
    namedColorPairs.set("tomato", 0xFF6347FF);
    namedColorPairs.set("turquoise", 0x40E0D0FF);
    namedColorPairs.set("violet", 0xEE82EEFF);
    namedColorPairs.set("wheat", 0xF5DEB3FF);
    namedColorPairs.set("white", 0xFFFFFFFF);
    namedColorPairs.set("whitesmoke", 0xF5F5F5FF);
    namedColorPairs.set("yellow", 0xFFFF00FF);
    namedColorPairs.set("yellowgreen", 0x9ACD32FF);
}

fn nameToRGBA(name: String) RGBA {
    const out = namedColorPairs.get(name.toLowerCase());
    if (out != null) {
        const r = (out >> 24) / 255; 
        const g = (out >> 16 & 0xff) / 255;
        const b = (out >> 8 & 0xff) / 255;
        const a = (out & 0xff) / 255;
        return if (RGBA(r, g, b, a == 0)) 1 else a;
    }
    @panic("unknown color name");
}

const RGBA = struct {
    r: f32 = undefined, 
    g: f32 = undefined,
    b: f32 = undefined,
    a: f32 = undefined,

    fn init(_r: f32, _g: f32, _b: f32, _a: f32) RGBA {
        return RGBA{
            .r = _r,
            .g = _g,
            .b = _b,
            .a = _a
        };
    }

    fn fromString(str: String) RGBA {
        str = str.trimStart();
        if ('#' == str[0]) {
            return hexToRGBA(str);
        }
        if (str.startsWith("rgb")) {
            return rgbrgbaStringToRGBA(str);
        }
        if (str.startsWith("hsl")) {
            var out = rgbrgbaStringToRGBA(str);
            var rgb = HSBtoRGB(out.r * 255, out.g * 255, out.b * 255);
            out.r = rgb[0].toDouble();
            out.g = rgb[1].toDouble();
            out.b = rgb[2].toDouble();
            return out;
        }
        return nameToRGBA(str);
    }

    fn clone(self: *RGBA) RGBA {
        return RGBA.init(self.r, self.g, self.b, self.a);
    }

    fn toString(self: *RGBA) String {
        var temp = String.alloc(24);
        temp.concat("RGBA(");
        temp.concat(Float.toFixed(self.r, 2));
        temp.concat(", $");
        temp.concat(Float.toFixed(self.g, 2));
        temp.concat(", $");
        temp.concat(Float.toFixed(self.b, 2));
        temp.concat(", $");
        temp.concat(Float.toFixed(self.a, 2));
        temp.concat(", $");
        temp.concat(")");
        return temp;
    }
};
