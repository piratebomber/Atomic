// Atomic Runtime - Memory Management
package AtomicRuntime.Memory api;

import Std.Platform;

// Memory allocation functions
fn Allocate(size: u64) -> *u8 {
    match (Platform.GetCurrentOS()) {
        case (Platform.OS.Windows) {
            return WindowsAllocate(size);
        }
        default {
            return UnixAllocate(size);
        }
    }
}

fn Reallocate(ptr: *u8, new_size: u64) -> *u8 {
    match (Platform.GetCurrentOS()) {
        case (Platform.OS.Windows) {
            return WindowsReallocate(ptr, new_size);
        }
        default {
            return UnixReallocate(ptr, new_size);
        }
    }
}

fn Deallocate(ptr: *u8) {
    match (Platform.GetCurrentOS()) {
        case (Platform.OS.Windows) {
            WindowsDeallocate(ptr);
        }
        default {
            UnixDeallocate(ptr);
        }
    }
}

fn AllocateAligned(size: u64, alignment: u64) -> *u8 {
    match (Platform.GetCurrentOS()) {
        case (Platform.OS.Windows) {
            return WindowsAllocateAligned(size, alignment);
        }
        default {
            return UnixAllocateAligned(size, alignment);
        }
    }
}

fn DeallocateAligned(ptr: *u8) {
    match (Platform.GetCurrentOS()) {
        case (Platform.OS.Windows) {
            WindowsDeallocateAligned(ptr);
        }
        default {
            UnixDeallocateAligned(ptr);
        }
    }
}

// Memory utilities
fn MemoryCopy(dest: *u8, src: *u8, size: u64) {
    var i: u64 = 0;
    while (i < size) {
        dest[i] = src[i];
        i += 1;
    }
}

fn MemorySet(ptr: *u8, value: u8, size: u64) {
    var i: u64 = 0;
    while (i < size) {
        ptr[i] = value;
        i += 1;
    }
}

fn MemoryZero(ptr: *u8, size: u64) {
    MemorySet(ptr, 0, size);
}

fn MemoryCompare(ptr1: *u8, ptr2: *u8, size: u64) -> i32 {
    var i: u64 = 0;
    while (i < size) {
        if (ptr1[i] < ptr2[i]) {
            return -1;
        } else if (ptr1[i] > ptr2[i]) {
            return 1;
        }
        i += 1;
    }
    return 0;
}

// Platform-specific implementations
// Windows
fn WindowsAllocate(size: u64) -> *u8 {
    return HeapAlloc(GetProcessHeap(), 0, size);
}

fn WindowsReallocate(ptr: *u8, new_size: u64) -> *u8 {
    if (ptr == null) {
        return WindowsAllocate(new_size);
    }
    return HeapReAlloc(GetProcessHeap(), 0, ptr, new_size);
}

fn WindowsDeallocate(ptr: *u8) {
    if (ptr != null) {
        HeapFree(GetProcessHeap(), 0, ptr);
    }
}

fn WindowsAllocateAligned(size: u64, alignment: u64) -> *u8 {
    return _aligned_malloc(size, alignment);
}

fn WindowsDeallocateAligned(ptr: *u8) {
    if (ptr != null) {
        _aligned_free(ptr);
    }
}

// Unix/Linux/macOS
fn UnixAllocate(size: u64) -> *u8 {
    return malloc(size);
}

fn UnixReallocate(ptr: *u8, new_size: u64) -> *u8 {
    return realloc(ptr, new_size);
}

fn UnixDeallocate(ptr: *u8) {
    if (ptr != null) {
        free(ptr);
    }
}

fn UnixAllocateAligned(size: u64, alignment: u64) -> *u8 {
    var result: *u8;
    if (posix_memalign(&result, alignment, size) == 0) {
        return result;
    }
    return null;
}

fn UnixDeallocateAligned(ptr: *u8) {
    if (ptr != null) {
        free(ptr);
    }
}

// Garbage Collection Support
struct GCHeader {
    var size: u64;
    var mark: Bool;
    var next: *GCHeader;
}

class GarbageCollector {
    var heap_start: *GCHeader;
    var heap_size: u64;
    var allocated_size: u64;
    var gc_threshold: u64;
    
    fn Create() -> Self {
        return {
            .heap_start = null,
            .heap_size = 0,
            .allocated_size = 0,
            .gc_threshold = 1024 * 1024 // 1MB default threshold
        };
    }
    
    fn AllocateGC(self: Self, size: u64) -> *u8 {
        var total_size: u64 = size + SizeOf(GCHeader);
        var header: *GCHeader = Allocate(total_size);
        
        if (header == null) {
            // Try garbage collection and retry
            self.Collect();
            header = Allocate(total_size);
            if (header == null) {
                return null;
            }
        }
        
        header.size = size;
        header.mark = False;
        header.next = self.heap_start;
        self.heap_start = header;
        
        self.allocated_size += total_size;
        
        // Trigger GC if threshold exceeded
        if (self.allocated_size > self.gc_threshold) {
            self.Collect();
        }
        
        return header + 1; // Return pointer after header
    }
    
    fn Collect(self: Self) {
        // Mark phase - mark all reachable objects
        self.MarkReachable();
        
        // Sweep phase - deallocate unmarked objects
        self.SweepUnmarked();
    }
    
    fn MarkReachable(self: Self) {
        // This would traverse the root set and mark reachable objects
        // Implementation depends on runtime stack scanning and global variables
        var current: *GCHeader = self.heap_start;
        while (current != null) {
            // For now, mark all objects as reachable
            // Real implementation would do proper reachability analysis
            current.mark = True;
            current = current.next;
        }
    }
    
    fn SweepUnmarked(self: Self) {
        var current: *GCHeader = self.heap_start;
        var previous: *GCHeader = null;
        
        while (current != null) {
            if (not current.mark) {
                // Unmark object, deallocate it
                if (previous == null) {
                    self.heap_start = current.next;
                } else {
                    previous.next = current.next;
                }
                
                var to_free: *GCHeader = current;
                current = current.next;
                
                self.allocated_size -= (to_free.size + SizeOf(GCHeader));
                Deallocate(to_free);
            } else {
                // Reset mark for next collection
                current.mark = False;
                previous = current;
                current = current.next;
            }
        }
    }
    
    fn GetAllocatedSize(self: Self) -> u64 {
        return self.allocated_size;
    }
    
    fn SetThreshold(self: Self, threshold: u64) {
        self.gc_threshold = threshold;
    }
}

// Global garbage collector instance
var global_gc: GarbageCollector = GarbageCollector.Create();

// Public GC interface
fn GCAllocate(size: u64) -> *u8 {
    return global_gc.AllocateGC(size);
}

fn GCCollect() {
    global_gc.Collect();
}

fn GCGetAllocatedSize() -> u64 {
    return global_gc.GetAllocatedSize();
}

fn GCSetThreshold(threshold: u64) {
    global_gc.SetThreshold(threshold);
}

// System call declarations
// Windows
fn GetProcessHeap() -> i64;
fn HeapAlloc(heap: i64, flags: u32, size: u64) -> *u8;
fn HeapReAlloc(heap: i64, flags: u32, mem: *u8, size: u64) -> *u8;
fn HeapFree(heap: i64, flags: u32, mem: *u8) -> Bool;
fn _aligned_malloc(size: u64, alignment: u64) -> *u8;
fn _aligned_free(ptr: *u8);

// Unix
fn malloc(size: u64) -> *u8;
fn realloc(ptr: *u8, size: u64) -> *u8;
fn free(ptr: *u8);
fn posix_memalign(memptr: **u8, alignment: u64, size: u64) -> i32;