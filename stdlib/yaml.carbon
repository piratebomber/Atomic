// Atomic Standard Library - YAML Parser
package Std.YAML api;

import Std.String;
import Std.Array;
import Std.Collections;
import Std.Memory;

// YAML value types
choice YAMLType {
    Null,
    Boolean,
    Integer,
    Float,
    String,
    Array,
    Object
}

// YAML node
class YAMLNode {
    var type: YAMLType;
    var bool_value: Bool;
    var int_value: i64;
    var float_value: f64;
    var string_value: String;
    var array_value: Array(YAMLNode);
    var object_value: HashMap(String, YAMLNode);
    var tag: String;
    var anchor: String;
    var line_number: i32;
    
    fn CreateNull() -> Self {
        return {
            .type = YAMLType.Null,
            .bool_value = False,
            .int_value = 0,
            .float_value = 0.0,
            .string_value = "",
            .array_value = Array(YAMLNode)(),
            .object_value = HashMap(String, YAMLNode).Create(),
            .tag = "",
            .anchor = "",
            .line_number = 0
        };
    }
    
    fn CreateBool(value: Bool) -> Self {
        return {
            .type = YAMLType.Boolean,
            .bool_value = value,
            .int_value = 0,
            .float_value = 0.0,
            .string_value = "",
            .array_value = Array(YAMLNode)(),
            .object_value = HashMap(String, YAMLNode).Create(),
            .tag = "",
            .anchor = "",
            .line_number = 0
        };
    }
    
    fn CreateInt(value: i64) -> Self {
        return {
            .type = YAMLType.Integer,
            .bool_value = False,
            .int_value = value,
            .float_value = 0.0,
            .string_value = "",
            .array_value = Array(YAMLNode)(),
            .object_value = HashMap(String, YAMLNode).Create(),
            .tag = "",
            .anchor = "",
            .line_number = 0
        };
    }
    
    fn CreateFloat(value: f64) -> Self {
        return {
            .type = YAMLType.Float,
            .bool_value = False,
            .int_value = 0,
            .float_value = value,
            .string_value = "",
            .array_value = Array(YAMLNode)(),
            .object_value = HashMap(String, YAMLNode).Create(),
            .tag = "",
            .anchor = "",
            .line_number = 0
        };
    }
    
    fn CreateString(value: String) -> Self {
        return {
            .type = YAMLType.String,
            .bool_value = False,
            .int_value = 0,
            .float_value = 0.0,
            .string_value = value,
            .array_value = Array(YAMLNode)(),
            .object_value = HashMap(String, YAMLNode).Create(),
            .tag = "",
            .anchor = "",
            .line_number = 0
        };
    }
    
    fn CreateArray() -> Self {
        return {
            .type = YAMLType.Array,
            .bool_value = False,
            .int_value = 0,
            .float_value = 0.0,
            .string_value = "",
            .array_value = Array(YAMLNode)(),
            .object_value = HashMap(String, YAMLNode).Create(),
            .tag = "",
            .anchor = "",
            .line_number = 0
        };
    }
    
    fn CreateObject() -> Self {
        return {
            .type = YAMLType.Object,
            .bool_value = False,
            .int_value = 0,
            .float_value = 0.0,
            .string_value = "",
            .array_value = Array(YAMLNode)(),
            .object_value = HashMap(String, YAMLNode).Create(),
            .tag = "",
            .anchor = "",
            .line_number = 0
        };
    }
    
    // Type checking
    fn IsNull(self: Self) -> Bool { return self.type == YAMLType.Null; }
    fn IsBool(self: Self) -> Bool { return self.type == YAMLType.Boolean; }
    fn IsInt(self: Self) -> Bool { return self.type == YAMLType.Integer; }
    fn IsFloat(self: Self) -> Bool { return self.type == YAMLType.Float; }
    fn IsString(self: Self) -> Bool { return self.type == YAMLType.String; }
    fn IsArray(self: Self) -> Bool { return self.type == YAMLType.Array; }
    fn IsObject(self: Self) -> Bool { return self.type == YAMLType.Object; }
    
    // Value access
    fn AsBool(self: Self) -> Optional(Bool) {
        if (self.type == YAMLType.Boolean) {
            return Optional(Bool).Some(self.bool_value);
        }
        return Optional(Bool).None();
    }
    
    fn AsInt(self: Self) -> Optional(i64) {
        if (self.type == YAMLType.Integer) {
            return Optional(i64).Some(self.int_value);
        }
        return Optional(i64).None();
    }
    
    fn AsFloat(self: Self) -> Optional(f64) {
        if (self.type == YAMLType.Float) {
            return Optional(f64).Some(self.float_value);
        } else if (self.type == YAMLType.Integer) {
            return Optional(f64).Some(self.int_value as f64);
        }
        return Optional(f64).None();
    }
    
    fn AsString(self: Self) -> Optional(String) {
        if (self.type == YAMLType.String) {
            return Optional(String).Some(self.string_value);
        }
        return Optional(String).None();
    }
    
    // Array operations
    fn ArrayPush(self: Self, value: YAMLNode) -> Bool {
        if (self.type == YAMLType.Array) {
            self.array_value.Push(value);
            return True;
        }
        return False;
    }
    
    fn ArrayGet(self: Self, index: u64) -> Optional(YAMLNode) {
        if (self.type == YAMLType.Array and index < self.array_value.Size()) {
            return self.array_value.Get(index);
        }
        return Optional(YAMLNode).None();
    }
    
    fn ArraySize(self: Self) -> u64 {
        if (self.type == YAMLType.Array) {
            return self.array_value.Size();
        }
        return 0;
    }
    
    // Object operations
    fn ObjectSet(self: Self, key: String, value: YAMLNode) -> Bool {
        if (self.type == YAMLType.Object) {
            self.object_value.Insert(key, value);
            return True;
        }
        return False;
    }
    
    fn ObjectGet(self: Self, key: String) -> Optional(YAMLNode) {
        if (self.type == YAMLType.Object) {
            return self.object_value.Get(key);
        }
        return Optional(YAMLNode).None();
    }
    
    fn ObjectHas(self: Self, key: String) -> Bool {
        if (self.type == YAMLType.Object) {
            return self.object_value.Contains(key);
        }
        return False;
    }
}

// YAML Parser
class YAMLParser {
    var lines: Array(String);
    var current_line: u64;
    var current_column: u64;
    var indent_stack: Array(i32);
    var anchors: HashMap(String, YAMLNode);
    var in_flow_context: Bool;
    
    fn Create(yaml_text: String) -> Self {
        var lines: Array(String) = yaml_text.Split("\n");
        return {
            .lines = lines,
            .current_line = 0,
            .current_column = 0,
            .indent_stack = Array(i32)(),
            .anchors = HashMap(String, YAMLNode).Create(),
            .in_flow_context = False
        };
    }
    
    fn Parse(self: Self) -> Result(YAMLNode, String) {
        if (self.lines.Size() == 0) {
            return Result(YAMLNode, String).Ok(YAMLNode.CreateNull());
        }
        
        // Skip document markers and directives
        self.SkipDocumentStart();
        
        if (self.current_line >= self.lines.Size()) {
            return Result(YAMLNode, String).Ok(YAMLNode.CreateNull());
        }
        
        return self.ParseValue(0);
    }
    
    fn ParseValue(self: Self, base_indent: i32) -> Result(YAMLNode, String) {
        self.SkipEmptyLines();
        
        if (self.current_line >= self.lines.Size()) {
            return Result(YAMLNode, String).Ok(YAMLNode.CreateNull());
        }
        
        var line: String = self.lines[self.current_line];
        var trimmed: String = line.TrimLeft();
        
        if (trimmed.IsEmpty()) {
            return Result(YAMLNode, String).Ok(YAMLNode.CreateNull());
        }
        
        // Check for special markers
        if (trimmed.StartsWith("---") or trimmed.StartsWith("...")) {
            self.current_line += 1;
            return self.ParseValue(base_indent);
        }
        
        // Check for comments
        if (trimmed.StartsWith("#")) {
            self.current_line += 1;
            return self.ParseValue(base_indent);
        }
        
        var indent: i32 = self.GetIndentLevel(line);
        
        // Flow sequences and mappings
        if (trimmed.StartsWith("[")) {
            return self.ParseFlowSequence();
        }
        
        if (trimmed.StartsWith("{")) {
            return self.ParseFlowMapping();
        }
        
        // Block sequences
        if (trimmed.StartsWith("- ")) {
            return self.ParseBlockSequence(indent);
        }
        
        // Check if this looks like a mapping
        var colon_pos: i32 = trimmed.IndexOf(":");
        if (colon_pos >= 0) {
            var after_colon: String = trimmed.Substring(colon_pos + 1).TrimLeft();
            if (after_colon.IsEmpty() or after_colon.StartsWith("#")) {
                return self.ParseBlockMapping(indent);
            } else {
                return self.ParseInlineMapping(trimmed);
            }
        }
        
        // Parse scalar value
        return self.ParseScalar(trimmed);
    }
    
    fn ParseBlockSequence(self: Self, indent: i32) -> Result(YAMLNode, String) {
        var result: YAMLNode = YAMLNode.CreateArray();
        
        while (self.current_line < self.lines.Size()) {
            var line: String = self.lines[self.current_line];
            var line_indent: i32 = self.GetIndentLevel(line);
            var trimmed: String = line.TrimLeft();
            
            if (trimmed.IsEmpty() or trimmed.StartsWith("#")) {
                self.current_line += 1;
                continue;
            }
            
            if (line_indent < indent) {
                break;
            }
            
            if (not trimmed.StartsWith("- ")) {
                break;
            }
            
            self.current_line += 1;
            var item_content: String = trimmed.Substring(2).TrimLeft();
            
            if (item_content.IsEmpty()) {
                var item_result: Result(YAMLNode, String) = self.ParseValue(indent + 2);
                if (item_result.IsError()) {
                    return item_result;
                }
                result.ArrayPush(item_result.Unwrap());
            } else {
                var item_result: Result(YAMLNode, String) = self.ParseScalar(item_content);
                if (item_result.IsError()) {
                    return item_result;
                }
                result.ArrayPush(item_result.Unwrap());
            }
        }
        
        return Result(YAMLNode, String).Ok(result);
    }
    
    fn ParseBlockMapping(self: Self, indent: i32) -> Result(YAMLNode, String) {
        var result: YAMLNode = YAMLNode.CreateObject();
        
        while (self.current_line < self.lines.Size()) {
            var line: String = self.lines[self.current_line];
            var line_indent: i32 = self.GetIndentLevel(line);
            var trimmed: String = line.TrimLeft();
            
            if (trimmed.IsEmpty() or trimmed.StartsWith("#")) {
                self.current_line += 1;
                continue;
            }
            
            if (line_indent < indent) {
                break;
            }
            
            var colon_pos: i32 = trimmed.IndexOf(":");
            if (colon_pos < 0) {
                break;
            }
            
            var key: String = trimmed.Substring(0, colon_pos).Trim();
            var value_part: String = trimmed.Substring(colon_pos + 1).TrimLeft();
            
            self.current_line += 1;
            
            var value: YAMLNode;
            if (value_part.IsEmpty() or value_part.StartsWith("#")) {
                var value_result: Result(YAMLNode, String) = self.ParseValue(indent + 2);
                if (value_result.IsError()) {
                    return value_result;
                }
                value = value_result.Unwrap();
            } else {
                var value_result: Result(YAMLNode, String) = self.ParseScalar(value_part);
                if (value_result.IsError()) {
                    return value_result;
                }
                value = value_result.Unwrap();
            }
            
            result.ObjectSet(key, value);
        }
        
        return Result(YAMLNode, String).Ok(result);
    }
    
    fn ParseInlineMapping(self: Self, line: String) -> Result(YAMLNode, String) {
        var result: YAMLNode = YAMLNode.CreateObject();
        var colon_pos: i32 = line.IndexOf(":");
        
        var key: String = line.Substring(0, colon_pos).Trim();
        var value_part: String = line.Substring(colon_pos + 1).Trim();
        
        var value_result: Result(YAMLNode, String) = self.ParseScalar(value_part);
        if (value_result.IsError()) {
            return value_result;
        }
        
        result.ObjectSet(key, value_result.Unwrap());
        self.current_line += 1;
        
        return Result(YAMLNode, String).Ok(result);
    }
    
    fn ParseFlowSequence(self: Self) -> Result(YAMLNode, String) {
        var result: YAMLNode = YAMLNode.CreateArray();
        var line: String = self.lines[self.current_line];
        var content: String = line.Substring(1, line.Length() - 1).Trim(); // Remove [ ]
        
        if (content.IsEmpty()) {
            self.current_line += 1;
            return Result(YAMLNode, String).Ok(result);
        }
        
        var items: Array(String) = self.SplitFlowItems(content);
        for (item: String in items) {
            var item_result: Result(YAMLNode, String) = self.ParseScalar(item.Trim());
            if (item_result.IsError()) {
                return item_result;
            }
            result.ArrayPush(item_result.Unwrap());
        }
        
        self.current_line += 1;
        return Result(YAMLNode, String).Ok(result);
    }
    
    fn ParseFlowMapping(self: Self) -> Result(YAMLNode, String) {
        var result: YAMLNode = YAMLNode.CreateObject();
        var line: String = self.lines[self.current_line];
        var content: String = line.Substring(1, line.Length() - 1).Trim(); // Remove { }
        
        if (content.IsEmpty()) {
            self.current_line += 1;
            return Result(YAMLNode, String).Ok(result);
        }
        
        var pairs: Array(String) = self.SplitFlowItems(content);
        for (pair: String in pairs) {
            var colon_pos: i32 = pair.IndexOf(":");
            if (colon_pos >= 0) {
                var key: String = pair.Substring(0, colon_pos).Trim();
                var value_part: String = pair.Substring(colon_pos + 1).Trim();
                
                var value_result: Result(YAMLNode, String) = self.ParseScalar(value_part);
                if (value_result.IsError()) {
                    return value_result;
                }
                
                result.ObjectSet(key, value_result.Unwrap());
            }
        }
        
        self.current_line += 1;
        return Result(YAMLNode, String).Ok(result);
    }
    
    fn ParseScalar(self: Self, value: String) -> Result(YAMLNode, String) {
        var trimmed: String = value.Trim();
        
        if (trimmed.IsEmpty() or trimmed == "null" or trimmed == "~") {
            return Result(YAMLNode, String).Ok(YAMLNode.CreateNull());
        }
        
        // Boolean values
        if (trimmed == "true" or trimmed == "True" or trimmed == "TRUE" or trimmed == "yes" or trimmed == "Yes" or trimmed == "YES" or trimmed == "on" or trimmed == "On" or trimmed == "ON") {
            return Result(YAMLNode, String).Ok(YAMLNode.CreateBool(True));
        }
        
        if (trimmed == "false" or trimmed == "False" or trimmed == "FALSE" or trimmed == "no" or trimmed == "No" or trimmed == "NO" or trimmed == "off" or trimmed == "Off" or trimmed == "OFF") {
            return Result(YAMLNode, String).Ok(YAMLNode.CreateBool(False));
        }
        
        // Numeric values with 64-bit support
        if (self.IsInteger(trimmed)) {
            var int_result: Result(i64, String) = TryStringToInt64(trimmed);
            if (int_result.IsOk()) {
                return Result(YAMLNode, String).Ok(YAMLNode.CreateInt(int_result.Value()));
            }
        }
        
        if (self.IsFloat(trimmed)) {
            var float_result: Result(f64, String) = TryStringToFloat64(trimmed);
            if (float_result.IsOk()) {
                return Result(YAMLNode, String).Ok(YAMLNode.CreateFloat(float_result.Value()));
            }
        }
        
        // Special float values
        if (trimmed == ".inf" or trimmed == ".Inf" or trimmed == ".INF" or trimmed == "+.inf" or trimmed == "+.Inf" or trimmed == "+.INF") {
            return Result(YAMLNode, String).Ok(YAMLNode.CreateFloat(1.0 / 0.0)); // Positive infinity
        }
        
        if (trimmed == "-.inf" or trimmed == "-.Inf" or trimmed == "-.INF") {
            return Result(YAMLNode, String).Ok(YAMLNode.CreateFloat(-1.0 / 0.0)); // Negative infinity
        }
        
        if (trimmed == ".nan" or trimmed == ".NaN" or trimmed == ".NAN") {
            return Result(YAMLNode, String).Ok(YAMLNode.CreateFloat(0.0 / 0.0)); // NaN
        }
        
        // String value (handle quotes)
        if ((trimmed.StartsWith("\"") and trimmed.EndsWith("\"")) or (trimmed.StartsWith("'") and trimmed.EndsWith("'"))) {
            var unquoted: String = trimmed.Substring(1, trimmed.Length() - 1);
            return Result(YAMLNode, String).Ok(YAMLNode.CreateString(self.UnescapeString(unquoted)));
        }
        
        return Result(YAMLNode, String).Ok(YAMLNode.CreateString(trimmed));
    }
    
    fn IsInteger(self: Self, value: String) -> Bool {
        if (value.IsEmpty()) { return False; }
        
        var start: u64 = 0;
        if (value[0] == '+' or value[0] == '-') {
            start = 1;
        }
        
        // Hexadecimal
        if (value.StartsWith("0x") or value.StartsWith("0X")) {
            for (i: u64 in Range(2, value.Length())) {
                var c: u8 = value[i];
                if (not ((c >= '0' and c <= '9') or (c >= 'a' and c <= 'f') or (c >= 'A' and c <= 'F'))) {
                    return False;
                }
            }
            return True;
        }
        
        // Octal
        if (value.StartsWith("0o") or value.StartsWith("0O")) {
            for (i: u64 in Range(2, value.Length())) {
                var c: u8 = value[i];
                if (not (c >= '0' and c <= '7')) {
                    return False;
                }
            }
            return True;
        }
        
        // Binary
        if (value.StartsWith("0b") or value.StartsWith("0B")) {
            for (i: u64 in Range(2, value.Length())) {
                var c: u8 = value[i];
                if (not (c == '0' or c == '1')) {
                    return False;
                }
            }
            return True;
        }
        
        // Decimal
        for (i: u64 in Range(start, value.Length())) {
            var c: u8 = value[i];
            if (not (c >= '0' and c <= '9')) {
                return False;
            }
        }
        
        return True;
    }
    
    fn IsFloat(self: Self, value: String) -> Bool {
        if (value.IsEmpty()) { return False; }
        
        var has_dot: Bool = False;
        var has_exp: Bool = False;
        var start: u64 = 0;
        
        if (value[0] == '+' or value[0] == '-') {
            start = 1;
        }
        
        for (i: u64 in Range(start, value.Length())) {
            var c: u8 = value[i];
            
            if (c == '.') {
                if (has_dot or has_exp) { return False; }
                has_dot = True;
            } else if (c == 'e' or c == 'E') {
                if (has_exp) { return False; }
                has_exp = True;
                if (i + 1 < value.Length() and (value[i + 1] == '+' or value[i + 1] == '-')) {
                    i += 1;
                }
            } else if (not (c >= '0' and c <= '9')) {
                return False;
            }
        }
        
        return has_dot or has_exp;
    }
    

    
    fn UnescapeString(self: Self, value: String) -> String {
        var result: String = "";
        var i: u64 = 0;
        
        while (i < value.Length()) {
            if (value[i] == '\\' and i + 1 < value.Length()) {
                var next: u8 = value[i + 1];
                if (next == 'n') {
                    result += "\n";
                } else if (next == 't') {
                    result += "\t";
                } else if (next == 'r') {
                    result += "\r";
                } else if (next == '\\') {
                    result += "\\";
                } else if (next == '"') {
                    result += "\"";
                } else if (next == '\'') {
                    result += "'";
                } else {
                    result += String.FromChar(next);
                }
                i += 2;
            } else {
                result += String.FromChar(value[i]);
                i += 1;
            }
        }
        
        return result;
    }
    
    fn SplitFlowItems(self: Self, content: String) -> Array(String) {
        var items: Array(String) = Array(String)();
        var current: String = "";
        var in_quotes: Bool = False;
        var quote_char: u8 = 0;
        var brace_level: i32 = 0;
        var bracket_level: i32 = 0;
        
        for (i: u64 in Range(0, content.Length())) {
            var c: u8 = content[i];
            
            if (not in_quotes) {
                if (c == '"' or c == '\'') {
                    in_quotes = True;
                    quote_char = c;
                    current += String.FromChar(c);
                } else if (c == '{') {
                    brace_level += 1;
                    current += String.FromChar(c);
                } else if (c == '}') {
                    brace_level -= 1;
                    current += String.FromChar(c);
                } else if (c == '[') {
                    bracket_level += 1;
                    current += String.FromChar(c);
                } else if (c == ']') {
                    bracket_level -= 1;
                    current += String.FromChar(c);
                } else if (c == ',' and brace_level == 0 and bracket_level == 0) {
                    items.Push(current);
                    current = "";
                } else {
                    current += String.FromChar(c);
                }
            } else {
                current += String.FromChar(c);
                if (c == quote_char) {
                    in_quotes = False;
                }
            }
        }
        
        if (not current.IsEmpty()) {
            items.Push(current);
        }
        
        return items;
    }
    
    fn GetIndentLevel(self: Self, line: String) -> i32 {
        var indent: i32 = 0;
        for (c: u8 in line) {
            if (c == ' ') {
                indent += 1;
            } else if (c == '\t') {
                indent += 8; // Tab = 8 spaces
            } else {
                break;
            }
        }
        return indent;
    }
    
    fn SkipEmptyLines(self: Self) {
        while (self.current_line < self.lines.Size()) {
            var line: String = self.lines[self.current_line].Trim();
            if (line.IsEmpty() or line.StartsWith("#")) {
                self.current_line += 1;
            } else {
                break;
            }
        }
    }
    
    fn SkipDocumentStart(self: Self) {
        while (self.current_line < self.lines.Size()) {
            var line: String = self.lines[self.current_line].Trim();
            if (line.StartsWith("---") or line.StartsWith("%") or line.IsEmpty() or line.StartsWith("#")) {
                self.current_line += 1;
            } else {
                break;
            }
        }
    }
}

// YAML Serializer
class YAMLSerializer {
    var indent_size: i32;
    var current_indent: i32;
    
    fn Create(indent_size: i32) -> Self {
        return {
            .indent_size = indent_size,
            .current_indent = 0
        };
    }
    
    fn Serialize(self: Self, node: YAMLNode) -> String {
        return self.SerializeNode(node, False);
    }
    
    fn SerializeNode(self: Self, node: YAMLNode, inline: Bool) -> String {
        match (node.type) {
            case YAMLType.Null => {
                return "null";
            }
            case YAMLType.Boolean => {
                return if (node.bool_value) "true" else "false";
            }
            case YAMLType.Integer => {
                return String.FromInt64(node.int_value);
            }
            case YAMLType.Float => {
                return String.FromFloat64(node.float_value);
            }
            case YAMLType.String => {
                return self.SerializeString(node.string_value);
            }
            case YAMLType.Array => {
                return self.SerializeArray(node, inline);
            }
            case YAMLType.Object => {
                return self.SerializeObject(node, inline);
            }
        }
        return "";
    }
    
    fn SerializeString(self: Self, value: String) -> String {
        if (self.NeedsQuoting(value)) {
            return "\"" + self.EscapeString(value) + "\"";
        }
        return value;
    }
    
    fn SerializeArray(self: Self, node: YAMLNode, inline: Bool) -> String {
        if (node.array_value.Size() == 0) {
            return "[]";
        }
        
        if (inline) {
            var result: String = "[";
            for (i: u64 in Range(0, node.array_value.Size())) {
                if (i > 0) { result += ", "; }
                var item: Optional(YAMLNode) = node.array_value.Get(i);
                if (item.IsSome()) {
                    result += self.SerializeNode(item.Unwrap(), True);
                }
            }
            result += "]";
            return result;
        }
        
        var result: String = "";
        for (i: u64 in Range(0, node.array_value.Size())) {
            result += self.GetIndent() + "- ";
            var item: Optional(YAMLNode) = node.array_value.Get(i);
            if (item.IsSome()) {
                var item_node: YAMLNode = item.Unwrap();
                if (item_node.type == YAMLType.Array or item_node.type == YAMLType.Object) {
                    result += "\n";
                    self.current_indent += self.indent_size;
                    result += self.SerializeNode(item_node, False);
                    self.current_indent -= self.indent_size;
                } else {
                    result += self.SerializeNode(item_node, True);
                }
            }
            result += "\n";
        }
        
        return result;
    }
    
    fn SerializeObject(self: Self, node: YAMLNode, inline: Bool) -> String {
        if (node.object_value.Size() == 0) {
            return "{}";
        }
        
        if (inline) {
            var result: String = "{";
            var first: Bool = True;
            var iter: HashMapIterator(String, YAMLNode) = node.object_value.GetIterator();
            while (iter.HasNext()) {
                var pair: KeyValuePair(String, YAMLNode) = iter.Next();
                if (not first) { result += ", "; }
                result += self.SerializeString(pair.key) + ": " + self.SerializeNode(pair.value, True);
                first = False;
            }
            result += "}";
            return result;
        }
        
        var result: String = "";
        var iter: HashMapIterator(String, YAMLNode) = node.object_value.GetIterator();
        while (iter.HasNext()) {
            var pair: KeyValuePair(String, YAMLNode) = iter.Next();
            result += self.GetIndent() + self.SerializeString(pair.key) + ": ";
            
            if (pair.value.type == YAMLType.Array or pair.value.type == YAMLType.Object) {
                result += "\n";
                self.current_indent += self.indent_size;
                result += self.SerializeNode(pair.value, False);
                self.current_indent -= self.indent_size;
            } else {
                result += self.SerializeNode(pair.value, True);
            }
            result += "\n";
        }
        
        return result;
    }
    
    fn NeedsQuoting(self: Self, value: String) -> Bool {
        if (value.IsEmpty()) { return True; }
        
        // Check for special YAML values
        if (value == "true" or value == "false" or value == "null" or value == "~") {
            return True;
        }
        
        // Check for numeric values
        var parser: YAMLParser = YAMLParser.Create("");
        if (parser.IsInteger(value) or parser.IsFloat(value)) {
            return True;
        }
        
        // Check for special characters
        for (c: u8 in value) {
            if (c == ':' or c == '[' or c == ']' or c == '{' or c == '}' or c == ',' or c == '#' or c == '&' or c == '*' or c == '!' or c == '|' or c == '>' or c == '\'' or c == '"' or c == '%' or c == '@' or c == '`') {
                return True;
            }
        }
        
        return False;
    }
    
    fn EscapeString(self: Self, value: String) -> String {
        var result: String = "";
        for (c: u8 in value) {
            if (c == '\n') {
                result += "\\n";
            } else if (c == '\t') {
                result += "\\t";
            } else if (c == '\r') {
                result += "\\r";
            } else if (c == '\\') {
                result += "\\\\";
            } else if (c == '"') {
                result += "\\\"";
            } else {
                result += String.FromChar(c);
            }
        }
        return result;
    }
    
    fn GetIndent(self: Self) -> String {
        var result: String = "";
        for (i: i32 in Range(0, self.current_indent)) {
            result += " ";
        }
        return result;
    }
}

// Utility functions
fn ParseYAML(yaml_text: String) -> Result(YAMLNode, String) {
    var parser: YAMLParser = YAMLParser.Create(yaml_text);
    return parser.Parse();
}

fn SerializeYAML(node: YAMLNode) -> String {
    var serializer: YAMLSerializer = YAMLSerializer.Create(2);
    return serializer.Serialize(node);
} + 1).TrimLeft();
            if (after_colon.IsEmpty() or after_colon.StartsWith("#")) {
                // This is a mapping key with value on next line or no value
                return self.ParseBlockMapping(indent);
            } else {
                // This is a mapping key with inline value
                return self.ParseBlockMapping(indent);
            }
        }
        
        // Scalar value
        return self.ParseScalar();
    }
    
    fn ParseBlockSequence(self: Self, base_indent: i32) -> Result(YAMLNode, String) {
        var sequence: YAMLNode = YAMLNode.CreateArray();
        sequence.line_number = self.current_line as i32;
        
        while (self.current_line < self.lines.Size()) {
            var line: String = self.lines[self.current_line];
            var trimmed: String = line.TrimLeft();
            var indent: i32 = self.GetIndentLevel(line);
            
            if (trimmed.IsEmpty() or trimmed.StartsWith("#")) {
                self.current_line += 1;
                continue;
            }
            
            if (indent < base_indent) {
                break;
            }
            
            if (not trimmed.StartsWith("- ")) {
                break;
            }
            
            // Parse sequence item
            var item_content: String = trimmed.Substring(2).TrimLeft();
            
            if (item_content.IsEmpty()) {
                // Item on next line
                self.current_line += 1;
                var item_result: Result(YAMLNode, String) = self.ParseValue(indent + 2);
                if (not item_result.IsOk()) {
                    return item_result;
                }
                sequence.ArrayPush(item_result.Value());
            } else {
                // Inline item
                var saved_line: u64 = self.current_line;
                var temp_lines: Array(String) = Array(String)();
                temp_lines.Push(item_content);
                
                var temp_parser: YAMLParser = YAMLParser.Create(item_content);
                var item_result: Result(YAMLNode, String) = temp_parser.Parse();
                
                self.current_line = saved_line + 1;
                
                if (not item_result.IsOk()) {
                    return item_result;
                }
                sequence.ArrayPush(item_result.Value());
            }
        }
        
        return Result(YAMLNode, String).Ok(sequence);
    }
    
    fn ParseBlockMapping(self: Self, base_indent: i32) -> Result(YAMLNode, String) {
        var mapping: YAMLNode = YAMLNode.CreateObject();
        mapping.line_number = self.current_line as i32;
        
        while (self.current_line < self.lines.Size()) {
            var line: String = self.lines[self.current_line];
            var trimmed: String = line.TrimLeft();
            var indent: i32 = self.GetIndentLevel(line);
            
            if (trimmed.IsEmpty() or trimmed.StartsWith("#")) {
                self.current_line += 1;
                continue;
            }
            
            if (indent < base_indent) {
                break;
            }
            
            var colon_pos: i32 = trimmed.IndexOf(":");
            if (colon_pos < 0) {
                break;
            }
            
            var key: String = trimmed.Substring(0, colon_pos).Trim();
            var value_part: String = trimmed.Substring(colon_pos + 1).TrimLeft();
            
            // Remove quotes from key if present
            key = self.UnquoteString(key);
            
            var value: YAMLNode;
            
            if (value_part.IsEmpty() or value_part.StartsWith("#")) {
                // Value on next line
                self.current_line += 1;
                var value_result: Result(YAMLNode, String) = self.ParseValue(indent + 2);
                if (not value_result.IsOk()) {
                    return value_result;
                }
                value = value_result.Value();
            } else {
                // Inline value
                var temp_parser: YAMLParser = YAMLParser.Create(value_part);
                var value_result: Result(YAMLNode, String) = temp_parser.Parse();
                if (not value_result.IsOk()) {
                    return value_result;
                }
                value = value_result.Value();
                self.current_line += 1;
            }
            
            mapping.ObjectSet(key, value);
        }
        
        return Result(YAMLNode, String).Ok(mapping);
    }
    
    fn ParseFlowSequence(self: Self) -> Result(YAMLNode, String) {
        var sequence: YAMLNode = YAMLNode.CreateArray();
        var line: String = self.lines[self.current_line];
        var pos: u64 = line.IndexOf("[") + 1;
        
        self.in_flow_context = True;
        
        while (pos < line.Length()) {
            // Skip whitespace
            while (pos < line.Length() and (line[pos] == ' ' or line[pos] == '\t')) {
                pos += 1;
            }
            
            if (pos >= line.Length()) {
                break;
            }
            
            if (line[pos] == ']') {
                break;
            }
            
            // Parse item
            var item_start: u64 = pos;
            var item_end: u64 = self.FindFlowItemEnd(line, pos, ',', ']');
            
            if (item_end > item_start) {
                var item_text: String = line.Substring(item_start, item_end - item_start).Trim();
                var temp_parser: YAMLParser = YAMLParser.Create(item_text);
                var item_result: Result(YAMLNode, String) = temp_parser.Parse();
                
                if (item_result.IsOk()) {
                    sequence.ArrayPush(item_result.Value());
                }
            }
            
            pos = item_end + 1;
        }
        
        self.in_flow_context = False;
        self.current_line += 1;
        
        return Result(YAMLNode, String).Ok(sequence);
    }
    
    fn ParseFlowMapping(self: Self) -> Result(YAMLNode, String) {
        var mapping: YAMLNode = YAMLNode.CreateObject();
        var line: String = self.lines[self.current_line];
        var pos: u64 = line.IndexOf("{") + 1;
        
        self.in_flow_context = True;
        
        while (pos < line.Length()) {
            // Skip whitespace
            while (pos < line.Length() and (line[pos] == ' ' or line[pos] == '\t')) {
                pos += 1;
            }
            
            if (pos >= line.Length()) {
                break;
            }
            
            if (line[pos] == '}') {
                break;
            }
            
            // Parse key-value pair
            var pair_end: u64 = self.FindFlowItemEnd(line, pos, ',', '}');
            var pair_text: String = line.Substring(pos, pair_end - pos).Trim();
            
            var colon_pos: i32 = pair_text.IndexOf(":");
            if (colon_pos >= 0) {
                var key: String = pair_text.Substring(0, colon_pos).Trim();
                var value_text: String = pair_text.Substring(colon_pos + 1).Trim();
                
                key = self.UnquoteString(key);
                
                var temp_parser: YAMLParser = YAMLParser.Create(value_text);
                var value_result: Result(YAMLNode, String) = temp_parser.Parse();
                
                if (value_result.IsOk()) {
                    mapping.ObjectSet(key, value_result.Value());
                }
            }
            
            pos = pair_end + 1;
        }
        
        self.in_flow_context = False;
        self.current_line += 1;
        
        return Result(YAMLNode, String).Ok(mapping);
    }
    
    fn ParseScalar(self: Self) -> Result(YAMLNode, String) {
        var line: String = self.lines[self.current_line];
        var trimmed: String = line.TrimLeft();
        
        // Handle multiline strings
        if (trimmed.EndsWith("|") or trimmed.EndsWith(">")) {
            return self.ParseMultilineString();
        }
        
        // Remove inline comments
        var comment_pos: i32 = trimmed.IndexOf(" #");
        if (comment_pos >= 0) {
            trimmed = trimmed.Substring(0, comment_pos).Trim();
        }
        
        self.current_line += 1;
        
        // Parse the scalar value
        return Result(YAMLNode, String).Ok(self.ParseScalarValue(trimmed));
    }
    
    fn ParseScalarValue(self: Self, value: String) -> YAMLNode {
        var trimmed: String = value.Trim();
        
        // Null values
        if (trimmed.IsEmpty() or trimmed == "null" or trimmed == "~") {
            return YAMLNode.CreateNull();
        }
        
        // Boolean values
        if (trimmed == "true" or trimmed == "True" or trimmed == "TRUE" or trimmed == "yes" or trimmed == "Yes" or trimmed == "YES") {
            return YAMLNode.CreateBool(True);
        }
        
        if (trimmed == "false" or trimmed == "False" or trimmed == "FALSE" or trimmed == "no" or trimmed == "No" or trimmed == "NO") {
            return YAMLNode.CreateBool(False);
        }
        
        // Quoted strings
        if ((trimmed.StartsWith("\"") and trimmed.EndsWith("\"")) or
            (trimmed.StartsWith("'") and trimmed.EndsWith("'"))) {
            return YAMLNode.CreateString(self.UnquoteString(trimmed));
        }
        
        // Numbers with enhanced 64-bit support
        if (self.IsInteger(trimmed)) {
            var int_result: Result(i64, String) = TryStringToInt64(trimmed);
            if (int_result.IsOk()) {
                return YAMLNode.CreateInt(int_result.Value());
            }
        }
        
        if (self.IsFloat(trimmed)) {
            var float_result: Result(f64, String) = TryStringToFloat64(trimmed);
            if (float_result.IsOk()) {
                return YAMLNode.CreateFloat(float_result.Value());
            }
        }
        
        // Default to string
        return YAMLNode.CreateString(trimmed);
    }
    
    fn ParseMultilineString(self: Self) -> Result(YAMLNode, String) {
        var line: String = self.lines[self.current_line];
        var trimmed: String = line.TrimLeft();
        var is_literal: Bool = trimmed.EndsWith("|");
        var base_indent: i32 = self.GetIndentLevel(line);
        
        self.current_line += 1;
        
        var content: String = "";
        var first_content_line: Bool = True;
        var content_indent: i32 = 0;
        
        while (self.current_line < self.lines.Size()) {
            var content_line: String = self.lines[self.current_line];
            
            if (content_line.TrimLeft().IsEmpty()) {
                if (not first_content_line) {
                    content += "\n";
                }
                self.current_line += 1;
                continue;
            }
            
            var line_indent: i32 = self.GetIndentLevel(content_line);
            
            if (line_indent <= base_indent) {
                break;
            }
            
            if (first_content_line) {
                content_indent = line_indent;
                first_content_line = False;
            }
            
            var line_content: String = content_line.Substring(content_indent);
            
            if (is_literal) {
                content += line_content + "\n";
            } else {
                if (not content.IsEmpty() and not content.EndsWith(" ")) {
                    content += " ";
                }
                content += line_content.Trim();
            }
            
            self.current_line += 1;
        }
        
        return Result(YAMLNode, String).Ok(YAMLNode.CreateString(content));
    }
    
    fn UnquoteString(self: Self, str: String) -> String {
        var trimmed: String = str.Trim();
        
        if (trimmed.Length() >= 2) {
            if ((trimmed.StartsWith("\"") and trimmed.EndsWith("\"")) or
                (trimmed.StartsWith("'") and trimmed.EndsWith("'"))) {
                var unquoted: String = trimmed.Substring(1, trimmed.Length() - 2);
                return self.UnescapeString(unquoted);
            }
        }
        
        return trimmed;
    }
    
    fn UnescapeString(self: Self, str: String) -> String {
        var result: String = "";
        var i: u64 = 0;
        
        while (i < str.Length()) {
            if (str[i] == '\\' and i + 1 < str.Length()) {
                var next: i32 = str[i + 1];
                match (next) {
                    case ('n') { result += "\n"; }
                    case ('t') { result += "\t"; }
                    case ('r') { result += "\r"; }
                    case ('\\') { result += "\\"; }
                    case ('"') { result += "\""; }
                    case ('\'') { result += "'"; }
                    default { result += CharToString(next); }
                }
                i += 2;
            } else {
                result += CharToString(str[i]);
                i += 1;
            }
        }
        
        return result;
    }
    
    fn GetIndentLevel(self: Self, line: String) -> i32 {
        var indent: i32 = 0;
        var i: u64 = 0;
        
        while (i < line.Length()) {
            if (line[i] == ' ') {
                indent += 1;
            } else if (line[i] == '\t') {
                indent += 8; // Tab = 8 spaces
            } else {
                break;
            }
            i += 1;
        }
        
        return indent;
    }
    
    fn SkipEmptyLines(self: Self) {
        while (self.current_line < self.lines.Size()) {
            var line: String = self.lines[self.current_line];
            var trimmed: String = line.Trim();
            
            if (trimmed.IsEmpty() or trimmed.StartsWith("#")) {
                self.current_line += 1;
            } else {
                break;
            }
        }
    }
    
    fn SkipDocumentStart(self: Self) {
        while (self.current_line < self.lines.Size()) {
            var line: String = self.lines[self.current_line];
            var trimmed: String = line.Trim();
            
            if (trimmed.StartsWith("%") or trimmed.StartsWith("---")) {
                self.current_line += 1;
            } else {
                break;
            }
        }
    }
    
    fn FindFlowItemEnd(self: Self, line: String, start: u64, separator: i32, terminator: i32) -> u64 {
        var pos: u64 = start;
        var depth: i32 = 0;
        var in_quotes: Bool = False;
        var quote_char: i32 = 0;
        
        while (pos < line.Length()) {
            var ch: i32 = line[pos];
            
            if (in_quotes) {
                if (ch == quote_char and (pos == 0 or line[pos - 1] != '\\')) {
                    in_quotes = False;
                }
            } else {
                if (ch == '"' or ch == '\'') {
                    in_quotes = True;
                    quote_char = ch;
                } else if (ch == '[' or ch == '{') {
                    depth += 1;
                } else if (ch == ']' or ch == '}') {
                    depth -= 1;
                } else if (depth == 0 and (ch == separator or ch == terminator)) {
                    return pos;
                }
            }
            
            pos += 1;
        }
        
        return pos;
    }
    
    fn IsInteger(self: Self, str: String) -> Bool {
        if (str.IsEmpty()) {
            return False;
        }
        
        var start: u64 = 0;
        if (str[0] == '-' or str[0] == '+') {
            start = 1;
        }
        
        if (start >= str.Length()) {
            return False;
        }
        
        var i: u64 = start;
        while (i < str.Length()) {
            if (str[i] < '0' or str[i] > '9') {
                return False;
            }
            i += 1;
        }
        
        return True;
    }
    
    fn IsFloat(self: Self, str: String) -> Bool {
        if (str.IsEmpty()) {
            return False;
        }
        
        var has_dot: Bool = False;
        var has_e: Bool = False;
        var start: u64 = 0;
        
        if (str[0] == '-' or str[0] == '+') {
            start = 1;
        }
        
        if (start >= str.Length()) {
            return False;
        }
        
        var i: u64 = start;
        while (i < str.Length()) {
            var ch: i32 = str[i];
            
            if (ch >= '0' and ch <= '9') {
                // Valid digit
            } else if (ch == '.' and not has_dot and not has_e) {
                has_dot = True;
            } else if ((ch == 'e' or ch == 'E') and not has_e) {
                has_e = True;
                if (i + 1 < str.Length() and (str[i + 1] == '+' or str[i + 1] == '-')) {
                    i += 1; // Skip sign after e
                }
            } else {
                return False;
            }
            
            i += 1;
        }
        
        return has_dot or has_e;
    }
}

// YAML Serializer
class YAMLSerializer {
    var indent_level: i32;
    var indent_size: i32;
    
    fn Create() -> Self {
        return {
            .indent_level = 0,
            .indent_size = 2
        };
    }
    
    fn Serialize(self: Self, node: YAMLNode) -> String {
        return self.SerializeNode(node, False);
    }
    
    fn SerializeNode(self: Self, node: YAMLNode, inline: Bool) -> String {
        match (node.type) {
            case (YAMLType.Null) {
                return "null";
            }
            case (YAMLType.Boolean) {
                return node.bool_value ? "true" : "false";
            }
            case (YAMLType.Integer) {
                return Int64ToString(node.int_value);
            }
            case (YAMLType.Float) {
                return Float64ToString(node.float_value);
            }
            case (YAMLType.String) {
                return self.SerializeString(node.string_value);
            }
            case (YAMLType.Array) {
                return self.SerializeArray(node.array_value, inline);
            }
            case (YAMLType.Object) {
                return self.SerializeObject(node.object_value, inline);
            }
        }
        
        return "";
    }
    
    fn SerializeString(self: Self, str: String) -> String {
        // Check if string needs quoting
        if (self.NeedsQuoting(str)) {
            return "\"" + self.EscapeString(str) + "\"";
        }
        
        return str;
    }
    
    fn SerializeArray(self: Self, arr: Array(YAMLNode), inline: Bool) -> String {
        if (arr.Size() == 0) {
            return "[]";
        }
        
        if (inline) {
            var result: String = "[";
            var i: u64 = 0;
            while (i < arr.Size()) {
                if (i > 0) {
                    result += ", ";
                }
                var item_opt: Optional(YAMLNode) = arr.Get(i);
                if (item_opt.HasValue()) {
                    result += self.SerializeNode(item_opt.Value(), True);
                }
                i += 1;
            }
            result += "]";
            return result;
        } else {
            var result: String = "";
            var i: u64 = 0;
            while (i < arr.Size()) {
                result += self.GetIndent() + "- ";
                var item_opt: Optional(YAMLNode) = arr.Get(i);
                if (item_opt.HasValue()) {
                    var item: YAMLNode = item_opt.Value();
                    if (item.type == YAMLType.Array or item.type == YAMLType.Object) {
                        result += "\n";
                        self.indent_level += 1;
                        result += self.SerializeNode(item, False);
                        self.indent_level -= 1;
                    } else {
                        result += self.SerializeNode(item, True);
                    }
                }
                if (i < arr.Size() - 1) {
                    result += "\n";
                }
                i += 1;
            }
            return result;
        }
    }
    
    fn SerializeObject(self: Self, obj: HashMap(String, YAMLNode), inline: Bool) -> String {
        if (obj.Size() == 0) {
            return "{}";
        }
        
        var keys: Array(String) = obj.GetKeys();
        keys.Sort();
        
        if (inline) {
            var result: String = "{";
            var i: u64 = 0;
            while (i < keys.Size()) {
                if (i > 0) {
                    result += ", ";
                }
                var key_opt: Optional(String) = keys.Get(i);
                if (key_opt.HasValue()) {
                    var key: String = key_opt.Value();
                    var value_opt: Optional(YAMLNode) = obj.Get(key);
                    if (value_opt.HasValue()) {
                        result += self.SerializeString(key) + ": " + self.SerializeNode(value_opt.Value(), True);
                    }
                }
                i += 1;
            }
            result += "}";
            return result;
        } else {
            var result: String = "";
            var i: u64 = 0;
            while (i < keys.Size()) {
                var key_opt: Optional(String) = keys.Get(i);
                if (key_opt.HasValue()) {
                    var key: String = key_opt.Value();
                    var value_opt: Optional(YAMLNode) = obj.Get(key);
                    if (value_opt.HasValue()) {
                        var value: YAMLNode = value_opt.Value();
                        result += self.GetIndent() + self.SerializeString(key) + ":";
                        
                        if (value.type == YAMLType.Array or value.type == YAMLType.Object) {
                            result += "\n";
                            self.indent_level += 1;
                            result += self.SerializeNode(value, False);
                            self.indent_level -= 1;
                        } else {
                            result += " " + self.SerializeNode(value, True);
                        }
                    }
                }
                if (i < keys.Size() - 1) {
                    result += "\n";
                }
                i += 1;
            }
            return result;
        }
    }
    
    fn NeedsQuoting(self: Self, str: String) -> Bool {
        if (str.IsEmpty()) {
            return True;
        }
        
        // Check for YAML special values
        if (str == "true" or str == "false" or str == "null" or str == "~") {
            return True;
        }
        
        // Check for numbers
        var parser: YAMLParser = YAMLParser.Create("");
        if (parser.IsInteger(str) or parser.IsFloat(str)) {
            return True;
        }
        
        // Check for special characters
        var special_chars: String = "{}[],:>|*&!%#`@";
        var i: u64 = 0;
        while (i < str.Length()) {
            if (special_chars.IndexOf(CharToString(str[i])) >= 0) {
                return True;
            }
            i += 1;
        }
        
        return False;
    }
    
    fn EscapeString(self: Self, str: String) -> String {
        var result: String = "";
        var i: u64 = 0;
        
        while (i < str.Length()) {
            var ch: i32 = str[i];
            match (ch) {
                case ('"') { result += "\\\""; }
                case ('\\') { result += "\\\\"; }
                case ('\n') { result += "\\n"; }
                case ('\t') { result += "\\t"; }
                case ('\r') { result += "\\r"; }
                default { result += CharToString(ch); }
            }
            i += 1;
        }
        
        return result;
    }
    
    fn GetIndent(self: Self) -> String {
        var indent: String = "";
        var i: i32 = 0;
        while (i < self.indent_level * self.indent_size) {
            indent += " ";
            i += 1;
        }
        return indent;
    }
}

// Utility functions
fn ParseYAML(yaml_text: String) -> Result(YAMLNode, String) {
    var parser: YAMLParser = YAMLParser.Create(yaml_text);
    return parser.Parse();
}

fn SerializeYAML(node: YAMLNode) -> String {
    var serializer: YAMLSerializer = YAMLSerializer.Create();
    return serializer.Serialize(node);
}

// Enhanced 64-bit number conversion functions
class YAMLNumberConverter {
    // Convert string to 64-bit integer with full logic
    fn StringToInt64(str: String) -> Result(i64, String) {
        if (str.IsEmpty()) {
            return Result(i64, String).Error("Empty string");
        }
        
        var result: i64 = 0;
        var negative: Bool = False;
        var start: u64 = 0;
        var base: i64 = 10;
        
        // Handle sign
        if (str[0] == '-') {
            negative = True;
            start = 1;
        } else if (str[0] == '+') {
            start = 1;
        }
        
        if (start >= str.Length()) {
            return Result(i64, String).Error("Invalid number format");
        }
        
        // Detect base
        if (str.Length() > start + 1) {
            if (str[start] == '0') {
                if (str[start + 1] == 'x' or str[start + 1] == 'X') {
                    base = 16;
                    start += 2;
                } else if (str[start + 1] == 'o' or str[start + 1] == 'O') {
                    base = 8;
                    start += 2;
                } else if (str[start + 1] == 'b' or str[start + 1] == 'B') {
                    base = 2;
                    start += 2;
                }
            }
        }
        
        // Parse digits
        var i: u64 = start;
        while (i < str.Length()) {
            var ch: i32 = str[i];
            var digit: i64 = 0;
            
            if (ch >= '0' and ch <= '9') {
                digit = (ch - '0') as i64;
            } else if (base == 16 and ch >= 'a' and ch <= 'f') {
                digit = (ch - 'a' + 10) as i64;
            } else if (base == 16 and ch >= 'A' and ch <= 'F') {
                digit = (ch - 'A' + 10) as i64;
            } else {
                return Result(i64, String).Error("Invalid digit for base");
            }
            
            if (digit >= base) {
                return Result(i64, String).Error("Digit out of range for base");
            }
            
            // Check for overflow
            var max_val: i64 = 9223372036854775807; // i64 max
            if (result > (max_val - digit) / base) {
                return Result(i64, String).Error("Integer overflow");
            }
            
            result = result * base + digit;
            i += 1;
        }
        
        if (negative) {
            result = -result;
        }
        
        return Result(i64, String).Ok(result);
    }
    
    // Convert string to 64-bit float with full logic
    fn StringToFloat64(str: String) -> Result(f64, String) {
        if (str.IsEmpty()) {
            return Result(f64, String).Error("Empty string");
        }
        
        var result: f64 = 0.0;
        var negative: Bool = False;
        var start: u64 = 0;
        var decimal_part: f64 = 0.0;
        var decimal_places: i32 = 0;
        var in_decimal: Bool = False;
        var in_exponent: Bool = False;
        var exponent: i32 = 0;
        var exp_negative: Bool = False;
        
        // Handle sign
        if (str[0] == '-') {
            negative = True;
            start = 1;
        } else if (str[0] == '+') {
            start = 1;
        }
        
        if (start >= str.Length()) {
            return Result(f64, String).Error("Invalid number format");
        }
        
        // Special values
        var trimmed: String = str.Substring(start);
        if (trimmed == "inf" or trimmed == "Inf" or trimmed == "INF") {
            return Result(f64, String).Ok(negative ? -1.0/0.0 : 1.0/0.0);
        }
        if (trimmed == "nan" or trimmed == "NaN" or trimmed == "NAN") {
            return Result(f64, String).Ok(0.0/0.0);
        }
        
        var i: u64 = start;
        while (i < str.Length()) {
            var ch: i32 = str[i];
            
            if (ch >= '0' and ch <= '9') {
                var digit: f64 = (ch - '0') as f64;
                
                if (in_exponent) {
                    exponent = exponent * 10 + (digit as i32);
                } else if (in_decimal) {
                    decimal_places += 1;
                    decimal_part = decimal_part * 10.0 + digit;
                } else {
                    result = result * 10.0 + digit;
                }
            } else if (ch == '.' and not in_decimal and not in_exponent) {
                in_decimal = True;
            } else if ((ch == 'e' or ch == 'E') and not in_exponent) {
                in_exponent = True;
                if (i + 1 < str.Length()) {
                    if (str[i + 1] == '-') {
                        exp_negative = True;
                        i += 1;
                    } else if (str[i + 1] == '+') {
                        i += 1;
                    }
                }
            } else {
                return Result(f64, String).Error("Invalid character in number");
            }
            
            i += 1;
        }
        
        // Apply decimal part
        if (decimal_places > 0) {
            var divisor: f64 = 1.0;
            var j: i32 = 0;
            while (j < decimal_places) {
                divisor *= 10.0;
                j += 1;
            }
            result += decimal_part / divisor;
        }
        
        // Apply exponent
        if (in_exponent) {
            var exp_multiplier: f64 = 1.0;
            var k: i32 = 0;
            while (k < exponent) {
                exp_multiplier *= 10.0;
                k += 1;
            }
            
            if (exp_negative) {
                result /= exp_multiplier;
            } else {
                result *= exp_multiplier;
            }
        }
        
        if (negative) {
            result = -result;
        }
        
        return Result(f64, String).Ok(result);
    }
    
    // Convert 64-bit integer to string with full logic
    fn Int64ToString(value: i64) -> String {
        if (value == 0) {
            return "0";
        }
        
        var negative: Bool = value < 0;
        var abs_value: u64 = negative ? (-value) as u64 : value as u64;
        var result: String = "";
        
        while (abs_value > 0) {
            var digit: u64 = abs_value % 10;
            result = CharToString('0' + (digit as i32)) + result;
            abs_value = abs_value / 10;
        }
        
        return negative ? "-" + result : result;
    }
    
    // Convert 64-bit float to string with full logic
    fn Float64ToString(value: f64) -> String {
        // Handle special values
        if (value != value) { // NaN check
            return "nan";
        }
        if (value == 1.0/0.0) {
            return "inf";
        }
        if (value == -1.0/0.0) {
            return "-inf";
        }
        if (value == 0.0) {
            return "0.0";
        }
        
        var negative: Bool = value < 0.0;
        var abs_value: f64 = negative ? -value : value;
        
        // Handle very large or very small numbers with scientific notation
        if (abs_value >= 1e15 or (abs_value < 1e-4 and abs_value != 0.0)) {
            return self.ToScientificNotation(value);
        }
        
        var integer_part: i64 = abs_value as i64;
        var fractional_part: f64 = abs_value - (integer_part as f64);
        
        var result: String = negative ? "-" : "";
        result += self.Int64ToString(integer_part);
        
        if (fractional_part > 0.0) {
            result += ".";
            
            // Format fractional part with up to 15 significant digits
            var precision: i32 = 15;
            var trailing_zeros: i32 = 0;
            var i: i32 = 0;
            
            while (i < precision and fractional_part > 1e-15) {
                fractional_part *= 10.0;
                var digit: i32 = (fractional_part as i32) % 10;
                
                if (digit == 0) {
                    trailing_zeros += 1;
                } else {
                    // Add any accumulated trailing zeros
                    var j: i32 = 0;
                    while (j < trailing_zeros) {
                        result += "0";
                        j += 1;
                    }
                    trailing_zeros = 0;
                    result += CharToString('0' + digit);
                }
                
                fractional_part -= (digit as f64);
                i += 1;
            }
            
            // Remove trailing zeros if no significant digits follow
            if (trailing_zeros > 0 and result.EndsWith(".")) {
                result += "0";
            }
        } else {
            result += ".0";
        }
        
        return result;
    }
    
    fn ToScientificNotation(value: f64) -> String {
        var negative: Bool = value < 0.0;
        var abs_value: f64 = negative ? -value : value;
        
        var exponent: i32 = 0;
        
        if (abs_value >= 10.0) {
            while (abs_value >= 10.0) {
                abs_value /= 10.0;
                exponent += 1;
            }
        } else if (abs_value < 1.0 and abs_value != 0.0) {
            while (abs_value < 1.0) {
                abs_value *= 10.0;
                exponent -= 1;
            }
        }
        
        var mantissa: String = self.Float64ToString(abs_value);
        if (mantissa.EndsWith(".0")) {
            mantissa = mantissa.Substring(0, mantissa.Length() - 2);
        }
        
        var result: String = negative ? "-" : "";
        result += mantissa + "e";
        result += exponent >= 0 ? "+" : "";
        result += self.Int64ToString(exponent as i64);
        
        return result;
    }
}

// Global converter instance
var number_converter: YAMLNumberConverter = YAMLNumberConverter();

// Helper functions for number conversion
fn StringToInt64(str: String) -> i64 {
    var result: Result(i64, String) = number_converter.StringToInt64(str);
    return result.IsOk() ? result.Value() : 0;
}

fn StringToFloat64(str: String) -> f64 {
    var result: Result(f64, String) = number_converter.StringToFloat64(str);
    return result.IsOk() ? result.Value() : 0.0;
}

fn Int64ToString(value: i64) -> String {
    return number_converter.Int64ToString(value);
}

fn Float64ToString(value: f64) -> String {
    return number_converter.Float64ToString(value);
}

// Additional utility functions for safe conversion
fn TryStringToInt64(str: String) -> Result(i64, String) {
    return number_converter.StringToInt64(str);
}

fn TryStringToFloat64(str: String) -> Result(f64, String) {
    return number_converter.StringToFloat64(str);
}
