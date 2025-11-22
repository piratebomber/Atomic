// Atomic Standard Library - XML Parser
package Std.XML api;

import Std.String;
import Std.Array;
import Std.Collections;
import Std.Memory;

// XML node types
choice XMLNodeType {
    Element,
    Text,
    Comment,
    ProcessingInstruction,
    CDATA,
    Document
}

// XML attribute
struct XMLAttribute {
    var name: String;
    var value: String;
    var namespace: String;
}

// XML namespace
struct XMLNamespace {
    var prefix: String;
    var uri: String;
}

// XML node
class XMLNode {
    var type: XMLNodeType;
    var name: String;
    var value: String;
    var attributes: HashMap(String, XMLAttribute);
    var children: Array(XMLNode);
    var parent: Optional(*XMLNode);
    var namespaces: Array(XMLNamespace);
    var line_number: i32;
    var column_number: i32;
    
    fn CreateElement(name: String) -> Self {
        return {
            .type = XMLNodeType.Element,
            .name = name,
            .value = "",
            .attributes = HashMap(String, XMLAttribute).Create(),
            .children = Array(XMLNode)(),
            .parent = Optional(*XMLNode).None(),
            .namespaces = Array(XMLNamespace)(),
            .line_number = 0,
            .column_number = 0
        };
    }
    
    fn CreateText(text: String) -> Self {
        return {
            .type = XMLNodeType.Text,
            .name = "",
            .value = text,
            .attributes = HashMap(String, XMLAttribute).Create(),
            .children = Array(XMLNode)(),
            .parent = Optional(*XMLNode).None(),
            .namespaces = Array(XMLNamespace)(),
            .line_number = 0,
            .column_number = 0
        };
    }
    
    fn CreateComment(comment: String) -> Self {
        return {
            .type = XMLNodeType.Comment,
            .name = "",
            .value = comment,
            .attributes = HashMap(String, XMLAttribute).Create(),
            .children = Array(XMLNode)(),
            .parent = Optional(*XMLNode).None(),
            .namespaces = Array(XMLNamespace)(),
            .line_number = 0,
            .column_number = 0
        };
    }
    
    fn CreateDocument() -> Self {
        return {
            .type = XMLNodeType.Document,
            .name = "",
            .value = "",
            .attributes = HashMap(String, XMLAttribute).Create(),
            .children = Array(XMLNode)(),
            .parent = Optional(*XMLNode).None(),
            .namespaces = Array(XMLNamespace)(),
            .line_number = 0,
            .column_number = 0
        };
    }
    
    // Attribute operations
    fn SetAttribute(self: Self, name: String, value: String) {
        var attr: XMLAttribute = {
            .name = name,
            .value = value,
            .namespace = ""
        };
        self.attributes.Insert(name, attr);
    }
    
    fn GetAttribute(self: Self, name: String) -> Optional(String) {
        var attr_opt: Optional(XMLAttribute) = self.attributes.Get(name);
        if (attr_opt.HasValue()) {
            return Optional(String).Some(attr_opt.Value().value);
        }
        return Optional(String).None();
    }
    
    fn HasAttribute(self: Self, name: String) -> Bool {
        return self.attributes.Contains(name);
    }
    
    fn RemoveAttribute(self: Self, name: String) -> Bool {
        return self.attributes.Remove(name);
    }
    
    // Child operations
    fn AddChild(self: Self, child: XMLNode) {
        child.parent = Optional(*XMLNode).Some(&self);
        self.children.Push(child);
    }
    
    fn RemoveChild(self: Self, child: *XMLNode) -> Bool {
        var i: u64 = 0;
        while (i < self.children.Size()) {
            if (&self.children[i] == child) {
                self.children.Remove(i);
                child.parent = Optional(*XMLNode).None();
                return True;
            }
            i += 1;
        }
        return False;
    }
    
    fn GetChildrenByName(self: Self, name: String) -> Array(XMLNode) {
        var result: Array(XMLNode) = Array(XMLNode)();
        var i: u64 = 0;
        while (i < self.children.Size()) {
            if (self.children[i].name == name) {
                result.Push(self.children[i]);
            }
            i += 1;
        }
        return result;
    }
    
    fn GetFirstChild(self: Self, name: String) -> Optional(XMLNode) {
        var i: u64 = 0;
        while (i < self.children.Size()) {
            if (self.children[i].name == name) {
                return self.children.Get(i);
            }
            i += 1;
        }
        return Optional(XMLNode).None();
    }
    
    // Text content operations
    fn GetTextContent(self: Self) -> String {
        if (self.type == XMLNodeType.Text) {
            return self.value;
        }
        
        var text: String = "";
        var i: u64 = 0;
        while (i < self.children.Size()) {
            if (self.children[i].type == XMLNodeType.Text) {
                text += self.children[i].value;
            } else if (self.children[i].type == XMLNodeType.Element) {
                text += self.children[i].GetTextContent();
            }
            i += 1;
        }
        return text;
    }
    
    fn SetTextContent(self: Self, text: String) {
        // Remove all text children
        var new_children: Array(XMLNode) = Array(XMLNode)();
        var i: u64 = 0;
        while (i < self.children.Size()) {
            if (self.children[i].type != XMLNodeType.Text) {
                new_children.Push(self.children[i]);
            }
            i += 1;
        }
        self.children = new_children;
        
        // Add new text node
        if (not text.IsEmpty()) {
            self.AddChild(XMLNode.CreateText(text));
        }
    }
    
    // Namespace operations
    fn AddNamespace(self: Self, prefix: String, uri: String) {
        var ns: XMLNamespace = {
            .prefix = prefix,
            .uri = uri
        };
        self.namespaces.Push(ns);
    }
    
    fn GetNamespaceURI(self: Self, prefix: String) -> Optional(String) {
        var i: u64 = 0;
        while (i < self.namespaces.Size()) {
            if (self.namespaces[i].prefix == prefix) {
                return Optional(String).Some(self.namespaces[i].uri);
            }
            i += 1;
        }
        
        // Check parent namespaces
        if (self.parent.HasValue()) {
            return self.parent.Value().GetNamespaceURI(prefix);
        }
        
        return Optional(String).None();
    }
    
    // XPath-like queries
    fn SelectNodes(self: Self, xpath: String) -> Array(XMLNode) {
        var parser: XPathParser = XPathParser.Create(xpath);
        return parser.Evaluate(&self);
    }
    
    fn SelectSingleNode(self: Self, xpath: String) -> Optional(XMLNode) {
        var nodes: Array(XMLNode) = self.SelectNodes(xpath);
        if (nodes.Size() > 0) {
            return nodes.Get(0);
        }
        return Optional(XMLNode).None();
    }
}

// XML Parser
class XMLParser {
    var text: String;
    var position: u64;
    var length: u64;
    var line: i32;
    var column: i32;
    var preserve_whitespace: Bool;
    var validate_namespaces: Bool;
    
    fn Create(xml_text: String) -> Self {
        return {
            .text = xml_text,
            .position = 0,
            .length = xml_text.Length(),
            .line = 1,
            .column = 1,
            .preserve_whitespace = False,
            .validate_namespaces = True
        };
    }
    
    fn Parse(self: Self) -> Result(XMLNode, String) {
        self.SkipWhitespace();
        
        var document: XMLNode = XMLNode.CreateDocument();
        
        // Parse XML declaration if present
        if (self.PeekString("<?xml")) {
            var decl_result: Result(XMLNode, String) = self.ParseProcessingInstruction();
            if (not decl_result.IsOk()) {
                return decl_result;
            }
            document.AddChild(decl_result.Value());
        }
        
        // Parse document content
        while (self.position < self.length) {
            self.SkipWhitespace();
            
            if (self.position >= self.length) {
                break;
            }
            
            var node_result: Result(XMLNode, String) = self.ParseNode();
            if (not node_result.IsOk()) {
                return node_result;
            }
            
            document.AddChild(node_result.Value());
        }
        
        return Result(XMLNode, String).Ok(document);
    }
    
    fn ParseNode(self: Self) -> Result(XMLNode, String) {
        self.SkipWhitespace();
        
        if (self.position >= self.length) {
            return Result(XMLNode, String).Error("Unexpected end of input");
        }
        
        if (self.text[self.position] == '<') {
            if (self.PeekString("<!--")) {
                return self.ParseComment();
            } else if (self.PeekString("<![CDATA[")) {
                return self.ParseCDATA();
            } else if (self.PeekString("<?")) {
                return self.ParseProcessingInstruction();
            } else {
                return self.ParseElement();
            }
        } else {
            return self.ParseText();
        }
    }
    
    fn ParseElement(self: Self) -> Result(XMLNode, String) {
        if (self.text[self.position] != '<') {
            return Result(XMLNode, String).Error("Expected '<' at start of element");
        }
        
        self.Advance(); // Skip '<'
        
        // Parse element name
        var name: String = self.ParseName();
        if (name.IsEmpty()) {
            return Result(XMLNode, String).Error("Invalid element name");
        }
        
        var element: XMLNode = XMLNode.CreateElement(name);
        element.line_number = self.line;
        element.column_number = self.column;
        
        // Parse attributes
        while (True) {
            self.SkipWhitespace();
            
            if (self.position >= self.length) {
                return Result(XMLNode, String).Error("Unexpected end of input in element");
            }
            
            var ch: i32 = self.text[self.position];
            if (ch == '>') {
                self.Advance();
                break;
            } else if (ch == '/' and self.position + 1 < self.length and self.text[self.position + 1] == '>') {
                // Self-closing tag
                self.position += 2;
                return Result(XMLNode, String).Ok(element);
            } else {
                // Parse attribute
                var attr_result: Result(XMLAttribute, String) = self.ParseAttribute();
                if (not attr_result.IsOk()) {
                    return Result(XMLNode, String).Error(attr_result.Error());
                }
                
                var attr: XMLAttribute = attr_result.Value();
                element.attributes.Insert(attr.name, attr);
            }
        }
        
        // Parse element content
        while (True) {
            self.SkipWhitespace();
            
            if (self.position >= self.length) {
                return Result(XMLNode, String).Error("Unexpected end of input in element content");
            }
            
            if (self.PeekString("</")) {
                // End tag
                self.position += 2;
                var end_name: String = self.ParseName();
                
                if (end_name != name) {
                    return Result(XMLNode, String).Error("Mismatched end tag: expected " + name + ", got " + end_name);
                }
                
                self.SkipWhitespace();
                if (self.position >= self.length or self.text[self.position] != '>') {
                    return Result(XMLNode, String).Error("Expected '>' after end tag");
                }
                
                self.Advance();
                break;
            } else {
                // Parse child node
                var child_result: Result(XMLNode, String) = self.ParseNode();
                if (not child_result.IsOk()) {
                    return child_result;
                }
                
                element.AddChild(child_result.Value());
            }
        }
        
        return Result(XMLNode, String).Ok(element);
    }
    
    fn ParseAttribute(self: Self) -> Result(XMLAttribute, String) {
        var name: String = self.ParseName();
        if (name.IsEmpty()) {
            return Result(XMLAttribute, String).Error("Invalid attribute name");
        }
        
        self.SkipWhitespace();
        
        if (self.position >= self.length or self.text[self.position] != '=') {
            return Result(XMLAttribute, String).Error("Expected '=' after attribute name");
        }
        
        self.Advance(); // Skip '='
        self.SkipWhitespace();
        
        var value: String = self.ParseAttributeValue();
        
        var attr: XMLAttribute = {
            .name = name,
            .value = value,
            .namespace = ""
        };
        
        return Result(XMLAttribute, String).Ok(attr);
    }
    
    fn ParseAttributeValue(self: Self) -> String {
        if (self.position >= self.length) {
            return "";
        }
        
        var quote: i32 = self.text[self.position];
        if (quote != '"' and quote != '\'') {
            return "";
        }
        
        self.Advance(); // Skip opening quote
        
        var value: String = "";
        while (self.position < self.length and self.text[self.position] != quote) {
            var ch: i32 = self.text[self.position];
            
            if (ch == '&') {
                var entity: String = self.ParseEntity();
                value += entity;
            } else {
                value += CharToString(ch);
                self.Advance();
            }
        }
        
        if (self.position < self.length) {
            self.Advance(); // Skip closing quote
        }
        
        return value;
    }
    
    fn ParseText(self: Self) -> Result(XMLNode, String) {
        var text: String = "";
        
        while (self.position < self.length and self.text[self.position] != '<') {
            var ch: i32 = self.text[self.position];
            
            if (ch == '&') {
                var entity: String = self.ParseEntity();
                text += entity;
            } else {
                text += CharToString(ch);
                self.Advance();
            }
        }
        
        // Trim whitespace if not preserving
        if (not self.preserve_whitespace) {
            text = text.Trim();
        }
        
        if (text.IsEmpty() and not self.preserve_whitespace) {
            return Result(XMLNode, String).Error("Empty text node");
        }
        
        return Result(XMLNode, String).Ok(XMLNode.CreateText(text));
    }
    
    fn ParseComment(self: Self) -> Result(XMLNode, String) {
        if (not self.PeekString("<!--")) {
            return Result(XMLNode, String).Error("Expected comment start");
        }
        
        self.position += 4; // Skip "<!--"
        
        var comment: String = "";
        while (self.position + 2 < self.length) {
            if (self.PeekString("-->")) {
                self.position += 3;
                return Result(XMLNode, String).Ok(XMLNode.CreateComment(comment));
            }
            
            comment += CharToString(self.text[self.position]);
            self.Advance();
        }
        
        return Result(XMLNode, String).Error("Unterminated comment");
    }
    
    fn ParseCDATA(self: Self) -> Result(XMLNode, String) {
        if (not self.PeekString("<![CDATA[")) {
            return Result(XMLNode, String).Error("Expected CDATA start");
        }
        
        self.position += 9; // Skip "<![CDATA["
        
        var cdata: String = "";
        while (self.position + 2 < self.length) {
            if (self.PeekString("]]>")) {
                self.position += 3;
                var node: XMLNode = XMLNode.CreateText(cdata);
                node.type = XMLNodeType.CDATA;
                return Result(XMLNode, String).Ok(node);
            }
            
            cdata += CharToString(self.text[self.position]);
            self.Advance();
        }
        
        return Result(XMLNode, String).Error("Unterminated CDATA section");
    }
    
    fn ParseProcessingInstruction(self: Self) -> Result(XMLNode, String) {
        if (not self.PeekString("<?")) {
            return Result(XMLNode, String).Error("Expected processing instruction start");
        }
        
        self.position += 2; // Skip "<?"
        
        var target: String = self.ParseName();
        var data: String = "";
        
        self.SkipWhitespace();
        
        while (self.position + 1 < self.length) {
            if (self.PeekString("?>")) {
                self.position += 2;
                var node: XMLNode = XMLNode.CreateElement(target);
                node.type = XMLNodeType.ProcessingInstruction;
                node.value = data;
                return Result(XMLNode, String).Ok(node);
            }
            
            data += CharToString(self.text[self.position]);
            self.Advance();
        }
        
        return Result(XMLNode, String).Error("Unterminated processing instruction");
    }
    
    fn ParseEntity(self: Self) -> String {
        if (self.text[self.position] != '&') {
            return "";
        }
        
        self.Advance(); // Skip '&'
        
        var entity: String = "";
        while (self.position < self.length and self.text[self.position] != ';') {
            entity += CharToString(self.text[self.position]);
            self.Advance();
        }
        
        if (self.position < self.length) {
            self.Advance(); // Skip ';'
        }
        
        // Resolve entity
        if (entity == "lt") { return "<"; }
        if (entity == "gt") { return ">"; }
        if (entity == "amp") { return "&"; }
        if (entity == "quot") { return "\""; }
        if (entity == "apos") { return "'"; }
        
        // Numeric entities
        if (entity.StartsWith("#")) {
            var num_str: String = entity.Substring(1);
            var code_point: i32 = 0;
            
            if (num_str.StartsWith("x")) {
                // Hexadecimal
                code_point = HexStringToInt(num_str.Substring(1));
            } else {
                // Decimal
                code_point = StringToInt(num_str);
            }
            
            return CharToString(code_point);
        }
        
        return "&" + entity + ";"; // Unknown entity, return as-is
    }
    
    fn ParseName(self: Self) -> String {
        var name: String = "";
        
        // First character must be letter or underscore
        if (self.position < self.length) {
            var ch: i32 = self.text[self.position];
            if (self.IsNameStartChar(ch)) {
                name += CharToString(ch);
                self.Advance();
            } else {
                return "";
            }
        }
        
        // Subsequent characters
        while (self.position < self.length) {
            var ch: i32 = self.text[self.position];
            if (self.IsNameChar(ch)) {
                name += CharToString(ch);
                self.Advance();
            } else {
                break;
            }
        }
        
        return name;
    }
    
    fn SkipWhitespace(self: Self) {
        while (self.position < self.length) {
            var ch: i32 = self.text[self.position];
            if (ch == ' ' or ch == '\t' or ch == '\n' or ch == '\r') {
                if (ch == '\n') {
                    self.line += 1;
                    self.column = 1;
                } else {
                    self.column += 1;
                }
                self.position += 1;
            } else {
                break;
            }
        }
    }
    
    fn Advance(self: Self) {
        if (self.position < self.length) {
            if (self.text[self.position] == '\n') {
                self.line += 1;
                self.column = 1;
            } else {
                self.column += 1;
            }
            self.position += 1;
        }
    }
    
    fn PeekString(self: Self, str: String) -> Bool {
        if (self.position + str.Length() > self.length) {
            return False;
        }
        
        var i: u64 = 0;
        while (i < str.Length()) {
            if (self.text[self.position + i] != str[i]) {
                return False;
            }
            i += 1;
        }
        
        return True;
    }
    
    fn IsNameStartChar(self: Self, ch: i32) -> Bool {
        return (ch >= 'A' and ch <= 'Z') or (ch >= 'a' and ch <= 'z') or ch == '_' or ch == ':';
    }
    
    fn IsNameChar(self: Self, ch: i32) -> Bool {
        return self.IsNameStartChar(ch) or (ch >= '0' and ch <= '9') or ch == '-' or ch == '.';
    }
}

// Simple XPath parser for basic queries
class XPathParser {
    var expression: String;
    var position: u64;
    
    fn Create(xpath: String) -> Self {
        return {
            .expression = xpath,
            .position = 0
        };
    }
    
    fn Evaluate(self: Self, context: *XMLNode) -> Array(XMLNode) {
        var result: Array(XMLNode) = Array(XMLNode)();
        
        if (self.expression.StartsWith("//")) {
            // Descendant search
            var name: String = self.expression.Substring(2);
            self.FindDescendants(context, name, &result);
        } else if (self.expression.StartsWith("/")) {
            // Child search
            var name: String = self.expression.Substring(1);
            self.FindChildren(context, name, &result);
        } else {
            // Direct child search
            self.FindChildren(context, self.expression, &result);
        }
        
        return result;
    }
    
    fn FindChildren(self: Self, node: *XMLNode, name: String, result: *Array(XMLNode)) {
        var i: u64 = 0;
        while (i < node.children.Size()) {
            if (node.children[i].name == name or name == "*") {
                result.Push(node.children[i]);
            }
            i += 1;
        }
    }
    
    fn FindDescendants(self: Self, node: *XMLNode, name: String, result: *Array(XMLNode)) {
        var i: u64 = 0;
        while (i < node.children.Size()) {
            if (node.children[i].name == name or name == "*") {
                result.Push(node.children[i]);
            }
            self.FindDescendants(&node.children[i], name, result);
            i += 1;
        }
    }
}

// XML Serializer
class XMLSerializer {
    var indent_level: i32;
    var pretty_print: Bool;
    var encoding: String;
    
    fn Create(pretty_print: Bool) -> Self {
        return {
            .indent_level = 0,
            .pretty_print = pretty_print,
            .encoding = "UTF-8"
        };
    }
    
    fn Serialize(self: Self, node: XMLNode) -> String {
        if (node.type == XMLNodeType.Document) {
            var result: String = "<?xml version=\"1.0\" encoding=\"" + self.encoding + "\"?>";
            if (self.pretty_print) {
                result += "\n";
            }
            
            var i: u64 = 0;
            while (i < node.children.Size()) {
                result += self.SerializeNode(node.children[i]);
                i += 1;
            }
            
            return result;
        } else {
            return self.SerializeNode(node);
        }
    }
    
    fn SerializeNode(self: Self, node: XMLNode) -> String {
        match (node.type) {
            case (XMLNodeType.Element) {
                return self.SerializeElement(node);
            }
            case (XMLNodeType.Text) {
                return self.EscapeText(node.value);
            }
            case (XMLNodeType.Comment) {
                return "<!--" + node.value + "-->";
            }
            case (XMLNodeType.CDATA) {
                return "<![CDATA[" + node.value + "]]>";
            }
            case (XMLNodeType.ProcessingInstruction) {
                return "<?" + node.name + " " + node.value + "?>";
            }
            default {
                return "";
            }
        }
    }
    
    fn SerializeElement(self: Self, element: XMLNode) -> String {
        var result: String = "";
        
        if (self.pretty_print) {
            result += self.GetIndent();
        }
        
        result += "<" + element.name;
        
        // Serialize attributes
        var attr_keys: Array(String) = element.attributes.GetKeys();
        attr_keys.Sort();
        
        var i: u64 = 0;
        while (i < attr_keys.Size()) {
            var key_opt: Optional(String) = attr_keys.Get(i);
            if (key_opt.HasValue()) {
                var key: String = key_opt.Value();
                var attr_opt: Optional(XMLAttribute) = element.attributes.Get(key);
                if (attr_opt.HasValue()) {
                    var attr: XMLAttribute = attr_opt.Value();
                    result += " " + attr.name + "=\"" + self.EscapeAttribute(attr.value) + "\"";
                }
            }
            i += 1;
        }
        
        if (element.children.Size() == 0) {
            result += "/>";
            if (self.pretty_print) {
                result += "\n";
            }
        } else {
            result += ">";
            
            var has_element_children: Bool = False;
            i = 0;
            while (i < element.children.Size()) {
                if (element.children[i].type == XMLNodeType.Element) {
                    has_element_children = True;
                    break;
                }
                i += 1;
            }
            
            if (self.pretty_print and has_element_children) {
                result += "\n";
                self.indent_level += 1;
            }
            
            // Serialize children
            i = 0;
            while (i < element.children.Size()) {
                result += self.SerializeNode(element.children[i]);
                i += 1;
            }
            
            if (self.pretty_print and has_element_children) {
                self.indent_level -= 1;
                result += self.GetIndent();
            }
            
            result += "</" + element.name + ">";
            
            if (self.pretty_print) {
                result += "\n";
            }
        }
        
        return result;
    }
    
    fn EscapeText(self: Self, text: String) -> String {
        var result: String = text;
        result = result.Replace("&", "&amp;");
        result = result.Replace("<", "&lt;");
        result = result.Replace(">", "&gt;");
        return result;
    }
    
    fn EscapeAttribute(self: Self, text: String) -> String {
        var result: String = self.EscapeText(text);
        result = result.Replace("\"", "&quot;");
        result = result.Replace("'", "&apos;");
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
fn ParseXML(xml_text: String) -> Result(XMLNode, String) {
    var parser: XMLParser = XMLParser.Create(xml_text);
    return parser.Parse();
}

fn SerializeXML(node: XMLNode, pretty_print: Bool) -> String {
    var serializer: XMLSerializer = XMLSerializer.Create(pretty_print);
    return serializer.Serialize(node);
}

fn HexStringToInt(hex_str: String) -> i32 {
    var result: i32 = 0;
    var i: u64 = 0;
    
    while (i < hex_str.Length()) {
        var ch: i32 = hex_str[i];
        var digit: i32 = 0;
        
        if (ch >= '0' and ch <= '9') {
            digit = ch - '0';
        } else if (ch >= 'A' and ch <= 'F') {
            digit = ch - 'A' + 10;
        } else if (ch >= 'a' and ch <= 'f') {
            digit = ch - 'a' + 10;
        }
        
        result = result * 16 + digit;
        i += 1;
    }
    
    return result;
}