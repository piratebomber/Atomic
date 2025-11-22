// Atomic Carbon Semantic Analyzer
package AtomicCompiler.Semantic api;

import Std.Array;
import Std.String;
import Std.Map;
import AtomicCompiler.Parser;

// Symbol types
choice SymbolType {
    Variable,
    Function,
    Class,
    Interface,
    Choice,
    Struct,
    Parameter,
    Field,
    Method,
    Constructor,
    Destructor,
    Namespace,
    Template,
    Alias
}

// Symbol information
struct Symbol {
    var name: String;
    var type: SymbolType;
    var data_type: String;
    var scope_level: i32;
    var line: i32;
    var column: i32;
    var is_mutable: Bool;
    var is_public: Bool;
    var is_static: Bool;
    var is_virtual: Bool;
    var is_abstract: Bool;
    var parameters: Array(Symbol);
    var return_type: String;
    var parent_scope: Optional(String);
}

// Scope management
class SymbolTable {
    var symbols: Map(String, Symbol);
    var scopes: Array(String);
    var current_scope: String;
    var scope_counter: i32;
    
    fn Create() -> Self {
        var table: Self = {
            .symbols = Map(String, Symbol)(),
            .scopes = Array(String)(),
            .current_scope = "global",
            .scope_counter = 0
        };
        table.scopes.Push("global");
        return table;
    }
    
    fn EnterScope(self: Self, scope_name: String) {
        var full_scope: String = self.current_scope + "::" + scope_name + IntToString(self.scope_counter);
        self.scope_counter += 1;
        self.scopes.Push(full_scope);
        self.current_scope = full_scope;
    }
    
    fn ExitScope(self: Self) {
        if (self.scopes.Size() > 1) {
            self.scopes.Pop();
            self.current_scope = self.scopes[self.scopes.Size() - 1];
        }
    }
    
    fn AddSymbol(self: Self, symbol: Symbol) -> Result(Bool, String) {
        var full_name: String = self.current_scope + "::" + symbol.name;
        
        // Check for redefinition in current scope
        if (self.symbols.Contains(full_name)) {
            return Result(Bool, String).Error("Symbol '" + symbol.name + "' already defined in current scope");
        }
        
        var new_symbol: Symbol = symbol;
        new_symbol.parent_scope = Optional(String).Some(self.current_scope);
        self.symbols.Insert(full_name, new_symbol);
        
        return Result(Bool, String).Ok(True);
    }
    
    fn LookupSymbol(self: Self, name: String) -> Optional(Symbol) {
        // Search from current scope up to global
        var i: i32 = self.scopes.Size() - 1;
        while (i >= 0) {
            var full_name: String = self.scopes[i] + "::" + name;
            if (self.symbols.Contains(full_name)) {
                return Optional(Symbol).Some(self.symbols.Get(full_name));
            }
            i -= 1;
        }
        return Optional(Symbol).None();
    }
    
    fn GetCurrentScope(self: Self) -> String {
        return self.current_scope;
    }
}

// Type system
class TypeChecker {
    var built_in_types: Map(String, TypeInfo);
    var user_types: Map(String, TypeInfo);
    
    fn Create() -> Self {
        var checker: Self = {
            .built_in_types = Map(String, TypeInfo)(),
            .user_types = Map(String, TypeInfo)()
        };
        checker.InitializeBuiltInTypes();
        return checker;
    }
    
    fn InitializeBuiltInTypes(self: Self) {
        // Integer types
        self.built_in_types.Insert("i8", {.name = "i8", .size = 1, .is_signed = True, .is_numeric = True});
        self.built_in_types.Insert("i16", {.name = "i16", .size = 2, .is_signed = True, .is_numeric = True});
        self.built_in_types.Insert("i32", {.name = "i32", .size = 4, .is_signed = True, .is_numeric = True});
        self.built_in_types.Insert("i64", {.name = "i64", .size = 8, .is_signed = True, .is_numeric = True});
        
        // Unsigned integer types
        self.built_in_types.Insert("u8", {.name = "u8", .size = 1, .is_signed = False, .is_numeric = True});
        self.built_in_types.Insert("u16", {.name = "u16", .size = 2, .is_signed = False, .is_numeric = True});
        self.built_in_types.Insert("u32", {.name = "u32", .size = 4, .is_signed = False, .is_numeric = True});
        self.built_in_types.Insert("u64", {.name = "u64", .size = 8, .is_signed = False, .is_numeric = True});
        
        // Floating point types
        self.built_in_types.Insert("f32", {.name = "f32", .size = 4, .is_signed = True, .is_numeric = True});
        self.built_in_types.Insert("f64", {.name = "f64", .size = 8, .is_signed = True, .is_numeric = True});
        
        // Other types
        self.built_in_types.Insert("Bool", {.name = "Bool", .size = 1, .is_signed = False, .is_numeric = False});
        self.built_in_types.Insert("String", {.name = "String", .size = 8, .is_signed = False, .is_numeric = False});
        self.built_in_types.Insert("Void", {.name = "Void", .size = 0, .is_signed = False, .is_numeric = False});
    }
    
    fn IsValidType(self: Self, type_name: String) -> Bool {
        return self.built_in_types.Contains(type_name) or self.user_types.Contains(type_name);
    }
    
    fn GetTypeInfo(self: Self, type_name: String) -> Optional(TypeInfo) {
        if (self.built_in_types.Contains(type_name)) {
            return Optional(TypeInfo).Some(self.built_in_types.Get(type_name));
        }
        if (self.user_types.Contains(type_name)) {
            return Optional(TypeInfo).Some(self.user_types.Get(type_name));
        }
        return Optional(TypeInfo).None();
    }
    
    fn CanImplicitlyConvert(self: Self, from_type: String, to_type: String) -> Bool {
        if (from_type == to_type) { return True; }
        
        // Numeric conversions
        var from_info_opt: Optional(TypeInfo) = self.GetTypeInfo(from_type);
        var to_info_opt: Optional(TypeInfo) = self.GetTypeInfo(to_type);
        
        if (from_info_opt.HasValue() and to_info_opt.HasValue()) {
            var from_info: TypeInfo = from_info_opt.Value();
            var to_info: TypeInfo = to_info_opt.Value();
            
            if (from_info.is_numeric and to_info.is_numeric) {
                // Allow widening conversions
                if (from_info.size <= to_info.size) {
                    return True;
                }
            }
        }
        
        return False;
    }
    
    fn GetCommonType(self: Self, type1: String, type2: String) -> Optional(String) {
        if (type1 == type2) {
            return Optional(String).Some(type1);
        }
        
        // Find common numeric type
        var info1_opt: Optional(TypeInfo) = self.GetTypeInfo(type1);
        var info2_opt: Optional(TypeInfo) = self.GetTypeInfo(type2);
        
        if (info1_opt.HasValue() and info2_opt.HasValue()) {
            var info1: TypeInfo = info1_opt.Value();
            var info2: TypeInfo = info2_opt.Value();
            
            if (info1.is_numeric and info2.is_numeric) {
                // Return the larger type
                if (info1.size >= info2.size) {
                    return Optional(String).Some(type1);
                } else {
                    return Optional(String).Some(type2);
                }
            }
        }
        
        return Optional(String).None();
    }
    
    fn AddUserType(self: Self, type_info: TypeInfo) {
        self.user_types.Insert(type_info.name, type_info);
    }
}

struct TypeInfo {
    var name: String;
    var size: i32;
    var is_signed: Bool;
    var is_numeric: Bool;
}

// Main semantic analyzer
class SemanticAnalyzer {
    var symbol_table: SymbolTable;
    var type_checker: TypeChecker;
    var errors: Array(String);
    var warnings: Array(String);
    var current_function: Optional(String);
    var current_class: Optional(String);
    
    fn Create() -> Self {
        return {
            .symbol_table = SymbolTable.Create(),
            .type_checker = TypeChecker.Create(),
            .errors = Array(String)(),
            .warnings = Array(String)(),
            .current_function = Optional(String).None(),
            .current_class = Optional(String).None()
        };
    }
    
    fn Analyze(self: Self, ast: ASTNode) -> Result(ASTNode, String) {
        self.errors.Clear();
        self.warnings.Clear();
        
        var result: Result(ASTNode, String) = self.AnalyzeNode(ast);
        
        if (self.errors.Size() > 0) {
            var error_msg: String = "Semantic errors:\n";
            var i: i32 = 0;
            while (i < self.errors.Size()) {
                error_msg += self.errors[i] + "\n";
                i += 1;
            }
            return Result(ASTNode, String).Error(error_msg);
        }
        
        return result;
    }
    
    fn AnalyzeNode(self: Self, node: ASTNode) -> Result(ASTNode, String) {
        match (node.type) {
            case (ASTNodeType.Program) {
                return self.AnalyzeProgram(node);
            }
            case (ASTNodeType.Package) {
                return self.AnalyzePackage(node);
            }
            case (ASTNodeType.Import) {
                return self.AnalyzeImport(node);
            }
            case (ASTNodeType.Function) {
                return self.AnalyzeFunction(node);
            }
            case (ASTNodeType.Variable) {
                return self.AnalyzeVariable(node);
            }
            case (ASTNodeType.Class) {
                return self.AnalyzeClass(node);
            }
            case (ASTNodeType.Block) {
                return self.AnalyzeBlock(node);
            }
            case (ASTNodeType.Expression) {
                return self.AnalyzeExpression(node);
            }
            case (ASTNodeType.BinaryOp) {
                return self.AnalyzeBinaryOp(node);
            }
            case (ASTNodeType.UnaryOp) {
                return self.AnalyzeUnaryOp(node);
            }
            case (ASTNodeType.Call) {
                return self.AnalyzeCall(node);
            }
            case (ASTNodeType.Identifier) {
                return self.AnalyzeIdentifier(node);
            }
            case (ASTNodeType.Literal) {
                return self.AnalyzeLiteral(node);
            }
            case (ASTNodeType.If) {
                return self.AnalyzeIf(node);
            }
            case (ASTNodeType.While) {
                return self.AnalyzeWhile(node);
            }
            case (ASTNodeType.Return) {
                return self.AnalyzeReturn(node);
            }
            default {
                // Analyze children
                var analyzed_node: ASTNode = node;
                var i: i32 = 0;
                while (i < node.children.Size()) {
                    var child_result: Result(ASTNode, String) = self.AnalyzeNode(node.children[i]);
                    if (not child_result.IsOk()) {
                        return child_result;
                    }
                    analyzed_node.children[i] = child_result.Value();
                    i += 1;
                }
                return Result(ASTNode, String).Ok(analyzed_node);
            }
        }
    }
    
    fn AnalyzeProgram(self: Self, node: ASTNode) -> Result(ASTNode, String) {
        var analyzed_node: ASTNode = node;
        
        // Analyze all top-level declarations
        var i: i32 = 0;
        while (i < node.children.Size()) {
            var child_result: Result(ASTNode, String) = self.AnalyzeNode(node.children[i]);
            if (not child_result.IsOk()) {
                return child_result;
            }
            analyzed_node.children[i] = child_result.Value();
            i += 1;
        }
        
        return Result(ASTNode, String).Ok(analyzed_node);
    }
    
    fn AnalyzeFunction(self: Self, node: ASTNode) -> Result(ASTNode, String) {
        var function_name: String = node.value;
        var return_type: String = node.data_type.HasValue() ? node.data_type.Value() : "Void";
        
        // Check return type validity
        if (not self.type_checker.IsValidType(return_type)) {
            self.AddError("Unknown return type '" + return_type + "' in function '" + function_name + "'", node.line);
        }
        
        // Create function symbol
        var func_symbol: Symbol = {
            .name = function_name,
            .type = SymbolType.Function,
            .data_type = return_type,
            .scope_level = 0,
            .line = node.line,
            .column = node.column,
            .is_mutable = False,
            .is_public = True,
            .is_static = False,
            .is_virtual = False,
            .is_abstract = False,
            .parameters = Array(Symbol)(),
            .return_type = return_type,
            .parent_scope = Optional(String).None()
        };
        
        // Add function to symbol table
        var add_result: Result(Bool, String) = self.symbol_table.AddSymbol(func_symbol);
        if (not add_result.IsOk()) {
            self.AddError(add_result.Error(), node.line);
        }
        
        // Enter function scope
        self.symbol_table.EnterScope(function_name);
        self.current_function = Optional(String).Some(function_name);
        
        var analyzed_node: ASTNode = node;
        
        // Analyze parameters and body
        var i: i32 = 0;
        while (i < node.children.Size()) {
            var child_result: Result(ASTNode, String) = self.AnalyzeNode(node.children[i]);
            if (not child_result.IsOk()) {
                return child_result;
            }
            analyzed_node.children[i] = child_result.Value();
            i += 1;
        }
        
        // Exit function scope
        self.symbol_table.ExitScope();
        self.current_function = Optional(String).None();
        
        return Result(ASTNode, String).Ok(analyzed_node);
    }
    
    fn AnalyzeVariable(self: Self, node: ASTNode) -> Result(ASTNode, String) {
        var var_name: String = node.value;
        var var_type: String = node.data_type.HasValue() ? node.data_type.Value() : "auto";
        
        // If type is auto, try to infer from initializer
        if (var_type == "auto" and node.children.Size() > 0) {
            var init_result: Result(ASTNode, String) = self.AnalyzeNode(node.children[0]);
            if (not init_result.IsOk()) {
                return init_result;
            }
            
            if (init_result.Value().data_type.HasValue()) {
                var_type = init_result.Value().data_type.Value();
            } else {
                self.AddError("Cannot infer type for variable '" + var_name + "'", node.line);
                var_type = "i32"; // Default fallback
            }
        }
        
        // Check type validity
        if (not self.type_checker.IsValidType(var_type)) {
            self.AddError("Unknown type '" + var_type + "' for variable '" + var_name + "'", node.line);
        }
        
        // Create variable symbol
        var var_symbol: Symbol = {
            .name = var_name,
            .type = SymbolType.Variable,
            .data_type = var_type,
            .scope_level = 0,
            .line = node.line,
            .column = node.column,
            .is_mutable = True,
            .is_public = False,
            .is_static = False,
            .is_virtual = False,
            .is_abstract = False,
            .parameters = Array(Symbol)(),
            .return_type = "",
            .parent_scope = Optional(String).None()
        };
        
        // Add variable to symbol table
        var add_result: Result(Bool, String) = self.symbol_table.AddSymbol(var_symbol);
        if (not add_result.IsOk()) {
            self.AddError(add_result.Error(), node.line);
        }
        
        var analyzed_node: ASTNode = node;
        analyzed_node.data_type = Optional(String).Some(var_type);
        
        // Analyze initializer if present
        if (node.children.Size() > 0) {
            var init_result: Result(ASTNode, String) = self.AnalyzeNode(node.children[0]);
            if (not init_result.IsOk()) {
                return init_result;
            }
            
            analyzed_node.children[0] = init_result.Value();
            
            // Check type compatibility
            if (init_result.Value().data_type.HasValue()) {
                var init_type: String = init_result.Value().data_type.Value();
                if (not self.type_checker.CanImplicitlyConvert(init_type, var_type)) {
                    self.AddError("Cannot convert from '" + init_type + "' to '" + var_type + "'", node.line);
                }
            }
        }
        
        return Result(ASTNode, String).Ok(analyzed_node);
    }
    
    fn AnalyzeBinaryOp(self: Self, node: ASTNode) -> Result(ASTNode, String) {
        if (node.children.Size() != 2) {
            self.AddError("Binary operation requires exactly 2 operands", node.line);
            return Result(ASTNode, String).Ok(node);
        }
        
        // Analyze operands
        var left_result: Result(ASTNode, String) = self.AnalyzeNode(node.children[0]);
        var right_result: Result(ASTNode, String) = self.AnalyzeNode(node.children[1]);
        
        if (not left_result.IsOk()) { return left_result; }
        if (not right_result.IsOk()) { return right_result; }
        
        var left: ASTNode = left_result.Value();
        var right: ASTNode = right_result.Value();
        
        var analyzed_node: ASTNode = node;
        analyzed_node.children[0] = left;
        analyzed_node.children[1] = right;
        
        // Type checking for binary operations
        if (left.data_type.HasValue() and right.data_type.HasValue()) {
            var left_type: String = left.data_type.Value();
            var right_type: String = right.data_type.Value();
            var op: String = node.value;
            
            // Determine result type
            var result_type_opt: Optional(String) = self.GetBinaryOpResultType(op, left_type, right_type);
            if (result_type_opt.HasValue()) {
                analyzed_node.data_type = result_type_opt;
            } else {
                self.AddError("Invalid operation '" + op + "' between '" + left_type + "' and '" + right_type + "'", node.line);
            }
        }
        
        return Result(ASTNode, String).Ok(analyzed_node);
    }
    
    fn AnalyzeIdentifier(self: Self, node: ASTNode) -> Result(ASTNode, String) {
        var name: String = node.value;
        var symbol_opt: Optional(Symbol) = self.symbol_table.LookupSymbol(name);
        
        if (not symbol_opt.HasValue()) {
            self.AddError("Undefined identifier '" + name + "'", node.line);
            return Result(ASTNode, String).Ok(node);
        }
        
        var symbol: Symbol = symbol_opt.Value();
        var analyzed_node: ASTNode = node;
        analyzed_node.data_type = Optional(String).Some(symbol.data_type);
        
        return Result(ASTNode, String).Ok(analyzed_node);
    }
    
    fn AnalyzeLiteral(self: Self, node: ASTNode) -> Result(ASTNode, String) {
        // Type is already set during parsing
        return Result(ASTNode, String).Ok(node);
    }
    
    fn GetBinaryOpResultType(self: Self, op: String, left_type: String, right_type: String) -> Optional(String) {
        // Arithmetic operations
        if (op == "+" or op == "-" or op == "*" or op == "/" or op == "%") {
            var common_type_opt: Optional(String) = self.type_checker.GetCommonType(left_type, right_type);
            if (common_type_opt.HasValue()) {
                return common_type_opt;
            }
        }
        
        // Comparison operations
        if (op == "==" or op == "!=" or op == "<" or op == "<=" or op == ">" or op == ">=") {
            var common_type_opt: Optional(String) = self.type_checker.GetCommonType(left_type, right_type);
            if (common_type_opt.HasValue()) {
                return Optional(String).Some("Bool");
            }
        }
        
        // Logical operations
        if (op == "and" or op == "or") {
            if (left_type == "Bool" and right_type == "Bool") {
                return Optional(String).Some("Bool");
            }
        }
        
        return Optional(String).None();
    }
    
    fn AddError(self: Self, message: String, line: i32) {
        self.errors.Push("Line " + IntToString(line) + ": " + message);
    }
    
    fn AddWarning(self: Self, message: String, line: i32) {
        self.warnings.Push("Line " + IntToString(line) + ": " + message);
    }
    
    fn GetErrors(self: Self) -> Array(String) {
        return self.errors;
    }
    
    fn GetWarnings(self: Self) -> Array(String) {
        return self.warnings;
    }
}