const OS = enum {
    linux,
    windows
};

const ARCH = enum {
    x64,
    arm64
};

const BACKEND = enum {
    webgpu,
    cairo_pango,
    z2d
};

const config = .{
    .os = OS.linux,
    .arch = ARCH.x64,
    .backend = BACKEND.cairo_pango
};
