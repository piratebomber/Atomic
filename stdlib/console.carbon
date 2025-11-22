// Atomic Standard Library - Console I/O
package Std.Console api;

import Std.String;
import Std.Platform;
import Std.Memory;

// Platform detection
fn GetPlatform() -> Platform.OS {
    return Platform.GetCurrentOS();
}

// Console output functions
fn WriteLine(message: String) {
    match (GetPlatform()) {
        case (Platform.OS.Windows) {
            WindowsWriteLine(message);
        }
        case (Platform.OS.Linux) {
            UnixWriteLine(message);
        }
        case (Platform.OS.MacOS) {
            UnixWriteLine(message);
        }
        default {
            UnixWriteLine(message);
        }
    }
}

fn Write(message: String) {
    match (GetPlatform()) {
        case (Platform.OS.Windows) {
            WindowsWrite(message);
        }
        case (Platform.OS.Linux) {
            UnixWrite(message);
        }
        case (Platform.OS.MacOS) {
            UnixWrite(message);
        }
        default {
            UnixWrite(message);
        }
    }
}

fn WriteError(message: String) {
    match (GetPlatform()) {
        case (Platform.OS.Windows) {
            WindowsWriteError(message);
        }
        case (Platform.OS.Linux) {
            UnixWriteError(message);
        }
        case (Platform.OS.MacOS) {
            UnixWriteError(message);
        }
        default {
            UnixWriteError(message);
        }
    }
}

// Console input functions
fn ReadLine() -> String {
    match (GetPlatform()) {
        case (Platform.OS.Windows) {
            return WindowsReadLine();
        }
        case (Platform.OS.Linux) {
            return UnixReadLine();
        }
        case (Platform.OS.MacOS) {
            return UnixReadLine();
        }
        default {
            return UnixReadLine();
        }
    }
}

fn ReadKey() -> i32 {
    match (GetPlatform()) {
        case (Platform.OS.Windows) {
            return WindowsReadKey();
        }
        case (Platform.OS.Linux) {
            return UnixReadKey();
        }
        case (Platform.OS.MacOS) {
            return UnixReadKey();
        }
        default {
            return UnixReadKey();
        }
    }
}

// Formatted output
fn WriteLineFormatted(format: String, args: Array(String)) {
    var formatted: String = FormatString(format, args);
    WriteLine(formatted);
}

fn WriteFormatted(format: String, args: Array(String)) {
    var formatted: String = FormatString(format, args);
    Write(formatted);
}

// Helper function for string formatting
fn FormatString(format: String, args: Array(String)) -> String {
    var result: String = format;
    var i: i32 = 0;
    
    while (i < args.Size()) {
        var placeholder: String = "{" + IntToString(i) + "}";
        result = result.Replace(placeholder, args[i]);
        i += 1;
    }
    
    return result;
}

// Clear console
fn Clear() {
    match (GetPlatform()) {
        case (Platform.OS.Windows) {
            WindowsClear();
        }
        case (Platform.OS.Linux) {
            UnixClear();
        }
        case (Platform.OS.MacOS) {
            UnixClear();
        }
        default {
            UnixClear();
        }
    }
}

// Set console colors (platform-specific)
choice ConsoleColor {
    Black,
    DarkBlue,
    DarkGreen,
    DarkCyan,
    DarkRed,
    DarkMagenta,
    DarkYellow,
    Gray,
    DarkGray,
    Blue,
    Green,
    Cyan,
    Red,
    Magenta,
    Yellow,
    White
}

fn SetForegroundColor(color: ConsoleColor) {
    match (GetPlatform()) {
        case (Platform.OS.Windows) {
            WindowsSetForegroundColor(ColorToInt(color));
        }
        case (Platform.OS.Linux) {
            UnixSetForegroundColor(ColorToInt(color));
        }
        case (Platform.OS.MacOS) {
            UnixSetForegroundColor(ColorToInt(color));
        }
        default {
            UnixSetForegroundColor(ColorToInt(color));
        }
    }
}

fn SetBackgroundColor(color: ConsoleColor) {
    match (GetPlatform()) {
        case (Platform.OS.Windows) {
            WindowsSetBackgroundColor(ColorToInt(color));
        }
        case (Platform.OS.Linux) {
            UnixSetBackgroundColor(ColorToInt(color));
        }
        case (Platform.OS.MacOS) {
            UnixSetBackgroundColor(ColorToInt(color));
        }
        default {
            UnixSetBackgroundColor(ColorToInt(color));
        }
    }
}

fn ResetColors() {
    match (GetPlatform()) {
        case (Platform.OS.Windows) {
            WindowsResetColors();
        }
        case (Platform.OS.Linux) {
            UnixResetColors();
        }
        case (Platform.OS.MacOS) {
            UnixResetColors();
        }
        default {
            UnixResetColors();
        }
    }
}

// Helper function to convert color enum to integer
fn ColorToInt(color: ConsoleColor) -> i32 {
    match (color) {
        case (ConsoleColor.Black) { return 0; }
        case (ConsoleColor.DarkBlue) { return 1; }
        case (ConsoleColor.DarkGreen) { return 2; }
        case (ConsoleColor.DarkCyan) { return 3; }
        case (ConsoleColor.DarkRed) { return 4; }
        case (ConsoleColor.DarkMagenta) { return 5; }
        case (ConsoleColor.DarkYellow) { return 6; }
        case (ConsoleColor.Gray) { return 7; }
        case (ConsoleColor.DarkGray) { return 8; }
        case (ConsoleColor.Blue) { return 9; }
        case (ConsoleColor.Green) { return 10; }
        case (ConsoleColor.Cyan) { return 11; }
        case (ConsoleColor.Red) { return 12; }
        case (ConsoleColor.Magenta) { return 13; }
        case (ConsoleColor.Yellow) { return 14; }
        case (ConsoleColor.White) { return 15; }
    }
}

// Windows-specific implementations
fn WindowsWriteLine(message: String) {
    var handle: i64 = GetStdHandle(-11); // STD_OUTPUT_HANDLE
    var buffer: Array(u8) = StringToUtf16(message + "\r\n");
    var written: u32 = 0;
    WriteConsoleW(handle, buffer.Data(), buffer.Size() / 2, &written, 0);
}

fn WindowsWrite(message: String) {
    var handle: i64 = GetStdHandle(-11);
    var buffer: Array(u8) = StringToUtf16(message);
    var written: u32 = 0;
    WriteConsoleW(handle, buffer.Data(), buffer.Size() / 2, &written, 0);
}

fn WindowsWriteError(message: String) {
    var handle: i64 = GetStdHandle(-12); // STD_ERROR_HANDLE
    var buffer: Array(u8) = StringToUtf16(message + "\r\n");
    var written: u32 = 0;
    WriteConsoleW(handle, buffer.Data(), buffer.Size() / 2, &written, 0);
}

fn WindowsReadLine() -> String {
    var handle: i64 = GetStdHandle(-10); // STD_INPUT_HANDLE
    var buffer: Array(u16) = Array(u16)(256);
    var read: u32 = 0;
    ReadConsoleW(handle, buffer.Data(), 256, &read, 0);
    return Utf16ToString(buffer, read - 2); // Remove \r\n
}

fn WindowsReadKey() -> i32 {
    var handle: i64 = GetStdHandle(-10);
    var record: INPUT_RECORD;
    var read: u32 = 0;
    
    while (True) {
        ReadConsoleInputW(handle, &record, 1, &read);
        if (record.EventType == 1 and record.Event.KeyEvent.bKeyDown) { // KEY_EVENT
            return record.Event.KeyEvent.wVirtualKeyCode;
        }
    }
    return 0;
}

fn WindowsClear() {
    var handle: i64 = GetStdHandle(-11);
    var info: CONSOLE_SCREEN_BUFFER_INFO;
    GetConsoleScreenBufferInfo(handle, &info);
    
    var size: u32 = info.dwSize.X * info.dwSize.Y;
    var written: u32 = 0;
    var coord: COORD = {.X = 0, .Y = 0};
    
    FillConsoleOutputCharacterW(handle, ' ', size, coord, &written);
    SetConsoleCursorPosition(handle, coord);
}

fn WindowsSetForegroundColor(color: i32) {
    var handle: i64 = GetStdHandle(-11);
    var info: CONSOLE_SCREEN_BUFFER_INFO;
    GetConsoleScreenBufferInfo(handle, &info);
    SetConsoleTextAttribute(handle, (info.wAttributes & 0xF0) | color);
}

fn WindowsSetBackgroundColor(color: i32) {
    var handle: i64 = GetStdHandle(-11);
    var info: CONSOLE_SCREEN_BUFFER_INFO;
    GetConsoleScreenBufferInfo(handle, &info);
    SetConsoleTextAttribute(handle, (info.wAttributes & 0x0F) | (color << 4));
}

fn WindowsResetColors() {
    var handle: i64 = GetStdHandle(-11);
    SetConsoleTextAttribute(handle, 7); // Default: white on black
}

// Unix/Linux/macOS implementations
fn UnixWriteLine(message: String) {
    var buffer: Array(u8) = StringToUtf8(message + "\n");
    write(1, buffer.Data(), buffer.Size()); // stdout
}

fn UnixWrite(message: String) {
    var buffer: Array(u8) = StringToUtf8(message);
    write(1, buffer.Data(), buffer.Size());
}

fn UnixWriteError(message: String) {
    var buffer: Array(u8) = StringToUtf8(message + "\n");
    write(2, buffer.Data(), buffer.Size()); // stderr
}

fn UnixReadLine() -> String {
    var buffer: Array(u8) = Array(u8)(256);
    var bytes_read: i64 = read(0, buffer.Data(), 255); // stdin
    if (bytes_read > 0 and buffer[bytes_read - 1] == '\n') {
        bytes_read -= 1; // Remove newline
    }
    return Utf8ToString(buffer, bytes_read);
}

fn UnixReadKey() -> i32 {
    // Set terminal to raw mode
    var old_termios: termios;
    var new_termios: termios;
    tcgetattr(0, &old_termios);
    new_termios = old_termios;
    new_termios.c_lflag &= ~(ICANON | ECHO);
    tcsetattr(0, TCSANOW, &new_termios);
    
    var ch: u8;
    read(0, &ch, 1);
    
    // Restore terminal mode
    tcsetattr(0, TCSANOW, &old_termios);
    return ch;
}

fn UnixClear() {
    write(1, "\x1b[2J\x1b[H", 7); // ANSI escape codes
}

fn UnixSetForegroundColor(color: i32) {
    var ansi_code: String = "\x1b[3" + IntToString(color % 8) + "m";
    var buffer: Array(u8) = StringToUtf8(ansi_code);
    write(1, buffer.Data(), buffer.Size());
}

fn UnixSetBackgroundColor(color: i32) {
    var ansi_code: String = "\x1b[4" + IntToString(color % 8) + "m";
    var buffer: Array(u8) = StringToUtf8(ansi_code);
    write(1, buffer.Data(), buffer.Size());
}

fn UnixResetColors() {
    write(1, "\x1b[0m", 4); // ANSI reset
}

// Platform-specific system call declarations
// Windows API
fn GetStdHandle(handle_id: i32) -> i64;
fn WriteConsoleW(handle: i64, buffer: *u16, chars: u32, written: *u32, reserved: i64) -> Bool;
fn ReadConsoleW(handle: i64, buffer: *u16, chars: u32, read: *u32, reserved: i64) -> Bool;
fn ReadConsoleInputW(handle: i64, buffer: *INPUT_RECORD, length: u32, read: *u32) -> Bool;
fn GetConsoleScreenBufferInfo(handle: i64, info: *CONSOLE_SCREEN_BUFFER_INFO) -> Bool;
fn SetConsoleCursorPosition(handle: i64, pos: COORD) -> Bool;
fn FillConsoleOutputCharacterW(handle: i64, ch: u16, length: u32, pos: COORD, written: *u32) -> Bool;
fn SetConsoleTextAttribute(handle: i64, attributes: u16) -> Bool;

// Unix system calls
fn write(fd: i32, buffer: *u8, count: u64) -> i64;
fn read(fd: i32, buffer: *u8, count: u64) -> i64;
fn tcgetattr(fd: i32, termios_p: *termios) -> i32;
fn tcsetattr(fd: i32, optional_actions: i32, termios_p: *termios) -> i32;

// Windows structures
struct COORD {
    var X: i16;
    var Y: i16;
}

struct SMALL_RECT {
    var Left: i16;
    var Top: i16;
    var Right: i16;
    var Bottom: i16;
}

struct CONSOLE_SCREEN_BUFFER_INFO {
    var dwSize: COORD;
    var dwCursorPosition: COORD;
    var wAttributes: u16;
    var srWindow: SMALL_RECT;
    var dwMaximumWindowSize: COORD;
}

struct KEY_EVENT_RECORD {
    var bKeyDown: Bool;
    var wRepeatCount: u16;
    var wVirtualKeyCode: u16;
    var wVirtualScanCode: u16;
    var uChar: u16;
    var dwControlKeyState: u32;
}

struct INPUT_RECORD {
    var EventType: u16;
    var Event: KEY_EVENT_RECORD; // Union in real implementation
}

// Unix structures
struct termios {
    var c_iflag: u32;
    var c_oflag: u32;
    var c_cflag: u32;
    var c_lflag: u32;
    var c_cc: Array(u8); // NCCS elements
}

// Constants
let ICANON: u32 = 0x00000002;
let ECHO: u32 = 0x00000008;
let TCSANOW: i32 = 0;