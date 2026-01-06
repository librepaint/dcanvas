const backend = @import("./backend/Backend.zig");
const vexlib = @import("./lib/vexlib.zig");

const cairo = @import("./backend/backend.zig").cairo;
const cairo_user_data_key_t = cairo.cairo_user_data_key_t;
const cairo_pattern_t = cairo.cairo_pattern_t;

// 
// Canvas types.
// 
const repeat_type_t = i32;
const RepeatType = struct {
    const NO_REPEAT: repeat_type_t = 0;  // match CAIRO_EXTEND_NONE
    const REPEAT: repeat_type_t = 1;  // match CAIRO_EXTEND_REPEAT
    const REPEAT_X: repeat_type_t = 2; // needs custom processing
    const REPEAT_Y: repeat_type_t = 3; // needs custom processing
};

const RepeatTypeError = error {
    UNDEFINED
};

var patternRepeatKey: *cairo_user_data_key_t = null;
fn allocPatternRepeatKey() void {
    const allocator = vexlib.allocatorPtr.*;
    patternRepeatKey = allocator.create(cairo_user_data_key_t);
}

const Pattern = struct {
    _pattern: *cairo_pattern_t,
    _repeat: repeat_type_t = RepeatType.REPEAT,

    fn init(__pattern: *cairo_pattern_t, __repeat: repeat_type_t) Pattern {
        return Pattern{
            ._pattern = __pattern,
            ._repeat = __repeat
        };
    }

    fn get_repeat_type_for_cairo_pattern(__pattern: *cairo_pattern_t) RepeatTypeError.UNDEFINED!repeat_type_t {
        if (patternRepeatKey == null) {
            allocPatternRepeatKey();
        }

        const ud: *void = cairo.cairo_pattern_get_user_data(__pattern, patternRepeatKey);
        const enumValPtr: *repeat_type_t = @ptrCast(ud);
        const enumVal = enumValPtr.*;

        if (enumVal < 0 or enumVal > 3) {
            return RepeatTypeError.UNDEFINED;
        }
        
        return enumVal;
    }
    
    fn pattern(self: *Pattern) *cairo_pattern_t {
        return self._pattern;
    }
};
