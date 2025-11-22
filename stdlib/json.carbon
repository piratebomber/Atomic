// Atomic Standard Library - JSON Parser
package Std.JSON api;

import Std.String;
import Std.Array;
import Std.Collections;
import Std.Memory;

// JSON value types
choice JSONType {
    Null,
    Boolean,
    Number,
    String,
    Array,
    Object
}

// JSON value structure
class JSONValue {
    var type: JSONType;
    var bool_value: Bool;
    var number_value: f64;
    var string_value: String;
    var array_value: Array(JSONValue);
    var object_value: HashMap(String, JSONValue);
    
    fn CreateNull() -> Self {
        return {
            .type = JSONType.Null,
            .bool_value = False,
            .number_value = 0.0,
            .string_value = "",
            .array_value = Array(JSONValue)(),
            .object_value = HashMap(String, JSONValue)()
        };
    }
    
    fn CreateBool(value: Bool) -> Self {
        return {
            .type = JSONType.Boolean,
            .bool_value = value,
            .number_value = 0.0,
            .string_value = "",
            .array_value = Array(JSONValue)(),
            .object_value = HashMap(String, JSONValue)()
        };
    }
    
    fn CreateNumber(value: f64) -> Self {
        return {
            .type = JSONType.Number,
            .bool_value = False,
            .number_value = value,
            .string_value = "",
            .array_value = Array(JSONValue)(),
            .object_value = HashMap(String, JSONValue)()
        };
    }
    
    fn CreateString(value: String) -> Self {
        return {
            .type = JSONType.String,
            .bool_value = False,
            .number_value = 0.0,
            .string_value = value,
            .array_value = Array(JSONValue)(),
            .object_value = HashMap(String, JSONValue)()
        };
    }
    
    fn CreateArray() -> Self {
        return {
            .type = JSONType.Array,
            .bool_value = False,
            .number_value = 0.0,
            .string_value = "",
            .array_value = Array(JSONValue)(),
            .object_value = HashMap(String, JSONValue)()
        };
    }
    
    fn CreateObject() -> Self {
        return {
            .type = JSONType.Object,
            .bool_value = False,
            .number_value = 0.0,
            .string_value = "",
            .array_value = Array(JSONValue)(),
            .object_value = HashMap(String, JSONValue).Create()
        };
    }
    
    // Type checking methods
    fn IsNull(self: Self) -> Bool {
        return self.type == JSONType.Null;
    }
    
    fn IsBool(self: Self) -> Bool {
        return self.type == JSONType.Boolean;
    }
    
    fn IsNumber(self: Self) -> Bool {
        return self.type == JSONType.Number;
    }
    
    fn IsString(self: Self) -> Bool {
        return self.type == JSONType.String;
    }
    
    fn IsArray(self: Self) -> Bool {
        return self.type == JSONType.Array;
    }
    
    fn IsObject(self: Self) -> Bool {
        return self.type == JSONType.Object;
    }
    
    // Value access methods
    fn AsBool(self: Self) -> Optional(Bool) {
        if (self.type == JSONType.Boolean) {
            return Optional(Bool).Some(self.bool_value);
        }
        return Optional(Bool).None();
    }
    
    fn AsNumber(self: Self) -> Optional(f64) {
        if (self.type == JSONType.Number) {
            return Optional(f64).Some(self.number_value);
        }
        return Optional(f64).None();
    }
    
    fn AsString(self: Self) -> Optional(String) {
        if (self.type == JSONType.String) {
            return Optional(String).Some(self.string_value);
        }
        return Optional(String).None();
    }
    
    fn AsArray(self: Self) -> Optional(Array(JSONValue)) {
        if (self.type == JSONType.Array) {
            return Optional(Array(JSONValue)).Some(self.array_value);
        }
        return Optional(Array(JSONValue)).None();
    }
    
    fn AsObject(self: Self) -> Optional(HashMap(String, JSONValue)) {
        if (self.type == JSONType.Object) {
            return Optional(HashMap(String, JSONValue)).Some(self.object_value);
        }
        return Optional(HashMap(String, JSONValue)).None();
    }
    
    // Array operations
    fn ArrayPush(self: Self, value: JSONValue) -> Bool {
        if (self.type == JSONType.Array) {
            self.array_value.Push(value);
            return True;
        }
        return False;
    }
    
    fn ArrayGet(self: Self, index: u64) -> Optional(JSONValue) {
        if (self.type == JSONType.Array and index < self.array_value.Size()) {
            return self.array_value.Get(index);
        }
        return Optional(JSONValue).None();
    }
    
    fn ArraySize(self: Self) -> u64 {
        if (self.type == JSONType.Array) {
            return self.array_value.Size();
        }
        return 0;
    }
    
    // Object operations
    fn ObjectSet(self: Self, key: String, value: JSONValue) -> Bool {
        if (self.type == JSONType.Object) {
            self.object_value.Insert(key, value);
            return True;
        }
        return False;
    }
    
    fn ObjectGet(self: Self, key: String) -> Optional(JSONValue) {
        if (self.type == JSONType.Object) {
            return self.object_value.Get(key);
        }
        return Optional(JSONValue).None();
    }
    
    fn ObjectHas(self: Self, key: String) -> Bool {
        if (self.type == JSONType.Object) {
            return self.object_value.Contains(key);
        }
        return False;
    }
    
    fn ObjectRemove(self: Self, key: String) -> Bool {
        if (self.type == JSONType.Object) {
            return self.object_value.Remove(key);
        }
        return False;
    }
}

// JSON Parser
class JSONParser {
    var text: String;
    var position: u64;
    var length: u64;
    
    fn Create(json_text: String) -> Self {
        return {
            .text = json_text,
            .position = 0,
            .length = json_text.Length()
        };
    }
    
    fn Parse(self: Self) -> Result(JSONValue, String) {
        self.SkipWhitespace();
        
        if (self.position >= self.length) {
            return Result(JSONValue, String).Error("Empty JSON input");
        }
        
        return self.ParseValue();
    }
    
    fn ParseValue(self: Self) -> Result(JSONValue, String) {
        self.SkipWhitespace();
        
        if (self.position >= self.length) {
            return Result(JSONValue, String).Error("Unexpected end of input");
        }
        
        var ch: i32 = self.text[self.position];
        
        match (ch) {
            case ('{') {
                return self.ParseObject();
            }
            case ('[') {
                return self.ParseArray();
            }
            case ('"') {
                return self.ParseString();
            }
            case ('t') {
                return self.ParseLiteral("true", JSONValue.CreateBool(True));
            }
            case ('f') {
                return self.ParseLiteral("false", JSONValue.CreateBool(False));
            }
            case ('n') {
                return self.ParseLiteral("null", JSONValue.CreateNull());
            }
            default {
                if (ch == '-' or (ch >= '0' and ch <= '9')) {
                    return self.ParseNumber();
                } else {
                    return Result(JSONValue, String).Error("Unexpected character: " + CharToString(ch));
                }
            }
        }
    }
    
    fn ParseObject(self: Self) -> Result(JSONValue, String) {
        var obj: JSONValue = JSONValue.CreateObject();
        
        self.position += 1; // Skip '{'
        self.SkipWhitespace();
        
        // Handle empty object
        if (self.position < self.length and self.text[self.position] == '}') {
            self.position += 1;
            return Result(JSONValue, String).Ok(obj);
        }
        
        while (True) {
            self.SkipWhitespace();
            
            // Parse key
            if (self.position >= self.length or self.text[self.position] != '"') {
                return Result(JSONValue, String).Error("Expected string key in object");
            }
            
            var key_result: Result(JSONValue, String) = self.ParseString();
            if (not key_result.IsOk()) {
                return key_result;
            }
            
            var key: String = key_result.Value().string_value;
            
            self.SkipWhitespace();
            
            // Expect ':'
            if (self.position >= self.length or self.text[self.position] != ':') {
                return Result(JSONValue, String).Error("Expected ':' after object key");
            }
            
            self.position += 1; // Skip ':'
            self.SkipWhitespace();
            
            // Parse value
            var value_result: Result(JSONValue, String) = self.ParseValue();
            if (not value_result.IsOk()) {
                return value_result;
            }
            
            obj.ObjectSet(key, value_result.Value());
            
            self.SkipWhitespace();
            
            if (self.position >= self.length) {
                return Result(JSONValue, String).Error("Unexpected end of input in object");
            }
            
            var next_ch: i32 = self.text[self.position];
            if (next_ch == '}') {
                self.position += 1;
                break;
            } else if (next_ch == ',') {
                self.position += 1;
                continue;
            } else {
                return Result(JSONValue, String).Error("Expected ',' or '}' in object");
            }
        }
        
        return Result(JSONValue, String).Ok(obj);
    }
    
    fn ParseArray(self: Self) -> Result(JSONValue, String) {
        var arr: JSONValue = JSONValue.CreateArray();
        
        self.position += 1; // Skip '['
        self.SkipWhitespace();
        
        // Handle empty array
        if (self.position < self.length and self.text[self.position] == ']') {
            self.position += 1;
            return Result(JSONValue, String).Ok(arr);
        }
        
        while (True) {
            self.SkipWhitespace();
            
            var value_result: Result(JSONValue, String) = self.ParseValue();
            if (not value_result.IsOk()) {
                return value_result;
            }
            
            arr.ArrayPush(value_result.Value());
            
            self.SkipWhitespace();
            
            if (self.position >= self.length) {
                return Result(JSONValue, String).Error("Unexpected end of input in array");
            }
            
            var next_ch: i32 = self.text[self.position];
            if (next_ch == ']') {
                self.position += 1;
                break;
            } else if (next_ch == ',') {
                self.position += 1;
                continue;
            } else {
                return Result(JSONValue, String).Error("Expected ',' or ']' in array");
            }
        }
        
        return Result(JSONValue, String).Ok(arr);
    }
    
    fn ParseString(self: Self) -> Result(JSONValue, String) {
        self.position += 1; // Skip opening quote
        
        var value: String = "";
        
        while (self.position < self.length) {
            var ch: i32 = self.text[self.position];
            
            if (ch == '"') {
                self.position += 1; // Skip closing quote
                return Result(JSONValue, String).Ok(JSONValue.CreateString(value));
            } else if (ch == '\\') {
                self.position += 1;
                
                if (self.position >= self.length) {
                    return Result(JSONValue, String).Error("Unexpected end of input in string escape");
                }
                
                var escaped: i32 = self.text[self.position];
                match (escaped) {
                    case ('"') { value += "\""; }
                    case ('\\') { value += "\\"; }
                    case ('/') { value += "/"; }
                    case ('b') { value += "\b"; }
                    case ('f') { value += "\f"; }
                    case ('n') { value += "\n"; }
                    case ('r') { value += "\r"; }
                    case ('t') { value += "\t"; }
                    case ('u') {
                        // Unicode escape sequence
                        var unicode_result: Result(String, String) = self.ParseUnicodeEscape();
                        if (not unicode_result.IsOk()) {
                            return Result(JSONValue, String).Error(unicode_result.Error());
                        }
                        value += unicode_result.Value();
                        continue; // Skip the increment at the end
                    }
                    default {
                        return Result(JSONValue, String).Error("Invalid escape sequence: \\" + CharToString(escaped));
                    }
                }
                
                self.position += 1;
            } else if (ch < 32) {
                return Result(JSONValue, String).Error("Control character in string");
            } else {
                value += CharToString(ch);
                self.position += 1;
            }
        }
        
        return Result(JSONValue, String).Error("Unterminated string");
    }
    
    fn ParseUnicodeEscape(self: Self) -> Result(String, String) {
        self.position += 1; // Skip 'u'
        
        if (self.position + 4 > self.length) {
            return Result(String, String).Error("Incomplete unicode escape sequence");
        }
        
        var hex_digits: String = self.text.Substring(self.position, 4);
        var code_point: u32 = 0;
        
        var i: i32 = 0;
        while (i < 4) {
            var digit: i32 = hex_digits[i];
            var hex_value: u32 = 0;
            
            if (digit >= '0' and digit <= '9') {
                hex_value = digit - '0';
            } else if (digit >= 'A' and digit <= 'F') {
                hex_value = digit - 'A' + 10;
            } else if (digit >= 'a' and digit <= 'f') {
                hex_value = digit - 'a' + 10;
            } else {
                return Result(String, String).Error("Invalid hex digit in unicode escape");
            }
            
            code_point = code_point * 16 + hex_value;
            i += 1;
        }
        
        self.position += 4;
        
        // Convert Unicode code point to UTF-8
        return Result(String, String).Ok(UnicodeToUtf8(code_point));
    }
    
    fn ParseNumber(self: Self) -> Result(JSONValue, String) {
        var start: u64 = self.position;
        var has_decimal: Bool = False;
        var has_exponent: Bool = False;
        
        // Handle negative sign
        if (self.position < self.length and self.text[self.position] == '-') {
            self.position += 1;
        }
        
        // Parse integer part
        if (self.position >= self.length or not self.IsDigit(self.text[self.position])) {
            return Result(JSONValue, String).Error("Invalid number format");
        }
        
        if (self.text[self.position] == '0') {
            self.position += 1;
        } else {
            while (self.position < self.length and self.IsDigit(self.text[self.position])) {
                self.position += 1;
            }
        }
        
        // Parse decimal part
        if (self.position < self.length and self.text[self.position] == '.') {
            has_decimal = True;
            self.position += 1;
            
            if (self.position >= self.length or not self.IsDigit(self.text[self.position])) {
                return Result(JSONValue, String).Error("Invalid decimal number format");
            }
            
            while (self.position < self.length and self.IsDigit(self.text[self.position])) {
                self.position += 1;
            }
        }
        
        // Parse exponent part
        if (self.position < self.length and (self.text[self.position] == 'e' or self.text[self.position] == 'E')) {
            has_exponent = True;
            self.position += 1;
            
            if (self.position < self.length and (self.text[self.position] == '+' or self.text[self.position] == '-')) {
                self.position += 1;
            }
            
            if (self.position >= self.length or not self.IsDigit(self.text[self.position])) {
                return Result(JSONValue, String).Error("Invalid exponent format");
            }
            
            while (self.position < self.length and self.IsDigit(self.text[self.position])) {
                self.position += 1;
            }
        }
        
        var number_str: String = self.text.Substring(start, self.position - start);
        var number_value: f64 = StringToFloat(number_str);
        
        return Result(JSONValue, String).Ok(JSONValue.CreateNumber(number_value));
    }
    
    fn ParseLiteral(self: Self, literal: String, value: JSONValue) -> Result(JSONValue, String) {
        if (self.position + literal.Length() > self.length) {
            return Result(JSONValue, String).Error("Unexpected end of input");
        }
        
        var i: u64 = 0;
        while (i < literal.Length()) {
            if (self.text[self.position + i] != literal[i]) {
                return Result(JSONValue, String).Error("Invalid literal: " + literal);
            }
            i += 1;
        }
        
        self.position += literal.Length();
        return Result(JSONValue, String).Ok(value);
    }
    
    fn SkipWhitespace(self: Self) {
        while (self.position < self.length) {
            var ch: i32 = self.text[self.position];
            if (ch == ' ' or ch == '\t' or ch == '\n' or ch == '\r') {
                self.position += 1;
            } else {
                break;
            }
        }
    }
    
    fn IsDigit(self: Self, ch: i32) -> Bool {
        return ch >= '0' and ch <= '9';
    }
}

// JSON Serializer
class JSONSerializer {
    var indent_level: i32;
    var pretty_print: Bool;
    
    fn Create(pretty_print: Bool) -> Self {
        return {
            .indent_level = 0,
            .pretty_print = pretty_print
        };
    }
    
    fn Serialize(self: Self, value: JSONValue) -> String {
        return self.SerializeValue(value);
    }
    
    fn SerializeValue(self: Self, value: JSONValue) -> String {
        match (value.type) {
            case (JSONType.Null) {
                return "null";
            }
            case (JSONType.Boolean) {
                return value.bool_value ? "true" : "false";
            }
            case (JSONType.Number) {
                return FloatToString(value.number_value);
            }
            case (JSONType.String) {
                return self.SerializeString(value.string_value);
            }
            case (JSONType.Array) {
                return self.SerializeArray(value.array_value);
            }
            case (JSONType.Object) {
                return self.SerializeObject(value.object_value);
            }
        }
        
        return "null";
    }
    
    fn SerializeString(self: Self, str: String) -> String {
        var result: String = "\"";
        
        var i: u64 = 0;
        while (i < str.Length()) {
            var ch: i32 = str[i];
            
            match (ch) {
                case ('"') { result += "\\\""; }
                case ('\\') { result += "\\\\"; }
                case ('/') { result += "\\/"; }
                case ('\b') { result += "\\b"; }
                case ('\f') { result += "\\f"; }
                case ('\n') { result += "\\n"; }
                case ('\r') { result += "\\r"; }
                case ('\t') { result += "\\t"; }
                default {
                    if (ch < 32) {
                        result += "\\u" + IntToHex(ch, 4);
                    } else {
                        result += CharToString(ch);
                    }
                }
            }
            
            i += 1;
        }
        
        result += "\"";
        return result;
    }
    
    fn SerializeArray(self: Self, arr: Array(JSONValue)) -> String {
        var result: String = "[";
        
        if (self.pretty_print and arr.Size() > 0) {
            result += "\n";
            self.indent_level += 1;
        }
        
        var i: u64 = 0;
        while (i < arr.Size()) {
            if (self.pretty_print) {
                result += self.GetIndent();
            }
            
            var item_opt: Optional(JSONValue) = arr.Get(i);
            if (item_opt.HasValue()) {
                result += self.SerializeValue(item_opt.Value());
            }
            
            if (i < arr.Size() - 1) {
                result += ",";
            }
            
            if (self.pretty_print) {
                result += "\n";
            }
            
            i += 1;
        }
        
        if (self.pretty_print and arr.Size() > 0) {
            self.indent_level -= 1;
            result += self.GetIndent();
        }
        
        result += "]";
        return result;
    }
    
    fn SerializeObject(self: Self, obj: HashMap(String, JSONValue)) -> String {
        var result: String = "{";
        
        if (self.pretty_print and obj.Size() > 0) {
            result += "\n";
            self.indent_level += 1;
        }
        
        var keys: Array(String) = obj.GetKeys();
        keys.Sort()
        
        var i: u64 = 0;
        while (i < keys.Size()) {
            if (self.pretty_print) {
                result += self.GetIndent();
            }
            
            var key_opt: Optional(String) = keys.Get(i);
            if (key_opt.HasValue()) {
                var key: String = key_opt.Value();
                var value_opt: Optional(JSONValue) = obj.Get(key);
                
                if (value_opt.HasValue()) {
                    result += self.SerializeString(key);
                    result += ":";
                    
                    if (self.pretty_print) {
                        result += " ";
                    }
                    
                    result += self.SerializeValue(value_opt.Value());
                }
            }
            
            if (i < keys.Size() - 1) {
                result += ",";
            }
            
            if (self.pretty_print) {
                result += "\n";
            }
            
            i += 1;
        }
        
        if (self.pretty_print and obj.Size() > 0) {
            self.indent_level -= 1;
            result += self.GetIndent();
        }
        
        result += "}";
        return result;
    }
    
    fn GetIndent(self: Self) -> String {
        var indent: String = "";
        var i: i32 = 0;
        while (i < self.indent_level) {
            indent += "  ";
            i += 1;
        }
        return indent;
    }
}

// Utility functions
fn ParseJSON(json_text: String) -> Result(JSONValue, String) {
    var parser: JSONParser = JSONParser.Create(json_text);
    return parser.Parse();
}

fn SerializeJSON(value: JSONValue, pretty_print: Bool) -> String {
    var serializer: JSONSerializer = JSONSerializer.Create(pretty_print);
    return serializer.Serialize(value);
}

// Helper functions for string conversion
fn StringToFloat(str: String) -> f64 {
    // Implementation would convert string to floating point number
    // This is a placeholder - real implementation would parse the string
    return 0.0;
}

fn FloatToString(value: f64) -> String {
    // Implementation would convert floating point to string
    // This is a placeholder - real implementation would format the number
    return "0.0";
}

fn IntToHex(value: i32, width: i32) -> String {
    // Implementation would convert integer to hexadecimal string
    // This is a placeholder
    return "0000";
}

fn UnicodeToUtf8(code_point: u32) -> String {
    // Implementation would convert Unicode code point to UTF-8 string
    // This is a placeholder
    return "";
}