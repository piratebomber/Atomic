// Atomic Code Formatter (.ato files)
package Atomic.Formatter api;

import Std.String;
import Std.Array;
import Std.Collections;
import Std.FileSystem;
import Std.Console;

choice BraceStyle { Allman, KernighanRitchie, GNU }

class FormatterConfig {
    var indent_size: i32;
    var use_tabs: Bool;
    var max_line_length: i32;
    var insert_final_newline: Bool;
    var trim_trailing_whitespace: Bool;
    var space_around_operators: Bool;
    var brace_style: BraceStyle;
    
    fn Create() -> Self {
        return { .indent_size = 4, .use_tabs = False, .max_line_length = 100, .insert_final_newline = True, .trim_trailing_whitespace = True, .space_around_operators = True, .brace_style = BraceStyle.Allman };
    }
}

choice TokenType { Keyword, Identifier, Literal, Operator, Punctuation, Comment, Whitespace, Newline, EOF }

class Token {
    var type: TokenType;
    var value: String;
    var line: i32;
    var column: i32;
    
    fn Create(type: TokenType, value: String, line: i32, column: i32) -> Self {
        return { .type = type, .value = value, .line = line, .column = column };
    }
}

class FormatterLexer {
    var source: String;
    var position: u64;
    var line: i32;
    var column: i32;
    var keywords: Array(String);
    
    fn Create(source: String) -> Self {
        var keywords: Array(String) = Array(String)();
        keywords.Push("fn"); keywords.Push("var"); keywords.Push("if"); keywords.Push("else"); keywords.Push("class");
        keywords.Push("match"); keywords.Push("case"); keywords.Push("import"); keywords.Push("package");
        
        return { .source = source, .position = 0, .line = 1, .column = 1, .keywords = keywords };
    }
    
    fn Tokenize(self: Self) -> Array(Token) {
        var tokens: Array(Token) = Array(Token)();
        
        while (self.position < self.source.Length()) {
            var token: Optional(Token) = self.NextToken();
            if (token.IsSome()) {
                tokens.Push(token.Unwrap());
            }
        }
        
        tokens.Push(Token.Create(TokenType.EOF, "", self.line, self.column));
        return tokens;
    }
    
    fn NextToken(self: Self) -> Optional(Token) {
        self.SkipWhitespace();
        
        if (self.position >= self.source.Length()) {
            return Optional(Token).None();
        }
        
        var start_line: i32 = self.line;
        var start_column: i32 = self.column;
        var c: u8 = self.source[self.position];
        
        // Comments
        if (c == '/' and self.Peek() == '/') {
            return Optional(Token).Some(self.ReadLineComment(start_line, start_column));
        }
        
        // String literals
        if (c == '"') {
            return Optional(Token).Some(self.ReadStringLiteral(start_line, start_column));
        }
        
        // Numbers
        if (self.IsDigit(c)) {
            return Optional(Token).Some(self.ReadNumber(start_line, start_column));
        }
        
        // Identifiers and keywords
        if (self.IsAlpha(c) or c == '_') {
            return Optional(Token).Some(self.ReadIdentifier(start_line, start_column));
        }
        
        // Operators
        if (self.IsOperator(c)) {
            var op: String = String.FromChar(c);
            self.Advance();
            return Optional(Token).Some(Token.Create(TokenType.Operator, op, start_line, start_column));
        }
        
        // Punctuation
        if (self.IsPunctuation(c)) {
            var punct: String = String.FromChar(c);
            self.Advance();
            return Optional(Token).Some(Token.Create(TokenType.Punctuation, punct, start_line, start_column));
        }
        
        // Newlines
        if (c == '\n') {
            self.Advance();
            return Optional(Token).Some(Token.Create(TokenType.Newline, "\n", start_line, start_column));
        }
        
        self.Advance();
        return Optional(Token).None();
    }
    
    fn ReadLineComment(self: Self, line: i32, column: i32) -> Token {
        var comment: String = "";
        
        while (self.position < self.source.Length() and self.source[self.position] != '\n') {
            comment += String.FromChar(self.source[self.position]);
            self.Advance();
        }
        
        return Token.Create(TokenType.Comment, comment, line, column);
    }
    
    fn ReadStringLiteral(self: Self, line: i32, column: i32) -> Token {
        var literal: String = "";
        self.Advance(); // Skip opening quote
        
        while (self.position < self.source.Length() and self.source[self.position] != '"') {
            literal += String.FromChar(self.source[self.position]);
            self.Advance();
        }
        
        if (self.position < self.source.Length()) {
            self.Advance(); // Skip closing quote
        }
        
        return Token.Create(TokenType.Literal, "\"" + literal + "\"", line, column);
    }
    
    fn ReadNumber(self: Self, line: i32, column: i32) -> Token {
        var number: String = "";
        
        while (self.position < self.source.Length() and (self.IsDigit(self.source[self.position]) or self.source[self.position] == '.')) {
            number += String.FromChar(self.source[self.position]);
            self.Advance();
        }
        
        return Token.Create(TokenType.Literal, number, line, column);
    }
    
    fn ReadIdentifier(self: Self, line: i32, column: i32) -> Token {
        var identifier: String = "";
        
        while (self.position < self.source.Length() and (self.IsAlphaNumeric(self.source[self.position]) or self.source[self.position] == '_')) {
            identifier += String.FromChar(self.source[self.position]);
            self.Advance();
        }
        
        var token_type: TokenType = TokenType.Identifier;
        for (keyword: String in self.keywords) {
            if (identifier == keyword) {
                token_type = TokenType.Keyword;
                break;
            }
        }
        
        return Token.Create(token_type, identifier, line, column);
    }
    
    fn SkipWhitespace(self: Self) {
        while (self.position < self.source.Length() and (self.source[self.position] == ' ' or self.source[self.position] == '\t' or self.source[self.position] == '\r')) {
            self.Advance();
        }
    }
    
    fn Peek(self: Self) -> u8 {
        if (self.position + 1 < self.source.Length()) {
            return self.source[self.position + 1];
        }
        return 0;
    }
    
    fn Advance(self: Self) {
        if (self.position < self.source.Length()) {
            if (self.source[self.position] == '\n') {
                self.line += 1;
                self.column = 1;
            } else {
                self.column += 1;
            }
            self.position += 1;
        }
    }
    
    fn IsDigit(self: Self, c: u8) -> Bool {
        return c >= '0' and c <= '9';
    }
    
    fn IsAlpha(self: Self, c: u8) -> Bool {
        return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z');
    }
    
    fn IsAlphaNumeric(self: Self, c: u8) -> Bool {
        return self.IsAlpha(c) or self.IsDigit(c);
    }
    
    fn IsOperator(self: Self, c: u8) -> Bool {
        return c == '=' or c == '+' or c == '-' or c == '*' or c == '/' or c == '<' or c == '>' or c == '!' or c == '&' or c == '|';
    }
    
    fn IsPunctuation(self: Self, c: u8) -> Bool {
        return c == '(' or c == ')' or c == '{' or c == '}' or c == '[' or c == ']' or c == ';' or c == ',' or c == '.';
    }
}

class CodeFormatter {
    var config: FormatterConfig;
    var tokens: Array(Token);
    var position: u64;
    var output: String;
    var current_indent: i32;
    
    fn Create(config: FormatterConfig) -> Self {
        return { .config = config, .tokens = Array(Token)(), .position = 0, .output = "", .current_indent = 0 };
    }
    
    fn Format(self: Self, source: String) -> Result(String, String) {
        var lexer: FormatterLexer = FormatterLexer.Create(source);
        self.tokens = lexer.Tokenize();
        self.position = 0;
        self.output = "";
        self.current_indent = 0;
        
        while (self.position < self.tokens.Size()) {
            var token_opt: Optional(Token) = self.tokens.Get(self.position);
            if (token_opt.IsSome()) {
                var token: Token = token_opt.Unwrap();
                self.FormatToken(token);
            }
            self.position += 1;
        }
        
        if (self.config.trim_trailing_whitespace) {
            self.output = self.TrimTrailingWhitespace(self.output);
        }
        
        if (self.config.insert_final_newline and not self.output.EndsWith("\n")) {
            self.output += "\n";
        }
        
        return Result(String, String).Ok(self.output);
    }
    
    fn FormatToken(self: Self, token: Token) {
        match (token.type) {
            case TokenType.Keyword => {
                self.output += token.value;
                if (token.value == "fn" or token.value == "var" or token.value == "if" or token.value == "class") {
                    self.output += " ";
                }
            }
            case TokenType.Identifier => {
                self.output += token.value;
            }
            case TokenType.Literal => {
                self.output += token.value;
            }
            case TokenType.Operator => {
                if (self.config.space_around_operators) {
                    if (not self.output.EndsWith(" ")) {
                        self.output += " ";
                    }
                    self.output += token.value;
                    self.output += " ";
                } else {
                    self.output += token.value;
                }
            }
            case TokenType.Punctuation => {
                self.FormatPunctuation(token);
            }
            case TokenType.Comment => {
                if (not self.output.EndsWith(" ") and not self.output.EndsWith("\n")) {
                    self.output += " ";
                }
                self.output += token.value;
            }
            case TokenType.Newline => {
                if (not self.output.EndsWith("\n")) {
                    self.output += "\n";
                    self.AddIndent();
                }
            }
            default => {
                self.output += token.value;
            }
        }
    }
    
    fn FormatPunctuation(self: Self, token: Token) {
        match (token.value) {
            case "{" => {
                match (self.config.brace_style) {
                    case BraceStyle.Allman => {
                        if (not self.output.EndsWith("\n")) {
                            self.output += "\n";
                            self.AddIndent();
                        }
                        self.output += token.value;
                        self.output += "\n";
                        self.current_indent += 1;
                        self.AddIndent();
                    }
                    case BraceStyle.KernighanRitchie => {
                        if (not self.output.EndsWith(" ")) {
                            self.output += " ";
                        }
                        self.output += token.value;
                        self.output += "\n";
                        self.current_indent += 1;
                        self.AddIndent();
                    }
                    default => {
                        self.output += token.value;
                        self.current_indent += 1;
                    }
                }
            }
            case "}" => {
                self.current_indent -= 1;
                if (not self.output.EndsWith("\n")) {
                    self.output += "\n";
                }
                self.AddIndent();
                self.output += token.value;
                self.output += "\n";
                if (self.current_indent > 0) {
                    self.AddIndent();
                }
            }
            case ";" => {
                self.output += token.value;
                if (not self.IsLastTokenOnLine()) {
                    self.output += "\n";
                    self.AddIndent();
                }
            }
            case "," => {
                self.output += token.value;
                self.output += " ";
            }
            default => {
                self.output += token.value;
            }
        }
    }
    
    fn AddIndent(self: Self) {
        if (self.config.use_tabs) {
            for (i: i32 in Range(0, self.current_indent)) {
                self.output += "\t";
            }
        } else {
            for (i: i32 in Range(0, self.current_indent * self.config.indent_size)) {
                self.output += " ";
            }
        }
    }
    
    fn IsLastTokenOnLine(self: Self) -> Bool {
        var i: u64 = self.position + 1;
        while (i < self.tokens.Size()) {
            var token_opt: Optional(Token) = self.tokens.Get(i);
            if (token_opt.IsSome()) {
                var token: Token = token_opt.Unwrap();
                if (token.type == TokenType.Newline) {
                    return True;
                }
                if (token.type != TokenType.Whitespace and token.type != TokenType.Comment) {
                    return False;
                }
            }
            i += 1;
        }
        return True;
    }
    
    fn TrimTrailingWhitespace(self: Self, text: String) -> String {
        var lines: Array(String) = text.Split("\n");
        var result: String = "";
        
        for (i: u64 in Range(0, lines.Size())) {
            var line: Optional(String) = lines.Get(i);
            if (line.IsSome()) {
                var trimmed: String = line.Unwrap().TrimRight();
                result += trimmed;
                
                if (i < lines.Size() - 1) {
                    result += "\n";
                }
            }
        }
        
        return result;
    }
}

class AtomicFormatter {
    fn FormatFile(file_path: String, config_path: Optional(String)) -> Result(String, String) {
        var source_result: Result(String, String) = FileSystem.ReadFile(file_path);
        if (source_result.IsError()) {
            return source_result;
        }
        
        var config: FormatterConfig = FormatterConfig.Create();
        var formatter: CodeFormatter = CodeFormatter.Create(config);
        return formatter.Format(source_result.Unwrap());
    }
    
    fn FormatString(source: String, config: FormatterConfig) -> Result(String, String) {
        var formatter: CodeFormatter = CodeFormatter.Create(config);
        return formatter.Format(source);
    }
    
    fn FormatDirectory(directory_path: String, recursive: Bool) -> Result(i32, String) {
        var files_result: Result(Array(String), String) = FileSystem.ListFiles(directory_path, recursive);
        if (files_result.IsError()) {
            return Result(i32, String).Error(files_result.UnwrapError());
        }
        
        var files: Array(String) = files_result.Unwrap();
        var formatted_count: i32 = 0;
        
        for (file_path: String in files) {
            if (file_path.EndsWith(".ato") or file_path.EndsWith(".carbon")) {
                var format_result: Result(String, String) = Self.FormatFile(file_path, Optional(String).None());
                
                if (format_result.IsOk()) {
                    var write_result: Result(Bool, String) = FileSystem.WriteFile(file_path, format_result.Unwrap());
                    if (write_result.IsOk()) {
                        formatted_count += 1;
                        Console.WriteLine("Formatted: " + file_path);
                    }
                }
            }
        }
        
        return Result(i32, String).Ok(formatted_count);
    }
    
    fn CheckFormatting(file_path: String) -> Result(Bool, String) {
        var source_result: Result(String, String) = FileSystem.ReadFile(file_path);
        if (source_result.IsError()) {
            return Result(Bool, String).Error(source_result.UnwrapError());
        }
        
        var original_source: String = source_result.Unwrap();
        var format_result: Result(String, String) = Self.FormatFile(file_path, Optional(String).None());
        
        if (format_result.IsError()) {
            return Result(Bool, String).Error(format_result.UnwrapError());
        }
        
        var formatted_source: String = format_result.Unwrap();
        return Result(Bool, String).Ok(original_source == formatted_source);
    }
}