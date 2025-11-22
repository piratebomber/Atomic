// Atomic Standard Library - Platform Detection
package Std.Platform api;

// Operating system enumeration
choice OS {
    Windows,
    Linux,
    MacOS,
    FreeBSD,
    OpenBSD,
    NetBSD,
    Solaris,
    Unknown
}

// Architecture enumeration
choice Architecture {
    X86,
    X64,
    ARM,
    ARM64,
    MIPS,
    MIPS64,
    PowerPC,
    PowerPC64,
    SPARC,
    SPARC64,
    Unknown
}

// Platform information structure
struct PlatformInfo {
    var os: OS;
    var architecture: Architecture;
    var version: String;
    var hostname: String;
    var username: String;
}

// Get current operating system
fn GetCurrentOS() -> OS {
    #if (ATOMIC_TARGET_WINDOWS) {
        return OS.Windows;
    } #elif (ATOMIC_TARGET_LINUX) {
        return OS.Linux;
    } #elif (ATOMIC_TARGET_MACOS) {
        return OS.MacOS;
    } #elif (ATOMIC_TARGET_FREEBSD) {
        return OS.FreeBSD;
    } #elif (ATOMIC_TARGET_OPENBSD) {
        return OS.OpenBSD;
    } #elif (ATOMIC_TARGET_NETBSD) {
        return OS.NetBSD;
    } #elif (ATOMIC_TARGET_SOLARIS) {
        return OS.Solaris;
    } #else {
        return OS.Unknown;
    }
}

// Get current architecture
fn GetCurrentArchitecture() -> Architecture {
    #if (ATOMIC_TARGET_X86) {
        return Architecture.X86;
    } #elif (ATOMIC_TARGET_X64) {
        return Architecture.X64;
    } #elif (ATOMIC_TARGET_ARM) {
        return Architecture.ARM;
    } #elif (ATOMIC_TARGET_ARM64) {
        return Architecture.ARM64;
    } #elif (ATOMIC_TARGET_MIPS) {
        return Architecture.MIPS;
    } #elif (ATOMIC_TARGET_MIPS64) {
        return Architecture.MIPS64;
    } #elif (ATOMIC_TARGET_POWERPC) {
        return Architecture.PowerPC;
    } #elif (ATOMIC_TARGET_POWERPC64) {
        return Architecture.PowerPC64;
    } #elif (ATOMIC_TARGET_SPARC) {
        return Architecture.SPARC;
    } #elif (ATOMIC_TARGET_SPARC64) {
        return Architecture.SPARC64;
    } #else {
        return Architecture.Unknown;
    }
}

// Get comprehensive platform information
fn GetPlatformInfo() -> PlatformInfo {
    return {
        .os = GetCurrentOS(),
        .architecture = GetCurrentArchitecture(),
        .version = GetOSVersion(),
        .hostname = GetHostname(),
        .username = GetUsername()
    };
}

// Get OS version string
fn GetOSVersion() -> String {
    match (GetCurrentOS()) {
        case (OS.Windows) {
            return GetWindowsVersion();
        }
        case (OS.Linux) {
            return GetLinuxVersion();
        }
        case (OS.MacOS) {
            return GetMacOSVersion();
        }
        default {
            return "Unknown";
        }
    }
}

// Get system hostname
fn GetHostname() -> String {
    match (GetCurrentOS()) {
        case (OS.Windows) {
            return GetWindowsHostname();
        }
        default {
            return GetUnixHostname();
        }
    }
}

// Get current username
fn GetUsername() -> String {
    match (GetCurrentOS()) {
        case (OS.Windows) {
            return GetWindowsUsername();
        }
        default {
            return GetUnixUsername();
        }
    }
}

// Check if running on specific platforms
fn IsWindows() -> Bool {
    return GetCurrentOS() == OS.Windows;
}

fn IsLinux() -> Bool {
    return GetCurrentOS() == OS.Linux;
}

fn IsMacOS() -> Bool {
    return GetCurrentOS() == OS.MacOS;
}

fn IsUnix() -> Bool {
    var os: OS = GetCurrentOS();
    return os == OS.Linux or os == OS.MacOS or 
           os == OS.FreeBSD or os == OS.OpenBSD or 
           os == OS.NetBSD or os == OS.Solaris;
}

fn Is64Bit() -> Bool {
    var arch: Architecture = GetCurrentArchitecture();
    return arch == Architecture.X64 or arch == Architecture.ARM64 or
           arch == Architecture.MIPS64 or arch == Architecture.PowerPC64 or
           arch == Architecture.SPARC64;
}

// Platform-specific implementations
fn GetWindowsVersion() -> String {
    var info: OSVERSIONINFOW;
    info.dwOSVersionInfoSize = SizeOf(OSVERSIONINFOW);
    
    if (GetVersionExW(&info)) {
        return IntToString(info.dwMajorVersion) + "." + 
               IntToString(info.dwMinorVersion) + "." + 
               IntToString(info.dwBuildNumber);
    }
    
    return "Unknown";
}

fn GetLinuxVersion() -> String {
    var info: utsname;
    if (uname(&info) == 0) {
        return CStringToString(info.release);
    }
    return "Unknown";
}

fn GetMacOSVersion() -> String {
    var info: utsname;
    if (uname(&info) == 0) {
        return CStringToString(info.release);
    }
    return "Unknown";
}

fn GetWindowsHostname() -> String {
    var buffer: Array(u16) = Array(u16)(256);
    var size: u32 = 256;
    
    if (GetComputerNameW(buffer.Data(), &size)) {
        return Utf16ToString(buffer, size);
    }
    
    return "Unknown";
}

fn GetUnixHostname() -> String {
    var buffer: Array(u8) = Array(u8)(256);
    
    if (gethostname(buffer.Data(), 256) == 0) {
        return CStringToString(buffer.Data());
    }
    
    return "Unknown";
}

fn GetWindowsUsername() -> String {
    var buffer: Array(u16) = Array(u16)(256);
    var size: u32 = 256;
    
    if (GetUserNameW(buffer.Data(), &size)) {
        return Utf16ToString(buffer, size - 1); // Remove null terminator
    }
    
    return "Unknown";
}

fn GetUnixUsername() -> String {
    var uid: u32 = getuid();
    var pwd: *passwd = getpwuid(uid);
    
    if (pwd != null) {
        return CStringToString(pwd.pw_name);
    }
    
    return "Unknown";
}

// Environment variables
fn GetEnvironmentVariable(name: String) -> Optional(String) {
    match (GetCurrentOS()) {
        case (OS.Windows) {
            return GetWindowsEnvironmentVariable(name);
        }
        default {
            return GetUnixEnvironmentVariable(name);
        }
    }
}

fn SetEnvironmentVariable(name: String, value: String) -> Bool {
    match (GetCurrentOS()) {
        case (OS.Windows) {
            return SetWindowsEnvironmentVariable(name, value);
        }
        default {
            return SetUnixEnvironmentVariable(name, value);
        }
    }
}

fn GetWindowsEnvironmentVariable(name: String) -> Optional(String) {
    var name_utf16: Array(u8) = StringToUtf16(name);
    var buffer: Array(u16) = Array(u16)(32768);
    
    var result: u32 = GetEnvironmentVariableW(name_utf16.Data(), buffer.Data(), 32768);
    if (result > 0 and result < 32768) {
        return Optional(String).Some(Utf16ToString(buffer, result));
    }
    
    return Optional(String).None();
}

fn GetUnixEnvironmentVariable(name: String) -> Optional(String) {
    var name_cstr: Array(u8) = StringToCString(name);
    var result: *u8 = getenv(name_cstr.Data());
    
    if (result != null) {
        return Optional(String).Some(CStringToString(result));
    }
    
    return Optional(String).None();
}

fn SetWindowsEnvironmentVariable(name: String, value: String) -> Bool {
    var name_utf16: Array(u8) = StringToUtf16(name);
    var value_utf16: Array(u8) = StringToUtf16(value);
    
    return SetEnvironmentVariableW(name_utf16.Data(), value_utf16.Data());
}

fn SetUnixEnvironmentVariable(name: String, value: String) -> Bool {
    var name_cstr: Array(u8) = StringToCString(name);
    var value_cstr: Array(u8) = StringToCString(value);
    
    return setenv(name_cstr.Data(), value_cstr.Data(), 1) == 0;
}

// System call declarations
// Windows API
fn GetVersionExW(info: *OSVERSIONINFOW) -> Bool;
fn GetComputerNameW(buffer: *u16, size: *u32) -> Bool;
fn GetUserNameW(buffer: *u16, size: *u32) -> Bool;
fn GetEnvironmentVariableW(name: *u16, buffer: *u16, size: u32) -> u32;
fn SetEnvironmentVariableW(name: *u16, value: *u16) -> Bool;

// Unix system calls
fn uname(info: *utsname) -> i32;
fn gethostname(name: *u8, len: u64) -> i32;
fn getuid() -> u32;
fn getpwuid(uid: u32) -> *passwd;
fn getenv(name: *u8) -> *u8;
fn setenv(name: *u8, value: *u8, overwrite: i32) -> i32;

// Platform-specific structures
// Windows
struct OSVERSIONINFOW {
    var dwOSVersionInfoSize: u32;
    var dwMajorVersion: u32;
    var dwMinorVersion: u32;
    var dwBuildNumber: u32;
    var dwPlatformId: u32;
    var szCSDVersion: Array(u16); // 128 elements
}

// Unix
struct utsname {
    var sysname: Array(u8);  // 65 elements
    var nodename: Array(u8); // 65 elements
    var release: Array(u8);  // 65 elements
    var version: Array(u8);  // 65 elements
    var machine: Array(u8);  // 65 elements
}

struct passwd {
    var pw_name: *u8;
    var pw_passwd: *u8;
    var pw_uid: u32;
    var pw_gid: u32;
    var pw_gecos: *u8;
    var pw_dir: *u8;
    var pw_shell: *u8;
}