// Networking Example - Real-world DNS resolution and HTTP client
package NetworkingExample api;

import Std.Console;
import Std.Networking;
import Std.Collections;

fn Main() -> i32 {
    Console.WriteLine("=== Atomic Networking Example ===");
    
    // Test DNS resolution
    TestDNSResolution();
    
    // Test HTTP client
    TestHttpClient();
    
    // Test TCP server/client
    TestTcpSocket();
    
    return 0;
}

fn TestDNSResolution() {
    Console.WriteLine("\n--- DNS Resolution Test ---");
    
    // Test various hostnames
    var hostnames: Array(String) = Array(String)();
    hostnames.Push("google.com");
    hostnames.Push("github.com");
    hostnames.Push("stackoverflow.com");
    hostnames.Push("localhost");
    hostnames.Push("127.0.0.1");
    hostnames.Push("invalid-hostname-test.nonexistent");
    
    var i: i32 = 0;
    while (i < hostnames.Size()) {
        var hostname: String = hostnames[i];
        Console.WriteLine("Resolving: " + hostname);
        
        // Test IPv4 resolution
        var ipv4_opt: Optional(IPv4Address) = DNSResolver.ResolveIPv4(hostname);
        if (ipv4_opt.HasValue()) {
            Console.WriteLine("  IPv4: " + ipv4_opt.Value().ToString());
        } else {
            Console.WriteLine("  IPv4: Resolution failed");
        }
        
        // Test cached resolution (should be faster)
        var cached_opt: Optional(IPv4Address) = DNSResolver.ResolveWithCache(hostname);
        if (cached_opt.HasValue()) {
            Console.WriteLine("  Cached IPv4: " + cached_opt.Value().ToString());
        }
        
        // Test reverse lookup for successful resolutions
        if (ipv4_opt.HasValue()) {
            var socket_addr: SocketAddress = SocketAddress.CreateIPv4(ipv4_opt.Value(), 80);
            var reverse_opt: Optional(String) = DNSResolver.ReverseLookup(socket_addr);
            if (reverse_opt.HasValue()) {
                Console.WriteLine("  Reverse: " + reverse_opt.Value());
            }
        }
        
        Console.WriteLine("");
        i += 1;
    }
}

fn TestHttpClient() {
    Console.WriteLine("\n--- HTTP Client Test ---");
    
    // Test HTTP GET requests
    var client: HttpClient = HttpClient.Create("http://httpbin.org");
    
    Console.WriteLine("Testing GET request to httpbin.org/get");
    var get_result: Result(HttpResponse, String) = client.Get("/get");
    if (get_result.IsOk()) {
        var response: HttpResponse = get_result.Value();
        Console.WriteLine("Status Code: " + IntToString(response.status_code));
        Console.WriteLine("Response Body Length: " + IntToString(response.body.Length()));
        
        // Print some headers
        if (response.headers.Contains("Content-Type")) {
            var content_type: String = response.headers.Get("Content-Type").Value();
            Console.WriteLine("Content-Type: " + content_type);
        }
        
        if (response.headers.Contains("Server")) {
            var server: String = response.headers.Get("Server").Value();
            Console.WriteLine("Server: " + server);
        }
    } else {
        Console.WriteLine("GET request failed: " + get_result.Error());
    }
    
    // Test HTTP POST request
    Console.WriteLine("\nTesting POST request to httpbin.org/post");
    var post_body: String = "{\"message\": \"Hello from Atomic Carbon!\", \"timestamp\": 1234567890}";
    var post_result: Result(HttpResponse, String) = client.Post("/post", post_body);
    if (post_result.IsOk()) {
        var response: HttpResponse = post_result.Value();
        Console.WriteLine("POST Status Code: " + IntToString(response.status_code));
        Console.WriteLine("POST Response Length: " + IntToString(response.body.Length()));
    } else {
        Console.WriteLine("POST request failed: " + post_result.Error());
    }
    
    // Test HTTPS (if supported)
    Console.WriteLine("\nTesting HTTPS request");
    var https_client: HttpClient = HttpClient.Create("https://api.github.com");
    var github_result: Result(HttpResponse, String) = https_client.Get("/users/octocat");
    if (github_result.IsOk()) {
        var response: HttpResponse = github_result.Value();
        Console.WriteLine("GitHub API Status: " + IntToString(response.status_code));
        if (response.status_code == 200) {
            Console.WriteLine("Successfully retrieved GitHub user data");
        }
    } else {
        Console.WriteLine("HTTPS request failed: " + github_result.Error());
    }
}

fn TestTcpSocket() {
    Console.WriteLine("\n--- TCP Socket Test ---");
    
    // Create a simple echo server in a separate thread (conceptually)
    Console.WriteLine("Creating TCP server on port 8080...");
    
    var server_result: Result(Socket, String) = Socket.Create(SocketType.TCP, AddressFamily.IPv4);
    if (not server_result.IsOk()) {
        Console.WriteLine("Failed to create server socket: " + server_result.Error());
        return;
    }
    
    var server: Socket = server_result.Value();
    
    // Bind to localhost:8080
    var server_addr: SocketAddress = SocketAddress.CreateIPv4(IPv4Address.Create(127, 0, 0, 1), 8080);
    var bind_result: Result(Bool, String) = server.Bind(server_addr);
    if (not bind_result.IsOk()) {
        Console.WriteLine("Failed to bind server: " + bind_result.Error());
        server.Close();
        return;
    }
    
    // Start listening
    var listen_result: Result(Bool, String) = server.Listen(5);
    if (not listen_result.IsOk()) {
        Console.WriteLine("Failed to listen: " + listen_result.Error());
        server.Close();
        return;
    }
    
    Console.WriteLine("Server listening on 127.0.0.1:8080");
    
    // In a real implementation, we'd spawn a thread here for the server
    // For this example, we'll simulate a client connection
    
    // Create client socket
    Console.WriteLine("Creating client connection...");
    var client_result: Result(Socket, String) = Socket.Create(SocketType.TCP, AddressFamily.IPv4);
    if (not client_result.IsOk()) {
        Console.WriteLine("Failed to create client socket: " + client_result.Error());
        server.Close();
        return;
    }
    
    var client: Socket = client_result.Value();\n    \n    // Connect to server\n    var connect_result: Result(Bool, String) = client.Connect(server_addr);\n    if (connect_result.IsOk()) {\n        Console.WriteLine(\"Client connected successfully!\");\n        \n        // Send test message\n        var message: String = \"Hello from Atomic Carbon TCP client!\";\n        var message_bytes: Array(u8) = StringToUtf8(message);\n        var send_result: Result(i32, String) = client.Send(message_bytes);\n        \n        if (send_result.IsOk()) {\n            Console.WriteLine(\"Sent \" + IntToString(send_result.Value()) + \" bytes\");\n        } else {\n            Console.WriteLine(\"Send failed: \" + send_result.Error());\n        }\n        \n        client.Close();\n    } else {\n        Console.WriteLine(\"Client connection failed: \" + connect_result.Error());\n    }\n    \n    server.Close();\n    Console.WriteLine(\"TCP socket test completed\");\n}\n\n// Advanced networking example with connection pooling\nfn TestConnectionPooling() {\n    Console.WriteLine(\"\\n--- Connection Pooling Test ---\");\n    \n    var pool: ConnectionPool = ConnectionPool.Create(\"httpbin.org\", 80, 5);\n    \n    // Simulate multiple concurrent requests\n    var i: i32 = 0;\n    while (i < 10) {\n        var connection_opt: Optional(Socket) = pool.GetConnection();\n        if (connection_opt.HasValue()) {\n            var socket: Socket = connection_opt.Value();\n            \n            // Send HTTP request\n            var request: String = \"GET /get HTTP/1.1\\r\\nHost: httpbin.org\\r\\nConnection: keep-alive\\r\\n\\r\\n\";\n            var request_bytes: Array(u8) = StringToUtf8(request);\n            socket.Send(request_bytes);\n            \n            // Read response (simplified)\n            var buffer: Array(u8) = Array(u8)(1024);\n            socket.Receive(buffer);\n            \n            Console.WriteLine(\"Request \" + IntToString(i + 1) + \" completed\");\n            \n            // Return connection to pool\n            pool.ReturnConnection(socket);\n        } else {\n            Console.WriteLine(\"No available connections in pool\");\n        }\n        \n        i += 1;\n    }\n    \n    pool.Close();\n}\n\n// Simple connection pool implementation\nclass ConnectionPool {\n    var host: String;\n    var port: u16;\n    var max_connections: i32;\n    var available_connections: Queue(Socket);\n    var active_connections: i32;\n    \n    fn Create(host: String, port: u16, max_connections: i32) -> Self {\n        return {\n            .host = host,\n            .port = port,\n            .max_connections = max_connections,\n            .available_connections = Queue(Socket).Create(),\n            .active_connections = 0\n        };\n    }\n    \n    fn GetConnection(self: Self) -> Optional(Socket) {\n        // Try to get existing connection\n        if (not self.available_connections.IsEmpty()) {\n            return self.available_connections.Dequeue();\n        }\n        \n        // Create new connection if under limit\n        if (self.active_connections < self.max_connections) {\n            var socket_result: Result(Socket, String) = Socket.Create(SocketType.TCP, AddressFamily.IPv4);\n            if (socket_result.IsOk()) {\n                var socket: Socket = socket_result.Value();\n                \n                // Resolve host and connect\n                var ip_opt: Optional(IPv4Address) = DNSResolver.ResolveWithCache(self.host);\n                if (ip_opt.HasValue()) {\n                    var addr: SocketAddress = SocketAddress.CreateIPv4(ip_opt.Value(), self.port);\n                    var connect_result: Result(Bool, String) = socket.Connect(addr);\n                    \n                    if (connect_result.IsOk()) {\n                        self.active_connections += 1;\n                        return Optional(Socket).Some(socket);\n                    }\n                }\n                \n                socket.Close();\n            }\n        }\n        \n        return Optional(Socket).None();\n    }\n    \n    fn ReturnConnection(self: Self, socket: Socket) {\n        // In a real implementation, we'd check if the connection is still valid\n        self.available_connections.Enqueue(socket);\n    }\n    \n    fn Close(self: Self) {\n        // Close all connections\n        while (not self.available_connections.IsEmpty()) {\n            var socket_opt: Optional(Socket) = self.available_connections.Dequeue();\n            if (socket_opt.HasValue()) {\n                socket_opt.Value().Close();\n            }\n        }\n        self.active_connections = 0;\n    }\n}