// Atomic Carbon Lexer
package AtomicCompiler.Lexer api;

import Std.String;
import Std.Array;
import Std.Optional;

// Token types for Carbon language
choice TokenType {
    // Literals
    IntegerLiteral,
    FloatLiteral,
    StringLiteral,
    BoolLiteral,
    
    // Identifiers and keywords
    Identifier,
    Package,
    Import,
    Api,
    Impl,
    Library,
    Fn,
    Var,
    Let,
    If,
    Else,
    While,
    For,
    Match,
    Case,
    Default,
    Return,
    Break,
    Continue,
    Class,
    Interface,
    Choice,
    Constraint,
    Template,
    Forall,
    Where,
    Extends,
    Impls,
    As,
    Auto,
    Self,
    Base,
    
    // Types
    I8, I16, I32, I64,
    U8, U16, U32, U64,
    F32, F64,
    Bool,
    String,
    Type,
    
    // Operators
    Plus,
    Minus,
    Multiply,
    Divide,
    Modulo,
    Assign,
    Equal,
    NotEqual,
    Less,
    LessEqual,
    Greater,
    GreaterEqual,
    And,
    Or,
    Not,
    BitwiseAnd,
    BitwiseOr,
    BitwiseXor,
    BitwiseNot,
    LeftShift,
    RightShift,
    
    // Punctuation
    LeftParen,
    RightParen,
    LeftBrace,
    RightBrace,
    LeftBracket,
    RightBracket,
    Semicolon,
    Colon,
    Comma,
    Dot,
    Arrow,
    DoubleArrow,
    
    // Special
    Newline,
    Eof,
    Invalid
}

struct Token {
    var type: TokenType;
    var value: String;
    var line: i32;
    var column: i32;
}

class Lexer {
    var source: String;
    var position: i32;
    var line: i32;
    var column: i32;
    var tokens: Array(Token);
    
    fn Create(source: String) -> Self {
        return {
            .source = source,
            .position = 0,
            .line = 1,
            .column = 1,
            .tokens = Array(Token)()
        };
    }
    
    fn Tokenize(self: Self) -> Result(Array(Token), String) {
        while (self.position < self.source.Size()) {
            var result: Result(Token, String) = self.NextToken();
            if (not result.IsOk()) {
                return Result(Array(Token), String).Error(result.Error());
            }
            
            var token: Token = result.Value();
            if (token.type == TokenType.Eof) {
                self.tokens.Push(token);
                break;
            }
            
            if (token.type != TokenType.Invalid) {
                self.tokens.Push(token);
            }
        }
        
        return Result(Array(Token), String).Ok(self.tokens);
    }
    
    fn NextToken(self: Self) -> Result(Token, String) {
        self.SkipWhitespace();
        
        if (self.position >= self.source.Size()) {
            return Result(Token, String).Ok({
                .type = TokenType.Eof,
                .value = "",
                .line = self.line,
                .column = self.column
            });
        }
        
        var ch: i32 = self.source.At(self.position);
        var start_line: i32 = self.line;
        var start_column: i32 = self.column;
        
        // Single character tokens
        match (ch) {
            case ('(') {
                self.Advance();
                return Result(Token, String).Ok({
                    .type = TokenType.LeftParen,
                    .value = "(",
                    .line = start_line,
                    .column = start_column
                });
            }
            case (')') {
                self.Advance();
                return Result(Token, String).Ok({
                    .type = TokenType.RightParen,
                    .value = ")",
                    .line = start_line,
                    .column = start_column
                });
            }
            case ('{') {
                self.Advance();
                return Result(Token, String).Ok({
                    .type = TokenType.LeftBrace,
                    .value = "{",
                    .line = start_line,
                    .column = start_column
                });
            }
            case ('}') {
                self.Advance();
                return Result(Token, String).Ok({
                    .type = TokenType.RightBrace,
                    .value = "}",
                    .line = start_line,
                    .column = start_column
                });
            }
            case ('[') {
                self.Advance();
                return Result(Token, String).Ok({
                    .type = TokenType.LeftBracket,
                    .value = "[",
                    .line = start_line,
                    .column = start_column
                });
            }
            case (']') {
                self.Advance();
                return Result(Token, String).Ok({
                    .type = TokenType.RightBracket,
                    .value = "]",
                    .line = start_line,
                    .column = start_column
                });
            }
            case (';') {
                self.Advance();
                return Result(Token, String).Ok({
                    .type = TokenType.Semicolon,
                    .value = ";",
                    .line = start_line,
                    .column = start_column
                });
            }
            case (':') {
                self.Advance();
                return Result(Token, String).Ok({
                    .type = TokenType.Colon,
                    .value = ":",
                    .line = start_line,
                    .column = start_column
                });
            }
            case (',') {
                self.Advance();
                return Result(Token, String).Ok({
                    .type = TokenType.Comma,
                    .value = ",",
                    .line = start_line,
                    .column = start_column
                });
            }
            case ('.') {
                self.Advance();
                return Result(Token, String).Ok({
                    .type = TokenType.Dot,
                    .value = ".",
                    .line = start_line,
                    .column = start_column
                });
            }
            case ('+') {
                self.Advance();
                return Result(Token, String).Ok({
                    .type = TokenType.Plus,
                    .value = "+",
                    .line = start_line,
                    .column = start_column
                });
            }
            case ('-') {
                self.Advance();
                if (self.position < self.source.Size() and self.source.At(self.position) == '>') {
                    self.Advance();
                    return Result(Token, String).Ok({
                        .type = TokenType.Arrow,
                        .value = "->",
                        .line = start_line,
                        .column = start_column
                    });
                }
                return Result(Token, String).Ok({
                    .type = TokenType.Minus,
                    .value = "-",
                    .line = start_line,
                    .column = start_column
                });
            }
            case ('*') {
                self.Advance();
                return Result(Token, String).Ok({
                    .type = TokenType.Multiply,
                    .value = "*",
                    .line = start_line,
                    .column = start_column
                });
            }
            case ('/') {
                self.Advance();
                // Handle comments
                if (self.position < self.source.Size() and self.source.At(self.position) == '/') {
                    self.SkipLineComment();
                    return self.NextToken();
                }
                return Result(Token, String).Ok({
                    .type = TokenType.Divide,
                    .value = "/",
                    .line = start_line,
                    .column = start_column
                });
            }
            case ('=') {
                self.Advance();
                if (self.position < self.source.Size() and self.source.At(self.position) == '=') {
                    self.Advance();
                    return Result(Token, String).Ok({
                        .type = TokenType.Equal,
                        .value = "==",
                        .line = start_line,
                        .column = start_column
                    });
                }
                return Result(Token, String).Ok({
                    .type = TokenType.Assign,
                    .value = "=",
                    .line = start_line,
                    .column = start_column
                });
            }
            case ('!') {
                self.Advance();
                if (self.position < self.source.Size() and self.source.At(self.position) == '=') {
                    self.Advance();
                    return Result(Token, String).Ok({
                        .type = TokenType.NotEqual,
                        .value = "!=",
                        .line = start_line,
                        .column = start_column
                    });
                }
                return Result(Token, String).Ok({
                    .type = TokenType.Not,
                    .value = "!",
                    .line = start_line,
                    .column = start_column
                });
            }
            case ('<') {
                self.Advance();
                if (self.position < self.source.Size() and self.source.At(self.position) == '=') {
                    self.Advance();
                    return Result(Token, String).Ok({
                        .type = TokenType.LessEqual,
                        .value = "<=",
                        .line = start_line,
                        .column = start_column
                    });
                }
                return Result(Token, String).Ok({
                    .type = TokenType.Less,
                    .value = "<",
                    .line = start_line,
                    .column = start_column
                });
            }
            case ('>') {
                self.Advance();
                if (self.position < self.source.Size() and self.source.At(self.position) == '=') {
                    self.Advance();
                    return Result(Token, String).Ok({
                        .type = TokenType.GreaterEqual,
                        .value = ">=",
                        .line = start_line,
                        .column = start_column
                    });
                }
                return Result(Token, String).Ok({
                    .type = TokenType.Greater,
                    .value = ">",
                    .line = start_line,
                    .column = start_column
                });
            }
            case ('"') {
                return self.ReadString();
            }
            default {
                if (self.IsDigit(ch)) {
                    return self.ReadNumber();
                } else if (self.IsAlpha(ch)) {
                    return self.ReadIdentifier();
                } else {
                    return Result(Token, String).Error("Unexpected character: " + CharToString(ch));
                }
            }
        }
    }
    
    fn SkipWhitespace(self: Self) {
        while (self.position < self.source.Size()) {
            var ch: i32 = self.source.At(self.position);
            if (ch == ' ' or ch == '\t' or ch == '\r') {
                self.Advance();
            } else if (ch == '\n') {
                self.line += 1;
                self.column = 1;
                self.position += 1;
            } else {
                break;
            }
        }
    }
    
    fn SkipLineComment(self: Self) {
        while (self.position < self.source.Size() and self.source.At(self.position) != '\n') {
            self.Advance();
        }
    }
    
    fn ReadString(self: Self) -> Result(Token, String) {
        var start_line: i32 = self.line;
        var start_column: i32 = self.column;
        var value: String = "";
        
        self.Advance(); // Skip opening quote
        
        while (self.position < self.source.Size() and self.source.At(self.position) != '"') {
            var ch: i32 = self.source.At(self.position);
            if (ch == '\\') {
                self.Advance();
                if (self.position >= self.source.Size()) {
                    return Result(Token, String).Error("Unterminated string literal");
                }
                var escaped: i32 = self.source.At(self.position);
                match (escaped) {
                    case ('n') { value += "\n"; }
                    case ('t') { value += "\t"; }
                    case ('r') { value += "\r"; }
                    case ('\\') { value += "\\"; }
                    case ('"') { value += "\""; }
                    default { value += CharToString(escaped); }
                }
            } else {
                value += CharToString(ch);
            }
            self.Advance();
        }
        
        if (self.position >= self.source.Size()) {
            return Result(Token, String).Error("Unterminated string literal");
        }
        
        self.Advance(); // Skip closing quote
        
        return Result(Token, String).Ok({
            .type = TokenType.StringLiteral,
            .value = value,
            .line = start_line,
            .column = start_column
        });
    }
    
    fn ReadNumber(self: Self) -> Result(Token, String) {
        var start_line: i32 = self.line;
        var start_column: i32 = self.column;
        var value: String = "";
        var is_float: Bool = False;
        
        while (self.position < self.source.Size() and self.IsDigit(self.source.At(self.position))) {
            value += CharToString(self.source.At(self.position));
            self.Advance();
        }
        
        if (self.position < self.source.Size() and self.source.At(self.position) == '.') {
            is_float = True;
            value += ".";
            self.Advance();
            
            while (self.position < self.source.Size() and self.IsDigit(self.source.At(self.position))) {
                value += CharToString(self.source.At(self.position));
                self.Advance();
            }
        }
        
        return Result(Token, String).Ok({
            .type = is_float ? TokenType.FloatLiteral : TokenType.IntegerLiteral,
            .value = value,
            .line = start_line,
            .column = start_column
        });
    }
    
    fn ReadIdentifier(self: Self) -> Result(Token, String) {
        var start_line: i32 = self.line;
        var start_column: i32 = self.column;
        var value: String = "";
        
        while (self.position < self.source.Size() and 
               (self.IsAlpha(self.source.At(self.position)) or 
                self.IsDigit(self.source.At(self.position)) or 
                self.source.At(self.position) == '_')) {
            value += CharToString(self.source.At(self.position));
            self.Advance();
        }
        
        var token_type: TokenType = self.GetKeywordType(value);
        
        return Result(Token, String).Ok({
            .type = token_type,
            .value = value,
            .line = start_line,
            .column = start_column
        });
    }
    
    fn GetKeywordType(self: Self, value: String) -> TokenType {
        if (value == "package") { return TokenType.Package; }
        if (value == "import") { return TokenType.Import; }
        if (value == "api") { return TokenType.Api; }
        if (value == "impl") { return TokenType.Impl; }
        if (value == "library") { return TokenType.Library; }
        if (value == "fn") { return TokenType.Fn; }
        if (value == "var") { return TokenType.Var; }
        if (value == "let") { return TokenType.Let; }
        if (value == "if") { return TokenType.If; }
        if (value == "else") { return TokenType.Else; }
        if (value == "while") { return TokenType.While; }
        if (value == "for") { return TokenType.For; }
        if (value == "match") { return TokenType.Match; }
        if (value == "case") { return TokenType.Case; }
        if (value == "default") { return TokenType.Default; }
        if (value == "return") { return TokenType.Return; }
        if (value == "break") { return TokenType.Break; }
        if (value == "continue") { return TokenType.Continue; }
        if (value == "class") { return TokenType.Class; }
        if (value == "interface") { return TokenType.Interface; }
        if (value == "choice") { return TokenType.Choice; }
        if (value == "constraint") { return TokenType.Constraint; }
        if (value == "template") { return TokenType.Template; }
        if (value == "forall") { return TokenType.Forall; }
        if (value == "where") { return TokenType.Where; }
        if (value == "extends") { return TokenType.Extends; }
        if (value == "impls") { return TokenType.Impls; }
        if (value == "as") { return TokenType.As; }
        if (value == "auto") { return TokenType.Auto; }
        if (value == "Self") { return TokenType.Self; }
        if (value == "Base") { return TokenType.Base; }
        if (value == "i8") { return TokenType.I8; }
        if (value == "i16") { return TokenType.I16; }
        if (value == "i32") { return TokenType.I32; }
        if (value == "i64") { return TokenType.I64; }
        if (value == "u8") { return TokenType.U8; }
        if (value == "u16") { return TokenType.U16; }
        if (value == "u32") { return TokenType.U32; }
        if (value == "u64") { return TokenType.U64; }
        if (value == "f32") { return TokenType.F32; }
        if (value == "f64") { return TokenType.F64; }
        if (value == "Bool") { return TokenType.Bool; }
        if (value == "String") { return TokenType.String; }
        if (value == "Type") { return TokenType.Type; }
        if (value == "True" or value == "False") { return TokenType.BoolLiteral; }
        if (value == "and") { return TokenType.And; }
        if (value == "or") { return TokenType.Or; }
        if (value == "not") { return TokenType.Not; }
        
        return TokenType.Identifier;
    }
    
    fn IsDigit(self: Self, ch: i32) -> Bool {
        return ch >= '0' and ch <= '9';
    }
    
    fn IsAlpha(self: Self, ch: i32) -> Bool {
        return (ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z') or ch == '_';
    }
    
    fn Advance(self: Self) {
        self.position += 1;
        self.column += 1;
    }
}