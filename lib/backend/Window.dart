import './Backend.dart';
import '../Canvas.dart';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

export './Backend.dart'
    show SDL_INIT_EVERYTHING, SDL_WindowFlags;

enum EventTypes {
    Quit,
    KeyDown,
    Unknown
}

class Event {
    late EventTypes which;
    late int data;
    Event({
        required this.which,
        required this.data
    });
}

class Key {
    static final int Escape = 27;
}

class SDLWindow {
    void Function(Event)? eventHandler;
    late int width;
    late int height;
    late Canvas canvas;

    late ffi.Pointer<SDL_Window> sdlWindow;
    late ffi.Pointer<SDL_Renderer> sdlRenderer;

    SDLWindow({
        String title = "",
        int x = SDL_WINDOWPOS_UNDEFINED,
        int y = SDL_WINDOWPOS_UNDEFINED,
        int width = 400,
        int height = 400,
        List<SDL_WindowFlags>? flagsList
    }) {
        int flags = SDL_WindowFlags.SDL_WINDOW_SHOWN.value;
        if (flagsList != null) {
            for (var i = 0; i < flagsList.length; i++) {
                flags = flags | flagsList[i].value;
            }
        }

        // create window
        final cstr_title = title.toNativeUtf8();
        final window = sdl.SDL_CreateWindow(
            cstr_title.cast(), // title string/NULL
            x, // x
            y, // y
            width, // w
            height, // height
            flags
        );
        malloc.free(cstr_title);
        if (window == ffi.nullptr) {
            throw "failed to create SDL window";
        }

        // create renderer
        final sdlRenderer = sdl.SDL_CreateRenderer(
            window, -1,
            SDL_RendererFlags.SDL_RENDERER_ACCELERATED.value | SDL_RendererFlags.SDL_RENDERER_PRESENTVSYNC.value
        );
        if (sdlRenderer == ffi.nullptr) {
            throw "failed to create SDL renderer";
        }

        // get dimensions
        const i32Width = 4 /*ffi.sizeOf<ffi.Int>()*/; // set to literal for micro optimization
        final chunk = malloc.allocate(2 * i32Width);
        final CA = chunk.address;
        ffi.Pointer<ffi.Int> windowWidth = ffi.Pointer.fromAddress(CA + i32Width * 0);
        ffi.Pointer<ffi.Int> windowHeight = ffi.Pointer.fromAddress(CA + i32Width * 1);
        sdl.SDL_GetWindowSize(window, windowWidth, windowHeight);

        this.eventHandler = null;
        this.width = windowWidth.value;
        this.height = windowHeight.value;
        this.sdlWindow = window;
        this.sdlRenderer = sdlRenderer;

        var success = 0 == sdl.SDL_SetRenderDrawColor(sdlRenderer, 0, 0, 0, 0);
        success = success && (0 == sdl.SDL_RenderClear(sdlRenderer));
        if (!success) {
            throw "SDLWindowError.WindowInitFail";
        }
    }

    void setCanvas(Canvas canvasPtr) {
        this.canvas = canvasPtr;
    }
    
    void setAppIcon(String path) {
        var cstr_path = path.toNativeUtf8();
        // var sdlIconSurface = sdl.IMG_Load(cstr_path);
        // sdl.SDL_SetWindowIcon(this.sdlWindow);
        malloc.free(cstr_path);
    }

    void render() {
        var pixels = cairo.cairo_image_surface_get_data(this.canvas.surface());
        // create sdl surface
        ffi.Pointer<SDL_Surface> sdlSurface = sdl.SDL_CreateRGBSurfaceFrom(
            pixels.cast(),
            this.width, this.height, // surface dimensions
            32, // bit depth
            cairo.cairo_format_stride_for_width(this.canvas.backend().format, this.width),
            0x00ff0000, 0x0000ff00, 0x000000ff, 0 // rgba masks
        );
        if (sdlSurface == ffi.nullptr) {
            throw "failed to create SDL surface";
        }

        final texture = sdl.SDL_CreateTextureFromSurface(this.sdlRenderer, sdlSurface);
        if (texture == ffi.nullptr) {
            throw "SDLWindowError.RenderFail";
        }

        sdl.SDL_RenderCopy(this.sdlRenderer, texture, ffi.nullptr, ffi.nullptr);
        sdl.SDL_UpdateWindowSurface(this.sdlWindow);
        sdl.SDL_RenderPresent(this.sdlRenderer);
        sdl.SDL_DestroyTexture(texture);
        sdl.SDL_FreeSurface(sdlSurface);
    }

    void free() {
        // sdl.SDL_DestroyTexture(self._texture);
        sdl.SDL_DestroyRenderer(this.sdlRenderer);
        sdl.SDL_DestroyWindow(this.sdlWindow);

        sdl.SDL_Quit();
    }

    void pollInput() {
        var eventPtr = malloc<SDL_Event>();
        var isPendingEvent = true;

        while (isPendingEvent) {
            isPendingEvent = sdl.SDL_PollEvent(eventPtr) == 1;
            final event = eventPtr.ref;

            var dcanvasEvent;
            switch (SDL_EventType.fromValue(event.type)) {
                case SDL_EventType.SDL_KEYDOWN:
                    dcanvasEvent = Event(
                        which: EventTypes.KeyDown,
                        data: event.key.keysym.sym
                    );
                case SDL_EventType.SDL_QUIT:
                    dcanvasEvent = Event(
                        which: EventTypes.Quit,
                        data: 0
                    );
                default:
                    dcanvasEvent = Event(
                        which: EventTypes.Unknown,
                        data: 0
                    );
            };

            final eventHandler = this.eventHandler;
            if (eventHandler != null) {
                eventHandler(dcanvasEvent);
            }
        }
    }
}

void initSDL(int flags) {
    if (sdl.SDL_Init(flags) != 0) {
        throw "SDLWindowError.SDLInitFail";
    }
}

void wait(int ms) {
    sdl.SDL_Delay(ms);
}
