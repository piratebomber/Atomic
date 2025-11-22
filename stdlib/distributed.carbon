// Atomic Distributed Systems Framework
package Atomic.Distributed api;

import Std.String;
import Std.Array;
import Std.Collections;
import Std.Networking;
import Std.JSON;
import Std.Crypto;
import Std.Time;

choice MessageType { Request, Response, Notification, Heartbeat, Election, Consensus }
choice NodeStatus { Active, Inactive, Suspected, Failed }

class DistributedMessage {
    var id: String;
    var type: MessageType;
    var sender_id: String;
    var receiver_id: String;
    var timestamp: i64;
    var payload: JSONNode;
    var term: i64;
    
    fn Create(type: MessageType, sender: String, receiver: String, payload: JSONNode) -> Self {
        return { .id = UUID.Generate(), .type = type, .sender_id = sender, .receiver_id = receiver, .timestamp = Time.GetCurrentTimeMillis(), .payload = payload, .term = 0 };
    }
    
    fn ToJSON(self: Self) -> JSONNode {
        var json: JSONNode = JSONNode.CreateObject();
        json.ObjectSet("id", JSONNode.CreateString(self.id));
        json.ObjectSet("type", JSONNode.CreateInt(self.type as i64));
        json.ObjectSet("sender_id", JSONNode.CreateString(self.sender_id));
        json.ObjectSet("receiver_id", JSONNode.CreateString(self.receiver_id));
        json.ObjectSet("timestamp", JSONNode.CreateInt(self.timestamp));
        json.ObjectSet("payload", self.payload);
        json.ObjectSet("term", JSONNode.CreateInt(self.term));
        return json;
    }
}

class DistributedNode {
    var id: String;
    var address: String;
    var port: i32;
    var status: NodeStatus;
    var last_heartbeat: i64;
    
    fn Create(id: String, address: String, port: i32) -> Self {
        return { .id = id, .address = address, .port = port, .status = NodeStatus.Active, .last_heartbeat = Time.GetCurrentTimeMillis() };
    }
    
    fn IsAlive(self: Self, timeout_ms: i64) -> Bool {
        var current_time: i64 = Time.GetCurrentTimeMillis();
        return (current_time - self.last_heartbeat) < timeout_ms;
    }
    
    fn UpdateHeartbeat(self: Self) {
        self.last_heartbeat = Time.GetCurrentTimeMillis();
        if (self.status == NodeStatus.Suspected) {
            self.status = NodeStatus.Active;
        }
    }
}

class ClusterMembership {
    var nodes: HashMap(String, DistributedNode);
    var local_node_id: String;
    var heartbeat_interval_ms: i64;
    var failure_timeout_ms: i64;
    
    fn Create(local_node_id: String) -> Self {
        return { .nodes = HashMap(String, DistributedNode).Create(), .local_node_id = local_node_id, .heartbeat_interval_ms = 1000, .failure_timeout_ms = 5000 };
    }
    
    fn AddNode(self: Self, node: DistributedNode) {
        self.nodes.Insert(node.id, node);
    }
    
    fn RemoveNode(self: Self, node_id: String) {
        self.nodes.Remove(node_id);
    }
    
    fn GetActiveNodes(self: Self) -> Array(DistributedNode) {
        var active_nodes: Array(DistributedNode) = Array(DistributedNode)();
        var iter: HashMapIterator(String, DistributedNode) = self.nodes.GetIterator();
        
        while (iter.HasNext()) {
            var pair: KeyValuePair(String, DistributedNode) = iter.Next();
            if (pair.value.status == NodeStatus.Active) {
                active_nodes.Push(pair.value);
            }
        }
        
        return active_nodes;
    }
    
    fn CheckNodeHealth(self: Self) {
        var current_time: i64 = Time.GetCurrentTimeMillis();
        var iter: HashMapIterator(String, DistributedNode) = self.nodes.GetIterator();
        
        while (iter.HasNext()) {
            var pair: KeyValuePair(String, DistributedNode) = iter.Next();
            var node: DistributedNode = pair.value;
            var time_since_heartbeat: i64 = current_time - node.last_heartbeat;
            
            if (node.status == NodeStatus.Active and time_since_heartbeat > self.failure_timeout_ms) {
                node.status = NodeStatus.Failed;
            }
        }
    }
}

interface MessageHandler {
    fn HandleMessage(message: DistributedMessage) -> Void;
}

class DistributedMessageQueue {
    var queues: HashMap(String, Queue(DistributedMessage));
    var subscribers: HashMap(String, Array(MessageHandler));
    var replication_factor: i32;
    
    fn Create() -> Self {
        return { .queues = HashMap(String, Queue(DistributedMessage)).Create(), .subscribers = HashMap(String, Array(MessageHandler)).Create(), .replication_factor = 3 };
    }
    
    fn CreateQueue(self: Self, queue_name: String) -> Result(Bool, String) {
        if (self.queues.Contains(queue_name)) {
            return Result(Bool, String).Error("Queue already exists: " + queue_name);
        }
        
        var queue: Queue(DistributedMessage) = Queue(DistributedMessage).Create();
        self.queues.Insert(queue_name, queue);
        self.subscribers.Insert(queue_name, Array(MessageHandler)());
        
        return Result(Bool, String).Ok(True);
    }
    
    fn PublishMessage(self: Self, queue_name: String, message: DistributedMessage) -> Result(Bool, String) {
        var queue_opt: Optional(Queue(DistributedMessage)) = self.queues.Get(queue_name);
        if (queue_opt.IsNone()) {
            return Result(Bool, String).Error("Queue not found: " + queue_name);
        }
        
        var queue: Queue(DistributedMessage) = queue_opt.Unwrap();
        queue.Enqueue(message);
        
        self.NotifySubscribers(queue_name, message);
        return Result(Bool, String).Ok(True);
    }
    
    fn Subscribe(self: Self, queue_name: String, handler: MessageHandler) -> Result(Bool, String) {
        var subscribers_opt: Optional(Array(MessageHandler)) = self.subscribers.Get(queue_name);
        if (subscribers_opt.IsNone()) {
            return Result(Bool, String).Error("Queue not found: " + queue_name);
        }
        
        var handlers: Array(MessageHandler) = subscribers_opt.Unwrap();
        handlers.Push(handler);
        
        return Result(Bool, String).Ok(True);
    }
    
    fn NotifySubscribers(self: Self, queue_name: String, message: DistributedMessage) {
        var subscribers_opt: Optional(Array(MessageHandler)) = self.subscribers.Get(queue_name);
        if (subscribers_opt.IsSome()) {
            var handlers: Array(MessageHandler) = subscribers_opt.Unwrap();
            for (handler: MessageHandler in handlers) {
                handler.HandleMessage(message);
            }
        }
    }
}

choice RaftState { Follower, Candidate, Leader }

class RaftConsensus {
    var node_id: String;
    var current_term: i64;
    var voted_for: Optional(String);
    var log: Array(LogEntry);
    var commit_index: i64;
    var state: RaftState;
    var leader_id: Optional(String);
    var cluster_membership: ClusterMembership;
    var election_timeout_ms: i64;
    var votes_received: i32;
    
    fn Create(node_id: String, membership: ClusterMembership) -> Self {
        return { .node_id = node_id, .current_term = 0, .voted_for = Optional(String).None(), .log = Array(LogEntry)(), .commit_index = 0, .state = RaftState.Follower, .leader_id = Optional(String).None(), .cluster_membership = membership, .election_timeout_ms = 5000, .votes_received = 0 };
    }
    
    fn StartElection(self: Self) {
        self.current_term += 1;
        self.state = RaftState.Candidate;
        self.voted_for = Optional(String).Some(self.node_id);
        self.votes_received = 1;
        
        var active_nodes: Array(DistributedNode) = self.cluster_membership.GetActiveNodes();
        for (node: DistributedNode in active_nodes) {
            if (node.id != self.node_id) {
                self.SendRequestVote(node);
            }
        }
    }
    
    fn SendRequestVote(self: Self, node: DistributedNode) {
        var payload: JSONNode = JSONNode.CreateObject();
        payload.ObjectSet("term", JSONNode.CreateInt(self.current_term));
        payload.ObjectSet("candidate_id", JSONNode.CreateString(self.node_id));
        payload.ObjectSet("last_log_index", JSONNode.CreateInt(self.log.Size() as i64 - 1));
        
        var message: DistributedMessage = DistributedMessage.Create(MessageType.Request, self.node_id, node.id, payload);
        message.term = self.current_term;
    }
    
    fn HandleRequestVote(self: Self, message: DistributedMessage) -> DistributedMessage {
        var payload: JSONNode = message.payload;
        var term: i64 = payload.ObjectGet("term").Unwrap().AsInt().Unwrap();
        var candidate_id: String = payload.ObjectGet("candidate_id").Unwrap().AsString().Unwrap();
        
        var vote_granted: Bool = False;
        
        if (term > self.current_term) {
            self.current_term = term;
            self.voted_for = Optional(String).None();
            self.state = RaftState.Follower;
        }
        
        if (term == self.current_term and (self.voted_for.IsNone() or self.voted_for.Unwrap() == candidate_id)) {
            vote_granted = True;
            self.voted_for = Optional(String).Some(candidate_id);
        }
        
        var response_payload: JSONNode = JSONNode.CreateObject();
        response_payload.ObjectSet("term", JSONNode.CreateInt(self.current_term));
        response_payload.ObjectSet("vote_granted", JSONNode.CreateBool(vote_granted));
        
        var response: DistributedMessage = DistributedMessage.Create(MessageType.Response, self.node_id, message.sender_id, response_payload);
        response.term = self.current_term;
        
        return response;
    }
    
    fn HandleRequestVoteResponse(self: Self, message: DistributedMessage) {
        var payload: JSONNode = message.payload;
        var term: i64 = payload.ObjectGet("term").Unwrap().AsInt().Unwrap();
        var vote_granted: Bool = payload.ObjectGet("vote_granted").Unwrap().AsBool().Unwrap();
        
        if (term > self.current_term) {
            self.current_term = term;
            self.state = RaftState.Follower;
            self.voted_for = Optional(String).None();
            return;
        }
        
        if (self.state == RaftState.Candidate and term == self.current_term and vote_granted) {
            self.votes_received += 1;
            var majority: i32 = (self.cluster_membership.GetActiveNodes().Size() as i32 / 2) + 1;
            
            if (self.votes_received >= majority) {
                self.BecomeLeader();
            }
        }
    }
    
    fn BecomeLeader(self: Self) {
        self.state = RaftState.Leader;
        self.leader_id = Optional(String).Some(self.node_id);
    }
    
    fn AppendLogEntry(self: Self, command: String) -> Result(Bool, String) {
        if (self.state != RaftState.Leader) {
            return Result(Bool, String).Error("Only leader can append log entries");
        }
        
        var entry: LogEntry = LogEntry.Create(self.current_term, command);
        self.log.Push(entry);
        
        return Result(Bool, String).Ok(True);
    }
}

class LogEntry {
    var term: i64;
    var command: String;
    var timestamp: i64;
    
    fn Create(term: i64, command: String) -> Self {
        return { .term = term, .command = command, .timestamp = Time.GetCurrentTimeMillis() };
    }
}

choice ConsistencyLevel { One, Quorum, All }

class DistributedHashTable {
    var local_node: DistributedNode;
    var cluster_membership: ClusterMembership;
    var data: HashMap(String, String);
    var replication_factor: i32;
    var consistency_level: ConsistencyLevel;
    
    fn Create(local_node: DistributedNode, membership: ClusterMembership) -> Self {
        return { .local_node = local_node, .cluster_membership = membership, .data = HashMap(String, String).Create(), .replication_factor = 3, .consistency_level = ConsistencyLevel.Quorum };
    }
    
    fn Put(self: Self, key: String, value: String) -> Result(Bool, String) {
        var responsible_nodes: Array(DistributedNode) = self.GetResponsibleNodes(key);
        var success_count: i32 = 0;
        var required_successes: i32 = self.GetRequiredSuccesses();
        
        for (node: DistributedNode in responsible_nodes) {
            if (node.id == self.local_node.id) {
                self.data.Insert(key, value);
                success_count += 1;
            } else {
                var put_result: Result(Bool, String) = self.RemotePut(node, key, value);
                if (put_result.IsOk()) {
                    success_count += 1;
                }
            }
            
            if (success_count >= required_successes) {
                return Result(Bool, String).Ok(True);
            }
        }
        
        return Result(Bool, String).Error("Failed to achieve required consistency level");
    }
    
    fn Get(self: Self, key: String) -> Result(Optional(String), String) {
        var responsible_nodes: Array(DistributedNode) = self.GetResponsibleNodes(key);
        
        for (node: DistributedNode in responsible_nodes) {
            if (node.id == self.local_node.id) {
                return Result(Optional(String), String).Ok(self.data.Get(key));
            } else {
                var get_result: Result(Optional(String), String) = self.RemoteGet(node, key);
                if (get_result.IsOk()) {
                    return get_result;
                }
            }
        }
        
        return Result(Optional(String), String).Ok(Optional(String).None());
    }
    
    fn GetResponsibleNodes(self: Self, key: String) -> Array(DistributedNode) {
        var hash_result: Result(HashResult, String) = Hasher.HashString(HashAlgorithm.SHA256, key);
        if (hash_result.IsError()) {
            return Array(DistributedNode)();
        }
        
        var active_nodes: Array(DistributedNode) = self.cluster_membership.GetActiveNodes();
        var responsible_nodes: Array(DistributedNode) = Array(DistributedNode)();
        
        for (i: i32 in Range(0, Math.Min(self.replication_factor, active_nodes.Size() as i32))) {
            var node: Optional(DistributedNode) = active_nodes.Get(i as u64);
            if (node.IsSome()) {
                responsible_nodes.Push(node.Unwrap());
            }
        }
        
        return responsible_nodes;
    }
    
    fn GetRequiredSuccesses(self: Self) -> i32 {
        match (self.consistency_level) {
            case ConsistencyLevel.One => 1,
            case ConsistencyLevel.Quorum => (self.replication_factor / 2) + 1,
            case ConsistencyLevel.All => self.replication_factor,
            default => 1
        }
    }
    
    fn RemotePut(self: Self, node: DistributedNode, key: String, value: String) -> Result(Bool, String) {
        var payload: JSONNode = JSONNode.CreateObject();
        payload.ObjectSet("operation", JSONNode.CreateString("put"));
        payload.ObjectSet("key", JSONNode.CreateString(key));
        payload.ObjectSet("value", JSONNode.CreateString(value));
        
        var message: DistributedMessage = DistributedMessage.Create(MessageType.Request, self.local_node.id, node.id, payload);
        return Result(Bool, String).Ok(True);
    }
    
    fn RemoteGet(self: Self, node: DistributedNode, key: String) -> Result(Optional(String), String) {
        var payload: JSONNode = JSONNode.CreateObject();
        payload.ObjectSet("operation", JSONNode.CreateString("get"));
        payload.ObjectSet("key", JSONNode.CreateString(key));
        
        var message: DistributedMessage = DistributedMessage.Create(MessageType.Request, self.local_node.id, node.id, payload);
        return Result(Optional(String), String).Ok(Optional(String).None());
    }
}

class UUID {
    fn Generate() -> String {
        var random_bytes: Array(u8) = SecureRandom.GenerateBytes(16);
        
        random_bytes.Set(6, (random_bytes.Get(6).Unwrap() & 0x0F) | 0x40);
        random_bytes.Set(8, (random_bytes.Get(8).Unwrap() & 0x3F) | 0x80);
        
        var uuid: String = "";
        for (i: u64 in Range(0, 16)) {
            var byte_opt: Optional(u8) = random_bytes.Get(i);
            if (byte_opt.IsSome()) {
                var byte_val: u8 = byte_opt.Unwrap();
                uuid += String.FromHex(byte_val);
                
                if (i == 3 or i == 5 or i == 7 or i == 9) {
                    uuid += "-";
                }
            }
        }
        
        return uuid;
    }
}