// Atomic Standard Library - File System Operations
package Std.FileSystem api;

import Std.String;
import Std.Array;
import Std.Platform;
import Std.Memory;
import Std.Collections;

// File and directory information
struct FileInfo {
    var name: String;
    var full_path: String;
    var size: u64;
    var is_directory: Bool;
    var is_readonly: Bool;
    var is_hidden: Bool;
    var created_time: u64;
    var modified_time: u64;
    var accessed_time: u64;
}

struct DirectoryEntry {
    var name: String;
    var is_directory: Bool;
}

// File operations
class File {
    var handle: i64;
    var path: String;
    var is_open: Bool;
    var mode: FileMode;
    
    fn Open(path: String, mode: FileMode) -> Result(Self, String) {
        var file: Self = {
            .handle = -1,
            .path = path,
            .is_open = False,
            .mode = mode
        };
        
        var result: Result(i64, String) = file.OpenNative();
        if (not result.IsOk()) {
            return Result(Self, String).Error(result.Error());
        }
        
        file.handle = result.Value();
        file.is_open = True;
        return Result(Self, String).Ok(file);
    }
    
    fn Create(path: String) -> Result(Self, String) {
        return File.Open(path, FileMode.Write);
    }
    
    fn Read(self: Self, buffer: Array(u8)) -> Result(u64, String) {
        if (not self.is_open) {
            return Result(u64, String).Error("File not open");
        }
        
        return self.ReadNative(buffer);
    }
    
    fn ReadAll(self: Self) -> Result(Array(u8), String) {
        if (not self.is_open) {
            return Result(Array(u8), String).Error("File not open");
        }
        
        var size_result: Result(u64, String) = self.GetSize();
        if (not size_result.IsOk()) {
            return Result(Array(u8), String).Error(size_result.Error());
        }
        
        var size: u64 = size_result.Value();
        var buffer: Array(u8) = Array(u8)(size);
        
        var read_result: Result(u64, String) = self.Read(buffer);
        if (not read_result.IsOk()) {
            return Result(Array(u8), String).Error(read_result.Error());
        }
        
        return Result(Array(u8), String).Ok(buffer);
    }
    
    fn ReadString(self: Self) -> Result(String, String) {
        var bytes_result: Result(Array(u8), String) = self.ReadAll();
        if (not bytes_result.IsOk()) {
            return Result(String, String).Error(bytes_result.Error());
        }
        
        var content: String = Utf8ToString(bytes_result.Value());
        return Result(String, String).Ok(content);
    }
    
    fn Write(self: Self, data: Array(u8)) -> Result(u64, String) {
        if (not self.is_open) {
            return Result(u64, String).Error("File not open");
        }
        
        return self.WriteNative(data);
    }
    
    fn WriteString(self: Self, text: String) -> Result(u64, String) {
        var bytes: Array(u8) = StringToUtf8(text);
        return self.Write(bytes);
    }
    
    fn Seek(self: Self, position: u64, origin: SeekOrigin) -> Result(u64, String) {
        if (not self.is_open) {
            return Result(u64, String).Error("File not open");
        }
        
        return self.SeekNative(position, origin);
    }
    
    fn Tell(self: Self) -> Result(u64, String) {
        return self.Seek(0, SeekOrigin.Current);
    }
    
    fn GetSize(self: Self) -> Result(u64, String) {
        if (not self.is_open) {
            return Result(u64, String).Error("File not open");
        }
        
        return self.GetSizeNative();
    }
    
    fn Flush(self: Self) -> Result(Bool, String) {
        if (not self.is_open) {
            return Result(Bool, String).Error("File not open");
        }
        
        return self.FlushNative();
    }
    
    fn Close(self: Self) -> Result(Bool, String) {
        if (not self.is_open) {
            return Result(Bool, String).Ok(True);
        }
        
        var result: Result(Bool, String) = self.CloseNative();
        if (result.IsOk()) {
            self.is_open = False;
        }
        
        return result;
    }
    
    // Platform-specific implementations
    fn OpenNative(self: Self) -> Result(i64, String) {
        match (Platform.GetCurrentOS()) {
            case (Platform.OS.Windows) {
                return self.OpenWindows();
            }
            default {
                return self.OpenUnix();
            }
        }
    }
    
    fn OpenWindows(self: Self) -> Result(i64, String) {
        var path_utf16: Array(u8) = StringToUtf16(self.path);
        var access: u32 = 0;
        var creation: u32 = 0;
        
        match (self.mode) {
            case (FileMode.Read) {
                access = 0x80000000; // GENERIC_READ
                creation = 3; // OPEN_EXISTING
            }
            case (FileMode.Write) {
                access = 0x40000000; // GENERIC_WRITE
                creation = 2; // CREATE_ALWAYS
            }
            case (FileMode.ReadWrite) {
                access = 0x80000000 | 0x40000000; // GENERIC_READ | GENERIC_WRITE
                creation = 4; // OPEN_ALWAYS
            }
            case (FileMode.Append) {
                access = 0x40000000; // GENERIC_WRITE
                creation = 4; // OPEN_ALWAYS
            }
        }
        
        var handle: i64 = CreateFileW(
            path_utf16.Data(),
            access,
            1 | 2, // FILE_SHARE_READ | FILE_SHARE_WRITE
            null,
            creation,
            0x80, // FILE_ATTRIBUTE_NORMAL
            0
        );
        
        if (handle == -1) {
            return Result(i64, String).Error("Failed to open file");
        }
        
        // Seek to end for append mode
        if (self.mode == FileMode.Append) {
            SetFilePointer(handle, 0, null, 2); // FILE_END
        }
        
        return Result(i64, String).Ok(handle);
    }
    
    fn OpenUnix(self: Self) -> Result(i64, String) {
        var path_cstr: Array(u8) = StringToCString(self.path);
        var flags: i32 = 0;
        
        match (self.mode) {
            case (FileMode.Read) {
                flags = 0; // O_RDONLY
            }
            case (FileMode.Write) {
                flags = 1 | 64 | 512; // O_WRONLY | O_CREAT | O_TRUNC
            }
            case (FileMode.ReadWrite) {
                flags = 2 | 64; // O_RDWR | O_CREAT
            }
            case (FileMode.Append) {
                flags = 1 | 64 | 1024; // O_WRONLY | O_CREAT | O_APPEND
            }
        }
        
        var handle: i64 = open(path_cstr.Data(), flags, 0644); // rw-r--r--
        
        if (handle == -1) {
            return Result(i64, String).Error("Failed to open file");
        }
        
        return Result(i64, String).Ok(handle);
    }
    
    fn ReadNative(self: Self, buffer: Array(u8)) -> Result(u64, String) {
        match (Platform.GetCurrentOS()) {
            case (Platform.OS.Windows) {
                var bytes_read: u32 = 0;
                var success: Bool = ReadFile(self.handle, buffer.Data(), buffer.Size(), &bytes_read, null);
                if (success) {
                    return Result(u64, String).Ok(bytes_read);
                } else {
                    return Result(u64, String).Error("Read failed");
                }
            }
            default {
                var bytes_read: i64 = read(self.handle, buffer.Data(), buffer.Size());
                if (bytes_read >= 0) {
                    return Result(u64, String).Ok(bytes_read);
                } else {
                    return Result(u64, String).Error("Read failed");
                }
            }
        }
    }
    
    fn WriteNative(self: Self, data: Array(u8)) -> Result(u64, String) {
        match (Platform.GetCurrentOS()) {
            case (Platform.OS.Windows) {
                var bytes_written: u32 = 0;
                var success: Bool = WriteFile(self.handle, data.Data(), data.Size(), &bytes_written, null);
                if (success) {
                    return Result(u64, String).Ok(bytes_written);
                } else {
                    return Result(u64, String).Error("Write failed");
                }
            }
            default {
                var bytes_written: i64 = write(self.handle, data.Data(), data.Size());
                if (bytes_written >= 0) {
                    return Result(u64, String).Ok(bytes_written);
                } else {
                    return Result(u64, String).Error("Write failed");
                }
            }
        }
    }
    
    fn SeekNative(self: Self, position: u64, origin: SeekOrigin) -> Result(u64, String) {
        match (Platform.GetCurrentOS()) {
            case (Platform.OS.Windows) {
                var move_method: u32 = 0;
                match (origin) {
                    case (SeekOrigin.Begin) { move_method = 0; } // FILE_BEGIN
                    case (SeekOrigin.Current) { move_method = 1; } // FILE_CURRENT
                    case (SeekOrigin.End) { move_method = 2; } // FILE_END
                }
                
                var new_pos: u32 = SetFilePointer(self.handle, position as i32, null, move_method);
                if (new_pos != 0xFFFFFFFF) {
                    return Result(u64, String).Ok(new_pos);
                } else {
                    return Result(u64, String).Error("Seek failed");
                }
            }
            default {
                var whence: i32 = 0;
                match (origin) {
                    case (SeekOrigin.Begin) { whence = 0; } // SEEK_SET
                    case (SeekOrigin.Current) { whence = 1; } // SEEK_CUR
                    case (SeekOrigin.End) { whence = 2; } // SEEK_END
                }
                
                var new_pos: i64 = lseek(self.handle, position, whence);
                if (new_pos >= 0) {
                    return Result(u64, String).Ok(new_pos);
                } else {
                    return Result(u64, String).Error("Seek failed");
                }
            }
        }
    }
    
    fn GetSizeNative(self: Self) -> Result(u64, String) {
        match (Platform.GetCurrentOS()) {
            case (Platform.OS.Windows) {
                var size: u32 = GetFileSize(self.handle, null);
                if (size != 0xFFFFFFFF) {
                    return Result(u64, String).Ok(size);
                } else {
                    return Result(u64, String).Error("GetFileSize failed");
                }
            }
            default {
                var stat_buf: stat;
                var result: i32 = fstat(self.handle, &stat_buf);
                if (result == 0) {
                    return Result(u64, String).Ok(stat_buf.st_size);
                } else {
                    return Result(u64, String).Error("fstat failed");
                }
            }
        }
    }
    
    fn FlushNative(self: Self) -> Result(Bool, String) {
        match (Platform.GetCurrentOS()) {
            case (Platform.OS.Windows) {
                var success: Bool = FlushFileBuffers(self.handle);
                return Result(Bool, String).Ok(success);
            }
            default {
                var result: i32 = fsync(self.handle);
                return result == 0 ? Result(Bool, String).Ok(True) : Result(Bool, String).Error("fsync failed");
            }
        }
    }
    
    fn CloseNative(self: Self) -> Result(Bool, String) {
        match (Platform.GetCurrentOS()) {
            case (Platform.OS.Windows) {
                var success: Bool = CloseHandle(self.handle);
                return Result(Bool, String).Ok(success);
            }
            default {
                var result: i32 = close(self.handle);
                return result == 0 ? Result(Bool, String).Ok(True) : Result(Bool, String).Error("close failed");
            }
        }
    }
}

// Directory operations
class Directory {
    fn Exists(path: String) -> Bool {
        match (Platform.GetCurrentOS()) {
            case (Platform.OS.Windows) {
                var path_utf16: Array(u8) = StringToUtf16(path);
                var attrs: u32 = GetFileAttributesW(path_utf16.Data());
                return attrs != 0xFFFFFFFF and (attrs & 0x10) != 0; // FILE_ATTRIBUTE_DIRECTORY
            }
            default {
                var path_cstr: Array(u8) = StringToCString(path);
                var stat_buf: stat;
                var result: i32 = stat(path_cstr.Data(), &stat_buf);
                return result == 0 and S_ISDIR(stat_buf.st_mode);
            }
        }
    }
    
    fn Create(path: String) -> Result(Bool, String) {
        match (Platform.GetCurrentOS()) {
            case (Platform.OS.Windows) {
                var path_utf16: Array(u8) = StringToUtf16(path);
                var success: Bool = CreateDirectoryW(path_utf16.Data(), null);
                return Result(Bool, String).Ok(success);
            }
            default {
                var path_cstr: Array(u8) = StringToCString(path);
                var result: i32 = mkdir(path_cstr.Data(), 0755);
                return result == 0 ? Result(Bool, String).Ok(True) : Result(Bool, String).Error("mkdir failed");
            }
        }
    }
    
    fn CreateRecursive(path: String) -> Result(Bool, String) {
        if (Directory.Exists(path)) {
            return Result(Bool, String).Ok(True);
        }
        
        var parent: String = Path.GetDirectoryName(path);
        if (not parent.IsEmpty() and parent != path) {
            var parent_result: Result(Bool, String) = Directory.CreateRecursive(parent);
            if (not parent_result.IsOk()) {
                return parent_result;
            }
        }
        
        return Directory.Create(path);
    }
    
    fn Delete(path: String) -> Result(Bool, String) {
        match (Platform.GetCurrentOS()) {
            case (Platform.OS.Windows) {
                var path_utf16: Array(u8) = StringToUtf16(path);
                var success: Bool = RemoveDirectoryW(path_utf16.Data());
                return Result(Bool, String).Ok(success);
            }
            default {
                var path_cstr: Array(u8) = StringToCString(path);
                var result: i32 = rmdir(path_cstr.Data());
                return result == 0 ? Result(Bool, String).Ok(True) : Result(Bool, String).Error("rmdir failed");
            }
        }
    }
    
    fn GetEntries(path: String) -> Result(Array(DirectoryEntry), String) {
        var entries: Array(DirectoryEntry) = Array(DirectoryEntry)();
        
        match (Platform.GetCurrentOS()) {
            case (Platform.OS.Windows) {
                return Directory.GetEntriesWindows(path);
            }
            default {
                return Directory.GetEntriesUnix(path);
            }
        }
    }
    
    fn GetEntriesWindows(path: String) -> Result(Array(DirectoryEntry), String) {
        var entries: Array(DirectoryEntry) = Array(DirectoryEntry)();
        var search_path: String = path + "\\*";
        var search_path_utf16: Array(u8) = StringToUtf16(search_path);
        
        var find_data: WIN32_FIND_DATAW;
        var handle: i64 = FindFirstFileW(search_path_utf16.Data(), &find_data);
        
        if (handle == -1) {
            return Result(Array(DirectoryEntry), String).Error("FindFirstFile failed");
        }
        
        while (True) {
            var name: String = Utf16ToString(find_data.cFileName);
            if (name != "." and name != "..") {
                var entry: DirectoryEntry = {
                    .name = name,
                    .is_directory = (find_data.dwFileAttributes & 0x10) != 0 // FILE_ATTRIBUTE_DIRECTORY
                };
                entries.Push(entry);
            }
            
            if (not FindNextFileW(handle, &find_data)) {
                break;
            }
        }
        
        FindClose(handle);
        return Result(Array(DirectoryEntry), String).Ok(entries);
    }
    
    fn GetEntriesUnix(path: String) -> Result(Array(DirectoryEntry), String) {
        var entries: Array(DirectoryEntry) = Array(DirectoryEntry)();
        var path_cstr: Array(u8) = StringToCString(path);
        
        var dir: *DIR = opendir(path_cstr.Data());
        if (dir == null) {
            return Result(Array(DirectoryEntry), String).Error("opendir failed");
        }
        
        while (True) {
            var entry: *dirent = readdir(dir);
            if (entry == null) {
                break;
            }
            
            var name: String = CStringToString(entry.d_name);
            if (name != "." and name != "..") {
                var dir_entry: DirectoryEntry = {
                    .name = name,
                    .is_directory = entry.d_type == 4 // DT_DIR
                };
                entries.Push(dir_entry);
            }
        }
        
        closedir(dir);
        return Result(Array(DirectoryEntry), String).Ok(entries);
    }
    
    fn GetCurrentDirectory() -> Result(String, String) {
        match (Platform.GetCurrentOS()) {
            case (Platform.OS.Windows) {
                var buffer: Array(u16) = Array(u16)(260); // MAX_PATH
                var length: u32 = GetCurrentDirectoryW(260, buffer.Data());
                if (length > 0) {
                    return Result(String, String).Ok(Utf16ToString(buffer, length));
                } else {
                    return Result(String, String).Error("GetCurrentDirectory failed");
                }
            }
            default {
                var buffer: Array(u8) = Array(u8)(4096);
                var result: *u8 = getcwd(buffer.Data(), 4096);
                if (result != null) {
                    return Result(String, String).Ok(CStringToString(result));
                } else {
                    return Result(String, String).Error("getcwd failed");
                }
            }
        }
    }
    
    fn SetCurrentDirectory(path: String) -> Result(Bool, String) {
        match (Platform.GetCurrentOS()) {
            case (Platform.OS.Windows) {
                var path_utf16: Array(u8) = StringToUtf16(path);
                var success: Bool = SetCurrentDirectoryW(path_utf16.Data());
                return Result(Bool, String).Ok(success);
            }
            default {
                var path_cstr: Array(u8) = StringToCString(path);
                var result: i32 = chdir(path_cstr.Data());
                return result == 0 ? Result(Bool, String).Ok(True) : Result(Bool, String).Error("chdir failed");
            }
        }
    }
}

// Path utilities
class Path {
    fn Combine(path1: String, path2: String) -> String {
        var separator: String = Platform.IsWindows() ? "\\" : "/";
        
        if (path1.IsEmpty()) {
            return path2;
        }
        
        if (path2.IsEmpty()) {
            return path1;
        }
        
        var result: String = path1;
        if (not result.EndsWith(separator)) {
            result += separator;
        }
        
        if (path2.StartsWith(separator)) {
            result += path2.Substring(1);
        } else {
            result += path2;
        }
        
        return result;
    }
    
    fn GetFileName(path: String) -> String {
        var separator: String = Platform.IsWindows() ? "\\" : "/";
        var last_separator: i32 = path.LastIndexOf(separator);
        
        if (last_separator >= 0) {
            return path.Substring(last_separator + 1);
        }
        
        return path;
    }
    
    fn GetDirectoryName(path: String) -> String {
        var separator: String = Platform.IsWindows() ? "\\" : "/";
        var last_separator: i32 = path.LastIndexOf(separator);
        
        if (last_separator >= 0) {
            return path.Substring(0, last_separator);
        }
        
        return "";
    }
    
    fn GetExtension(path: String) -> String {
        var filename: String = Path.GetFileName(path);
        var last_dot: i32 = filename.LastIndexOf(".");
        
        if (last_dot >= 0) {
            return filename.Substring(last_dot);
        }
        
        return "";
    }
    
    fn GetFileNameWithoutExtension(path: String) -> String {
        var filename: String = Path.GetFileName(path);
        var last_dot: i32 = filename.LastIndexOf(".");
        
        if (last_dot >= 0) {
            return filename.Substring(0, last_dot);
        }
        
        return filename;
    }
    
    fn IsAbsolute(path: String) -> Bool {
        if (path.IsEmpty()) {
            return False;
        }
        
        if (Platform.IsWindows()) {
            // Check for drive letter (C:\) or UNC path (\\server\)
            return (path.Length() >= 3 and path[1] == ':' and path[2] == '\\') or
                   (path.Length() >= 2 and path[0] == '\\' and path[1] == '\\');
        } else {
            // Unix absolute paths start with /
            return path[0] == '/';
        }
    }
    
    fn Normalize(path: String) -> String {
        var separator: String = Platform.IsWindows() ? "\\" : "/";
        var parts: Array(String) = path.Split(separator);
        var normalized_parts: Array(String) = Array(String)();
        
        var i: i32 = 0;
        while (i < parts.Size()) {
            var part: String = parts[i];
            
            if (part == "." or part.IsEmpty()) {
                // Skip current directory references and empty parts
            } else if (part == "..") {
                // Go up one directory
                if (normalized_parts.Size() > 0) {
                    normalized_parts.Pop();
                }
            } else {
                normalized_parts.Push(part);
            }
            
            i += 1;
        }
        
        var result: String = "";
        i = 0;
        while (i < normalized_parts.Size()) {
            if (i > 0) {
                result += separator;
            }
            result += normalized_parts[i];
            i += 1;
        }
        
        return result;
    }
}

// File system utilities
fn FileExists(path: String) -> Bool {
    match (Platform.GetCurrentOS()) {
        case (Platform.OS.Windows) {
            var path_utf16: Array(u8) = StringToUtf16(path);
            var attrs: u32 = GetFileAttributesW(path_utf16.Data());
            return attrs != 0xFFFFFFFF and (attrs & 0x10) == 0; // Not a directory
        }
        default {
            var path_cstr: Array(u8) = StringToCString(path);
            var stat_buf: stat;
            var result: i32 = stat(path_cstr.Data(), &stat_buf);
            return result == 0 and S_ISREG(stat_buf.st_mode);
        }
    }
}

fn DeleteFile(path: String) -> Result(Bool, String) {
    match (Platform.GetCurrentOS()) {
        case (Platform.OS.Windows) {
            var path_utf16: Array(u8) = StringToUtf16(path);
            var success: Bool = DeleteFileW(path_utf16.Data());
            return Result(Bool, String).Ok(success);
        }
        default {
            var path_cstr: Array(u8) = StringToCString(path);
            var result: i32 = unlink(path_cstr.Data());
            return result == 0 ? Result(Bool, String).Ok(True) : Result(Bool, String).Error("unlink failed");
        }
    }
}

fn CopyFile(source: String, destination: String) -> Result(Bool, String) {
    match (Platform.GetCurrentOS()) {
        case (Platform.OS.Windows) {
            var src_utf16: Array(u8) = StringToUtf16(source);
            var dst_utf16: Array(u8) = StringToUtf16(destination);
            var success: Bool = CopyFileW(src_utf16.Data(), dst_utf16.Data(), False);
            return Result(Bool, String).Ok(success);
        }
        default {
            // Manual copy for Unix systems
            var src_file_result: Result(File, String) = File.Open(source, FileMode.Read);
            if (not src_file_result.IsOk()) {
                return Result(Bool, String).Error(src_file_result.Error());
            }
            
            var dst_file_result: Result(File, String) = File.Create(destination);
            if (not dst_file_result.IsOk()) {
                return Result(Bool, String).Error(dst_file_result.Error());
            }
            
            var src_file: File = src_file_result.Value();
            var dst_file: File = dst_file_result.Value();
            
            var buffer: Array(u8) = Array(u8)(8192);
            while (True) {
                var read_result: Result(u64, String) = src_file.Read(buffer);
                if (not read_result.IsOk()) {
                    break;
                }
                
                var bytes_read: u64 = read_result.Value();
                if (bytes_read == 0) {
                    break;
                }
                
                var write_data: Array(u8) = Array(u8)(bytes_read);
                var i: u64 = 0;
                while (i < bytes_read) {
                    write_data.Push(buffer[i]);
                    i += 1;
                }
                
                dst_file.Write(write_data);
            }
            
            src_file.Close();
            dst_file.Close();
            
            return Result(Bool, String).Ok(True);
        }
    }
}

fn MoveFile(source: String, destination: String) -> Result(Bool, String) {
    match (Platform.GetCurrentOS()) {
        case (Platform.OS.Windows) {
            var src_utf16: Array(u8) = StringToUtf16(source);
            var dst_utf16: Array(u8) = StringToUtf16(destination);
            var success: Bool = MoveFileW(src_utf16.Data(), dst_utf16.Data());
            return Result(Bool, String).Ok(success);
        }
        default {
            var src_cstr: Array(u8) = StringToCString(source);
            var dst_cstr: Array(u8) = StringToCString(destination);
            var result: i32 = rename(src_cstr.Data(), dst_cstr.Data());
            return result == 0 ? Result(Bool, String).Ok(True) : Result(Bool, String).Error("rename failed");
        }
    }
}

fn GetFileInfo(path: String) -> Result(FileInfo, String) {
    match (Platform.GetCurrentOS()) {
        case (Platform.OS.Windows) {
            return GetFileInfoWindows(path);
        }
        default {
            return GetFileInfoUnix(path);
        }
    }
}

fn GetFileInfoWindows(path: String) -> Result(FileInfo, String) {
    var path_utf16: Array(u8) = StringToUtf16(path);
    var find_data: WIN32_FIND_DATAW;
    var handle: i64 = FindFirstFileW(path_utf16.Data(), &find_data);
    
    if (handle == -1) {
        return Result(FileInfo, String).Error("FindFirstFile failed");
    }
    
    FindClose(handle);
    
    var info: FileInfo = {
        .name = Path.GetFileName(path),
        .full_path = path,
        .size = (find_data.nFileSizeHigh as u64 << 32) | find_data.nFileSizeLow,
        .is_directory = (find_data.dwFileAttributes & 0x10) != 0,
        .is_readonly = (find_data.dwFileAttributes & 0x01) != 0,
        .is_hidden = (find_data.dwFileAttributes & 0x02) != 0,
        .created_time = FileTimeToUnixTime(find_data.ftCreationTime),
        .modified_time = FileTimeToUnixTime(find_data.ftLastWriteTime),
        .accessed_time = FileTimeToUnixTime(find_data.ftLastAccessTime)
    };
    
    return Result(FileInfo, String).Ok(info);
}

fn GetFileInfoUnix(path: String) -> Result(FileInfo, String) {
    var path_cstr: Array(u8) = StringToCString(path);
    var stat_buf: stat;
    var result: i32 = stat(path_cstr.Data(), &stat_buf);
    
    if (result != 0) {
        return Result(FileInfo, String).Error("stat failed");
    }
    
    var info: FileInfo = {
        .name = Path.GetFileName(path),
        .full_path = path,
        .size = stat_buf.st_size,
        .is_directory = S_ISDIR(stat_buf.st_mode),
        .is_readonly = (stat_buf.st_mode & 0200) == 0, // Owner write permission
        .is_hidden = Path.GetFileName(path).StartsWith("."),
        .created_time = stat_buf.st_ctime,
        .modified_time = stat_buf.st_mtime,
        .accessed_time = stat_buf.st_atime
    };
    
    return Result(FileInfo, String).Ok(info);
}

// Enums and helper functions
choice FileMode {
    Read,
    Write,
    ReadWrite,
    Append
}

choice SeekOrigin {
    Begin,
    Current,
    End
}

fn FileTimeToUnixTime(filetime: FILETIME) -> u64 {
    var time64: u64 = (filetime.dwHighDateTime as u64 << 32) | filetime.dwLowDateTime;
    return (time64 - 116444736000000000) / 10000000; // Convert to Unix timestamp
}

fn S_ISDIR(mode: u32) -> Bool {
    return (mode & 0170000) == 0040000; // S_IFDIR
}

fn S_ISREG(mode: u32) -> Bool {
    return (mode & 0170000) == 0100000; // S_IFREG
}

// Platform-specific system calls and structures
// Windows API
fn CreateFileW(filename: *u16, access: u32, share: u32, security: *Void, creation: u32, flags: u32, template: i64) -> i64;
fn ReadFile(file: i64, buffer: *u8, bytes_to_read: u32, bytes_read: *u32, overlapped: *Void) -> Bool;
fn WriteFile(file: i64, buffer: *u8, bytes_to_write: u32, bytes_written: *u32, overlapped: *Void) -> Bool;
fn SetFilePointer(file: i64, distance: i32, distance_high: *i32, move_method: u32) -> u32;
fn GetFileSize(file: i64, file_size_high: *u32) -> u32;
fn FlushFileBuffers(file: i64) -> Bool;
fn CloseHandle(handle: i64) -> Bool;
fn GetFileAttributesW(filename: *u16) -> u32;
fn CreateDirectoryW(path: *u16, security: *Void) -> Bool;
fn RemoveDirectoryW(path: *u16) -> Bool;
fn DeleteFileW(filename: *u16) -> Bool;
fn CopyFileW(existing: *u16, new: *u16, fail_if_exists: Bool) -> Bool;
fn MoveFileW(existing: *u16, new: *u16) -> Bool;
fn FindFirstFileW(filename: *u16, find_data: *WIN32_FIND_DATAW) -> i64;
fn FindNextFileW(find_file: i64, find_data: *WIN32_FIND_DATAW) -> Bool;
fn FindClose(find_file: i64) -> Bool;
fn GetCurrentDirectoryW(buffer_length: u32, buffer: *u16) -> u32;
fn SetCurrentDirectoryW(path: *u16) -> Bool;

// Unix system calls
fn open(pathname: *u8, flags: i32, mode: u32) -> i64;
fn read(fd: i64, buf: *u8, count: u64) -> i64;
fn write(fd: i64, buf: *u8, count: u64) -> i64;
fn lseek(fd: i64, offset: u64, whence: i32) -> i64;
fn close(fd: i64) -> i32;
fn fsync(fd: i64) -> i32;
fn fstat(fd: i64, buf: *stat) -> i32;
fn stat(pathname: *u8, buf: *stat) -> i32;
fn mkdir(pathname: *u8, mode: u32) -> i32;
fn rmdir(pathname: *u8) -> i32;
fn unlink(pathname: *u8) -> i32;
fn rename(oldpath: *u8, newpath: *u8) -> i32;
fn opendir(name: *u8) -> *DIR;
fn readdir(dirp: *DIR) -> *dirent;
fn closedir(dirp: *DIR) -> i32;
fn getcwd(buf: *u8, size: u64) -> *u8;
fn chdir(path: *u8) -> i32;

// Platform-specific structures
struct FILETIME {
    var dwLowDateTime: u32;
    var dwHighDateTime: u32;
}

struct WIN32_FIND_DATAW {
    var dwFileAttributes: u32;
    var ftCreationTime: FILETIME;
    var ftLastAccessTime: FILETIME;
    var ftLastWriteTime: FILETIME;
    var nFileSizeHigh: u32;
    var nFileSizeLow: u32;
    var dwReserved0: u32;
    var dwReserved1: u32;
    var cFileName: Array(u16); // 260 elements
    var cAlternateFileName: Array(u16); // 14 elements
}

struct stat {
    var st_dev: u64;
    var st_ino: u64;
    var st_mode: u32;
    var st_nlink: u64;
    var st_uid: u32;
    var st_gid: u32;
    var st_rdev: u64;
    var st_size: u64;
    var st_blksize: u64;
    var st_blocks: u64;
    var st_atime: u64;
    var st_mtime: u64;
    var st_ctime: u64;
}

struct dirent {
    var d_ino: u64;
    var d_off: u64;
    var d_reclen: u16;
    var d_type: u8;
    var d_name: *u8;
}

// Opaque directory handle
struct DIR;