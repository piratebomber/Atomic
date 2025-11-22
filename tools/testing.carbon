// Atomic Testing Framework
package Atomic.Testing api;

import Std.String;
import Std.Array;
import Std.Collections;
import Std.Console;
import Std.Time;
import Std.Threading;

choice TestResult { Pass, Fail, Skip, Error }

class TestCase {
    var name: String;
    var test_function: fn() -> TestResult;
    var timeout_ms: i32;
    
    fn Create(name: String, test_fn: fn() -> TestResult) -> Self {
        return { .name = name, .test_function = test_fn, .timeout_ms = 5000 };
    }
}

class TestExecutionResult {
    var test_name: String;
    var result: TestResult;
    var execution_time_ms: i64;
    var error_message: String;
    
    fn Create(name: String, result: TestResult) -> Self {
        return { .test_name = name, .result = result, .execution_time_ms = 0, .error_message = "" };
    }
}

class TestSuite {
    var name: String;
    var tests: Array(TestCase);
    
    fn Create(name: String) -> Self {
        return { .name = name, .tests = Array(TestCase)() };
    }
    
    fn AddTest(self: Self, test: TestCase) {
        self.tests.Push(test);
    }
}

class TestRunner {
    var suites: Array(TestSuite);
    var results: Array(TestExecutionResult);
    
    fn Create() -> Self {
        return { .suites = Array(TestSuite)(), .results = Array(TestExecutionResult)() };
    }
    
    fn AddSuite(self: Self, suite: TestSuite) {
        self.suites.Push(suite);
    }
    
    fn RunAll(self: Self) -> TestReport {
        var report: TestReport = TestReport.Create();
        
        for (suite: TestSuite in self.suites) {
            Console.WriteLine("Running suite: " + suite.name);
            
            for (test: TestCase in suite.tests) {
                var result: TestExecutionResult = self.ExecuteTest(test);
                self.results.Push(result);
                report.AddResult(result);
                self.PrintTestResult(result);
            }
        }
        
        return report;
    }
    
    fn ExecuteTest(self: Self, test: TestCase) -> TestExecutionResult {
        var result: TestExecutionResult = TestExecutionResult.Create(test.name, TestResult.Pass);
        var start_time: i64 = Time.GetCurrentTimeMillis();
        
        try {
            var test_result: TestResult = test.test_function();
            result.result = test_result;
        } catch (e: Exception) {
            result.result = TestResult.Error;
            result.error_message = e.message;
        }
        
        result.execution_time_ms = Time.GetCurrentTimeMillis() - start_time;
        return result;
    }
    
    fn PrintTestResult(self: Self, result: TestExecutionResult) {
        var status: String = match (result.result) {
            case TestResult.Pass => "PASS",
            case TestResult.Fail => "FAIL", 
            case TestResult.Skip => "SKIP",
            case TestResult.Error => "ERROR"
        };
        
        Console.WriteLine("[" + status + "] " + result.test_name + " (" + String.FromInt64(result.execution_time_ms) + "ms)");
        
        if (result.result == TestResult.Fail or result.result == TestResult.Error) {
            if (not result.error_message.IsEmpty()) {
                Console.WriteLine("  Error: " + result.error_message);
            }
        }
    }
}

class TestReport {
    var total_tests: i32;
    var passed_tests: i32;
    var failed_tests: i32;
    var error_tests: i32;
    var results: Array(TestExecutionResult);
    
    fn Create() -> Self {
        return { .total_tests = 0, .passed_tests = 0, .failed_tests = 0, .error_tests = 0, .results = Array(TestExecutionResult)() };
    }
    
    fn AddResult(self: Self, result: TestExecutionResult) {
        self.results.Push(result);
        self.total_tests += 1;
        
        match (result.result) {
            case TestResult.Pass => { self.passed_tests += 1; }
            case TestResult.Fail => { self.failed_tests += 1; }
            case TestResult.Error => { self.error_tests += 1; }
            default => { }
        }
    }
    
    fn PrintSummary(self: Self) {
        Console.WriteLine("\n=== Test Summary ===");
        Console.WriteLine("Total: " + String.FromInt32(self.total_tests));
        Console.WriteLine("Passed: " + String.FromInt32(self.passed_tests));
        Console.WriteLine("Failed: " + String.FromInt32(self.failed_tests));
        Console.WriteLine("Errors: " + String.FromInt32(self.error_tests));
    }
}

class Assert {
    fn True(condition: Bool, message: String) -> TestResult {
        if (condition) {
            return TestResult.Pass;
        } else {
            Console.WriteLine("Assertion failed: " + message);
            return TestResult.Fail;
        }
    }
    
    fn Equal(expected: String, actual: String, message: String) -> TestResult {
        if (expected == actual) {
            return TestResult.Pass;
        } else {
            Console.WriteLine("Assertion failed: " + message);
            Console.WriteLine("Expected: " + expected);
            Console.WriteLine("Actual: " + actual);
            return TestResult.Fail;
        }
    }
}

class Benchmark {
    var name: String;
    var benchmark_function: fn() -> Void;
    var iterations: i32;
    
    fn Create(name: String, benchmark_fn: fn() -> Void) -> Self {
        return { .name = name, .benchmark_function = benchmark_fn, .iterations = 1000 };
    }
    
    fn Run(self: Self) -> BenchmarkResult {
        var total_time: i64 = 0;
        
        for (i: i32 in Range(0, self.iterations)) {
            var start: i64 = Time.GetCurrentTimeNanos();
            self.benchmark_function();
            var end: i64 = Time.GetCurrentTimeNanos();
            total_time += (end - start);
        }
        
        var avg_time: f64 = (total_time as f64) / (self.iterations as f64);
        return BenchmarkResult.Create(self.name, avg_time, self.iterations);
    }
}

class BenchmarkResult {
    var name: String;
    var avg_time_ns: f64;
    var iterations: i32;
    
    fn Create(name: String, avg: f64, iterations: i32) -> Self {
        return { .name = name, .avg_time_ns = avg, .iterations = iterations };
    }
    
    fn Print(self: Self) {
        Console.WriteLine("Benchmark: " + self.name);
        Console.WriteLine("  Average: " + String.FromFloat64(self.avg_time_ns / 1000000.0) + "ms");
    }
}