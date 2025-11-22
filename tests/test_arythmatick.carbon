// Tests for Arythmatick Math Library
package Tests.Arythmatick api;

import Atomic.Testing;
import Arythmatick;
import Arythmatick.Simple;

class ArythmatickTests {
    fn RunAllTests() -> TestReport {
        var runner: TestRunner = TestRunner.Create();
        var suite: TestSuite = TestSuite.Create("Arythmatick Math Library");
        
        // Basic Math Tests
        suite.AddTest(TestCase.Create("BasicMath_Abs", fn() -> TestResult {
            return Assert.Equal("5", String.FromFloat64(BasicMath.Abs(-5.0)), "Abs(-5) should be 5");
        }));
        
        suite.AddTest(TestCase.Create("BasicMath_Sqrt", fn() -> TestResult {
            var result: f64 = BasicMath.Sqrt(16.0);
            return Assert.True(BasicMath.Abs(result - 4.0) < 0.001, "Sqrt(16) should be 4");
        }));
        
        suite.AddTest(TestCase.Create("BasicMath_Pow", fn() -> TestResult {
            var result: f64 = BasicMath.Pow(2.0, 8.0);
            return Assert.True(BasicMath.Abs(result - 256.0) < 0.001, "Pow(2, 8) should be 256");
        }));
        
        // Trigonometry Tests
        suite.AddTest(TestCase.Create("Trig_Sin", fn() -> TestResult {
            var result: f64 = Trigonometry.Sin(MathConstants.PI / 2.0);
            return Assert.True(BasicMath.Abs(result - 1.0) < 0.001, "Sin(PI/2) should be 1");
        }));
        
        suite.AddTest(TestCase.Create("Trig_Cos", fn() -> TestResult {
            var result: f64 = Trigonometry.Cos(0.0);
            return Assert.True(BasicMath.Abs(result - 1.0) < 0.001, "Cos(0) should be 1");
        }));
        
        // Complex Number Tests
        suite.AddTest(TestCase.Create("Complex_Add", fn() -> TestResult {
            var c1: Complex = Complex.Create(3.0, 4.0);
            var c2: Complex = Complex.Create(1.0, 2.0);
            var result: Complex = c1.Add(c2);
            return Assert.True(result.real == 4.0 and result.imag == 6.0, "Complex addition failed");
        }));
        
        suite.AddTest(TestCase.Create("Complex_Magnitude", fn() -> TestResult {
            var c: Complex = Complex.Create(3.0, 4.0);
            var mag: f64 = c.Magnitude();
            return Assert.True(BasicMath.Abs(mag - 5.0) < 0.001, "Magnitude of 3+4i should be 5");
        }));
        
        // Vector Tests
        suite.AddTest(TestCase.Create("Vector2D_Add", fn() -> TestResult {
            var v1: Vector2D = Vector2D.Create(1.0, 2.0);
            var v2: Vector2D = Vector2D.Create(3.0, 4.0);
            var result: Vector2D = v1.Add(v2);
            return Assert.True(result.x == 4.0 and result.y == 6.0, "Vector addition failed");
        }));
        
        suite.AddTest(TestCase.Create("Vector2D_Dot", fn() -> TestResult {
            var v1: Vector2D = Vector2D.Create(1.0, 0.0);
            var v2: Vector2D = Vector2D.Create(0.0, 1.0);
            var dot: f64 = v1.Dot(v2);
            return Assert.True(dot == 0.0, "Dot product of perpendicular vectors should be 0");
        }));
        
        // Matrix Tests
        suite.AddTest(TestCase.Create("Matrix2x2_Identity", fn() -> TestResult {
            var identity: Matrix2x2 = Matrix2x2.Identity();
            var det: f64 = identity.Determinant();
            return Assert.True(BasicMath.Abs(det - 1.0) < 0.001, "Identity matrix determinant should be 1");
        }));
        
        // Geometry Tests
        suite.AddTest(TestCase.Create("Circle_Area", fn() -> TestResult {
            var center: Point2D = Point2D.Create(0.0, 0.0);
            var circle: Circle = Circle.Create(center, 1.0);
            var area: f64 = circle.Area();
            return Assert.True(BasicMath.Abs(area - MathConstants.PI) < 0.001, "Unit circle area should be PI");
        }));
        
        suite.AddTest(TestCase.Create("Rectangle_Contains", fn() -> TestResult {
            var rect: Rectangle = Rectangle.Create(0.0, 0.0, 10.0, 10.0);
            var point: Point2D = Point2D.Create(5.0, 5.0);
            return Assert.True(rect.Contains(point), "Rectangle should contain point (5,5)");
        }));
        
        // Statistics Tests
        suite.AddTest(TestCase.Create("Statistics_Mean", fn() -> TestResult {
            var values: Array(f64) = Array(f64)();
            values.Push(1.0); values.Push(2.0); values.Push(3.0); values.Push(4.0); values.Push(5.0);
            var mean: f64 = Statistics.Mean(values);
            return Assert.True(BasicMath.Abs(mean - 3.0) < 0.001, "Mean of 1,2,3,4,5 should be 3");
        }));
        
        // Simple Math Interface Tests
        suite.AddTest(TestCase.Create("Simple_Functions", fn() -> TestResult {
            var sin_result: f64 = Sin(MathConstants.PI / 6.0); // Should be 0.5
            var sqrt_result: f64 = Sqrt(25.0); // Should be 5
            return Assert.True(BasicMath.Abs(sin_result - 0.5) < 0.001 and BasicMath.Abs(sqrt_result - 5.0) < 0.001, "Simple math functions failed");
        }));
        
        runner.AddSuite(suite);
        return runner.RunAll();
    }
}

// Benchmark tests
class ArythmatickBenchmarks {
    fn RunBenchmarks() {
        var sin_bench: Benchmark = Benchmark.Create("Sin_Performance", fn() {
            var result: f64 = Trigonometry.Sin(1.5707963267948966); // PI/2
        });
        sin_bench.WithIterations(10000);
        
        var sqrt_bench: Benchmark = Benchmark.Create("Sqrt_Performance", fn() {
            var result: f64 = BasicMath.Sqrt(123456.789);
        });
        sqrt_bench.WithIterations(10000);
        
        var complex_bench: Benchmark = Benchmark.Create("Complex_Multiply", fn() {
            var c1: Complex = Complex.Create(3.0, 4.0);
            var c2: Complex = Complex.Create(1.0, 2.0);
            var result: Complex = c1.Multiply(c2);
        });
        complex_bench.WithIterations(5000);
        
        Console.WriteLine("=== Arythmatick Performance Benchmarks ===");
        sin_bench.Run().Print();
        sqrt_bench.Run().Print();
        complex_bench.Run().Print();
    }
}