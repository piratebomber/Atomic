// Atomic Carbon Compiler - Main Entry Point
package AtomicCompiler api;

import Std.CommandLine;
import Std.FileSystem;
import Std.Console;
import AtomicCompiler.Lexer;
import AtomicCompiler.Parser;
import AtomicCompiler.Semantic;
import AtomicCompiler.CodeGen;
import AtomicCompiler.Optimizer;
import AtomicCompiler.Linker;

fn Main() -> i32 {
    var args: Array(String) = CommandLine.GetArgs();
    
    if (args.Size() < 2) {
        Console.WriteLine("Usage: atomic-compiler <input.carbon> [-o output] [-O level] [--target platform]");
        return 1;
    }
    
    var input_file: String = args[1];
    var output_file: String = "a.exe";
    var opt_level: i32 = 2;
    var target: String = "native";
    var debug_info: Bool = False;
    
    // Parse command line arguments
    var i: i32 = 2;
    while (i < args.Size()) {
        if (args[i] == "-o" and i + 1 < args.Size()) {
            output_file = args[i + 1];
            i += 2;
        } else if (args[i] == "-O" and i + 1 < args.Size()) {
            opt_level = StringToInt(args[i + 1]);
            i += 2;
        } else if (args[i] == "--target" and i + 1 < args.Size()) {
            target = args[i + 1];
            i += 2;
        } else if (args[i] == "-g") {
            debug_info = True;
            i += 1;
        } else {
            i += 1;
        }
    }
    
    Console.WriteLine("Compiling " + input_file + " to " + output_file);
    
    // Read source file
    var source: Optional(String) = FileSystem.ReadFile(input_file);
    if (not source.HasValue()) {
        Console.WriteLine("Error: Cannot read file " + input_file);
        return 1;
    }
    
    // Lexical analysis
    Console.WriteLine("Lexical analysis...");
    var lexer: Lexer = Lexer.Create(source.Value());
    var tokens: Result(Array(Token), String) = lexer.Tokenize();
    if (not tokens.IsOk()) {
        Console.WriteLine("Lexer error: " + tokens.Error());
        return 1;
    }
    
    // Parsing
    Console.WriteLine("Parsing...");
    var parser: Parser = Parser.Create(tokens.Value());
    var ast: Result(AST, String) = parser.Parse();
    if (not ast.IsOk()) {
        Console.WriteLine("Parser error: " + ast.Error());
        return 1;
    }
    
    // Semantic analysis
    Console.WriteLine("Semantic analysis...");
    var analyzer: Semantic = Semantic.Create();
    var analyzed_ast: Result(AST, String) = analyzer.Analyze(ast.Value());
    if (not analyzed_ast.IsOk()) {
        Console.WriteLine("Semantic error: " + analyzed_ast.Error());
        return 1;
    }
    
    // Code generation
    Console.WriteLine("Code generation...");
    var codegen: CodeGen = CodeGen.Create(target, debug_info);
    var ir: Result(IR, String) = codegen.Generate(analyzed_ast.Value());
    if (not ir.IsOk()) {
        Console.WriteLine("Codegen error: " + ir.Error());
        return 1;
    }
    
    // Optimization
    var final_ir: IR = ir.Value();
    if (opt_level > 0) {
        Console.WriteLine("Optimization (level " + IntToString(opt_level) + ")...");
        var optimizer: Optimizer = Optimizer.Create(opt_level);
        var opt_result: Result(IR, String) = optimizer.Optimize(final_ir);
        if (not opt_result.IsOk()) {
            Console.WriteLine("Optimizer error: " + opt_result.Error());
            return 1;
        }
        final_ir = opt_result.Value();
    }
    
    // Linking
    Console.WriteLine("Linking...");
    var linker: Linker = Linker.Create();
    var link_result: Result(Bool, String) = linker.Link(final_ir, output_file);
    if (not link_result.IsOk()) {
        Console.WriteLine("Linker error: " + link_result.Error());
        return 1;
    }
    
    Console.WriteLine("Compilation successful: " + output_file);
    return 0;
}