// Tests for Development Tools
package Tests.Tools api;

import Atomic.Testing;
import Atomic.Debugger;
import Atomic.LSP;
import Atomic.Formatter;

class ToolsTests {
    fn RunAllTests() -> TestReport {
        var runner: TestRunner = TestRunner.Create();
        var suite: TestSuite = TestSuite.Create("Development Tools");
        
        // Debugger Tests
        suite.AddTest(TestCase.Create("Breakpoint_Create", fn() -> TestResult {
            var bp: Breakpoint = Breakpoint.Create(1, "test.carbon", 42);
            return Assert.True(bp.id == 1 and bp.line_number == 42 and bp.enabled, "Breakpoint should be created correctly");
        }));
        
        suite.AddTest(TestCase.Create("StackFrame_Create", fn() -> TestResult {
            var frame: StackFrame = StackFrame.Create("main", "app.carbon", 10);
            return Assert.Equal("main", frame.function_name, "Stack frame function name should be set");
        }));
        
        suite.AddTest(TestCase.Create("DebugSession_Create", fn() -> TestResult {
            var session: DebugSession = DebugSession.Create(1234);
            return Assert.True(session.process_id == 1234 and session.next_breakpoint_id == 1, "Debug session should be initialized");
        }));
        
        suite.AddTest(TestCase.Create("DebugSession_AddBreakpoint", fn() -> TestResult {
            var session: DebugSession = DebugSession.Create(5678);
            var bp_id: i32 = session.AddBreakpoint("main.carbon", 25);
            return Assert.True(bp_id == 1 and session.breakpoints.Size() == 1, "Breakpoint should be added to session");
        }));
        
        suite.AddTest(TestCase.Create("Debugger_Create", fn() -> TestResult {
            var debugger: Debugger = Debugger.Create();
            return Assert.True(debugger.sessions.Size() == 0, "Debugger should start with no sessions");
        }));
        
        // Profiler Tests
        suite.AddTest(TestCase.Create("ProfileSample_Create", fn() -> TestResult {
            var sample: ProfileSample = ProfileSample.Create();
            return Assert.True(sample.timestamp > 0, "Profile sample should have timestamp");
        }));
        
        suite.AddTest(TestCase.Create("Profiler_Create", fn() -> TestResult {
            var profiler: Profiler = Profiler.Create();
            return Assert.True(not profiler.is_profiling and profiler.sampling_interval_ms == 10, "Profiler should be initialized correctly");
        }));
        
        // Language Server Tests
        suite.AddTest(TestCase.Create("Position_Create", fn() -> TestResult {
            var pos: Position = Position.Create(10, 25);
            return Assert.True(pos.line == 10 and pos.character == 25, "Position should be created correctly");
        }));
        
        suite.AddTest(TestCase.Create("Range_Create", fn() -> TestResult {
            var start: Position = Position.Create(1, 0);
            var end: Position = Position.Create(1, 10);
            var range: Range = Range.Create(start, end);
            return Assert.True(range.start.line == 1 and range.end.character == 10, "Range should be created correctly");
        }));
        
        suite.AddTest(TestCase.Create("TextDocument_Create", fn() -> TestResult {
            var doc: TextDocumentItem = TextDocumentItem.Create("file:///test.carbon", "carbon", 1, "fn main() {}");
            return Assert.Equal("carbon", doc.language_id, "Text document language should be set");
        }));
        
        suite.AddTest(TestCase.Create("Diagnostic_Create", fn() -> TestResult {
            var range: Range = Range.Create(Position.Create(0, 0), Position.Create(0, 10));
            var diagnostic: Diagnostic = Diagnostic.Create(range, DiagnosticSeverity.Error, "Syntax error");
            return Assert.Equal("Syntax error", diagnostic.message, "Diagnostic message should be set");
        }));
        
        suite.AddTest(TestCase.Create("CompletionItem_Create", fn() -> TestResult {
            var item: CompletionItem = CompletionItem.Create("function", CompletionItemKind.Function);
            return Assert.True(item.label == "function" and item.kind == CompletionItemKind.Function, "Completion item should be created correctly");
        }));
        
        suite.AddTest(TestCase.Create("DocumentManager_Create", fn() -> TestResult {
            var manager: DocumentManager = DocumentManager.Create();
            return Assert.True(manager.documents.Size() == 0, "Document manager should start empty");
        }));
        
        suite.AddTest(TestCase.Create("DocumentManager_OpenDocument", fn() -> TestResult {
            var manager: DocumentManager = DocumentManager.Create();
            var doc: TextDocumentItem = TextDocumentItem.Create("file:///example.carbon", "carbon", 1, "var x: i32 = 42;");
            manager.OpenDocument(doc);
            return Assert.True(manager.documents.Size() == 1, "Document should be added to manager");
        }));
        
        suite.AddTest(TestCase.Create("CompletionProvider_Create", fn() -> TestResult {
            var provider: CompletionProvider = CompletionProvider.Create();
            return Assert.True(provider.keywords.Size() > 0, "Completion provider should have keywords");
        }));
        
        // Formatter Tests
        suite.AddTest(TestCase.Create("FormatterConfig_Create", fn() -> TestResult {
            var config: FormatterConfig = FormatterConfig.Create();
            return Assert.True(config.indent_size == 4 and not config.use_tabs, "Formatter config should have defaults");
        }));
        
        suite.AddTest(TestCase.Create("Token_Create", fn() -> TestResult {
            var token: Token = Token.Create(TokenType.Keyword, "fn", 1, 0);
            return Assert.True(token.type == TokenType.Keyword and token.value == "fn", "Token should be created correctly");
        }));
        
        suite.AddTest(TestCase.Create("FormatterLexer_Create", fn() -> TestResult {
            var lexer: FormatterLexer = FormatterLexer.Create("fn main() {}");
            return Assert.True(lexer.keywords.Size() > 0, "Lexer should have keywords loaded");
        }));
        
        suite.AddTest(TestCase.Create("FormatterLexer_Tokenize", fn() -> TestResult {
            var lexer: FormatterLexer = FormatterLexer.Create("fn test");
            var tokens: Array(Token) = lexer.Tokenize();
            return Assert.True(tokens.Size() >= 2, "Should tokenize at least 2 tokens");
        }));
        
        suite.AddTest(TestCase.Create("CodeFormatter_Create", fn() -> TestResult {
            var config: FormatterConfig = FormatterConfig.Create();
            var formatter: CodeFormatter = CodeFormatter.Create(config);
            return Assert.True(formatter.current_indent == 0, "Formatter should start with no indentation");
        }));
        
        suite.AddTest(TestCase.Create("AtomicFormatter_FormatString", fn() -> TestResult {
            var config: FormatterConfig = FormatterConfig.Create();
            var source: String = "fn main(){var x:i32=42;}";
            var result: Result(String, String) = AtomicFormatter.FormatString(source, config);
            return Assert.True(result.IsOk(), "Formatting should succeed");
        }));
        
        runner.AddSuite(suite);
        return runner.RunAll();
    }
}

class ToolsBenchmarks {
    fn RunBenchmarks() {
        var lexer_bench: Benchmark = Benchmark.Create("Lexer_Tokenization", fn() {
            var source: String = "fn fibonacci(n: i32) -> i32 { if (n <= 1) { return n; } return fibonacci(n-1) + fibonacci(n-2); }";
            var lexer: FormatterLexer = FormatterLexer.Create(source);
            var tokens: Array(Token) = lexer.Tokenize();
        });
        lexer_bench.WithIterations(100);
        
        var formatter_bench: Benchmark = Benchmark.Create("Code_Formatting", fn() {
            var config: FormatterConfig = FormatterConfig.Create();
            var source: String = "fn test(){var a:i32=1;var b:i32=2;return a+b;}";
            var result: Result(String, String) = AtomicFormatter.FormatString(source, config);
        });
        formatter_bench.WithIterations(50);
        
        var completion_bench: Benchmark = Benchmark.Create("Completion_Generation", fn() {
            var provider: CompletionProvider = CompletionProvider.Create();
            var doc: TextDocumentItem = TextDocumentItem.Create("test.carbon", "carbon", 1, "fn main() { var x: }");
            var pos: Position = Position.Create(0, 20);
            var completions: Array(CompletionItem) = provider.GetCompletions(doc, pos);
        });
        completion_bench.WithIterations(100);
        
        var diagnostic_bench: Benchmark = Benchmark.Create("Document_Analysis", fn() {
            var manager: DocumentManager = DocumentManager.Create();
            var doc: TextDocumentItem = TextDocumentItem.Create("bench.carbon", "carbon", 1, "fn test() { var x: i32; var y: String; }");
            manager.OpenDocument(doc);
        });
        diagnostic_bench.WithIterations(50);
        
        Console.WriteLine("=== Development Tools Performance Benchmarks ===");
        lexer_bench.Run().Print();
        formatter_bench.Run().Print();
        completion_bench.Run().Print();
        diagnostic_bench.Run().Print();
    }
}