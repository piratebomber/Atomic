// Atomic Standard Library - Collections
package Std.Collections api;

import Std.Memory;
import Std.String;

// Dynamic Array (Vector)
class Vector(T: Type) {
    var data: *T;
    var size: u64;
    var capacity: u64;
    
    fn Create() -> Self {
        return {
            .data = null,
            .size = 0,
            .capacity = 0
        };
    }
    
    fn CreateWithCapacity(initial_capacity: u64) -> Self {
        var vec: Self = {
            .data = null,
            .size = 0,
            .capacity = initial_capacity
        };
        if (initial_capacity > 0) {
            vec.data = Memory.Allocate(initial_capacity * SizeOf(T));
        }
        return vec;
    }
    
    fn Destroy(self: Self) {
        if (self.data != null) {
            Memory.Deallocate(self.data);
        }
    }
    
    fn Push(self: Self, item: T) {
        if (self.size >= self.capacity) {
            self.Grow();
        }
        self.data[self.size] = item;
        self.size += 1;
    }
    
    fn Pop(self: Self) -> Optional(T) {
        if (self.size == 0) {
            return Optional(T).None();
        }
        self.size -= 1;
        return Optional(T).Some(self.data[self.size]);
    }
    
    fn Get(self: Self, index: u64) -> Optional(T) {
        if (index >= self.size) {
            return Optional(T).None();
        }
        return Optional(T).Some(self.data[index]);
    }
    
    fn Set(self: Self, index: u64, item: T) -> Bool {
        if (index >= self.size) {
            return False;
        }
        self.data[index] = item;
        return True;
    }
    
    fn Insert(self: Self, index: u64, item: T) -> Bool {
        if (index > self.size) {
            return False;
        }
        
        if (self.size >= self.capacity) {
            self.Grow();
        }
        
        // Shift elements right
        var i: u64 = self.size;
        while (i > index) {
            self.data[i] = self.data[i - 1];
            i -= 1;
        }
        
        self.data[index] = item;
        self.size += 1;
        return True;
    }
    
    fn Remove(self: Self, index: u64) -> Optional(T) {
        if (index >= self.size) {
            return Optional(T).None();
        }
        
        var item: T = self.data[index];
        
        // Shift elements left
        var i: u64 = index;
        while (i < self.size - 1) {
            self.data[i] = self.data[i + 1];
            i += 1;
        }
        
        self.size -= 1;
        return Optional(T).Some(item);
    }
    
    fn Clear(self: Self) {
        self.size = 0;
    }
    
    fn Size(self: Self) -> u64 {
        return self.size;
    }
    
    fn IsEmpty(self: Self) -> Bool {
        return self.size == 0;
    }
    
    fn Capacity(self: Self) -> u64 {
        return self.capacity;
    }
    
    fn Reserve(self: Self, new_capacity: u64) {
        if (new_capacity > self.capacity) {
            self.Resize(new_capacity);
        }
    }
    
    fn Grow(self: Self) {
        var new_capacity: u64 = self.capacity == 0 ? 4 : self.capacity * 2;
        self.Resize(new_capacity);
    }
    
    fn Resize(self: Self, new_capacity: u64) {
        var new_data: *T = Memory.Allocate(new_capacity * SizeOf(T));
        
        if (self.data != null) {
            // Copy existing data
            Memory.MemoryCopy(new_data, self.data, self.size * SizeOf(T));
            Memory.Deallocate(self.data);
        }
        
        self.data = new_data;
        self.capacity = new_capacity;
    }
    
    fn Find(self: Self, item: T) -> Optional(u64) {
        var i: u64 = 0;
        while (i < self.size) {
            if (self.data[i] == item) {
                return Optional(u64).Some(i);
            }
            i += 1;
        }
        return Optional(u64).None();
    }
    
    fn Contains(self: Self, item: T) -> Bool {
        return self.Find(item).HasValue();
    }
    
    fn Sort(self: Self) {
        // Quick sort implementation
        if (self.size <= 1) {
            return;
        }
        self.QuickSort(0, self.size - 1);
    }
    
    fn QuickSort(self: Self, low: u64, high: u64) {
        if (low < high) {
            var pivot: u64 = self.Partition(low, high);
            if (pivot > 0) {
                self.QuickSort(low, pivot - 1);
            }
            self.QuickSort(pivot + 1, high);
        }
    }
    
    fn Partition(self: Self, low: u64, high: u64) -> u64 {
        var pivot: T = self.data[high];
        var i: u64 = low;
        
        var j: u64 = low;
        while (j < high) {
            if (self.Compare(self.data[j], pivot) <= 0) {
                var temp: T = self.data[i];
                self.data[i] = self.data[j];
                self.data[j] = temp;
                i += 1;
            }
            j += 1;
        }
        
        var temp: T = self.data[i];
        self.data[i] = self.data[high];
        self.data[high] = temp;
        
        return i;
    }
    
    fn Compare(self: Self, a: T, b: T) -> i32 {
        // Generic comparison using memory comparison
        var bytes_a: *u8 = &a;
        var bytes_b: *u8 = &b;
        return Memory.MemoryCompare(bytes_a, bytes_b, SizeOf(T));
    }
}

// Hash Map
struct HashMapEntry(K: Type, V: Type) {
    var key: K;
    var value: V;
    var hash: u64;
    var next: Optional(*HashMapEntry(K, V));
}

class HashMap(K: Type, V: Type) {
    var buckets: Vector(*HashMapEntry(K, V));
    var size: u64;
    var load_factor: f64;
    
    fn Create() -> Self {
        var map: Self = {
            .buckets = Vector(*HashMapEntry(K, V)).CreateWithCapacity(16),
            .size = 0,
            .load_factor = 0.75
        };
        
        // Initialize buckets to null
        var i: u64 = 0;
        while (i < 16) {
            map.buckets.Push(null);
            i += 1;
        }
        
        return map;
    }
    
    fn Insert(self: Self, key: K, value: V) {
        var hash: u64 = self.Hash(key);
        var bucket_index: u64 = hash % self.buckets.Size();
        
        var bucket_opt: Optional(*HashMapEntry(K, V)) = self.buckets.Get(bucket_index);
        if (bucket_opt.HasValue()) {
            var bucket: *HashMapEntry(K, V) = bucket_opt.Value();
            
            // Check if key already exists
            var current: *HashMapEntry(K, V) = bucket;
            while (current != null) {
                if (current.key == key) {
                    current.value = value; // Update existing
                    return;
                }
                if (not current.next.HasValue()) {
                    break;
                }
                current = current.next.Value();
            }
            
            // Add new entry to chain
            var new_entry: *HashMapEntry(K, V) = Memory.Allocate(SizeOf(HashMapEntry(K, V)));
            new_entry.key = key;
            new_entry.value = value;
            new_entry.hash = hash;
            new_entry.next = Optional(*HashMapEntry(K, V)).None();
            
            if (current != null) {
                current.next = Optional(*HashMapEntry(K, V)).Some(new_entry);
            } else {
                self.buckets.Set(bucket_index, new_entry);
            }
        } else {
            // Create new entry
            var new_entry: *HashMapEntry(K, V) = Memory.Allocate(SizeOf(HashMapEntry(K, V)));
            new_entry.key = key;
            new_entry.value = value;
            new_entry.hash = hash;
            new_entry.next = Optional(*HashMapEntry(K, V)).None();
            
            self.buckets.Set(bucket_index, new_entry);
        }
        
        self.size += 1;
        
        // Check if resize is needed
        if (self.size as f64 / self.buckets.Size() as f64 > self.load_factor) {
            self.Resize();
        }
    }
    
    fn Get(self: Self, key: K) -> Optional(V) {
        var hash: u64 = self.Hash(key);
        var bucket_index: u64 = hash % self.buckets.Size();
        
        var bucket_opt: Optional(*HashMapEntry(K, V)) = self.buckets.Get(bucket_index);
        if (not bucket_opt.HasValue()) {
            return Optional(V).None();
        }
        
        var current: *HashMapEntry(K, V) = bucket_opt.Value();
        while (current != null) {
            if (current.key == key) {
                return Optional(V).Some(current.value);
            }
            if (not current.next.HasValue()) {
                break;
            }
            current = current.next.Value();
        }
        
        return Optional(V).None();
    }
    
    fn Contains(self: Self, key: K) -> Bool {
        return self.Get(key).HasValue();
    }
    
    fn Remove(self: Self, key: K) -> Bool {
        var hash: u64 = self.Hash(key);
        var bucket_index: u64 = hash % self.buckets.Size();
        
        var bucket_opt: Optional(*HashMapEntry(K, V)) = self.buckets.Get(bucket_index);
        if (not bucket_opt.HasValue()) {
            return False;
        }
        
        var current: *HashMapEntry(K, V) = bucket_opt.Value();
        var previous: *HashMapEntry(K, V) = null;
        
        while (current != null) {
            if (current.key == key) {
                if (previous == null) {
                    // Remove first entry in chain
                    if (current.next.HasValue()) {
                        self.buckets.Set(bucket_index, current.next.Value());
                    } else {
                        self.buckets.Set(bucket_index, null);
                    }
                } else {
                    // Remove entry from middle/end of chain
                    previous.next = current.next;
                }
                
                Memory.Deallocate(current);
                self.size -= 1;
                return True;
            }
            
            previous = current;
            if (not current.next.HasValue()) {
                break;
            }
            current = current.next.Value();
        }
        
        return False;
    }
    
    fn Size(self: Self) -> u64 {
        return self.size;
    }
    
    fn IsEmpty(self: Self) -> Bool {
        return self.size == 0;
    }
    
    fn Clear(self: Self) {
        var i: u64 = 0;
        while (i < self.buckets.Size()) {
            var bucket_opt: Optional(*HashMapEntry(K, V)) = self.buckets.Get(i);
            if (bucket_opt.HasValue()) {
                var current: *HashMapEntry(K, V) = bucket_opt.Value();
                while (current != null) {
                    var next: *HashMapEntry(K, V) = current.next.HasValue() ? current.next.Value() : null;
                    Memory.Deallocate(current);
                    current = next;
                }
                self.buckets.Set(i, null);
            }
            i += 1;
        }
        self.size = 0;
    }
    
    fn Hash(self: Self, key: K) -> u64 {
        // Simple hash function - would be specialized for different types
        var hash: u64 = 0;
        var bytes: *u8 = &key;
        var i: u64 = 0;
        while (i < SizeOf(K)) {
            hash = hash * 31 + bytes[i];
            i += 1;
        }
        return hash;
    }
    
    fn Resize(self: Self) {
        var old_buckets: Vector(*HashMapEntry(K, V)) = self.buckets;
        self.buckets = Vector(*HashMapEntry(K, V)).CreateWithCapacity(old_buckets.Size() * 2);
        
        // Initialize new buckets
        var i: u64 = 0;
        while (i < self.buckets.Capacity()) {
            self.buckets.Push(null);
            i += 1;
        }
        
        self.size = 0;
        
        // Rehash all entries
        i = 0;
        while (i < old_buckets.Size()) {
            var bucket_opt: Optional(*HashMapEntry(K, V)) = old_buckets.Get(i);
            if (bucket_opt.HasValue()) {
                var current: *HashMapEntry(K, V) = bucket_opt.Value();
                while (current != null) {
                    self.Insert(current.key, current.value);
                    var next: *HashMapEntry(K, V) = current.next.HasValue() ? current.next.Value() : null;
                    Memory.Deallocate(current);
                    current = next;
                }
            }
            i += 1;
        }
    }
    
    // Iterator support
    fn GetIterator(self: Self) -> HashMapIterator(K, V) {
        return HashMapIterator(K, V).Create(&self);
    }
    
    fn GetKeys(self: Self) -> Array(K) {
        var keys: Array(K) = Array(K)();
        var iterator: HashMapIterator(K, V) = self.GetIterator();
        
        while (iterator.HasNext()) {
            var entry: KeyValuePair(K, V) = iterator.Next();
            keys.Push(entry.key);
        }
        
        return keys;
    }
}

// Set (using HashMap internally)
class Set(T: Type) {
    var map: HashMap(T, Bool);
    
    fn Create() -> Self {
        return {
            .map = HashMap(T, Bool).Create()
        };
    }
    
    fn Insert(self: Self, item: T) {
        self.map.Insert(item, True);
    }
    
    fn Remove(self: Self, item: T) -> Bool {
        return self.map.Remove(item);
    }
    
    fn Contains(self: Self, item: T) -> Bool {
        return self.map.Contains(item);
    }
    
    fn Size(self: Self) -> u64 {
        return self.map.Size();
    }
    
    fn IsEmpty(self: Self) -> Bool {
        return self.map.IsEmpty();
    }
    
    fn Clear(self: Self) {
        self.map.Clear();
    }
}

// Linked List
struct ListNode(T: Type) {
    var data: T;
    var next: Optional(*ListNode(T));
    var prev: Optional(*ListNode(T));
}

class LinkedList(T: Type) {
    var head: Optional(*ListNode(T));
    var tail: Optional(*ListNode(T));
    var size: u64;
    
    fn Create() -> Self {
        return {
            .head = Optional(*ListNode(T)).None(),
            .tail = Optional(*ListNode(T)).None(),
            .size = 0
        };
    }
    
    fn PushFront(self: Self, item: T) {
        var new_node: *ListNode(T) = Memory.Allocate(SizeOf(ListNode(T)));
        new_node.data = item;
        new_node.next = self.head;
        new_node.prev = Optional(*ListNode(T)).None();
        
        if (self.head.HasValue()) {
            self.head.Value().prev = Optional(*ListNode(T)).Some(new_node);
        } else {
            self.tail = Optional(*ListNode(T)).Some(new_node);
        }
        
        self.head = Optional(*ListNode(T)).Some(new_node);
        self.size += 1;
    }
    
    fn PushBack(self: Self, item: T) {
        var new_node: *ListNode(T) = Memory.Allocate(SizeOf(ListNode(T)));
        new_node.data = item;
        new_node.next = Optional(*ListNode(T)).None();
        new_node.prev = self.tail;
        
        if (self.tail.HasValue()) {
            self.tail.Value().next = Optional(*ListNode(T)).Some(new_node);
        } else {
            self.head = Optional(*ListNode(T)).Some(new_node);
        }
        
        self.tail = Optional(*ListNode(T)).Some(new_node);
        self.size += 1;
    }
    
    fn PopFront(self: Self) -> Optional(T) {
        if (not self.head.HasValue()) {
            return Optional(T).None();
        }
        
        var node: *ListNode(T) = self.head.Value();
        var data: T = node.data;
        
        self.head = node.next;
        if (self.head.HasValue()) {
            self.head.Value().prev = Optional(*ListNode(T)).None();
        } else {
            self.tail = Optional(*ListNode(T)).None();
        }
        
        Memory.Deallocate(node);
        self.size -= 1;
        
        return Optional(T).Some(data);
    }
    
    fn PopBack(self: Self) -> Optional(T) {
        if (not self.tail.HasValue()) {
            return Optional(T).None();
        }
        
        var node: *ListNode(T) = self.tail.Value();
        var data: T = node.data;
        
        self.tail = node.prev;
        if (self.tail.HasValue()) {
            self.tail.Value().next = Optional(*ListNode(T)).None();
        } else {
            self.head = Optional(*ListNode(T)).None();
        }
        
        Memory.Deallocate(node);
        self.size -= 1;
        
        return Optional(T).Some(data);
    }
    
    fn Size(self: Self) -> u64 {
        return self.size;
    }
    
    fn IsEmpty(self: Self) -> Bool {
        return self.size == 0;
    }
    
    fn Clear(self: Self) {
        while (not self.IsEmpty()) {
            self.PopFront();
        }
    }
}

// Queue (using LinkedList)
class Queue(T: Type) {
    var list: LinkedList(T);
    
    fn Create() -> Self {
        return {
            .list = LinkedList(T).Create()
        };
    }
    
    fn Enqueue(self: Self, item: T) {
        self.list.PushBack(item);
    }
    
    fn Dequeue(self: Self) -> Optional(T) {
        return self.list.PopFront();
    }
    
    fn Size(self: Self) -> u64 {
        return self.list.Size();
    }
    
    fn IsEmpty(self: Self) -> Bool {
        return self.list.IsEmpty();
    }
}

// Stack (using Vector)
class Stack(T: Type) {
    var vec: Vector(T);
    
    fn Create() -> Self {
        return {
            .vec = Vector(T).Create()
        };
    }
    
    fn Push(self: Self, item: T) {
        self.vec.Push(item);
    }
    
    fn Pop(self: Self) -> Optional(T) {
        return self.vec.Pop();
    }
    
    fn Peek(self: Self) -> Optional(T) {
        if (self.vec.IsEmpty()) {
            return Optional(T).None();
        }
        return self.vec.Get(self.vec.Size() - 1);
    }
    
    fn Size(self: Self) -> u64 {
        return self.vec.Size();
    }
    
    fn IsEmpty(self: Self) -> Bool {
        return self.vec.IsEmpty();
    }
}