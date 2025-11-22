// Tests for Distributed Systems Framework
package Tests.Distributed api;

import Atomic.Testing;
import Atomic.Distributed;

class DistributedTests {
    fn RunAllTests() -> TestReport {
        var runner: TestRunner = TestRunner.Create();
        var suite: TestSuite = TestSuite.Create("Distributed Systems");
        
        // DistributedMessage Tests
        suite.AddTest(TestCase.Create("Message_Create", fn() -> TestResult {
            var payload: JSONNode = JSONNode.CreateObject();
            payload.ObjectSet("data", JSONNode.CreateString("test"));
            var message: DistributedMessage = DistributedMessage.Create(MessageType.Request, "node1", "node2", payload);
            return Assert.Equal("node1", message.sender_id, "Sender ID should be set");
        }));
        
        suite.AddTest(TestCase.Create("Message_JSON", fn() -> TestResult {
            var payload: JSONNode = JSONNode.CreateString("hello");
            var message: DistributedMessage = DistributedMessage.Create(MessageType.Notification, "sender", "receiver", payload);
            var json: JSONNode = message.ToJSON();
            var sender: Optional(JSONNode) = json.ObjectGet("sender_id");
            return Assert.True(sender.IsSome() and sender.Unwrap().AsString().Unwrap() == "sender", "JSON serialization should work");
        }));
        
        // DistributedNode Tests
        suite.AddTest(TestCase.Create("Node_Create", fn() -> TestResult {
            var node: DistributedNode = DistributedNode.Create("node1", "192.168.1.100", 8080);
            return Assert.True(node.id == "node1" and node.port == 8080, "Node should be created correctly");
        }));
        
        suite.AddTest(TestCase.Create("Node_Heartbeat", fn() -> TestResult {
            var node: DistributedNode = DistributedNode.Create("node2", "localhost", 9000);
            var initial_time: i64 = node.last_heartbeat;
            Thread.Sleep(10); // Small delay
            node.UpdateHeartbeat();
            return Assert.True(node.last_heartbeat > initial_time, "Heartbeat should be updated");
        }));
        
        suite.AddTest(TestCase.Create("Node_IsAlive", fn() -> TestResult {
            var node: DistributedNode = DistributedNode.Create("node3", "127.0.0.1", 7000);
            return Assert.True(node.IsAlive(5000), "Recently created node should be alive");
        }));
        
        // ClusterMembership Tests
        suite.AddTest(TestCase.Create("Cluster_AddNode", fn() -> TestResult {
            var membership: ClusterMembership = ClusterMembership.Create("local");
            var node: DistributedNode = DistributedNode.Create("remote1", "10.0.0.1", 8080);
            membership.AddNode(node);
            var active_nodes: Array(DistributedNode) = membership.GetActiveNodes();
            return Assert.True(active_nodes.Size() == 1, "Cluster should have one active node");
        }));
        
        suite.AddTest(TestCase.Create("Cluster_RemoveNode", fn() -> TestResult {
            var membership: ClusterMembership = ClusterMembership.Create("local");
            var node: DistributedNode = DistributedNode.Create("remote2", "10.0.0.2", 8080);
            membership.AddNode(node);
            membership.RemoveNode("remote2");
            var active_nodes: Array(DistributedNode) = membership.GetActiveNodes();
            return Assert.True(active_nodes.Size() == 0, "Cluster should have no active nodes after removal");
        }));
        
        // MessageQueue Tests
        suite.AddTest(TestCase.Create("MessageQueue_CreateQueue", fn() -> TestResult {
            var queue: DistributedMessageQueue = DistributedMessageQueue.Create();
            var result: Result(Bool, String) = queue.CreateQueue("test-queue");
            return Assert.True(result.IsOk(), "Queue creation should succeed");
        }));
        
        suite.AddTest(TestCase.Create("MessageQueue_PublishMessage", fn() -> TestResult {
            var queue: DistributedMessageQueue = DistributedMessageQueue.Create();
            queue.CreateQueue("pub-queue");
            
            var payload: JSONNode = JSONNode.CreateString("test message");
            var message: DistributedMessage = DistributedMessage.Create(MessageType.Notification, "sender", "receiver", payload);
            var result: Result(Bool, String) = queue.PublishMessage("pub-queue", message);
            
            return Assert.True(result.IsOk(), "Message publishing should succeed");
        }));
        
        // Raft Consensus Tests
        suite.AddTest(TestCase.Create("Raft_Create", fn() -> TestResult {
            var membership: ClusterMembership = ClusterMembership.Create("node1");
            var raft: RaftConsensus = RaftConsensus.Create("node1", membership);
            return Assert.True(raft.node_id == "node1" and raft.current_term == 0, "Raft should be initialized correctly");
        }));
        
        suite.AddTest(TestCase.Create("Raft_StartElection", fn() -> TestResult {
            var membership: ClusterMembership = ClusterMembership.Create("candidate");
            var raft: RaftConsensus = RaftConsensus.Create("candidate", membership);
            raft.StartElection();
            return Assert.True(raft.state == RaftState.Candidate and raft.current_term == 1, "Election should start correctly");
        }));
        
        suite.AddTest(TestCase.Create("Raft_LogEntry", fn() -> TestResult {
            var entry: LogEntry = LogEntry.Create(1, "SET x=10");
            return Assert.True(entry.term == 1 and entry.command == "SET x=10", "Log entry should be created correctly");
        }));
        
        // DistributedHashTable Tests
        suite.AddTest(TestCase.Create("DHT_Create", fn() -> TestResult {
            var node: DistributedNode = DistributedNode.Create("dht1", "localhost", 8000);
            var membership: ClusterMembership = ClusterMembership.Create("dht1");
            var dht: DistributedHashTable = DistributedHashTable.Create(node, membership);
            return Assert.True(dht.replication_factor == 3, "DHT should have default replication factor");
        }));
        
        suite.AddTest(TestCase.Create("DHT_ConsistencyLevel", fn() -> TestResult {
            var node: DistributedNode = DistributedNode.Create("dht2", "localhost", 8001);
            var membership: ClusterMembership = ClusterMembership.Create("dht2");
            var dht: DistributedHashTable = DistributedHashTable.Create(node, membership);
            var required: i32 = dht.GetRequiredSuccesses();
            return Assert.True(required == 2, "Quorum should require 2 successes for replication factor 3");
        }));
        
        // UUID Tests
        suite.AddTest(TestCase.Create("UUID_Generate", fn() -> TestResult {
            var uuid1: String = UUID.Generate();
            var uuid2: String = UUID.Generate();
            return Assert.True(uuid1 != uuid2 and uuid1.Length() > 30, "UUIDs should be unique and properly formatted");
        }));
        
        runner.AddSuite(suite);
        return runner.RunAll();
    }
}

class DistributedBenchmarks {
    fn RunBenchmarks() {
        var message_bench: Benchmark = Benchmark.Create("Message_Creation", fn() {
            var payload: JSONNode = JSONNode.CreateObject();
            payload.ObjectSet("key", JSONNode.CreateString("value"));
            var message: DistributedMessage = DistributedMessage.Create(MessageType.Request, "node1", "node2", payload);
            var json: JSONNode = message.ToJSON();
        });
        message_bench.WithIterations(1000);
        
        var uuid_bench: Benchmark = Benchmark.Create("UUID_Generation", fn() {
            var uuid: String = UUID.Generate();
        });
        uuid_bench.WithIterations(1000);
        
        var cluster_bench: Benchmark = Benchmark.Create("Cluster_Operations", fn() {
            var membership: ClusterMembership = ClusterMembership.Create("bench");
            var node: DistributedNode = DistributedNode.Create("test", "127.0.0.1", 8080);
            membership.AddNode(node);
            var active: Array(DistributedNode) = membership.GetActiveNodes();
            membership.RemoveNode("test");
        });
        cluster_bench.WithIterations(500);
        
        var raft_bench: Benchmark = Benchmark.Create("Raft_LogEntry", fn() {
            var entry: LogEntry = LogEntry.Create(5, "APPEND data");
            var json: JSONNode = entry.ToJSON();
        });
        raft_bench.WithIterations(1000);
        
        Console.WriteLine("=== Distributed Systems Performance Benchmarks ===");
        message_bench.Run().Print();
        uuid_bench.Run().Print();
        cluster_bench.Run().Print();
        raft_bench.Run().Print();
    }
}