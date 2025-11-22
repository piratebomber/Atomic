// AtomicUI - Cross-platform Window System
package AtomicUI.Window api;

import Std.String;
import Std.Platform;
import Std.Array;
import AtomicUI.Event;
import AtomicUI.Graphics;

// Window creation flags
choice WindowFlags {
    None,
    Resizable,
    Maximized,
    Minimized,
    Fullscreen,
    Borderless,
    AlwaysOnTop,
    ToolWindow
}

// Window state
choice WindowState {
    Normal,
    Minimized,
    Maximized,
    Fullscreen,
    Hidden
}

// Window position and size
struct Rect {
    var x: i32;
    var y: i32;
    var width: i32;
    var height: i32;
}

struct Point {
    var x: i32;
    var y: i32;
}

struct Size {
    var width: i32;
    var height: i32;
}

// Main Window class
class Window {
    var handle: i64;
    var title: String;
    var rect: Rect;
    var state: WindowState;
    var flags: Array(WindowFlags);
    var event_handlers: Array(EventHandler);
    var graphics_context: Optional(Graphics.Context);
    var is_visible: Bool;
    var is_closed: Bool;
    
    // Static factory method
    fn Create(title: String, width: i32, height: i32) -> Self {
        return CreateWithFlags(title, width, height, Array(WindowFlags)());
    }
    
    fn CreateWithFlags(title: String, width: i32, height: i32, flags: Array(WindowFlags)) -> Self {
        var window: Self = {
            .handle = 0,
            .title = title,
            .rect = {.x = 100, .y = 100, .width = width, .height = height},
            .state = WindowState.Normal,
            .flags = flags,
            .event_handlers = Array(EventHandler)(),
            .graphics_context = Optional(Graphics.Context).None(),
            .is_visible = False,
            .is_closed = False
        };
        
        window.CreateNativeWindow();
        return window;
    }
    
    // Window lifecycle
    fn Show(self: Self) {
        if (not self.is_closed) {
            self.ShowNativeWindow();
            self.is_visible = True;
        }
    }
    
    fn Hide(self: Self) {
        if (not self.is_closed) {
            self.HideNativeWindow();
            self.is_visible = False;
        }
    }
    
    fn Close(self: Self) {
        if (not self.is_closed) {
            self.CloseNativeWindow();
            self.is_closed = True;
            self.is_visible = False;
        }
    }
    
    // Window properties
    fn SetTitle(self: Self, title: String) {
        self.title = title;
        if (not self.is_closed) {
            self.SetNativeTitle(title);
        }
    }
    
    fn GetTitle(self: Self) -> String {
        return self.title;
    }
    
    fn SetPosition(self: Self, x: i32, y: i32) {
        self.rect.x = x;
        self.rect.y = y;
        if (not self.is_closed) {
            self.SetNativePosition(x, y);
        }
    }
    
    fn GetPosition(self: Self) -> Point {
        return {.x = self.rect.x, .y = self.rect.y};
    }
    
    fn SetSize(self: Self, width: i32, height: i32) {
        self.rect.width = width;
        self.rect.height = height;
        if (not self.is_closed) {
            self.SetNativeSize(width, height);
        }
    }
    
    fn GetSize(self: Self) -> Size {
        return {.width = self.rect.width, .height = self.rect.height};
    }
    
    fn SetRect(self: Self, rect: Rect) {
        self.rect = rect;
        if (not self.is_closed) {
            self.SetNativeRect(rect);
        }
    }
    
    fn GetRect(self: Self) -> Rect {
        return self.rect;
    }
    
    // Window state management
    fn Minimize(self: Self) {
        if (not self.is_closed) {
            self.MinimizeNativeWindow();
            self.state = WindowState.Minimized;
        }
    }
    
    fn Maximize(self: Self) {
        if (not self.is_closed) {
            self.MaximizeNativeWindow();
            self.state = WindowState.Maximized;
        }
    }
    
    fn Restore(self: Self) {
        if (not self.is_closed) {
            self.RestoreNativeWindow();
            self.state = WindowState.Normal;
        }
    }
    
    fn SetFullscreen(self: Self, fullscreen: Bool) {
        if (not self.is_closed) {
            if (fullscreen) {
                self.SetNativeFullscreen();
                self.state = WindowState.Fullscreen;
            } else {
                self.ExitNativeFullscreen();
                self.state = WindowState.Normal;
            }
        }
    }
    
    fn IsVisible(self: Self) -> Bool {
        return self.is_visible and not self.is_closed;
    }
    
    fn IsClosed(self: Self) -> Bool {
        return self.is_closed;
    }
    
    fn IsMinimized(self: Self) -> Bool {
        return self.state == WindowState.Minimized;
    }
    
    fn IsMaximized(self: Self) -> Bool {
        return self.state == WindowState.Maximized;
    }
    
    fn IsFullscreen(self: Self) -> Bool {
        return self.state == WindowState.Fullscreen;
    }
    
    // Event handling
    fn AddEventHandler(self: Self, handler: EventHandler) {
        self.event_handlers.Push(handler);
    }
    
    fn RemoveEventHandler(self: Self, handler: EventHandler) {
        // Implementation would remove the handler from the array
        var i: i32 = 0;
        while (i < self.event_handlers.Size()) {
            if (self.event_handlers[i].id == handler.id) {
                self.event_handlers.RemoveAt(i);
                break;
            }
            i += 1;
        }
    }
    
    fn ProcessEvents(self: Self) {
        if (not self.is_closed) {
            self.ProcessNativeEvents();
        }
    }
    
    // Graphics context
    fn GetGraphicsContext(self: Self) -> Optional(Graphics.Context) {
        if (not self.graphics_context.HasValue() and not self.is_closed) {
            var context: Graphics.Context = Graphics.Context.Create(self.handle);
            self.graphics_context = Optional(Graphics.Context).Some(context);
        }
        return self.graphics_context;
    }
    
    fn Invalidate(self: Self) {
        if (not self.is_closed) {
            self.InvalidateNativeWindow();
        }
    }
    
    fn InvalidateRect(self: Self, rect: Rect) {
        if (not self.is_closed) {
            self.InvalidateNativeRect(rect);
        }
    }
    
    // Platform-specific implementations
    fn CreateNativeWindow(self: Self) {
        match (Platform.GetCurrentOS()) {
            case (Platform.OS.Windows) {
                self.CreateWindowsWindow();
            }
            case (Platform.OS.Linux) {
                self.CreateX11Window();
            }
            case (Platform.OS.MacOS) {
                self.CreateCocoaWindow();
            }
            default {
                self.CreateX11Window(); // Fallback to X11
            }
        }
    }
    
    fn ShowNativeWindow(self: Self) {
        match (Platform.GetCurrentOS()) {
            case (Platform.OS.Windows) {
                ShowWindow(self.handle, 1); // SW_SHOW
            }
            case (Platform.OS.Linux) {
                XMapWindow(self.GetX11Display(), self.handle);
            }
            case (Platform.OS.MacOS) {
                self.ShowCocoaWindow();
            }
            default {
                XMapWindow(self.GetX11Display(), self.handle);
            }
        }
    }
    
    fn HideNativeWindow(self: Self) {
        match (Platform.GetCurrentOS()) {
            case (Platform.OS.Windows) {
                ShowWindow(self.handle, 0); // SW_HIDE
            }
            case (Platform.OS.Linux) {
                XUnmapWindow(self.GetX11Display(), self.handle);
            }
            case (Platform.OS.MacOS) {
                self.HideCocoaWindow();
            }
            default {
                XUnmapWindow(self.GetX11Display(), self.handle);
            }
        }
    }
    
    fn CloseNativeWindow(self: Self) {
        match (Platform.GetCurrentOS()) {
            case (Platform.OS.Windows) {
                DestroyWindow(self.handle);
            }
            case (Platform.OS.Linux) {
                XDestroyWindow(self.GetX11Display(), self.handle);
            }
            case (Platform.OS.MacOS) {
                self.CloseCocoaWindow();
            }
            default {
                XDestroyWindow(self.GetX11Display(), self.handle);
            }
        }
    }
    
    // Windows-specific implementation
    fn CreateWindowsWindow(self: Self) {
        var class_name: String = "AtomicUIWindow";
        var style: u32 = 0x00CF0000; // WS_OVERLAPPEDWINDOW
        
        // Apply flags
        var i: i32 = 0;
        while (i < self.flags.Size()) {
            match (self.flags[i]) {
                case (WindowFlags.Resizable) {
                    style |= 0x00040000; // WS_THICKFRAME
                }
                case (WindowFlags.Borderless) {
                    style = 0x80000000; // WS_POPUP
                }
                case (WindowFlags.AlwaysOnTop) {
                    // Will be set with SetWindowPos
                }
                default {}
            }
            i += 1;
        }
        
        var title_utf16: Array(u8) = StringToUtf16(self.title);
        var class_utf16: Array(u8) = StringToUtf16(class_name);
        
        self.handle = CreateWindowExW(
            0, // Extended style
            class_utf16.Data(),
            title_utf16.Data(),
            style,
            self.rect.x,
            self.rect.y,
            self.rect.width,
            self.rect.height,
            0, // Parent window
            0, // Menu
            GetModuleHandleW(null),
            null // Additional data
        );
    }
    
    fn SetNativeTitle(self: Self, title: String) {
        match (Platform.GetCurrentOS()) {
            case (Platform.OS.Windows) {
                var title_utf16: Array(u8) = StringToUtf16(title);
                SetWindowTextW(self.handle, title_utf16.Data());
            }
            case (Platform.OS.Linux) {
                var title_cstr: Array(u8) = StringToCString(title);
                XStoreName(self.GetX11Display(), self.handle, title_cstr.Data());
            }
            case (Platform.OS.MacOS) {
                self.SetCocoaTitle(title);
            }
            default {
                var title_cstr: Array(u8) = StringToCString(title);
                XStoreName(self.GetX11Display(), self.handle, title_cstr.Data());
            }
        }
    }
    
    fn SetNativePosition(self: Self, x: i32, y: i32) {
        match (Platform.GetCurrentOS()) {
            case (Platform.OS.Windows) {
                SetWindowPos(self.handle, 0, x, y, 0, 0, 0x0001 | 0x0004); // SWP_NOSIZE | SWP_NOZORDER
            }
            case (Platform.OS.Linux) {
                XMoveWindow(self.GetX11Display(), self.handle, x, y);
            }
            case (Platform.OS.MacOS) {
                self.SetCocoaPosition(x, y);
            }
            default {
                XMoveWindow(self.GetX11Display(), self.handle, x, y);
            }
        }
    }
    
    fn SetNativeSize(self: Self, width: i32, height: i32) {
        match (Platform.GetCurrentOS()) {
            case (Platform.OS.Windows) {
                SetWindowPos(self.handle, 0, 0, 0, width, height, 0x0002 | 0x0004); // SWP_NOMOVE | SWP_NOZORDER
            }
            case (Platform.OS.Linux) {
                XResizeWindow(self.GetX11Display(), self.handle, width, height);
            }
            case (Platform.OS.MacOS) {
                self.SetCocoaSize(width, height);
            }
            default {
                XResizeWindow(self.GetX11Display(), self.handle, width, height);
            }
        }
    }
    
    fn SetNativeRect(self: Self, rect: Rect) {
        match (Platform.GetCurrentOS()) {
            case (Platform.OS.Windows) {
                SetWindowPos(self.handle, 0, rect.x, rect.y, rect.width, rect.height, 0x0004); // SWP_NOZORDER
            }
            case (Platform.OS.Linux) {
                XMoveResizeWindow(self.GetX11Display(), self.handle, rect.x, rect.y, rect.width, rect.height);
            }
            case (Platform.OS.MacOS) {
                self.SetCocoaRect(rect);
            }
            default {
                XMoveResizeWindow(self.GetX11Display(), self.handle, rect.x, rect.y, rect.width, rect.height);
            }
        }
    }
    
    fn MinimizeNativeWindow(self: Self) {
        match (Platform.GetCurrentOS()) {
            case (Platform.OS.Windows) {
                ShowWindow(self.handle, 6); // SW_MINIMIZE
            }
            case (Platform.OS.Linux) {
                self.MinimizeX11Window();
            }
            case (Platform.OS.MacOS) {
                self.MinimizeCocoaWindow();
            }
            default {
                self.MinimizeX11Window();
            }
        }
    }
    
    fn MaximizeNativeWindow(self: Self) {
        match (Platform.GetCurrentOS()) {
            case (Platform.OS.Windows) {
                ShowWindow(self.handle, 3); // SW_MAXIMIZE
            }
            case (Platform.OS.Linux) {
                self.MaximizeX11Window();
            }
            case (Platform.OS.MacOS) {
                self.MaximizeCocoaWindow();
            }
            default {
                self.MaximizeX11Window();
            }
        }
    }
    
    fn RestoreNativeWindow(self: Self) {
        match (Platform.GetCurrentOS()) {
            case (Platform.OS.Windows) {
                ShowWindow(self.handle, 9); // SW_RESTORE
            }
            case (Platform.OS.Linux) {
                self.RestoreX11Window();
            }
            case (Platform.OS.MacOS) {
                self.RestoreCocoaWindow();
            }
            default {
                self.RestoreX11Window();
            }
        }
    }
    
    fn ProcessNativeEvents(self: Self) {
        match (Platform.GetCurrentOS()) {
            case (Platform.OS.Windows) {
                self.ProcessWindowsEvents();
            }
            case (Platform.OS.Linux) {
                self.ProcessX11Events();
            }
            case (Platform.OS.MacOS) {
                self.ProcessCocoaEvents();
            }
            default {
                self.ProcessX11Events();
            }
        }
    }
    
    fn ProcessWindowsEvents(self: Self) {
        var msg: MSG;
        while (PeekMessageW(&msg, self.handle, 0, 0, 1)) { // PM_REMOVE
            TranslateMessage(&msg);
            DispatchMessageW(&msg);
        }
    }
    
    fn InvalidateNativeWindow(self: Self) {
        match (Platform.GetCurrentOS()) {
            case (Platform.OS.Windows) {
                InvalidateRect(self.handle, null, True);
            }
            case (Platform.OS.Linux) {
                self.InvalidateX11Window();
            }
            case (Platform.OS.MacOS) {
                self.InvalidateCocoaWindow();
            }
            default {
                self.InvalidateX11Window();
            }
        }
    }
    
    fn InvalidateNativeRect(self: Self, rect: Rect) {
        match (Platform.GetCurrentOS()) {
            case (Platform.OS.Windows) {
                var win_rect: RECT = {
                    .left = rect.x,
                    .top = rect.y,
                    .right = rect.x + rect.width,
                    .bottom = rect.y + rect.height
                };
                InvalidateRect(self.handle, &win_rect, True);
            }
            case (Platform.OS.Linux) {
                self.InvalidateX11Rect(rect);
            }
            case (Platform.OS.MacOS) {
                self.InvalidateCocoaRect(rect);
            }
            default {
                self.InvalidateX11Rect(rect);
            }
        }
    }
    
    // X11 helper methods
    fn GetX11Display(self: Self) -> *Display {
        // This would be stored globally or per-application
        return XOpenDisplay(null);
    }
    
    fn CreateX11Window(self: Self) {
        var display: *Display = self.GetX11Display();
        var screen: i32 = DefaultScreen(display);
        var root: u64 = RootWindow(display, screen);
        
        self.handle = XCreateSimpleWindow(
            display,
            root,
            self.rect.x,
            self.rect.y,
            self.rect.width,
            self.rect.height,
            1, // Border width
            BlackPixel(display, screen),
            WhitePixel(display, screen)
        );
        
        var title_cstr: Array(u8) = StringToCString(self.title);
        XStoreName(display, self.handle, title_cstr.Data());
        
        XSelectInput(display, self.handle, 
            0x00008000 | // ExposureMask
            0x00000001 | // KeyPressMask
            0x00000002 | // KeyReleaseMask
            0x00000004 | // ButtonPressMask
            0x00000008 | // ButtonReleaseMask
            0x00000040 | // PointerMotionMask
            0x00020000   // StructureNotifyMask
        );
    }
    
    // Cocoa helper methods (macOS)
    fn CreateCocoaWindow(self: Self) {
        // Implementation would use Objective-C runtime to create NSWindow
        // This is a simplified placeholder
        self.handle = self.CreateNSWindow();
    }
    
    fn CreateNSWindow(self: Self) -> i64 {
        // Objective-C runtime calls would go here
        return 0; // Placeholder
    }
}

// Event handler interface
struct EventHandler {
    var id: i32;
    var callback: fn(Event.WindowEvent) -> Void;
}

// Platform-specific system calls and structures
// Windows API
fn CreateWindowExW(ex_style: u32, class_name: *u16, window_name: *u16, style: u32, 
                   x: i32, y: i32, width: i32, height: i32, parent: i64, menu: i64, 
                   instance: i64, param: *Void) -> i64;
fn ShowWindow(hwnd: i64, cmd_show: i32) -> Bool;
fn DestroyWindow(hwnd: i64) -> Bool;
fn SetWindowTextW(hwnd: i64, text: *u16) -> Bool;
fn SetWindowPos(hwnd: i64, insert_after: i64, x: i32, y: i32, cx: i32, cy: i32, flags: u32) -> Bool;
fn GetModuleHandleW(module_name: *u16) -> i64;
fn PeekMessageW(msg: *MSG, hwnd: i64, filter_min: u32, filter_max: u32, remove: u32) -> Bool;
fn TranslateMessage(msg: *MSG) -> Bool;
fn DispatchMessageW(msg: *MSG) -> i64;
fn InvalidateRect(hwnd: i64, rect: *RECT, erase: Bool) -> Bool;

// X11 API
fn XOpenDisplay(display_name: *u8) -> *Display;
fn XCreateSimpleWindow(display: *Display, parent: u64, x: i32, y: i32, width: u32, height: u32,
                       border_width: u32, border: u64, background: u64) -> u64;
fn XMapWindow(display: *Display, window: u64) -> i32;
fn XUnmapWindow(display: *Display, window: u64) -> i32;
fn XDestroyWindow(display: *Display, window: u64) -> i32;
fn XStoreName(display: *Display, window: u64, name: *u8) -> i32;
fn XMoveWindow(display: *Display, window: u64, x: i32, y: i32) -> i32;
fn XResizeWindow(display: *Display, window: u64, width: u32, height: u32) -> i32;
fn XMoveResizeWindow(display: *Display, window: u64, x: i32, y: i32, width: u32, height: u32) -> i32;
fn XSelectInput(display: *Display, window: u64, event_mask: i64) -> i32;
fn DefaultScreen(display: *Display) -> i32;
fn RootWindow(display: *Display, screen: i32) -> u64;
fn BlackPixel(display: *Display, screen: i32) -> u64;
fn WhitePixel(display: *Display, screen: i32) -> u64;

// Platform structures
struct MSG {
    var hwnd: i64;
    var message: u32;
    var wParam: u64;
    var lParam: i64;
    var time: u32;
    var pt: POINT;
}

struct POINT {
    var x: i32;
    var y: i32;
}

struct RECT {
    var left: i32;
    var top: i32;
    var right: i32;
    var bottom: i32;
}

// X11 opaque types
struct Display; // Opaque X11 display structure