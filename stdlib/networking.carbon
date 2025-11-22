// Atomic Standard Library - Networking
package Std.Networking api;

import Std.String;
import Std.Array;
import Std.Platform;
import Std.Collections;

// Socket types
choice SocketType {
    TCP,
    UDP,
    Raw
}

choice AddressFamily {
    IPv4,
    IPv6,
    Unix
}

// Network address structures
struct IPv4Address {
    var octets: Array(u8); // 4 octets
    
    fn Create(a: u8, b: u8, c: u8, d: u8) -> Self {
        var addr: Self = {
            .octets = Array(u8)()
        };
        addr.octets.Push(a);
        addr.octets.Push(b);
        addr.octets.Push(c);
        addr.octets.Push(d);
        return addr;
    }
    
    fn FromString(ip_str: String) -> Optional(Self) {
        var parts: Array(String) = ip_str.Split(".");
        if (parts.Size() != 4) {
            return Optional(Self).None();
        }
        
        var addr: Self = {
            .octets = Array(u8)()
        };
        
        var i: i32 = 0;
        while (i < 4) {
            var octet: i32 = StringToInt(parts[i]);
            if (octet < 0 or octet > 255) {
                return Optional(Self).None();
            }
            addr.octets.Push(octet as u8);
            i += 1;
        }
        
        return Optional(Self).Some(addr);
    }
    
    fn ToString(self: Self) -> String {
        return IntToString(self.octets[0]) + "." +
               IntToString(self.octets[1]) + "." +
               IntToString(self.octets[2]) + "." +
               IntToString(self.octets[3]);
    }
}

struct IPv6Address {
    var segments: Array(u16); // 8 segments
    
    fn Create() -> Self {
        var addr: Self = {
            .segments = Array(u16)()
        };
        var i: i32 = 0;
        while (i < 8) {
            addr.segments.Push(0);
            i += 1;
        }
        return addr;
    }
}

struct SocketAddress {
    var family: AddressFamily;
    var ipv4: Optional(IPv4Address);
    var ipv6: Optional(IPv6Address);
    var port: u16;
    
    fn CreateIPv4(ip: IPv4Address, port: u16) -> Self {
        return {
            .family = AddressFamily.IPv4,
            .ipv4 = Optional(IPv4Address).Some(ip),
            .ipv6 = Optional(IPv6Address).None(),
            .port = port
        };
    }
    
    fn CreateIPv6(ip: IPv6Address, port: u16) -> Self {
        return {
            .family = AddressFamily.IPv6,
            .ipv4 = Optional(IPv4Address).None(),
            .ipv6 = Optional(IPv6Address).Some(ip),
            .port = port
        };
    }
}

// Socket class
class Socket {
    var handle: i64;
    var socket_type: SocketType;
    var family: AddressFamily;
    var is_connected: Bool;
    var is_listening: Bool;
    var local_address: Optional(SocketAddress);
    var remote_address: Optional(SocketAddress);
    
    fn Create(socket_type: SocketType, family: AddressFamily) -> Result(Self, String) {
        var socket: Self = {
            .handle = -1,
            .socket_type = socket_type,
            .family = family,
            .is_connected = False,
            .is_listening = False,
            .local_address = Optional(SocketAddress).None(),
            .remote_address = Optional(SocketAddress).None()
        };
        
        var result: Result(i64, String) = socket.CreateNativeSocket();
        if (not result.IsOk()) {
            return Result(Self, String).Error(result.Error());
        }
        
        socket.handle = result.Value();
        return Result(Self, String).Ok(socket);
    }
    
    fn Bind(self: Self, address: SocketAddress) -> Result(Bool, String) {
        if (self.handle == -1) {
            return Result(Bool, String).Error("Socket not created");
        }
        
        var bind_result: Result(Bool, String) = self.BindNative(address);
        if (bind_result.IsOk()) {
            self.local_address = Optional(SocketAddress).Some(address);
        }
        
        return bind_result;
    }
    
    fn Listen(self: Self, backlog: i32) -> Result(Bool, String) {
        if (self.handle == -1) {
            return Result(Bool, String).Error("Socket not created");
        }
        
        var listen_result: Result(Bool, String) = self.ListenNative(backlog);
        if (listen_result.IsOk()) {
            self.is_listening = True;
        }
        
        return listen_result;
    }
    
    fn Accept(self: Self) -> Result(Socket, String) {
        if (self.handle == -1 or not self.is_listening) {
            return Result(Socket, String).Error("Socket not listening");
        }
        
        return self.AcceptNative();
    }
    
    fn Connect(self: Self, address: SocketAddress) -> Result(Bool, String) {
        if (self.handle == -1) {
            return Result(Bool, String).Error("Socket not created");
        }
        
        var connect_result: Result(Bool, String) = self.ConnectNative(address);
        if (connect_result.IsOk()) {
            self.is_connected = True;
            self.remote_address = Optional(SocketAddress).Some(address);
        }
        
        return connect_result;
    }
    
    fn Send(self: Self, data: Array(u8)) -> Result(i32, String) {
        if (self.handle == -1 or not self.is_connected) {
            return Result(i32, String).Error("Socket not connected");
        }
        
        return self.SendNative(data);
    }
    
    fn Receive(self: Self, buffer: Array(u8)) -> Result(i32, String) {
        if (self.handle == -1 or not self.is_connected) {
            return Result(i32, String).Error("Socket not connected");
        }
        
        return self.ReceiveNative(buffer);
    }
    
    fn SendTo(self: Self, data: Array(u8), address: SocketAddress) -> Result(i32, String) {
        if (self.handle == -1) {
            return Result(i32, String).Error("Socket not created");
        }
        
        return self.SendToNative(data, address);
    }
    
    fn ReceiveFrom(self: Self, buffer: Array(u8)) -> Result(ReceiveResult, String) {
        if (self.handle == -1) {
            return Result(ReceiveResult, String).Error("Socket not created");
        }
        
        return self.ReceiveFromNative(buffer);
    }
    
    fn Close(self: Self) -> Result(Bool, String) {
        if (self.handle == -1) {
            return Result(Bool, String).Ok(True);
        }
        
        var close_result: Result(Bool, String) = self.CloseNative();
        if (close_result.IsOk()) {
            self.handle = -1;
            self.is_connected = False;
            self.is_listening = False;
        }
        
        return close_result;
    }
    
    fn SetOption(self: Self, option: SocketOption, value: i32) -> Result(Bool, String) {
        return self.SetOptionNative(option, value);
    }
    
    fn GetOption(self: Self, option: SocketOption) -> Result(i32, String) {
        return self.GetOptionNative(option);
    }
    
    // Platform-specific implementations
    fn CreateNativeSocket(self: Self) -> Result(i64, String) {
        match (Platform.GetCurrentOS()) {
            case (Platform.OS.Windows) {
                return self.CreateWindowsSocket();
            }
            default {
                return self.CreateUnixSocket();
            }
        }
    }
    
    fn CreateWindowsSocket(self: Self) -> Result(i64, String) {
        var af: i32 = self.family == AddressFamily.IPv4 ? 2 : 23; // AF_INET : AF_INET6
        var type: i32 = self.socket_type == SocketType.TCP ? 1 : 2; // SOCK_STREAM : SOCK_DGRAM
        var protocol: i32 = self.socket_type == SocketType.TCP ? 6 : 17; // IPPROTO_TCP : IPPROTO_UDP
        
        var socket_handle: i64 = WSASocket(af, type, protocol, null, 0, 0);
        if (socket_handle == -1) {
            return Result(i64, String).Error("Failed to create Windows socket");
        }
        
        return Result(i64, String).Ok(socket_handle);
    }
    
    fn CreateUnixSocket(self: Self) -> Result(i64, String) {
        var af: i32 = self.family == AddressFamily.IPv4 ? 2 : 10; // AF_INET : AF_INET6
        var type: i32 = self.socket_type == SocketType.TCP ? 1 : 2; // SOCK_STREAM : SOCK_DGRAM
        var protocol: i32 = 0;
        
        var socket_handle: i64 = socket(af, type, protocol);
        if (socket_handle == -1) {
            return Result(i64, String).Error("Failed to create Unix socket");
        }
        
        return Result(i64, String).Ok(socket_handle);
    }
    
    fn BindNative(self: Self, address: SocketAddress) -> Result(Bool, String) {
        match (Platform.GetCurrentOS()) {
            case (Platform.OS.Windows) {
                return self.BindWindows(address);
            }
            default {
                return self.BindUnix(address);
            }
        }
    }
    
    fn BindWindows(self: Self, address: SocketAddress) -> Result(Bool, String) {
        if (address.family == AddressFamily.IPv4 and address.ipv4.HasValue()) {
            var addr: sockaddr_in = {
                .sin_family = 2, // AF_INET
                .sin_port = htons(address.port),
                .sin_addr = {.s_addr = 0}, // Will be set from IPv4Address
                .sin_zero = Array(u8)()
            };
            
            // Convert IPv4Address to s_addr
            var ip: IPv4Address = address.ipv4.Value();
            addr.sin_addr.s_addr = (ip.octets[0] as u32) |
                                  ((ip.octets[1] as u32) << 8) |
                                  ((ip.octets[2] as u32) << 16) |
                                  ((ip.octets[3] as u32) << 24);
            
            var result: i32 = bind(self.handle, &addr, SizeOf(sockaddr_in));
            if (result == 0) {
                return Result(Bool, String).Ok(True);
            } else {
                return Result(Bool, String).Error("Bind failed");
            }
        }
        
        return Result(Bool, String).Error("Unsupported address family");
    }
    
    fn BindUnix(self: Self, address: SocketAddress) -> Result(Bool, String) {
        // Similar to Windows implementation but using Unix structures
        return self.BindWindows(address); // Placeholder - would use Unix-specific code
    }
    
    fn ListenNative(self: Self, backlog: i32) -> Result(Bool, String) {
        var result: i32 = listen(self.handle, backlog);
        if (result == 0) {
            return Result(Bool, String).Ok(True);
        } else {
            return Result(Bool, String).Error("Listen failed");
        }
    }
    
    fn AcceptNative(self: Self) -> Result(Socket, String) {
        var client_addr: sockaddr_in;
        var addr_len: i32 = SizeOf(sockaddr_in);
        
        var client_handle: i64 = accept(self.handle, &client_addr, &addr_len);
        if (client_handle == -1) {
            return Result(Socket, String).Error("Accept failed");
        }
        
        var client_socket: Socket = {
            .handle = client_handle,
            .socket_type = self.socket_type,
            .family = self.family,
            .is_connected = True,
            .is_listening = False,
            .local_address = self.local_address,
            .remote_address = Optional(SocketAddress).None() // Would extract from client_addr
        };
        
        return Result(Socket, String).Ok(client_socket);
    }
    
    fn ConnectNative(self: Self, address: SocketAddress) -> Result(Bool, String) {
        if (address.family == AddressFamily.IPv4 and address.ipv4.HasValue()) {
            var addr: sockaddr_in = {
                .sin_family = 2, // AF_INET
                .sin_port = htons(address.port),
                .sin_addr = {.s_addr = 0},
                .sin_zero = Array(u8)()
            };
            
            // Convert IPv4Address to s_addr
            var ip: IPv4Address = address.ipv4.Value();
            addr.sin_addr.s_addr = (ip.octets[0] as u32) |
                                  ((ip.octets[1] as u32) << 8) |
                                  ((ip.octets[2] as u32) << 16) |
                                  ((ip.octets[3] as u32) << 24);
            
            var result: i32 = connect(self.handle, &addr, SizeOf(sockaddr_in));
            if (result == 0) {
                return Result(Bool, String).Ok(True);
            } else {
                return Result(Bool, String).Error("Connect failed");
            }
        }
        
        return Result(Bool, String).Error("Unsupported address family");
    }
    
    fn SendNative(self: Self, data: Array(u8)) -> Result(i32, String) {
        var bytes_sent: i32 = send(self.handle, data.Data(), data.Size(), 0);
        if (bytes_sent >= 0) {
            return Result(i32, String).Ok(bytes_sent);
        } else {
            return Result(i32, String).Error("Send failed");
        }
    }
    
    fn ReceiveNative(self: Self, buffer: Array(u8)) -> Result(i32, String) {
        var bytes_received: i32 = recv(self.handle, buffer.Data(), buffer.Size(), 0);
        if (bytes_received >= 0) {
            return Result(i32, String).Ok(bytes_received);
        } else {
            return Result(i32, String).Error("Receive failed");
        }
    }
    
    fn SendToNative(self: Self, data: Array(u8), address: SocketAddress) -> Result(i32, String) {
        // Implementation for UDP sendto
        return Result(i32, String).Error("SendTo not implemented");
    }
    
    fn ReceiveFromNative(self: Self, buffer: Array(u8)) -> Result(ReceiveResult, String) {
        // Implementation for UDP recvfrom
        return Result(ReceiveResult, String).Error("ReceiveFrom not implemented");
    }
    
    fn CloseNative(self: Self) -> Result(Bool, String) {
        match (Platform.GetCurrentOS()) {
            case (Platform.OS.Windows) {
                var result: i32 = closesocket(self.handle);
                return result == 0 ? Result(Bool, String).Ok(True) : Result(Bool, String).Error("Close failed");
            }
            default {
                var result: i32 = close(self.handle);
                return result == 0 ? Result(Bool, String).Ok(True) : Result(Bool, String).Error("Close failed");
            }
        }
    }
    
    fn SetOptionNative(self: Self, option: SocketOption, value: i32) -> Result(Bool, String) {
        var opt_name: i32 = self.GetSocketOptionValue(option);
        var result: i32 = setsockopt(self.handle, 1, opt_name, &value, SizeOf(i32)); // SOL_SOCKET = 1
        
        if (result == 0) {
            return Result(Bool, String).Ok(True);
        } else {
            return Result(Bool, String).Error("SetOption failed");
        }
    }
    
    fn GetOptionNative(self: Self, option: SocketOption) -> Result(i32, String) {
        var opt_name: i32 = self.GetSocketOptionValue(option);
        var value: i32 = 0;
        var len: i32 = SizeOf(i32);
        var result: i32 = getsockopt(self.handle, 1, opt_name, &value, &len);
        
        if (result == 0) {
            return Result(i32, String).Ok(value);
        } else {
            return Result(i32, String).Error("GetOption failed");
        }
    }
    
    fn GetSocketOptionValue(self: Self, option: SocketOption) -> i32 {
        match (option) {
            case (SocketOption.ReuseAddress) { return 2; } // SO_REUSEADDR
            case (SocketOption.KeepAlive) { return 9; } // SO_KEEPALIVE
            case (SocketOption.Broadcast) { return 6; } // SO_BROADCAST
            case (SocketOption.SendBuffer) { return 7; } // SO_SNDBUF
            case (SocketOption.ReceiveBuffer) { return 8; } // SO_RCVBUF
            default { return 0; }
        }
    }
}

// HTTP Client
class HttpClient {
    var base_url: String;
    var default_headers: HashMap(String, String);
    
    fn Create(base_url: String) -> Self {
        return {
            .base_url = base_url,
            .default_headers = HashMap(String, String).Create()
        };
    }
    
    fn Get(self: Self, path: String) -> Result(HttpResponse, String) {
        return self.Request("GET", path, Optional(String).None());
    }
    
    fn Post(self: Self, path: String, body: String) -> Result(HttpResponse, String) {
        return self.Request("POST", path, Optional(String).Some(body));
    }
    
    fn Request(self: Self, method: String, path: String, body: Optional(String)) -> Result(HttpResponse, String) {
        // Parse URL
        var url_parts: UrlParts = self.ParseUrl(self.base_url + path);
        
        // Create socket
        var socket_result: Result(Socket, String) = Socket.Create(SocketType.TCP, AddressFamily.IPv4);
        if (not socket_result.IsOk()) {
            return Result(HttpResponse, String).Error(socket_result.Error());
        }
        
        var socket: Socket = socket_result.Value();
        
        // Resolve hostname and connect
        var ip_opt: Optional(IPv4Address) = self.ResolveHostname(url_parts.host);
        if (not ip_opt.HasValue()) {
            return Result(HttpResponse, String).Error("Failed to resolve hostname");
        }
        
        var address: SocketAddress = SocketAddress.CreateIPv4(ip_opt.Value(), url_parts.port);
        var connect_result: Result(Bool, String) = socket.Connect(address);
        if (not connect_result.IsOk()) {
            return Result(HttpResponse, String).Error(connect_result.Error());
        }
        
        // Build HTTP request
        var request: String = method + " " + url_parts.path + " HTTP/1.1\r\n";
        request += "Host: " + url_parts.host + "\r\n";
        request += "Connection: close\r\n";
        
        if (body.HasValue()) {
            request += "Content-Length: " + IntToString(body.Value().Length()) + "\r\n";
        }
        
        request += "\r\n";
        
        if (body.HasValue()) {
            request += body.Value();
        }
        
        // Send request
        var request_bytes: Array(u8) = StringToUtf8(request);
        var send_result: Result(i32, String) = socket.Send(request_bytes);
        if (not send_result.IsOk()) {
            return Result(HttpResponse, String).Error(send_result.Error());
        }
        
        // Read response
        var response_data: Array(u8) = Array(u8)();
        var buffer: Array(u8) = Array(u8)(4096);
        
        while (True) {
            var recv_result: Result(i32, String) = socket.Receive(buffer);
            if (not recv_result.IsOk()) {
                break;
            }
            
            var bytes_received: i32 = recv_result.Value();
            if (bytes_received == 0) {
                break;
            }
            
            var i: i32 = 0;
            while (i < bytes_received) {
                response_data.Push(buffer[i]);
                i += 1;
            }
        }
        
        socket.Close();
        
        // Parse HTTP response
        var response_str: String = Utf8ToString(response_data);
        return self.ParseHttpResponse(response_str);
    }
    
    fn ParseUrl(self: Self, url: String) -> UrlParts {
        // Simple URL parsing
        var parts: UrlParts = {
            .scheme = "http",
            .host = "localhost",
            .port = 80,
            .path = "/"
        };
        
        // Extract scheme
        if (url.StartsWith("http://")) {
            parts.scheme = "http";
            url = url.Substring(7);
        } else if (url.StartsWith("https://")) {
            parts.scheme = "https";
            parts.port = 443;
            url = url.Substring(8);
        }
        
        // Extract host and path
        var slash_pos: i32 = url.IndexOf("/");
        if (slash_pos >= 0) {
            parts.host = url.Substring(0, slash_pos);
            parts.path = url.Substring(slash_pos);
        } else {
            parts.host = url;
        }
        
        // Extract port if present
        var colon_pos: i32 = parts.host.IndexOf(":");
        if (colon_pos >= 0) {
            var port_str: String = parts.host.Substring(colon_pos + 1);
            parts.port = StringToInt(port_str);
            parts.host = parts.host.Substring(0, colon_pos);
        }
        
        return parts;
    }
    
    fn ResolveHostname(self: Self, hostname: String) -> Optional(IPv4Address) {
        return DNSResolver.ResolveIPv4(hostname);
    }
    
    fn ParseHttpResponse(self: Self, response: String) -> Result(HttpResponse, String) {
        var lines: Array(String) = response.Split("\r\n");
        if (lines.Size() == 0) {
            return Result(HttpResponse, String).Error("Empty response");
        }
        
        // Parse status line
        var status_line: String = lines[0];
        var status_parts: Array(String) = status_line.Split(" ");
        if (status_parts.Size() < 3) {
            return Result(HttpResponse, String).Error("Invalid status line");
        }
        
        var status_code: i32 = StringToInt(status_parts[1]);
        
        // Parse headers
        var headers: HashMap(String, String) = HashMap(String, String).Create();
        var i: i32 = 1;
        var body_start: i32 = -1;
        
        while (i < lines.Size()) {
            if (lines[i].IsEmpty()) {
                body_start = i + 1;
                break;
            }
            
            var colon_pos: i32 = lines[i].IndexOf(":");
            if (colon_pos >= 0) {
                var header_name: String = lines[i].Substring(0, colon_pos).Trim();
                var header_value: String = lines[i].Substring(colon_pos + 1).Trim();
                headers.Insert(header_name, header_value);
            }
            
            i += 1;
        }
        
        // Extract body
        var body: String = "";
        if (body_start >= 0 and body_start < lines.Size()) {
            var j: i32 = body_start;
            while (j < lines.Size()) {
                body += lines[j];
                if (j < lines.Size() - 1) {
                    body += "\r\n";
                }
                j += 1;
            }
        }
        
        var http_response: HttpResponse = {
            .status_code = status_code,
            .headers = headers,
            .body = body
        };
        
        return Result(HttpResponse, String).Ok(http_response);
    }
}

// Supporting structures and enums
struct ReceiveResult {
    var bytes_received: i32;
    var sender_address: SocketAddress;
}

struct UrlParts {
    var scheme: String;
    var host: String;
    var port: u16;
    var path: String;
}

struct HttpResponse {
    var status_code: i32;
    var headers: HashMap(String, String);
    var body: String;
}

choice SocketOption {
    ReuseAddress,
    KeepAlive,
    Broadcast,
    SendBuffer,
    ReceiveBuffer
}

// Platform-specific structures
struct sockaddr_in {
    var sin_family: u16;
    var sin_port: u16;
    var sin_addr: in_addr;
    var sin_zero: Array(u8); // 8 bytes
}

struct in_addr {
    var s_addr: u32;
}

// DNS Resolution System
class DNSResolver {
    fn ResolveIPv4(hostname: String) -> Optional(IPv4Address) {
        // First try to parse as IP address
        var ip_opt: Optional(IPv4Address) = IPv4Address.FromString(hostname);
        if (ip_opt.HasValue()) {
            return ip_opt;
        }
        
        // Handle localhost
        if (hostname == "localhost" or hostname == "127.0.0.1") {
            return Optional(IPv4Address).Some(IPv4Address.Create(127, 0, 0, 1));
        }
        
        // Use platform-specific DNS resolution
        match (Platform.GetCurrentOS()) {
            case (Platform.OS.Windows) {
                return DNSResolver.ResolveWindowsIPv4(hostname);
            }
            default {
                return DNSResolver.ResolveUnixIPv4(hostname);
            }
        }
    }
    
    fn ResolveIPv6(hostname: String) -> Optional(IPv6Address) {
        match (Platform.GetCurrentOS()) {
            case (Platform.OS.Windows) {
                return DNSResolver.ResolveWindowsIPv6(hostname);
            }
            default {
                return DNSResolver.ResolveUnixIPv6(hostname);
            }
        }
    }
    
    fn ResolveAll(hostname: String, family: AddressFamily) -> Array(SocketAddress) {
        var addresses: Array(SocketAddress) = Array(SocketAddress)();
        
        match (Platform.GetCurrentOS()) {
            case (Platform.OS.Windows) {
                return DNSResolver.ResolveWindowsAll(hostname, family);
            }
            default {
                return DNSResolver.ResolveUnixAll(hostname, family);
            }
        }
    }
    
    // Windows DNS resolution using getaddrinfo
    fn ResolveWindowsIPv4(hostname: String) -> Optional(IPv4Address) {
        var hostname_cstr: Array(u8) = StringToCString(hostname);
        var hints: addrinfo = {
            .ai_flags = 0,
            .ai_family = 2, // AF_INET (IPv4)
            .ai_socktype = 1, // SOCK_STREAM
            .ai_protocol = 6, // IPPROTO_TCP
            .ai_addrlen = 0,
            .ai_canonname = null,
            .ai_addr = null,
            .ai_next = null
        };
        
        var result: *addrinfo = null;
        var ret: i32 = getaddrinfo(hostname_cstr.Data(), null, &hints, &result);
        
        if (ret != 0 or result == null) {
            return Optional(IPv4Address).None();
        }
        
        // Extract first IPv4 address
        var current: *addrinfo = result;
        while (current != null) {
            if (current.ai_family == 2 and current.ai_addr != null) { // AF_INET
                var sockaddr: *sockaddr_in = current.ai_addr;
                var addr_bytes: u32 = ntohl(sockaddr.sin_addr.s_addr);
                
                var ip: IPv4Address = IPv4Address.Create(
                    (addr_bytes >> 24) & 0xFF,
                    (addr_bytes >> 16) & 0xFF,
                    (addr_bytes >> 8) & 0xFF,
                    addr_bytes & 0xFF
                );
                
                freeaddrinfo(result);
                return Optional(IPv4Address).Some(ip);
            }
            current = current.ai_next;
        }
        
        freeaddrinfo(result);
        return Optional(IPv4Address).None();
    }
    
    fn ResolveWindowsIPv6(hostname: String) -> Optional(IPv6Address) {
        var hostname_cstr: Array(u8) = StringToCString(hostname);
        var hints: addrinfo = {
            .ai_flags = 0,
            .ai_family = 23, // AF_INET6
            .ai_socktype = 1, // SOCK_STREAM
            .ai_protocol = 6, // IPPROTO_TCP
            .ai_addrlen = 0,
            .ai_canonname = null,
            .ai_addr = null,
            .ai_next = null
        };
        
        var result: *addrinfo = null;
        var ret: i32 = getaddrinfo(hostname_cstr.Data(), null, &hints, &result);
        
        if (ret != 0 or result == null) {
            return Optional(IPv6Address).None();
        }
        
        // Extract first IPv6 address
        var current: *addrinfo = result;
        while (current != null) {
            if (current.ai_family == 23 and current.ai_addr != null) { // AF_INET6
                var sockaddr6: *sockaddr_in6 = current.ai_addr;
                var ipv6: IPv6Address = IPv6Address.Create();
                
                // Copy IPv6 address segments
                var i: i32 = 0;
                while (i < 8) {
                    var segment: u16 = ntohs(sockaddr6.sin6_addr.s6_addr16[i]);
                    ipv6.segments[i] = segment;
                    i += 1;
                }
                
                freeaddrinfo(result);
                return Optional(IPv6Address).Some(ipv6);
            }
            current = current.ai_next;
        }
        
        freeaddrinfo(result);
        return Optional(IPv6Address).None();
    }
    
    fn ResolveWindowsAll(hostname: String, family: AddressFamily) -> Array(SocketAddress) {
        var addresses: Array(SocketAddress) = Array(SocketAddress)();
        var hostname_cstr: Array(u8) = StringToCString(hostname);
        
        var hints: addrinfo = {
            .ai_flags = 0,
            .ai_family = family == AddressFamily.IPv4 ? 2 : (family == AddressFamily.IPv6 ? 23 : 0), // AF_UNSPEC = 0
            .ai_socktype = 1, // SOCK_STREAM
            .ai_protocol = 6, // IPPROTO_TCP
            .ai_addrlen = 0,
            .ai_canonname = null,
            .ai_addr = null,
            .ai_next = null
        };
        
        var result: *addrinfo = null;
        var ret: i32 = getaddrinfo(hostname_cstr.Data(), null, &hints, &result);
        
        if (ret != 0 or result == null) {
            return addresses;
        }
        
        // Extract all addresses
        var current: *addrinfo = result;
        while (current != null) {
            if (current.ai_addr != null) {
                if (current.ai_family == 2) { // AF_INET
                    var sockaddr: *sockaddr_in = current.ai_addr;
                    var addr_bytes: u32 = ntohl(sockaddr.sin_addr.s_addr);
                    
                    var ip: IPv4Address = IPv4Address.Create(
                        (addr_bytes >> 24) & 0xFF,
                        (addr_bytes >> 16) & 0xFF,
                        (addr_bytes >> 8) & 0xFF,
                        addr_bytes & 0xFF
                    );
                    
                    var socket_addr: SocketAddress = SocketAddress.CreateIPv4(ip, ntohs(sockaddr.sin_port));
                    addresses.Push(socket_addr);
                } else if (current.ai_family == 23) { // AF_INET6
                    var sockaddr6: *sockaddr_in6 = current.ai_addr;
                    var ipv6: IPv6Address = IPv6Address.Create();
                    
                    var i: i32 = 0;
                    while (i < 8) {
                        ipv6.segments[i] = ntohs(sockaddr6.sin6_addr.s6_addr16[i]);
                        i += 1;
                    }
                    
                    var socket_addr: SocketAddress = SocketAddress.CreateIPv6(ipv6, ntohs(sockaddr6.sin6_port));
                    addresses.Push(socket_addr);
                }
            }
            current = current.ai_next;
        }
        
        freeaddrinfo(result);
        return addresses;
    }
    
    // Unix DNS resolution using getaddrinfo
    fn ResolveUnixIPv4(hostname: String) -> Optional(IPv4Address) {
        return DNSResolver.ResolveWindowsIPv4(hostname); // Same implementation
    }
    
    fn ResolveUnixIPv6(hostname: String) -> Optional(IPv6Address) {
        return DNSResolver.ResolveWindowsIPv6(hostname); // Same implementation
    }
    
    fn ResolveUnixAll(hostname: String, family: AddressFamily) -> Array(SocketAddress) {
        return DNSResolver.ResolveWindowsAll(hostname, family); // Same implementation
    }
    
    // Reverse DNS lookup
    fn ReverseLookup(address: SocketAddress) -> Optional(String) {
        match (Platform.GetCurrentOS()) {
            case (Platform.OS.Windows) {
                return DNSResolver.ReverseLookupWindows(address);
            }
            default {
                return DNSResolver.ReverseLookupUnix(address);
            }
        }
    }
    
    fn ReverseLookupWindows(address: SocketAddress) -> Optional(String) {
        if (address.family == AddressFamily.IPv4 and address.ipv4.HasValue()) {
            var sockaddr: sockaddr_in = {
                .sin_family = 2, // AF_INET
                .sin_port = htons(address.port),
                .sin_addr = {.s_addr = 0},
                .sin_zero = Array(u8)()
            };
            
            var ip: IPv4Address = address.ipv4.Value();
            sockaddr.sin_addr.s_addr = htonl(
                (ip.octets[0] as u32 << 24) |
                (ip.octets[1] as u32 << 16) |
                (ip.octets[2] as u32 << 8) |
                (ip.octets[3] as u32)
            );
            
            var hostname: Array(u8) = Array(u8)(256);
            var service: Array(u8) = Array(u8)(32);
            
            var ret: i32 = getnameinfo(
                &sockaddr,
                SizeOf(sockaddr_in),
                hostname.Data(),
                256,
                service.Data(),
                32,
                0 // flags
            );
            
            if (ret == 0) {
                return Optional(String).Some(CStringToString(hostname.Data()));
            }
        }
        
        return Optional(String).None();
    }
    
    fn ReverseLookupUnix(address: SocketAddress) -> Optional(String) {
        return DNSResolver.ReverseLookupWindows(address); // Same implementation
    }
    
    // DNS cache for performance
    var dns_cache: HashMap(String, CacheEntry) = HashMap(String, CacheEntry).Create();
    
    fn ResolveWithCache(hostname: String) -> Optional(IPv4Address) {
        // Check cache first
        var cache_entry_opt: Optional(CacheEntry) = DNSResolver.dns_cache.Get(hostname);
        if (cache_entry_opt.HasValue()) {
            var entry: CacheEntry = cache_entry_opt.Value();
            var current_time: u64 = GetCurrentTimeSeconds();
            
            if (current_time < entry.expires_at) {
                return Optional(IPv4Address).Some(entry.address);
            } else {
                // Entry expired, remove from cache
                DNSResolver.dns_cache.Remove(hostname);
            }
        }
        
        // Resolve and cache
        var address_opt: Optional(IPv4Address) = DNSResolver.ResolveIPv4(hostname);
        if (address_opt.HasValue()) {
            var cache_entry: CacheEntry = {
                .address = address_opt.Value(),
                .expires_at = GetCurrentTimeSeconds() + 300 // 5 minutes TTL
            };
            DNSResolver.dns_cache.Insert(hostname, cache_entry);
        }
        
        return address_opt;
    }
    
    fn ClearCache() {
        DNSResolver.dns_cache.Clear();
    }
}

struct CacheEntry {
    var address: IPv4Address;
    var expires_at: u64;
}

// Additional networking structures for getaddrinfo
struct addrinfo {
    var ai_flags: i32;
    var ai_family: i32;
    var ai_socktype: i32;
    var ai_protocol: i32;
    var ai_addrlen: u64;
    var ai_canonname: *u8;
    var ai_addr: *sockaddr_in;
    var ai_next: *addrinfo;
}

struct sockaddr_in6 {
    var sin6_family: u16;
    var sin6_port: u16;
    var sin6_flowinfo: u32;
    var sin6_addr: in6_addr;
    var sin6_scope_id: u32;
}

struct in6_addr {
    var s6_addr: Array(u8); // 16 bytes
    var s6_addr16: Array(u16); // 8 u16 values
    var s6_addr32: Array(u32); // 4 u32 values
}

// System call declarations
// Windows
fn WSASocket(af: i32, type: i32, protocol: i32, info: *Void, group: u32, flags: u32) -> i64;
fn closesocket(socket: i64) -> i32;
fn WSAStartup(version: u16, data: *WSAData) -> i32;
fn WSACleanup() -> i32;

// Cross-platform getaddrinfo family
fn getaddrinfo(node: *u8, service: *u8, hints: *addrinfo, res: **addrinfo) -> i32;
fn freeaddrinfo(res: *addrinfo);
fn getnameinfo(sa: *sockaddr_in, salen: u64, host: *u8, hostlen: u64, serv: *u8, servlen: u64, flags: i32) -> i32;
fn gai_strerror(errcode: i32) -> *u8;

// Network byte order conversion
fn htonl(hostlong: u32) -> u32;
fn ntohl(netlong: u32) -> u32;
fn htons(hostshort: u16) -> u16;
fn ntohs(netshort: u16) -> u16;

// Unix/Common socket functions
fn socket(domain: i32, type: i32, protocol: i32) -> i64;
fn bind(socket: i64, addr: *sockaddr_in, addrlen: i32) -> i32;
fn listen(socket: i64, backlog: i32) -> i32;
fn accept(socket: i64, addr: *sockaddr_in, addrlen: *i32) -> i64;
fn connect(socket: i64, addr: *sockaddr_in, addrlen: i32) -> i32;
fn send(socket: i64, buf: *u8, len: u64, flags: i32) -> i32;
fn recv(socket: i64, buf: *u8, len: u64, flags: i32) -> i32;
fn close(fd: i32) -> i32;
fn setsockopt(socket: i64, level: i32, optname: i32, optval: *i32, optlen: i32) -> i32;
fn getsockopt(socket: i64, level: i32, optname: i32, optval: *i32, optlen: *i32) -> i32;

// Time functions
fn GetCurrentTimeSeconds() -> u64;

// Windows-specific structures
struct WSAData {
    var wVersion: u16;
    var wHighVersion: u16;
    var iMaxSockets: u16;
    var iMaxUdpDg: u16;
    var lpVendorInfo: *u8;
    var szDescription: Array(u8); // 257 bytes
    var szSystemStatus: Array(u8); // 129 bytes
}