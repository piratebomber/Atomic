// Atomic Language Server Protocol
package Atomic.LSP api;

import Std.String;
import Std.Array;
import Std.Collections;
import Std.JSON;
import Std.Networking;

class Position {
    var line: i32;
    var character: i32;
    
    fn Create(line: i32, character: i32) -> Self {
        return { .line = line, .character = character };
    }
}

class Range {
    var start: Position;
    var end: Position;
    
    fn Create(start: Position, end: Position) -> Self {
        return { .start = start, .end = end };
    }
}

class TextDocumentItem {
    var uri: String;
    var language_id: String;
    var version: i32;
    var text: String;
    
    fn Create(uri: String, language_id: String, version: i32, text: String) -> Self {
        return { .uri = uri, .language_id = language_id, .version = version, .text = text };
    }
}

choice DiagnosticSeverity { Error, Warning, Information, Hint }

class Diagnostic {
    var range: Range;
    var severity: DiagnosticSeverity;
    var message: String;
    
    fn Create(range: Range, severity: DiagnosticSeverity, message: String) -> Self {
        return { .range = range, .severity = severity, .message = message };
    }
}

choice CompletionItemKind { Text, Method, Function, Constructor, Field, Variable, Class, Interface, Module, Property }

class CompletionItem {
    var label: String;
    var kind: CompletionItemKind;
    var detail: String;
    
    fn Create(label: String, kind: CompletionItemKind) -> Self {
        return { .label = label, .kind = kind, .detail = "" };
    }
}

class DocumentManager {
    var documents: HashMap(String, TextDocumentItem);
    var diagnostics: HashMap(String, Array(Diagnostic));
    
    fn Create() -> Self {
        return { .documents = HashMap(String, TextDocumentItem).Create(), .diagnostics = HashMap(String, Array(Diagnostic)).Create() };
    }
    
    fn OpenDocument(self: Self, document: TextDocumentItem) {
        self.documents.Insert(document.uri, document);
        self.ValidateDocument(document.uri);
    }
    
    fn ValidateDocument(self: Self, uri: String) {
        var doc_opt: Optional(TextDocumentItem) = self.documents.Get(uri);
        if (doc_opt.IsSome()) {
            var doc: TextDocumentItem = doc_opt.Unwrap();
            var diagnostics: Array(Diagnostic) = self.AnalyzeDocument(doc);
            self.diagnostics.Insert(uri, diagnostics);
        }
    }
    
    fn AnalyzeDocument(self: Self, document: TextDocumentItem) -> Array(Diagnostic) {
        var diagnostics: Array(Diagnostic) = Array(Diagnostic)();
        var lines: Array(String) = document.text.Split("\n");
        
        for (i: u64 in Range(0, lines.Size())) {
            var line: Optional(String) = lines.Get(i);
            if (line.IsSome()) {
                var line_text: String = line.Unwrap();
                
                if (line_text.Contains("fn ") and not line_text.Contains("->")) {
                    var range: Range = Range.Create(Position.Create(i as i32, 0), Position.Create(i as i32, line_text.Length() as i32));
                    var diagnostic: Diagnostic = Diagnostic.Create(range, DiagnosticSeverity.Error, "Function declaration missing return type");
                    diagnostics.Push(diagnostic);
                }
            }
        }
        
        return diagnostics;
    }
}

class CompletionProvider {
    var keywords: Array(String);
    var builtin_types: Array(String);
    
    fn Create() -> Self {
        var keywords: Array(String) = Array(String)();
        keywords.Push("fn"); keywords.Push("var"); keywords.Push("if"); keywords.Push("else"); keywords.Push("class");
        
        var types: Array(String) = Array(String)();
        types.Push("i32"); types.Push("i64"); types.Push("String"); types.Push("Bool");
        
        return { .keywords = keywords, .builtin_types = types };
    }
    
    fn GetCompletions(self: Self, document: TextDocumentItem, position: Position) -> Array(CompletionItem) {
        var completions: Array(CompletionItem) = Array(CompletionItem)();
        
        for (keyword: String in self.keywords) {
            var item: CompletionItem = CompletionItem.Create(keyword, CompletionItemKind.Text);
            completions.Push(item);
        }
        
        for (type_name: String in self.builtin_types) {
            var item: CompletionItem = CompletionItem.Create(type_name, CompletionItemKind.Class);
            completions.Push(item);
        }
        
        return completions;
    }
}

class LanguageServer {
    var document_manager: DocumentManager;
    var completion_provider: CompletionProvider;
    var client_socket: Optional(TCPSocket);
    var is_running: Bool;
    
    fn Create() -> Self {
        return { .document_manager = DocumentManager.Create(), .completion_provider = CompletionProvider.Create(), .client_socket = Optional(TCPSocket).None(), .is_running = False };
    }
    
    fn StartServer(self: Self, port: i32) -> Result(Bool, String) {
        var server_socket: TCPServerSocket = TCPServerSocket.Create();
        var bind_result: Result(Bool, String) = server_socket.Bind("127.0.0.1", port);
        
        if (bind_result.IsError()) {
            return bind_result;
        }
        
        var listen_result: Result(Bool, String) = server_socket.Listen(1);
        if (listen_result.IsError()) {
            return listen_result;
        }
        
        Console.WriteLine("Language server listening on port " + String.FromInt32(port));
        
        self.is_running = True;
        
        while (self.is_running) {
            var accept_result: Result(TCPSocket, String) = server_socket.Accept();
            if (accept_result.IsOk()) {
                self.client_socket = Optional(TCPSocket).Some(accept_result.Unwrap());
                self.HandleClient();
            }
        }
        
        return Result(Bool, String).Ok(True);
    }
    
    fn HandleClient(self: Self) {
        if (self.client_socket.IsNone()) { return; }
        
        var socket: TCPSocket = self.client_socket.Unwrap();
        
        while (self.is_running) {
            var message_result: Result(String, String) = self.ReadMessage(socket);
            if (message_result.IsError()) { break; }
            
            var message_text: String = message_result.Unwrap();
            var response: String = self.ProcessMessage(message_text);
            
            if (not response.IsEmpty()) {
                self.SendMessage(socket, response);
            }
        }
        
        socket.Close();
    }
    
    fn ReadMessage(self: Self, socket: TCPSocket) -> Result(String, String) {
        var content_length: i32 = 0;
        
        while (True) {
            var line_result: Result(String, String) = socket.ReadLine();
            if (line_result.IsError()) { return line_result; }
            
            var line: String = line_result.Unwrap();
            if (line.IsEmpty() or line == "\r") { break; }
            
            if (line.StartsWith("Content-Length: ")) {
                var length_str: String = line.Substring(16).Trim();
                var length_opt: Optional(i32) = String.ToInt32(length_str);
                if (length_opt.IsSome()) {
                    content_length = length_opt.Unwrap();
                }
            }
        }
        
        if (content_length <= 0) {
            return Result(String, String).Error("Invalid content length");
        }
        
        var buffer_result: Result(Array(u8), String) = socket.Read(content_length);
        if (buffer_result.IsError()) {
            return Result(String, String).Error(buffer_result.UnwrapError());
        }
        
        return Result(String, String).Ok(String.FromBytes(buffer_result.Unwrap()));
    }
    
    fn SendMessage(self: Self, socket: TCPSocket, message: String) {
        var header: String = "Content-Length: " + String.FromInt32(message.Length() as i32) + "\r\n\r\n";
        var full_message: String = header + message;
        socket.Write(full_message.ToBytes());
    }
    
    fn ProcessMessage(self: Self, message_text: String) -> String {
        var parse_result: Result(JSONNode, String) = JSON.Parse(message_text);
        if (parse_result.IsError()) { return ""; }
        
        var json: JSONNode = parse_result.Unwrap();
        var method_opt: Optional(JSONNode) = json.ObjectGet("method");
        
        if (method_opt.IsNone()) { return ""; }
        
        var method: String = method_opt.Unwrap().AsString().Unwrap();
        
        match (method) {
            case "initialize" => { return self.HandleInitialize(json); }
            case "textDocument/didOpen" => { self.HandleDidOpen(json); return ""; }
            case "textDocument/completion" => { return self.HandleCompletion(json); }
            case "shutdown" => { return self.HandleShutdown(json); }
            case "exit" => { self.is_running = False; return ""; }
            default => { return ""; }
        }
    }
    
    fn HandleInitialize(self: Self, request: JSONNode) -> String {
        var capabilities: JSONNode = JSONNode.CreateObject();
        capabilities.ObjectSet("textDocumentSync", JSONNode.CreateInt(1));
        capabilities.ObjectSet("completionProvider", JSONNode.CreateObject());
        
        var result: JSONNode = JSONNode.CreateObject();
        result.ObjectSet("capabilities", capabilities);
        
        var response: JSONNode = JSONNode.CreateObject();
        response.ObjectSet("jsonrpc", JSONNode.CreateString("2.0"));
        response.ObjectSet("id", request.ObjectGet("id").Unwrap());
        response.ObjectSet("result", result);
        
        return JSON.Serialize(response);
    }
    
    fn HandleDidOpen(self: Self, params: JSONNode) {
        var text_doc_opt: Optional(JSONNode) = params.ObjectGet("params");
        if (text_doc_opt.IsSome()) {
            var text_doc: JSONNode = text_doc_opt.Unwrap().ObjectGet("textDocument").Unwrap();
            
            var uri: String = text_doc.ObjectGet("uri").Unwrap().AsString().Unwrap();
            var language_id: String = text_doc.ObjectGet("languageId").Unwrap().AsString().Unwrap();
            var version: i32 = text_doc.ObjectGet("version").Unwrap().AsInt().Unwrap();
            var text: String = text_doc.ObjectGet("text").Unwrap().AsString().Unwrap();
            
            var document: TextDocumentItem = TextDocumentItem.Create(uri, language_id, version, text);
            self.document_manager.OpenDocument(document);
        }
    }
    
    fn HandleCompletion(self: Self, request: JSONNode) -> String {
        var completions: Array(CompletionItem) = Array(CompletionItem)();
        completions.Push(CompletionItem.Create("fn", CompletionItemKind.Text));
        completions.Push(CompletionItem.Create("var", CompletionItemKind.Text));
        
        var result: JSONNode = JSONNode.CreateArray();
        for (completion: CompletionItem in completions) {
            var item: JSONNode = JSONNode.CreateObject();
            item.ObjectSet("label", JSONNode.CreateString(completion.label));
            item.ObjectSet("kind", JSONNode.CreateInt(completion.kind as i64));
            result.ArrayPush(item);
        }
        
        var response: JSONNode = JSONNode.CreateObject();
        response.ObjectSet("jsonrpc", JSONNode.CreateString("2.0"));
        response.ObjectSet("id", request.ObjectGet("id").Unwrap());
        response.ObjectSet("result", result);
        
        return JSON.Serialize(response);
    }
    
    fn HandleShutdown(self: Self, request: JSONNode) -> String {
        var response: JSONNode = JSONNode.CreateObject();
        response.ObjectSet("jsonrpc", JSONNode.CreateString("2.0"));
        response.ObjectSet("id", request.ObjectGet("id").Unwrap());
        response.ObjectSet("result", JSONNode.CreateNull());
        
        return JSON.Serialize(response);
    }
}