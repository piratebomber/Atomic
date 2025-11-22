// Atomic Carbon Parser
package AtomicCompiler.Parser api;

import Std.Array;
import Std.String;
import AtomicCompiler.Lexer;

// AST Node types
choice ASTNodeType {
    Program,
    Package,
    Import,
    Function,
    Variable,
    Class,
    Interface,
    Choice,
    Struct,
    Block,
    Expression,
    Statement,
    Type,
    Parameter,
    Argument,
    Literal,
    Identifier,
    BinaryOp,
    UnaryOp,
    Call,
    Member,
    Index,
    If,
    While,
    For,
    Match,
    Case,
    Return,
    Break,
    Continue,
    Assignment
}

// Base AST node
struct ASTNode {
    var type: ASTNodeType;
    var line: i32;
    var column: i32;
    var children: Array(ASTNode);
    var value: String;
    var data_type: Optional(String);
}

// Parser class
class Parser {
    var tokens: Array(Token);
    var position: i32;
    var current_token: Token;
    
    fn Create(tokens: Array(Token)) -> Self {
        var parser: Self = {
            .tokens = tokens,
            .position = 0,
            .current_token = tokens[0]
        };
        return parser;
    }
    
    fn Parse(self: Self) -> Result(ASTNode, String) {
        return self.ParseProgram();
    }
    
    fn ParseProgram(self: Self) -> Result(ASTNode, String) {
        var program: ASTNode = {
            .type = ASTNodeType.Program,
            .line = 1,
            .column = 1,
            .children = Array(ASTNode)(),
            .value = "",
            .data_type = Optional(String).None()
        };
        
        while (not self.IsAtEnd()) {
            var decl_result: Result(ASTNode, String) = self.ParseDeclaration();
            if (not decl_result.IsOk()) {
                return decl_result;
            }
            program.children.Push(decl_result.Value());
        }
        
        return Result(ASTNode, String).Ok(program);
    }
    
    fn ParseDeclaration(self: Self) -> Result(ASTNode, String) {
        match (self.current_token.type) {
            case (TokenType.Package) {
                return self.ParsePackage();
            }
            case (TokenType.Import) {
                return self.ParseImport();
            }
            case (TokenType.Fn) {
                return self.ParseFunction();
            }
            case (TokenType.Class) {
                return self.ParseClass();
            }
            case (TokenType.Interface) {
                return self.ParseInterface();
            }
            case (TokenType.Choice) {
                return self.ParseChoice();
            }
            case (TokenType.Var) {
                return self.ParseVariable();
            }
            default {
                return Result(ASTNode, String).Error("Unexpected token: " + self.current_token.value);
            }
        }
    }
    
    fn ParsePackage(self: Self) -> Result(ASTNode, String) {
        var package_node: ASTNode = {
            .type = ASTNodeType.Package,
            .line = self.current_token.line,
            .column = self.current_token.column,
            .children = Array(ASTNode)(),
            .value = "",
            .data_type = Optional(String).None()
        };
        
        self.Advance(); // consume 'package'
        
        if (self.current_token.type != TokenType.Identifier) {
            return Result(ASTNode, String).Error("Expected package name");
        }
        
        package_node.value = self.current_token.value;
        self.Advance();
        
        if (self.current_token.type == TokenType.Api) {
            self.Advance(); // consume 'api'
        } else if (self.current_token.type == TokenType.Impl) {
            self.Advance(); // consume 'impl'
        }
        
        if (self.current_token.type == TokenType.Semicolon) {
            self.Advance();
        }
        
        return Result(ASTNode, String).Ok(package_node);
    }
    
    fn ParseImport(self: Self) -> Result(ASTNode, String) {
        var import_node: ASTNode = {
            .type = ASTNodeType.Import,
            .line = self.current_token.line,
            .column = self.current_token.column,
            .children = Array(ASTNode)(),
            .value = "",
            .data_type = Optional(String).None()
        };
        
        self.Advance(); // consume 'import'
        
        var import_path: String = "";
        while (self.current_token.type == TokenType.Identifier) {
            import_path += self.current_token.value;
            self.Advance();
            
            if (self.current_token.type == TokenType.Dot) {
                import_path += ".";
                self.Advance();
            } else {
                break;
            }
        }
        
        import_node.value = import_path;
        
        if (self.current_token.type == TokenType.Semicolon) {
            self.Advance();
        }
        
        return Result(ASTNode, String).Ok(import_node);
    }
    
    fn ParseFunction(self: Self) -> Result(ASTNode, String) {
        var func_node: ASTNode = {
            .type = ASTNodeType.Function,
            .line = self.current_token.line,
            .column = self.current_token.column,
            .children = Array(ASTNode)(),
            .value = "",
            .data_type = Optional(String).None()
        };
        
        self.Advance(); // consume 'fn'
        
        if (self.current_token.type != TokenType.Identifier) {
            return Result(ASTNode, String).Error("Expected function name");
        }
        
        func_node.value = self.current_token.value;
        self.Advance();
        
        // Parse parameters
        if (self.current_token.type != TokenType.LeftParen) {
            return Result(ASTNode, String).Error("Expected '(' after function name");
        }
        self.Advance();
        
        while (self.current_token.type != TokenType.RightParen and not self.IsAtEnd()) {
            var param_result: Result(ASTNode, String) = self.ParseParameter();
            if (not param_result.IsOk()) {
                return param_result;
            }
            func_node.children.Push(param_result.Value());
            
            if (self.current_token.type == TokenType.Comma) {
                self.Advance();
            }
        }
        
        if (self.current_token.type != TokenType.RightParen) {
            return Result(ASTNode, String).Error("Expected ')' after parameters");
        }
        self.Advance();
        
        // Parse return type
        if (self.current_token.type == TokenType.Arrow) {
            self.Advance();
            var return_type_result: Result(ASTNode, String) = self.ParseType();
            if (not return_type_result.IsOk()) {
                return return_type_result;
            }
            func_node.data_type = Optional(String).Some(return_type_result.Value().value);
        }
        
        // Parse function body
        var body_result: Result(ASTNode, String) = self.ParseBlock();
        if (not body_result.IsOk()) {
            return body_result;
        }
        func_node.children.Push(body_result.Value());
        
        return Result(ASTNode, String).Ok(func_node);
    }
    
    fn ParseParameter(self: Self) -> Result(ASTNode, String) {
        var param_node: ASTNode = {
            .type = ASTNodeType.Parameter,
            .line = self.current_token.line,
            .column = self.current_token.column,
            .children = Array(ASTNode)(),
            .value = "",
            .data_type = Optional(String).None()
        };
        
        if (self.current_token.type != TokenType.Identifier) {
            return Result(ASTNode, String).Error("Expected parameter name");
        }
        
        param_node.value = self.current_token.value;
        self.Advance();
        
        if (self.current_token.type != TokenType.Colon) {
            return Result(ASTNode, String).Error("Expected ':' after parameter name");
        }
        self.Advance();
        
        var type_result: Result(ASTNode, String) = self.ParseType();
        if (not type_result.IsOk()) {
            return type_result;
        }
        param_node.data_type = Optional(String).Some(type_result.Value().value);
        
        return Result(ASTNode, String).Ok(param_node);
    }
    
    fn ParseType(self: Self) -> Result(ASTNode, String) {
        var type_node: ASTNode = {
            .type = ASTNodeType.Type,
            .line = self.current_token.line,
            .column = self.current_token.column,
            .children = Array(ASTNode)(),
            .value = "",
            .data_type = Optional(String).None()
        };
        
        // Handle basic types
        if (self.IsTypeToken(self.current_token.type)) {
            type_node.value = self.current_token.value;
            self.Advance();
        } else if (self.current_token.type == TokenType.Identifier) {
            // Custom type
            type_node.value = self.current_token.value;
            self.Advance();
            
            // Handle generic types
            if (self.current_token.type == TokenType.LeftParen) {
                self.Advance();
                while (self.current_token.type != TokenType.RightParen and not self.IsAtEnd()) {
                    var generic_type_result: Result(ASTNode, String) = self.ParseType();
                    if (not generic_type_result.IsOk()) {
                        return generic_type_result;
                    }
                    type_node.children.Push(generic_type_result.Value());
                    
                    if (self.current_token.type == TokenType.Comma) {
                        self.Advance();
                    }
                }
                
                if (self.current_token.type != TokenType.RightParen) {
                    return Result(ASTNode, String).Error("Expected ')' after generic type parameters");
                }
                self.Advance();
            }
        } else {
            return Result(ASTNode, String).Error("Expected type");
        }
        
        return Result(ASTNode, String).Ok(type_node);
    }
    
    fn ParseBlock(self: Self) -> Result(ASTNode, String) {
        var block_node: ASTNode = {
            .type = ASTNodeType.Block,
            .line = self.current_token.line,
            .column = self.current_token.column,
            .children = Array(ASTNode)(),
            .value = "",
            .data_type = Optional(String).None()
        };
        
        if (self.current_token.type != TokenType.LeftBrace) {
            return Result(ASTNode, String).Error("Expected '{'");
        }
        self.Advance();
        
        while (self.current_token.type != TokenType.RightBrace and not self.IsAtEnd()) {
            var stmt_result: Result(ASTNode, String) = self.ParseStatement();
            if (not stmt_result.IsOk()) {
                return stmt_result;
            }
            block_node.children.Push(stmt_result.Value());
        }
        
        if (self.current_token.type != TokenType.RightBrace) {
            return Result(ASTNode, String).Error("Expected '}'");
        }
        self.Advance();
        
        return Result(ASTNode, String).Ok(block_node);
    }
    
    fn ParseStatement(self: Self) -> Result(ASTNode, String) {
        match (self.current_token.type) {
            case (TokenType.Var) {
                return self.ParseVariable();
            }
            case (TokenType.If) {
                return self.ParseIf();
            }
            case (TokenType.While) {
                return self.ParseWhile();
            }
            case (TokenType.For) {
                return self.ParseFor();
            }
            case (TokenType.Match) {
                return self.ParseMatch();
            }
            case (TokenType.Return) {
                return self.ParseReturn();
            }
            case (TokenType.Break) {
                return self.ParseBreak();
            }
            case (TokenType.Continue) {
                return self.ParseContinue();
            }
            case (TokenType.LeftBrace) {
                return self.ParseBlock();
            }
            default {
                return self.ParseExpressionStatement();
            }
        }
    }
    
    fn ParseVariable(self: Self) -> Result(ASTNode, String) {
        var var_node: ASTNode = {
            .type = ASTNodeType.Variable,
            .line = self.current_token.line,
            .column = self.current_token.column,
            .children = Array(ASTNode)(),
            .value = "",
            .data_type = Optional(String).None()
        };
        
        self.Advance(); // consume 'var'
        
        if (self.current_token.type != TokenType.Identifier) {
            return Result(ASTNode, String).Error("Expected variable name");
        }
        
        var_node.value = self.current_token.value;
        self.Advance();
        
        if (self.current_token.type == TokenType.Colon) {
            self.Advance();
            var type_result: Result(ASTNode, String) = self.ParseType();
            if (not type_result.IsOk()) {
                return type_result;
            }
            var_node.data_type = Optional(String).Some(type_result.Value().value);
        }
        
        if (self.current_token.type == TokenType.Assign) {
            self.Advance();
            var expr_result: Result(ASTNode, String) = self.ParseExpression();
            if (not expr_result.IsOk()) {
                return expr_result;
            }
            var_node.children.Push(expr_result.Value());
        }
        
        if (self.current_token.type == TokenType.Semicolon) {
            self.Advance();
        }
        
        return Result(ASTNode, String).Ok(var_node);
    }
    
    fn ParseExpression(self: Self) -> Result(ASTNode, String) {
        return self.ParseLogicalOr();
    }
    
    fn ParseLogicalOr(self: Self) -> Result(ASTNode, String) {
        var left_result: Result(ASTNode, String) = self.ParseLogicalAnd();
        if (not left_result.IsOk()) {
            return left_result;
        }
        var left: ASTNode = left_result.Value();
        
        while (self.current_token.type == TokenType.Or) {
            var op: String = self.current_token.value;
            self.Advance();
            
            var right_result: Result(ASTNode, String) = self.ParseLogicalAnd();
            if (not right_result.IsOk()) {
                return right_result;
            }
            
            var binary_op: ASTNode = {
                .type = ASTNodeType.BinaryOp,
                .line = self.current_token.line,
                .column = self.current_token.column,
                .children = Array(ASTNode)(),
                .value = op,
                .data_type = Optional(String).None()
            };
            binary_op.children.Push(left);
            binary_op.children.Push(right_result.Value());
            left = binary_op;
        }
        
        return Result(ASTNode, String).Ok(left);
    }
    
    fn ParseLogicalAnd(self: Self) -> Result(ASTNode, String) {
        var left_result: Result(ASTNode, String) = self.ParseEquality();
        if (not left_result.IsOk()) {
            return left_result;
        }
        var left: ASTNode = left_result.Value();
        
        while (self.current_token.type == TokenType.And) {
            var op: String = self.current_token.value;
            self.Advance();
            
            var right_result: Result(ASTNode, String) = self.ParseEquality();
            if (not right_result.IsOk()) {
                return right_result;
            }
            
            var binary_op: ASTNode = {
                .type = ASTNodeType.BinaryOp,
                .line = self.current_token.line,
                .column = self.current_token.column,
                .children = Array(ASTNode)(),
                .value = op,
                .data_type = Optional(String).None()
            };
            binary_op.children.Push(left);
            binary_op.children.Push(right_result.Value());
            left = binary_op;
        }
        
        return Result(ASTNode, String).Ok(left);
    }
    
    fn ParseEquality(self: Self) -> Result(ASTNode, String) {
        var left_result: Result(ASTNode, String) = self.ParseComparison();
        if (not left_result.IsOk()) {
            return left_result;
        }
        var left: ASTNode = left_result.Value();
        
        while (self.current_token.type == TokenType.Equal or self.current_token.type == TokenType.NotEqual) {
            var op: String = self.current_token.value;
            self.Advance();
            
            var right_result: Result(ASTNode, String) = self.ParseComparison();
            if (not right_result.IsOk()) {
                return right_result;
            }
            
            var binary_op: ASTNode = {
                .type = ASTNodeType.BinaryOp,
                .line = self.current_token.line,
                .column = self.current_token.column,
                .children = Array(ASTNode)(),
                .value = op,
                .data_type = Optional(String).None()
            };
            binary_op.children.Push(left);
            binary_op.children.Push(right_result.Value());
            left = binary_op;
        }
        
        return Result(ASTNode, String).Ok(left);
    }
    
    fn ParseComparison(self: Self) -> Result(ASTNode, String) {
        var left_result: Result(ASTNode, String) = self.ParseTerm();
        if (not left_result.IsOk()) {
            return left_result;
        }
        var left: ASTNode = left_result.Value();
        
        while (self.current_token.type == TokenType.Less or 
               self.current_token.type == TokenType.LessEqual or
               self.current_token.type == TokenType.Greater or
               self.current_token.type == TokenType.GreaterEqual) {
            var op: String = self.current_token.value;
            self.Advance();
            
            var right_result: Result(ASTNode, String) = self.ParseTerm();
            if (not right_result.IsOk()) {
                return right_result;
            }
            
            var binary_op: ASTNode = {
                .type = ASTNodeType.BinaryOp,
                .line = self.current_token.line,
                .column = self.current_token.column,
                .children = Array(ASTNode)(),
                .value = op,
                .data_type = Optional(String).None()
            };
            binary_op.children.Push(left);
            binary_op.children.Push(right_result.Value());
            left = binary_op;
        }
        
        return Result(ASTNode, String).Ok(left);
    }
    
    fn ParseTerm(self: Self) -> Result(ASTNode, String) {
        var left_result: Result(ASTNode, String) = self.ParseFactor();
        if (not left_result.IsOk()) {
            return left_result;
        }
        var left: ASTNode = left_result.Value();
        
        while (self.current_token.type == TokenType.Plus or self.current_token.type == TokenType.Minus) {
            var op: String = self.current_token.value;
            self.Advance();
            
            var right_result: Result(ASTNode, String) = self.ParseFactor();
            if (not right_result.IsOk()) {
                return right_result;
            }
            
            var binary_op: ASTNode = {
                .type = ASTNodeType.BinaryOp,
                .line = self.current_token.line,
                .column = self.current_token.column,
                .children = Array(ASTNode)(),
                .value = op,
                .data_type = Optional(String).None()
            };
            binary_op.children.Push(left);
            binary_op.children.Push(right_result.Value());
            left = binary_op;
        }
        
        return Result(ASTNode, String).Ok(left);
    }
    
    fn ParseFactor(self: Self) -> Result(ASTNode, String) {
        var left_result: Result(ASTNode, String) = self.ParseUnary();
        if (not left_result.IsOk()) {
            return left_result;
        }
        var left: ASTNode = left_result.Value();
        
        while (self.current_token.type == TokenType.Multiply or self.current_token.type == TokenType.Divide) {
            var op: String = self.current_token.value;
            self.Advance();
            
            var right_result: Result(ASTNode, String) = self.ParseUnary();
            if (not right_result.IsOk()) {
                return right_result;
            }
            
            var binary_op: ASTNode = {
                .type = ASTNodeType.BinaryOp,
                .line = self.current_token.line,
                .column = self.current_token.column,
                .children = Array(ASTNode)(),
                .value = op,
                .data_type = Optional(String).None()
            };
            binary_op.children.Push(left);
            binary_op.children.Push(right_result.Value());
            left = binary_op;
        }
        
        return Result(ASTNode, String).Ok(left);
    }
    
    fn ParseUnary(self: Self) -> Result(ASTNode, String) {
        if (self.current_token.type == TokenType.Not or self.current_token.type == TokenType.Minus) {
            var op: String = self.current_token.value;
            var line: i32 = self.current_token.line;
            var column: i32 = self.current_token.column;
            self.Advance();
            
            var expr_result: Result(ASTNode, String) = self.ParseUnary();
            if (not expr_result.IsOk()) {
                return expr_result;
            }
            
            var unary_op: ASTNode = {
                .type = ASTNodeType.UnaryOp,
                .line = line,
                .column = column,
                .children = Array(ASTNode)(),
                .value = op,
                .data_type = Optional(String).None()
            };
            unary_op.children.Push(expr_result.Value());
            
            return Result(ASTNode, String).Ok(unary_op);
        }
        
        return self.ParsePrimary();
    }
    
    fn ParsePrimary(self: Self) -> Result(ASTNode, String) {
        match (self.current_token.type) {
            case (TokenType.IntegerLiteral) {
                var literal: ASTNode = {
                    .type = ASTNodeType.Literal,
                    .line = self.current_token.line,
                    .column = self.current_token.column,
                    .children = Array(ASTNode)(),
                    .value = self.current_token.value,
                    .data_type = Optional(String).Some("i32")
                };
                self.Advance();
                return Result(ASTNode, String).Ok(literal);
            }
            case (TokenType.FloatLiteral) {
                var literal: ASTNode = {
                    .type = ASTNodeType.Literal,
                    .line = self.current_token.line,
                    .column = self.current_token.column,
                    .children = Array(ASTNode)(),
                    .value = self.current_token.value,
                    .data_type = Optional(String).Some("f64")
                };
                self.Advance();
                return Result(ASTNode, String).Ok(literal);
            }
            case (TokenType.StringLiteral) {
                var literal: ASTNode = {
                    .type = ASTNodeType.Literal,
                    .line = self.current_token.line,
                    .column = self.current_token.column,
                    .children = Array(ASTNode)(),
                    .value = self.current_token.value,
                    .data_type = Optional(String).Some("String")
                };
                self.Advance();
                return Result(ASTNode, String).Ok(literal);
            }
            case (TokenType.BoolLiteral) {
                var literal: ASTNode = {
                    .type = ASTNodeType.Literal,
                    .line = self.current_token.line,
                    .column = self.current_token.column,
                    .children = Array(ASTNode)(),
                    .value = self.current_token.value,
                    .data_type = Optional(String).Some("Bool")
                };
                self.Advance();
                return Result(ASTNode, String).Ok(literal);
            }
            case (TokenType.Identifier) {
                var identifier: ASTNode = {
                    .type = ASTNodeType.Identifier,
                    .line = self.current_token.line,
                    .column = self.current_token.column,
                    .children = Array(ASTNode)(),
                    .value = self.current_token.value,
                    .data_type = Optional(String).None()
                };
                self.Advance();
                
                // Handle function calls, member access, etc.
                while (True) {
                    if (self.current_token.type == TokenType.LeftParen) {
                        // Function call
                        var call_result: Result(ASTNode, String) = self.ParseCall(identifier);
                        if (not call_result.IsOk()) {
                            return call_result;
                        }
                        identifier = call_result.Value();
                    } else if (self.current_token.type == TokenType.Dot) {
                        // Member access
                        var member_result: Result(ASTNode, String) = self.ParseMember(identifier);
                        if (not member_result.IsOk()) {
                            return member_result;
                        }
                        identifier = member_result.Value();
                    } else if (self.current_token.type == TokenType.LeftBracket) {
                        // Array/index access
                        var index_result: Result(ASTNode, String) = self.ParseIndex(identifier);
                        if (not index_result.IsOk()) {
                            return index_result;
                        }
                        identifier = index_result.Value();
                    } else {
                        break;
                    }
                }
                
                return Result(ASTNode, String).Ok(identifier);
            }
            case (TokenType.LeftParen) {
                self.Advance();
                var expr_result: Result(ASTNode, String) = self.ParseExpression();
                if (not expr_result.IsOk()) {
                    return expr_result;
                }
                
                if (self.current_token.type != TokenType.RightParen) {
                    return Result(ASTNode, String).Error("Expected ')' after expression");
                }
                self.Advance();
                
                return expr_result;
            }
            default {
                return Result(ASTNode, String).Error("Unexpected token in expression: " + self.current_token.value);
            }
        }
    }
    
    fn ParseCall(self: Self, callee: ASTNode) -> Result(ASTNode, String) {
        var call_node: ASTNode = {
            .type = ASTNodeType.Call,
            .line = callee.line,
            .column = callee.column,
            .children = Array(ASTNode)(),
            .value = "",
            .data_type = Optional(String).None()
        };
        
        call_node.children.Push(callee);
        
        self.Advance(); // consume '('
        
        while (self.current_token.type != TokenType.RightParen and not self.IsAtEnd()) {
            var arg_result: Result(ASTNode, String) = self.ParseExpression();
            if (not arg_result.IsOk()) {
                return arg_result;
            }
            call_node.children.Push(arg_result.Value());
            
            if (self.current_token.type == TokenType.Comma) {
                self.Advance();
            }
        }
        
        if (self.current_token.type != TokenType.RightParen) {
            return Result(ASTNode, String).Error("Expected ')' after function arguments");
        }
        self.Advance();
        
        return Result(ASTNode, String).Ok(call_node);
    }
    
    fn ParseMember(self: Self, object: ASTNode) -> Result(ASTNode, String) {
        var member_node: ASTNode = {
            .type = ASTNodeType.Member,
            .line = object.line,
            .column = object.column,
            .children = Array(ASTNode)(),
            .value = "",
            .data_type = Optional(String).None()
        };
        
        member_node.children.Push(object);
        
        self.Advance(); // consume '.'
        
        if (self.current_token.type != TokenType.Identifier) {
            return Result(ASTNode, String).Error("Expected member name after '.'");
        }
        
        var member_name: ASTNode = {
            .type = ASTNodeType.Identifier,
            .line = self.current_token.line,
            .column = self.current_token.column,
            .children = Array(ASTNode)(),
            .value = self.current_token.value,
            .data_type = Optional(String).None()
        };
        
        member_node.children.Push(member_name);
        self.Advance();
        
        return Result(ASTNode, String).Ok(member_node);
    }
    
    fn ParseIndex(self: Self, array: ASTNode) -> Result(ASTNode, String) {
        var index_node: ASTNode = {
            .type = ASTNodeType.Index,
            .line = array.line,
            .column = array.column,
            .children = Array(ASTNode)(),
            .value = "",
            .data_type = Optional(String).None()
        };
        
        index_node.children.Push(array);
        
        self.Advance(); // consume '['
        
        var index_expr_result: Result(ASTNode, String) = self.ParseExpression();
        if (not index_expr_result.IsOk()) {
            return index_expr_result;
        }
        index_node.children.Push(index_expr_result.Value());
        
        if (self.current_token.type != TokenType.RightBracket) {
            return Result(ASTNode, String).Error("Expected ']' after array index");
        }
        self.Advance();
        
        return Result(ASTNode, String).Ok(index_node);
    }
    
    fn ParseExpressionStatement(self: Self) -> Result(ASTNode, String) {
        var expr_result: Result(ASTNode, String) = self.ParseExpression();
        if (not expr_result.IsOk()) {
            return expr_result;
        }
        
        if (self.current_token.type == TokenType.Semicolon) {
            self.Advance();
        }
        
        return expr_result;
    }
    
    fn ParseReturn(self: Self) -> Result(ASTNode, String) {
        var return_node: ASTNode = {
            .type = ASTNodeType.Return,
            .line = self.current_token.line,
            .column = self.current_token.column,
            .children = Array(ASTNode)(),
            .value = "",
            .data_type = Optional(String).None()
        };
        
        self.Advance(); // consume 'return'
        
        if (self.current_token.type != TokenType.Semicolon and not self.IsAtEnd()) {
            var expr_result: Result(ASTNode, String) = self.ParseExpression();
            if (not expr_result.IsOk()) {
                return expr_result;
            }
            return_node.children.Push(expr_result.Value());
        }
        
        if (self.current_token.type == TokenType.Semicolon) {
            self.Advance();
        }
        
        return Result(ASTNode, String).Ok(return_node);
    }
    
    fn ParseBreak(self: Self) -> Result(ASTNode, String) {
        var break_node: ASTNode = {
            .type = ASTNodeType.Break,
            .line = self.current_token.line,
            .column = self.current_token.column,
            .children = Array(ASTNode)(),
            .value = "",
            .data_type = Optional(String).None()
        };
        
        self.Advance(); // consume 'break'
        
        if (self.current_token.type == TokenType.Semicolon) {
            self.Advance();
        }
        
        return Result(ASTNode, String).Ok(break_node);
    }
    
    fn ParseContinue(self: Self) -> Result(ASTNode, String) {
        var continue_node: ASTNode = {
            .type = ASTNodeType.Continue,
            .line = self.current_token.line,
            .column = self.current_token.column,
            .children = Array(ASTNode)(),
            .value = "",
            .data_type = Optional(String).None()
        };
        
        self.Advance(); // consume 'continue'
        
        if (self.current_token.type == TokenType.Semicolon) {
            self.Advance();
        }
        
        return Result(ASTNode, String).Ok(continue_node);
    }
    
    // Utility methods
    fn Advance(self: Self) {
        if (not self.IsAtEnd()) {
            self.position += 1;
            if (self.position < self.tokens.Size()) {
                self.current_token = self.tokens[self.position];
            }
        }
    }
    
    fn IsAtEnd(self: Self) -> Bool {
        return self.position >= self.tokens.Size() or self.current_token.type == TokenType.Eof;
    }
    
    fn IsTypeToken(self: Self, token_type: TokenType) -> Bool {
        return token_type == TokenType.I8 or token_type == TokenType.I16 or
               token_type == TokenType.I32 or token_type == TokenType.I64 or
               token_type == TokenType.U8 or token_type == TokenType.U16 or
               token_type == TokenType.U32 or token_type == TokenType.U64 or
               token_type == TokenType.F32 or token_type == TokenType.F64 or
               token_type == TokenType.Bool or token_type == TokenType.String;
    }
}