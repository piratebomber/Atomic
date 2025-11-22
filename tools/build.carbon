// Atomic Build Tool
package AtomicTools.Build api;

import Std.Console;
import Std.FileSystem;
import Std.CommandLine;
import Std.String;
import Std.Array;
import AtomicCompiler.Lexer;
import AtomicCompiler.Parser;

// Build configuration
struct BuildConfig {
    var source_files: Array(String);
    var output_file: String;
    var optimization_level: i32;
    var debug_info: Bool;
    var target_platform: String;
    var include_paths: Array(String);
    var library_paths: Array(String);
    var libraries: Array(String);
    var defines: Array(String);
}

// Build system main class
class BuildSystem {
    var config: BuildConfig;
    var verbose: Bool;
    
    fn Create() -> Self {
        return {
            .config = {
                .source_files = Array(String)(),
                .output_file = "output.exe",
                .optimization_level = 2,
                .debug_info = False,
                .target_platform = "native",
                .include_paths = Array(String)(),
                .library_paths = Array(String)(),
                .libraries = Array(String)(),
                .defines = Array(String)()
            },
            .verbose = False
        };
    }
    
    fn LoadBuildFile(self: Self, build_file: String) -> Result(Bool, String) {
        var content_opt: Optional(String) = FileSystem.ReadFile(build_file);
        if (not content_opt.HasValue()) {
            return Result(Bool, String).Error("Cannot read build file: " + build_file);
        }
        
        var content: String = content_opt.Value();
        return self.ParseBuildFile(content);
    }
    
    fn ParseBuildFile(self: Self, content: String) -> Result(Bool, String) {
        // Simple build file parser
        var lines: Array(String) = content.Split("\n");
        var i: i32 = 0;
        
        while (i < lines.Size()) {
            var line: String = lines[i].Trim();
            
            if (line.StartsWith("#") or line.IsEmpty()) {
                // Skip comments and empty lines
                i += 1;
                continue;
            }
            
            if (line.StartsWith("sources:")) {
                var sources_str: String = line.Substring(8).Trim();
                var sources: Array(String) = sources_str.Split(",");
                var j: i32 = 0;
                while (j < sources.Size()) {
                    self.config.source_files.Push(sources[j].Trim());
                    j += 1;
                }
            } else if (line.StartsWith("output:")) {
                self.config.output_file = line.Substring(7).Trim();
            } else if (line.StartsWith("optimization:")) {
                var opt_str: String = line.Substring(13).Trim();
                self.config.optimization_level = StringToInt(opt_str);
            } else if (line.StartsWith("debug:")) {
                var debug_str: String = line.Substring(6).Trim();
                self.config.debug_info = (debug_str == "true" or debug_str == "1");
            } else if (line.StartsWith("target:")) {
                self.config.target_platform = line.Substring(7).Trim();
            } else if (line.StartsWith("includes:")) {
                var includes_str: String = line.Substring(9).Trim();
                var includes: Array(String) = includes_str.Split(",");
                var j: i32 = 0;
                while (j < includes.Size()) {
                    self.config.include_paths.Push(includes[j].Trim());
                    j += 1;
                }
            } else if (line.StartsWith("libraries:")) {
                var libs_str: String = line.Substring(10).Trim();
                var libs: Array(String) = libs_str.Split(",");
                var j: i32 = 0;
                while (j < libs.Size()) {
                    self.config.libraries.Push(libs[j].Trim());
                    j += 1;
                }
            } else if (line.StartsWith("defines:")) {
                var defines_str: String = line.Substring(8).Trim();
                var defines: Array(String) = defines_str.Split(",");
                var j: i32 = 0;
                while (j < defines.Size()) {
                    self.config.defines.Push(defines[j].Trim());
                    j += 1;
                }
            }
            
            i += 1;
        }
        
        return Result(Bool, String).Ok(True);
    }
    
    fn Build(self: Self) -> Result(Bool, String) {
        if (self.verbose) {
            Console.WriteLine("Starting build process...");
            Console.WriteLine("Output file: " + self.config.output_file);
            Console.WriteLine("Optimization level: " + IntToString(self.config.optimization_level));
            Console.WriteLine("Target platform: " + self.config.target_platform);
        }
        
        // Check if source files exist
        var i: i32 = 0;
        while (i < self.config.source_files.Size()) {
            var file: String = self.config.source_files[i];
            if (not FileSystem.FileExists(file)) {
                return Result(Bool, String).Error("Source file not found: " + file);
            }
            i += 1;
        }
        
        // Compile each source file
        var object_files: Array(String) = Array(String)();
        i = 0;
        while (i < self.config.source_files.Size()) {
            var source_file: String = self.config.source_files[i];
            
            if (self.verbose) {
                Console.WriteLine("Compiling: " + source_file);
            }
            
            var compile_result: Result(String, String) = self.CompileFile(source_file);
            if (not compile_result.IsOk()) {
                return Result(Bool, String).Error("Compilation failed for " + source_file + ": " + compile_result.Error());
            }
            
            object_files.Push(compile_result.Value());
            i += 1;
        }
        
        // Link object files
        if (self.verbose) {
            Console.WriteLine("Linking...");
        }
        
        var link_result: Result(Bool, String) = self.LinkFiles(object_files);
        if (not link_result.IsOk()) {
            return link_result;
        }
        
        if (self.verbose) {
            Console.WriteLine("Build completed successfully!");
        }
        
        return Result(Bool, String).Ok(True);
    }
    
    fn CompileFile(self: Self, source_file: String) -> Result(String, String) {
        // Read source file
        var source_opt: Optional(String) = FileSystem.ReadFile(source_file);
        if (not source_opt.HasValue()) {
            return Result(String, String).Error("Cannot read source file");
        }
        
        var source: String = source_opt.Value();
        
        // Lexical analysis
        var lexer: Lexer = Lexer.Create(source);
        var tokens_result: Result(Array(Token), String) = lexer.Tokenize();
        if (not tokens_result.IsOk()) {
            return Result(String, String).Error("Lexer error: " + tokens_result.Error());
        }
        
        // Parsing
        var parser: Parser = Parser.Create(tokens_result.Value());
        var ast_result: Result(ASTNode, String) = parser.Parse();
        if (not ast_result.IsOk()) {
            return Result(String, String).Error("Parser error: " + ast_result.Error());
        }
        
        // Generate object file name
        var object_file: String = source_file.Replace(".carbon", ".o");
        
        // For now, just create a placeholder object file
        // Real implementation would generate actual machine code
        var success: Bool = FileSystem.WriteFile(object_file, "# Object file for " + source_file);
        if (not success) {
            return Result(String, String).Error("Cannot write object file");
        }
        
        return Result(String, String).Ok(object_file);
    }
    
    fn LinkFiles(self: Self, object_files: Array(String)) -> Result(Bool, String) {
        // Simple linker - just combine object files
        var combined_content: String = "";
        
        var i: i32 = 0;
        while (i < object_files.Size()) {
            var obj_content_opt: Optional(String) = FileSystem.ReadFile(object_files[i]);
            if (obj_content_opt.HasValue()) {
                combined_content += obj_content_opt.Value() + "\n";
            }
            i += 1;
        }
        
        // Write executable
        var success: Bool = FileSystem.WriteFile(self.config.output_file, combined_content);
        if (not success) {
            return Result(Bool, String).Error("Cannot write output file");
        }
        
        return Result(Bool, String).Ok(True);
    }
    
    fn Clean(self: Self) -> Result(Bool, String) {
        if (self.verbose) {
            Console.WriteLine("Cleaning build artifacts...");
        }
        
        // Remove object files
        var i: i32 = 0;
        while (i < self.config.source_files.Size()) {
            var object_file: String = self.config.source_files[i].Replace(".carbon", ".o");
            if (FileSystem.FileExists(object_file)) {
                FileSystem.DeleteFile(object_file);
                if (self.verbose) {
                    Console.WriteLine("Removed: " + object_file);
                }
            }
            i += 1;
        }
        
        // Remove output file
        if (FileSystem.FileExists(self.config.output_file)) {
            FileSystem.DeleteFile(self.config.output_file);
            if (self.verbose) {
                Console.WriteLine("Removed: " + self.config.output_file);
            }
        }
        
        if (self.verbose) {
            Console.WriteLine("Clean completed!");
        }
        
        return Result(Bool, String).Ok(True);
    }
    
    fn SetVerbose(self: Self, verbose: Bool) {
        self.verbose = verbose;
    }
    
    fn AddSourceFile(self: Self, file: String) {
        self.config.source_files.Push(file);
    }
    
    fn SetOutputFile(self: Self, file: String) {
        self.config.output_file = file;
    }
    
    fn SetOptimizationLevel(self: Self, level: i32) {
        self.config.optimization_level = level;
    }
    
    fn SetDebugInfo(self: Self, debug: Bool) {
        self.config.debug_info = debug;
    }
    
    fn SetTargetPlatform(self: Self, target: String) {
        self.config.target_platform = target;
    }
}

// Main build tool entry point
fn Main() -> i32 {
    var args: Array(String) = CommandLine.GetArgs();
    
    if (args.Size() < 2) {
        Console.WriteLine("Usage: atomic-build [command] [options]");
        Console.WriteLine("Commands:");
        Console.WriteLine("  build    - Build the project");
        Console.WriteLine("  clean    - Clean build artifacts");
        Console.WriteLine("  help     - Show this help");
        Console.WriteLine("");
        Console.WriteLine("Options:");
        Console.WriteLine("  -f <file>    - Build file (default: build.atomic)");
        Console.WriteLine("  -o <file>    - Output file");
        Console.WriteLine("  -O <level>   - Optimization level (0-3)");
        Console.WriteLine("  -g           - Include debug information");
        Console.WriteLine("  -v           - Verbose output");
        Console.WriteLine("  --target <platform> - Target platform");
        return 1;
    }
    
    var command: String = args[1];
    var build_system: BuildSystem = BuildSystem.Create();
    var build_file: String = "build.atomic";
    
    // Parse command line arguments
    var i: i32 = 2;
    while (i < args.Size()) {
        if (args[i] == "-f" and i + 1 < args.Size()) {
            build_file = args[i + 1];
            i += 2;
        } else if (args[i] == "-o" and i + 1 < args.Size()) {
            build_system.SetOutputFile(args[i + 1]);
            i += 2;
        } else if (args[i] == "-O" and i + 1 < args.Size()) {
            var level: i32 = StringToInt(args[i + 1]);
            build_system.SetOptimizationLevel(level);
            i += 2;
        } else if (args[i] == "-g") {
            build_system.SetDebugInfo(True);
            i += 1;
        } else if (args[i] == "-v") {
            build_system.SetVerbose(True);
            i += 1;
        } else if (args[i] == "--target" and i + 1 < args.Size()) {
            build_system.SetTargetPlatform(args[i + 1]);
            i += 2;
        } else {
            // Assume it's a source file
            build_system.AddSourceFile(args[i]);
            i += 1;
        }
    }
    
    // Load build file if it exists
    if (FileSystem.FileExists(build_file)) {
        var load_result: Result(Bool, String) = build_system.LoadBuildFile(build_file);
        if (not load_result.IsOk()) {
            Console.WriteLine("Error loading build file: " + load_result.Error());
            return 1;
        }
    }
    
    // Execute command
    if (command == "build") {
        var build_result: Result(Bool, String) = build_system.Build();
        if (not build_result.IsOk()) {
            Console.WriteLine("Build failed: " + build_result.Error());
            return 1;
        }
        Console.WriteLine("Build successful!");
    } else if (command == "clean") {
        var clean_result: Result(Bool, String) = build_system.Clean();
        if (not clean_result.IsOk()) {
            Console.WriteLine("Clean failed: " + clean_result.Error());
            return 1;
        }
        Console.WriteLine("Clean successful!");
    } else if (command == "help") {
        Console.WriteLine("Atomic Build Tool");
        Console.WriteLine("A build system for Atomic Carbon projects");
        return 0;
    } else {
        Console.WriteLine("Unknown command: " + command);
        return 1;
    }
    
    return 0;
}