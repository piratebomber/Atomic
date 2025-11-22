// Atomic Standard Library - Advanced Iterator System
package Std.Iterator api;

import Std.Array;
import Std.Collections;
import Std.Memory;

// Key-Value Pair for HashMap iteration
struct KeyValuePair(K: Type, V: Type) {
    var key: K;
    var value: V;
}

// Iterator traversal orders
choice IteratorTraversalOrder {
    Insertion,      // Order of insertion (default)
    KeyAscending,   // Sort by key ascending
    KeyDescending,  // Sort by key descending
    ValueAscending, // Sort by value ascending
    ValueDescending,// Sort by value descending
    HashOrder,      // Order by hash value
    Random          // Random order
}

// HashMap Iterator with complex traversal logic
class HashMapIterator(K: Type, V: Type) {
    var map: *HashMap(K, V);
    var current_bucket: u64;
    var current_entry: *HashMapEntry(K, V);
    var visited_count: u64;
    var modification_count: u64;
    var snapshot_entries: Array(KeyValuePair(K, V));
    var snapshot_index: u64;
    var use_snapshot: Bool;
    var traversal_order: IteratorTraversalOrder;
    
    fn Create(map: *HashMap(K, V)) -> Self {
        var iterator: Self = {
            .map = map,
            .current_bucket = 0,
            .current_entry = null,
            .visited_count = 0,
            .modification_count = 0,
            .snapshot_entries = Array(KeyValuePair(K, V))(),
            .snapshot_index = 0,
            .use_snapshot = False,
            .traversal_order = IteratorTraversalOrder.Insertion
        };
        
        iterator.FindNextEntry();
        return iterator;
    }
    
    fn CreateWithOrder(map: *HashMap(K, V), order: IteratorTraversalOrder) -> Self {
        var iterator: Self = HashMapIterator(K, V).Create(map);
        iterator.traversal_order = order;
        
        if (order != IteratorTraversalOrder.Insertion) {
            iterator.CreateSnapshot();
        }
        
        return iterator;
    }
    
    fn HasNext(self: Self) -> Bool {
        if (self.use_snapshot) {
            return self.snapshot_index < self.snapshot_entries.Size();
        }
        
        return self.current_entry != null or self.FindNextEntryFromCurrent();
    }
    
    fn Next(self: Self) -> KeyValuePair(K, V) {
        if (not self.HasNext()) {
            return {.key = K(), .value = V()};
        }
        
        if (self.use_snapshot) {
            var entry: KeyValuePair(K, V) = self.snapshot_entries[self.snapshot_index];
            self.snapshot_index += 1;
            return entry;
        }
        
        var entry: KeyValuePair(K, V) = {
            .key = self.current_entry.key,
            .value = self.current_entry.value
        };
        
        self.visited_count += 1;
        self.AdvanceToNext();
        
        return entry;
    }
    
    fn Peek(self: Self) -> Optional(KeyValuePair(K, V)) {
        if (not self.HasNext()) {
            return Optional(KeyValuePair(K, V)).None();
        }
        
        if (self.use_snapshot) {
            return Optional(KeyValuePair(K, V)).Some(self.snapshot_entries[self.snapshot_index]);
        }
        
        var entry: KeyValuePair(K, V) = {
            .key = self.current_entry.key,
            .value = self.current_entry.value
        };
        
        return Optional(KeyValuePair(K, V)).Some(entry);
    }
    
    fn Reset(self: Self) {
        self.current_bucket = 0;
        self.current_entry = null;
        self.visited_count = 0;
        self.snapshot_index = 0;
        
        if (not self.use_snapshot) {
            self.FindNextEntry();
        }
    }
    
    fn Skip(self: Self, count: u64) {
        var i: u64 = 0;
        while (i < count and self.HasNext()) {
            self.Next();
            i += 1;
        }
    }
    
    fn Remaining(self: Self) -> u64 {
        if (self.use_snapshot) {
            return self.snapshot_entries.Size() - self.snapshot_index;
        }
        
        return self.map.Size() - self.visited_count;
    }
    
    fn ToArray(self: Self) -> Array(KeyValuePair(K, V)) {
        var result: Array(KeyValuePair(K, V)) = Array(KeyValuePair(K, V))();
        
        while (self.HasNext()) {
            result.Push(self.Next());
        }
        
        return result;
    }
    
    // Private helper methods
    fn FindNextEntry(self: Self) {
        while (self.current_bucket < self.map.buckets.Size()) {
            var bucket_opt: Optional(*HashMapEntry(K, V)) = self.map.buckets.Get(self.current_bucket);
            if (bucket_opt.HasValue() and bucket_opt.Value() != null) {
                self.current_entry = bucket_opt.Value();
                return;
            }
            self.current_bucket += 1;
        }
        
        self.current_entry = null;
    }
    
    fn FindNextEntryFromCurrent(self: Self) -> Bool {
        var saved_bucket: u64 = self.current_bucket;
        var saved_entry: *HashMapEntry(K, V) = self.current_entry;
        
        self.AdvanceToNext();
        var has_next: Bool = self.current_entry != null;
        
        self.current_bucket = saved_bucket;
        self.current_entry = saved_entry;
        
        return has_next;
    }
    
    fn AdvanceToNext(self: Self) {
        if (self.current_entry != null and self.current_entry.next.HasValue()) {
            self.current_entry = self.current_entry.next.Value();
        } else {
            self.current_bucket += 1;
            self.FindNextEntry();
        }
    }
    
    fn CreateSnapshot(self: Self) {
        self.snapshot_entries.Clear();
        
        var temp_iterator: HashMapIterator(K, V) = HashMapIterator(K, V).Create(self.map);
        while (temp_iterator.HasNext()) {
            self.snapshot_entries.Push(temp_iterator.Next());
        }
        
        match (self.traversal_order) {
            case (IteratorTraversalOrder.KeyAscending) {
                self.SortSnapshotByKey(True);
            }
            case (IteratorTraversalOrder.KeyDescending) {
                self.SortSnapshotByKey(False);
            }
            case (IteratorTraversalOrder.ValueAscending) {
                self.SortSnapshotByValue(True);
            }
            case (IteratorTraversalOrder.ValueDescending) {
                self.SortSnapshotByValue(False);
            }
            case (IteratorTraversalOrder.HashOrder) {
                self.SortSnapshotByHash();
            }
            case (IteratorTraversalOrder.Random) {
                self.ShuffleSnapshot();
            }
            default {}
        }
        
        self.use_snapshot = True;
        self.snapshot_index = 0;
    }
    
    fn SortSnapshotByKey(self: Self, ascending: Bool) {
        var n: u64 = self.snapshot_entries.Size();
        var i: u64 = 0;
        
        while (i < n - 1) {
            var j: u64 = 0;
            while (j < n - i - 1) {
                var should_swap: Bool = False;
                
                if (ascending) {
                    should_swap = self.CompareKeys(self.snapshot_entries[j].key, self.snapshot_entries[j + 1].key) > 0;
                } else {
                    should_swap = self.CompareKeys(self.snapshot_entries[j].key, self.snapshot_entries[j + 1].key) < 0;
                }
                
                if (should_swap) {
                    var temp: KeyValuePair(K, V) = self.snapshot_entries[j];
                    self.snapshot_entries[j] = self.snapshot_entries[j + 1];
                    self.snapshot_entries[j + 1] = temp;
                }
                
                j += 1;
            }
            i += 1;
        }
    }
    
    fn SortSnapshotByValue(self: Self, ascending: Bool) {
        var n: u64 = self.snapshot_entries.Size();
        var i: u64 = 0;
        
        while (i < n - 1) {
            var j: u64 = 0;
            while (j < n - i - 1) {
                var should_swap: Bool = False;
                
                if (ascending) {
                    should_swap = self.CompareValues(self.snapshot_entries[j].value, self.snapshot_entries[j + 1].value) > 0;
                } else {
                    should_swap = self.CompareValues(self.snapshot_entries[j].value, self.snapshot_entries[j + 1].value) < 0;
                }
                
                if (should_swap) {
                    var temp: KeyValuePair(K, V) = self.snapshot_entries[j];
                    self.snapshot_entries[j] = self.snapshot_entries[j + 1];
                    self.snapshot_entries[j + 1] = temp;
                }
                
                j += 1;
            }
            i += 1;
        }
    }
    
    fn SortSnapshotByHash(self: Self) {
        var n: u64 = self.snapshot_entries.Size();
        var i: u64 = 0;
        
        while (i < n - 1) {
            var j: u64 = 0;
            while (j < n - i - 1) {
                var hash1: u64 = self.map.Hash(self.snapshot_entries[j].key);
                var hash2: u64 = self.map.Hash(self.snapshot_entries[j + 1].key);
                
                if (hash1 > hash2) {
                    var temp: KeyValuePair(K, V) = self.snapshot_entries[j];
                    self.snapshot_entries[j] = self.snapshot_entries[j + 1];
                    self.snapshot_entries[j + 1] = temp;
                }
                
                j += 1;
            }
            i += 1;
        }
    }
    
    fn ShuffleSnapshot(self: Self) {
        var n: u64 = self.snapshot_entries.Size();
        var i: u64 = n - 1;
        
        while (i > 0) {
            var j: u64 = self.GenerateRandomIndex(i + 1);
            
            var temp: KeyValuePair(K, V) = self.snapshot_entries[i];
            self.snapshot_entries[i] = self.snapshot_entries[j];
            self.snapshot_entries[j] = temp;
            
            i -= 1;
        }
    }
    
    fn CompareKeys(self: Self, key1: K, key2: K) -> i32 {
        var bytes1: *u8 = &key1;
        var bytes2: *u8 = &key2;
        return Memory.MemoryCompare(bytes1, bytes2, SizeOf(K));
    }
    
    fn CompareValues(self: Self, value1: V, value2: V) -> i32 {
        var bytes1: *u8 = &value1;
        var bytes2: *u8 = &value2;
        return Memory.MemoryCompare(bytes1, bytes2, SizeOf(V));
    }
    
    fn GenerateRandomIndex(self: Self, max: u64) -> u64 {
        var seed: u64 = self.visited_count * 1103515245 + 12345;
        return seed % max;
    }
}

// Specialized iterators for different use cases
class HashMapKeyIterator(K: Type, V: Type) {
    var base_iterator: HashMapIterator(K, V);
    
    fn Create(map: *HashMap(K, V)) -> Self {
        return {
            .base_iterator = HashMapIterator(K, V).Create(map)
        };
    }
    
    fn HasNext(self: Self) -> Bool {
        return self.base_iterator.HasNext();
    }
    
    fn Next(self: Self) -> K {
        return self.base_iterator.Next().key;
    }
}

class HashMapValueIterator(K: Type, V: Type) {
    var base_iterator: HashMapIterator(K, V);
    
    fn Create(map: *HashMap(K, V)) -> Self {
        return {
            .base_iterator = HashMapIterator(K, V).Create(map)
        };
    }
    
    fn HasNext(self: Self) -> Bool {
        return self.base_iterator.HasNext();
    }
    
    fn Next(self: Self) -> V {
        return self.base_iterator.Next().value;
    }
}

// Concurrent-safe iterator
class ConcurrentHashMapIterator(K: Type, V: Type) {
    var snapshot: Array(KeyValuePair(K, V));
    var index: u64;
    var version: u64;
    
    fn Create(map: *HashMap(K, V)) -> Self {
        var iterator: Self = {
            .snapshot = Array(KeyValuePair(K, V))(),
            .index = 0,
            .version = 0
        };
        
        var base_iterator: HashMapIterator(K, V) = map.GetIterator();
        while (base_iterator.HasNext()) {
            iterator.snapshot.Push(base_iterator.Next());
        }
        
        return iterator;
    }
    
    fn HasNext(self: Self) -> Bool {
        return self.index < self.snapshot.Size();
    }
    
    fn Next(self: Self) -> KeyValuePair(K, V) {
        if (not self.HasNext()) {
            return {.key = K(), .value = V()};
        }
        
        var entry: KeyValuePair(K, V) = self.snapshot[self.index];
        self.index += 1;
        return entry;
    }
}