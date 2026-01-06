# dcanvas
Drawlite's canvas implementation. Although dcanvas was created to be used with Drawlite, it can also be used standalone.

Originally this package was written entirely in Dart. However, I'm porting it to Zig as much as possible for performance reasons and to making creating bindings to other programming languages easier.

## Credits
dcanvas is heavily based upon [node-canvas](https://github.com/Automattic/node-canvas) so huge thanks to node-canvas

## Why
I wanted to use HTML canvas to create native apps, but all the existing canvas implementations are integrated with JS using NAPI and JS cannot compile to native code. Because of NAPI I can't just rebind the C++ library to Dart. Even so, binding the C++ library to Dart would be messy as I would have to create a C wrapper API around the C++ library and then create Dart bindings to the C wrapper. So instead I just wrote a whole new canvas implementation.

## Dependencies
dcanvas uses [jvbuild](https://github.com/vExcess/jvbuild) to manage its dependencies. Install jvbuild and run `jvbuild install`.

## Demo
Run the demo via `jvbuild run demo`.  

## Backends
There are three backends listed below. They are ordered from fastest to slowest.

### WebGPU
This is the hardware accelerated backend. You should use it if possible for best performance. Currently, it is not implemented as a part of dcanvas, but I am working on creating [https://github.com/librepaint/zig-webgpu](https://github.com/librepaint/zig-webgpu) which will be used as the WebGPU backend for dcanvas.

### Cairo + Pango
This is the primary software rendered backend. It it faster than the z2d backend, but slower than the webgpu backend. This backend is not supported on Windows.

### z2d
This is the secondary software rendered backend. It is the slowest backend and is feature lacking. However, it supports all platforms (including Windows) and has no external dependencies. Compared to the Cairo backend you can expect roughly 9% slower performance without anti-aliasing and 100% slower performance with anti-aliasing. This backend is also not yet implemented.