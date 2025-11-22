// Main Test Runner for Atomic Carbon
package Tests.Main api;

import Atomic.Testing;
import Tests.Arythmatick;
import Tests.Web;
import Tests.Graphics;
import Tests.Distributed;
import Tests.Tools;

class AtomicTestSuite {
    fn RunAllTests() {
        Console.WriteLine("=== Atomic Carbon Test Suite ===");
        Console.WriteLine("Running comprehensive tests for all components...\n");
        
        var total_passed: i32 = 0;
        var total_failed: i32 = 0;
        var total_errors: i32 = 0;
        var total_time: i64 = Time.GetCurrentTimeMillis();
        
        // Run Arythmatick Math Library Tests
        Console.WriteLine("🧮 Testing Arythmatick Math Library...");
        var math_tests: ArythmatickTests = ArythmatickTests();
        var math_report: TestReport = math_tests.RunAllTests();
        math_report.PrintSummary();
        total_passed += math_report.passed_tests;
        total_failed += math_report.failed_tests;
        total_errors += math_report.error_tests;
        Console.WriteLine("");
        
        // Run Web Framework Tests
        Console.WriteLine("🌐 Testing Web Framework...");
        var web_tests: WebFrameworkTests = WebFrameworkTests();
        var web_report: TestReport = web_tests.RunAllTests();
        web_report.PrintSummary();
        total_passed += web_report.passed_tests;
        total_failed += web_report.failed_tests;
        total_errors += web_report.error_tests;
        
        Console.WriteLine("🖼️ Testing WebView GUI...");
        var webview_tests: WebViewTests = WebViewTests();
        var webview_report: TestReport = webview_tests.RunAllTests();
        webview_report.PrintSummary();
        total_passed += webview_report.passed_tests;
        total_failed += webview_report.failed_tests;
        total_errors += webview_report.error_tests;
        Console.WriteLine("");
        
        // Run Graphics Engine Tests
        Console.WriteLine("🎮 Testing Graphics & Game Engine...");
        var graphics_tests: GraphicsTests = GraphicsTests();
        var graphics_report: TestReport = graphics_tests.RunAllTests();
        graphics_report.PrintSummary();
        total_passed += graphics_report.passed_tests;
        total_failed += graphics_report.failed_tests;
        total_errors += graphics_report.error_tests;
        Console.WriteLine("");
        
        // Run Distributed Systems Tests
        Console.WriteLine("🌍 Testing Distributed Systems...");
        var distributed_tests: DistributedTests = DistributedTests();
        var distributed_report: TestReport = distributed_tests.RunAllTests();
        distributed_report.PrintSummary();
        total_passed += distributed_report.passed_tests;
        total_failed += distributed_report.failed_tests;
        total_errors += distributed_report.error_tests;
        Console.WriteLine("");
        
        // Run Development Tools Tests
        Console.WriteLine("🛠️ Testing Development Tools...");
        var tools_tests: ToolsTests = ToolsTests();
        var tools_report: TestReport = tools_tests.RunAllTests();
        tools_report.PrintSummary();
        total_passed += tools_report.passed_tests;
        total_failed += tools_report.failed_tests;
        total_errors += tools_report.error_tests;
        Console.WriteLine("");
        
        // Final Summary
        var end_time: i64 = Time.GetCurrentTimeMillis();
        var total_time_ms: i64 = end_time - total_time;
        
        Console.WriteLine("🎯 === FINAL TEST RESULTS ===");
        Console.WriteLine("Total Tests: " + String.FromInt32(total_passed + total_failed + total_errors));
        Console.WriteLine("✅ Passed: " + String.FromInt32(total_passed));
        Console.WriteLine("❌ Failed: " + String.FromInt32(total_failed));
        Console.WriteLine("💥 Errors: " + String.FromInt32(total_errors));
        Console.WriteLine("⏱️ Total Time: " + String.FromInt64(total_time_ms) + "ms");
        
        var success_rate: f64 = (total_passed as f64) / ((total_passed + total_failed + total_errors) as f64) * 100.0;
        Console.WriteLine("📊 Success Rate: " + String.FromFloat64(success_rate) + "%");
        
        if (total_failed == 0 and total_errors == 0) {
            Console.WriteLine("🎉 ALL TESTS PASSED! Atomic Carbon is ready for production!");
        } else {
            Console.WriteLine("⚠️ Some tests failed. Please review the results above.");
        }
    }
    
    fn RunBenchmarks() {
        Console.WriteLine("\n🚀 === PERFORMANCE BENCHMARKS ===");
        Console.WriteLine("Running performance tests for all components...\n");
        
        // Math Library Benchmarks
        var math_benchmarks: ArythmatickBenchmarks = ArythmatickBenchmarks();
        math_benchmarks.RunBenchmarks();
        Console.WriteLine("");
        
        // Web Framework Benchmarks
        var web_benchmarks: WebBenchmarks = WebBenchmarks();
        web_benchmarks.RunBenchmarks();
        Console.WriteLine("");
        
        // Graphics Engine Benchmarks
        var graphics_benchmarks: GraphicsBenchmarks = GraphicsBenchmarks();
        graphics_benchmarks.RunBenchmarks();
        Console.WriteLine("");
        
        // Distributed Systems Benchmarks
        var distributed_benchmarks: DistributedBenchmarks = DistributedBenchmarks();
        distributed_benchmarks.RunBenchmarks();
        Console.WriteLine("");
        
        // Development Tools Benchmarks
        var tools_benchmarks: ToolsBenchmarks = ToolsBenchmarks();
        tools_benchmarks.RunBenchmarks();
        Console.WriteLine("");
        
        Console.WriteLine("✨ Benchmark suite completed!");
    }
    
    fn RunQuickTests() {
        Console.WriteLine("⚡ === QUICK SMOKE TESTS ===");
        Console.WriteLine("Running essential functionality tests...\n");
        
        var runner: TestRunner = TestRunner.Create();
        var suite: TestSuite = TestSuite.Create("Quick Smoke Tests");
        
        // Essential Math Test
        suite.AddTest(TestCase.Create("Math_Basic", fn() -> TestResult {
            var result: f64 = BasicMath.Sqrt(16.0) + Trigonometry.Sin(0.0);
            return Assert.True(BasicMath.Abs(result - 4.0) < 0.001, "Basic math should work");
        }));
        
        // Essential Web Test
        suite.AddTest(TestCase.Create("Web_Request", fn() -> TestResult {
            var request: HTTPRequest = HTTPRequest.Create(HTTPMethod.GET, "/test");
            return Assert.Equal("/test", request.path, "HTTP request should work");
        }));
        
        // Essential Graphics Test
        suite.AddTest(TestCase.Create("Graphics_Vector", fn() -> TestResult {
            var v: Vector3 = Vector3.Create(1.0, 2.0, 3.0);
            return Assert.True(v.x == 1.0, "Vector creation should work");
        }));
        
        // Essential Distributed Test
        suite.AddTest(TestCase.Create("Distributed_Node", fn() -> TestResult {
            var node: DistributedNode = DistributedNode.Create("test", "localhost", 8080);
            return Assert.Equal("test", node.id, "Node creation should work");
        }));
        
        // Essential Tools Test
        suite.AddTest(TestCase.Create("Tools_Token", fn() -> TestResult {
            var token: Token = Token.Create(TokenType.Keyword, "fn", 1, 0);
            return Assert.Equal("fn", token.value, "Token creation should work");
        }));
        
        runner.AddSuite(suite);
        var report: TestReport = runner.RunAll();
        report.PrintSummary();
        
        if (report.failed_tests == 0 and report.error_tests == 0) {
            Console.WriteLine("✅ All smoke tests passed! Core functionality is working.");
        } else {
            Console.WriteLine("❌ Some smoke tests failed! Check core implementations.");
        }
    }
}

// Main entry point for running tests
fn Main() -> i32 {
    var test_suite: AtomicTestSuite = AtomicTestSuite();
    
    // Check command line arguments for test type
    var args: Array(String) = Platform.GetCommandLineArgs();
    
    if (args.Size() > 1) {
        var arg: Optional(String) = args.Get(1);
        if (arg.IsSome()) {
            match (arg.Unwrap()) {
                case "quick" => {
                    test_suite.RunQuickTests();
                }
                case "bench" => {
                    test_suite.RunBenchmarks();
                }
                case "all" => {
                    test_suite.RunAllTests();
                    test_suite.RunBenchmarks();
                }
                default => {
                    test_suite.RunAllTests();
                }
            }
        }
    } else {
        test_suite.RunAllTests();
    }
    
    return 0;
}