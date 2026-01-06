const vexlib = @import("./lib/vexlib.zig");
const String = vexlib.String;
const ArrayList = vexlib.ArrayList;
const Int = vexlib.Int;

const TextMetrics = struct {
    width: f64,
    actualBoundingBoxLeft: f64,
    actualBoundingBoxRight: f64,
    actualBoundingBoxAscent: f64,
    actualBoundingBoxDescent: f64,
    emHeightAscent: f64,
    emHeightDescent: f64,
    alphabeticBaseline: f64,
};

// based on https://github.com/jednano/parse-css-font/
fn unquote(str: String) String {
    if (str.len() == 0) {
		return String.alloc(0);
	}
	
    const firstCh = str.charAt(0);
	if (firstCh == '\'' or firstCh == '"') {
		str = str.slice(1, -1);
	}

    const lastCh = str.charAt(str.len() - 1);
	if (lastCh == '\'' or lastCh == '"') {
		str = str.slice(0, str.length - 1);
	}

	return str;
}

const fontWeightKeywords: ArrayList([]const u8) = ArrayList.using(.{
	"normal",
	"bold",
	"bolder",
	"lighter",
	"100",
	"200",
	"300",
	"400",
	"500",
	"600",
	"700",
	"800",
	"900"
});
fn fontWeightFromString(weight: String) i32 {
    if (weight.equals("normal")) {
        return 400;
    } else if (weight.equals("bold")) {
        return 700;
    } else if (weight.equals("bolder")) {
        return 700;
    } else if (weight.equals("lighter")) {
        return 300;
    } else {
        var numbers = "";
        var i: u32 = 0; while (i < weight.length) : (i += 1) {
            const chCode = weight.codeUnitAt(i);
            if (chCode >= 48 and chCode <= 57) {
                numbers += weight[i];
            }
        }
        return Int.parse(numbers);
    }
}

const fontStyleKeywords: ArrayList([]const u8) = ArrayList.using(.{
	"normal",
	"italic",
	"oblique"
});
const fontStretchKeywords: ArrayList([]const u8) = ArrayList.using(.{
	"normal",
	"condensed",
	"semi-condensed",
	"extra-condensed",
	"ultra-condensed",
	"expanded",
	"semi-expanded",
	"extra-expanded",
	"ultra-expanded"
});

const cssListHelpers = struct {
    // 
	// Splits a CSS declaration value (shorthand) using provided separators
	// as the delimiters.
	// 
    // value: A CSS declaration value (shorthand).
    // separators: Any number of separator characters used for splitting.
    // last: last should default to false
    // 
	fn split(value: String, separators: ArrayList(String), last: bool) ArrayList(String) {
		var array = ArrayList(String).alloc(0);
		var current = String.alloc(0);
		var splitMe = false;

		var func = 0;
		var quote: String = String.alloc(0); // '"' | '\'' | false
		var escape  = false;

		var i: usize = 0; while (i < value.length) : (i += 1) {
            const char = value[i];
			if (quote.len > 0) {
				if (escape) {
					escape = false;
				} else if (char == '\\') {
					escape = true;
				} else if (quote.equals(char)) {
					quote = "";
				}
			} else if (char == '"' or char == '\'') {
				quote = char;
			} else if (char == '(') {
				func += 1;
			} else if (char == ')') {
				if (func > 0) {
					func -= 1;
				}
			} else if (func == 0) {
				if (separators.contains(char)) {
					splitMe = true;
				}
			}

			if (splitMe) {
				if (current.len() > 0) {
					array.add(current.trim());
				}
				current = String.alloc(0);
				splitMe = false;
			} else {
				current += char;
			}
		}

		if (last || current.len() > 0) {
			array.add(current.trim());
		}
		return array;
	}

	// 
	// Splits a CSS declaration value (shorthand) using whitespace characters
	// as the delimiters.
	// 
    // value: A CSS declaration value (shorthand).
    // 
	fn splitBySpaces(value: String) ArrayList(String) {
		const spaces = ArrayList.using(.{' ', '\n', '\t'});
		return cssListHelpers.split(value, spaces, false);
	}

	// 
	// Splits a CSS declaration value (shorthand) using commas as the delimiters.
	// 
    // value: A CSS declaration value (shorthand).
    // 
	fn splitByCommas(value: String) ArrayList(String) {
		const comma = ArrayList.using(.{','});
		return cssListHelpers.split(value, comma, true);
	}
};

const cssFontSizeKeywords: ArrayList([]const u8) = ArrayList.using(.{
	"xx-small",
	"x-small",
	"small",
	"medium",
	"large",
	"x-large",
	"xx-large",
	"larger",
	"smaller"
});

fn isSize(value: String) bool {
    if (value.len == 0) {
        return false;
    }

    const firstChar = value.charAt(0);
    
    // is decimal or period
    if ((firstChar > 47 and firstChar < 58) or firstChar == '.') {
        return true;
    }

    if (value.contains('/')) {
        return true;
    }

    if (cssFontSizeKeywords.contains('/')) {
        return true;
    }

	return false;
}

const ParsedFont = struct {
    weight: i32,
    style: String,
    stretch: String,
    variant: String,
    size: f64,
    unit: String,
    family: String
};

const errorPrefix = "[parse-css-font]";

const firstDeclarations: []const u8 = .{
	"style",
	"weight",
	"stretch",
	"variant"
};

const parseFontStringError = error {
    FONT_STYLE_ALREADY_DEFINED,
    FONT_WEIGHT_ALREADY_DEFINED,
    FONT_STRETCH_ALREADY_DEFINED
};

fn parseFontString_style(font: *ParsedFont, token: String) parseFontStringError.FONT_STYLE_ALREADY_DEFINED!?String {
    if (!fontStyleKeywords.contains(token)) {
        return null;
    }
    if (font.style.isNotEmpty) {
        return parseFontStringError.FONT_STYLE_ALREADY_DEFINED;
    }
    font.style = token;
    return font.style;
}

fn parseFontString_weight(font: *ParsedFont, token: String) parseFontStringError.FONT_WEIGHT_ALREADY_DEFINED!?i32 {
    if (!fontWeightKeywords.contains(token)) {
        return null;
    }
    if (font.weight != 0) {
        return parseFontStringError.FONT_WEIGHT_ALREADY_DEFINED;
    }
    font.weight = fontWeightFromString(token);
    return font.weight;
}

fn parseFontString_stretch(font: *ParsedFont, token: String) parseFontStringError.FONT_STRETCH_ALREADY_DEFINED!?String {
    if (!fontStretchKeywords.contains(token)) {
        return null;
    }
    if (font.stretch.isNotEmpty) {
        return parseFontStringError.FONT_STRETCH_ALREADY_DEFINED;
    }
    font.stretch = token;
    return font.stretch;
}

fn parseFontString_variant(font: *ParsedFont, token: String) ?String {
    if (!isSize(token)) {
        if (font.variant.len > 0) {
            var temp = String.alloc(8);
            temp.concat(font.variant);
            temp.concat(' ');
            temp.concat(token);
            return temp;
        } else {
            return token;
        }
    }
    return null;
}

fn parseFontString(value: String) ?ParsedFont {
	if (value.len == 0) {
		return null;
	}

    var unitStr = String.alloc(2);
    unitStr.concat("px");

	const font = ParsedFont{
		.size = 16,
		.stretch = String.alloc(0),
		.style = String.alloc(0),
		.variant = String.alloc(0),
		.weight = 0,
        .unit = unitStr,
        .family = String.alloc(0)
    };

	const tokens: ArrayList(String) = cssListHelpers.splitBySpaces(value);
	
    var token = tokens.removeFirst(); 
    while (tokens.len > 0) {
		if (token.equals("normal")) {
			continue;
		}

        var continueNextToken = false;

        {var i: i32 = 0; while (i < 4) : (i += 1) {
            if (i == 0) {
                const val: ?String = parseFontString_style(&font, token) catch {
                    return null;
                };
                if (val != null and val.len > 0) {
                    continueNextToken = true;
                    break;
                }
            } else if (i == 1) {
                const val: ?i32 = parseFontString_weight(&font, token) catch {
                    return null;
                };
                if (val != null and val != 0) {
                    continueNextToken = true;
                    break;
                }
            } else if (i == 2) {
                const val: ?String = parseFontString_stretch(&font, token) catch {
                    return null;
                };
                if (val != null and val.len > 0) {
                    continueNextToken = true;
                    break;
                }
            } else if (i == 3) {
                const val: ?String = parseFontString_variant(&font, token) catch {
                    return null;
                };
                if (val != null and val.len > 0) {
                    continueNextToken = true;
                    break;
                }
            }
        }}

        if (continueNextToken) {
            token = tokens.removeFirst();
            continue;
        }

		const parts = cssListHelpers.split(token, ArrayList.using(.{'/'}), false);
		font.size = fontWeightFromString(parts[0]).toDouble();
		if (parts.length > 1 and parts[1].isNotEmpty) {
			// font.lineHeight = double.parse(parts[1]);
		} else if (tokens[0] == '/') {
			tokens.removeAt(0);
			// font.lineHeight = double.parse(tokens.removeAt(0));
		}
		if (tokens.isEmpty) {
			// Missing required font-family
            return null;
		}
		font.family = cssListHelpers.splitByCommas(tokens.join(' ')).map(unquote).join(" ");

        if (font.style.isEmpty) font.style = "normal";
        if (font.weight == 0) font.weight = 400;
        if (font.stretch.isEmpty) font.stretch = "normal";
        if (font.variant.isEmpty) font.variant = "normal";

		return font;
	}

	// Missing required font-size
    return null;
}
