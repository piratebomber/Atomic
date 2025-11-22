// Arythmatick - Comprehensive Math Library for Atomic Carbon
// Import as: import Arythmatick; or import Amatick; or import Arythmatick.Simple;
package Arythmatick api;
package Amatick api; // Short alias

import Std.String;
import Std.Array;
import Std.Collections;

// Constants
class MathConstants {
    var PI: f64 = 3.141592653589793;
    var E: f64 = 2.718281828459045;
    var GOLDEN_RATIO: f64 = 1.618033988749895;
    var SQRT_2: f64 = 1.4142135623730951;
    var SQRT_3: f64 = 1.7320508075688772;
    var LN_2: f64 = 0.6931471805599453;
    var LN_10: f64 = 2.302585092994046;
    var EULER_GAMMA: f64 = 0.5772156649015329;
    var INFINITY: f64 = 1.0 / 0.0;
    var NAN: f64 = 0.0 / 0.0;
}

// Basic arithmetic operations
class BasicMath {
    fn Abs(x: f64) -> f64 { return if (x < 0.0) -x else x; }
    fn Min(a: f64, b: f64) -> f64 { return if (a < b) a else b; }
    fn Max(a: f64, b: f64) -> f64 { return if (a > b) a else b; }
    fn Clamp(x: f64, min: f64, max: f64) -> f64 { return Self.Min(Self.Max(x, min), max); }
    
    fn Pow(base: f64, exponent: f64) -> f64 {
        if (exponent == 0.0) { return 1.0; }
        if (exponent == 1.0) { return base; }
        if (exponent == 2.0) { return base * base; }
        
        // Use binary exponentiation for integer exponents
        if (Self.IsInteger(exponent)) {
            var result: f64 = 1.0;
            var exp: i64 = exponent as i64;
            var b: f64 = base;
            
            if (exp < 0) {
                b = 1.0 / b;
                exp = -exp;
            }
            
            while (exp > 0) {
                if (exp % 2 == 1) {
                    result *= b;
                }
                b *= b;
                exp /= 2;
            }
            return result;
        }
        
        // For non-integer exponents, use exp(ln(base) * exponent)
        return Self.Exp(Self.Ln(base) * exponent);
    }
    
    fn Sqrt(x: f64) -> f64 {
        if (x < 0.0) { return MathConstants.NAN; }
        if (x == 0.0) { return 0.0; }
        
        // Newton's method
        var guess: f64 = x / 2.0;
        for (i: i32 in Range(0, 20)) {
            var new_guess: f64 = (guess + x / guess) / 2.0;
            if (Self.Abs(new_guess - guess) < 1e-15) {
                return new_guess;
            }
            guess = new_guess;
        }
        return guess;
    }
    
    fn Cbrt(x: f64) -> f64 {
        if (x == 0.0) { return 0.0; }
        
        var sign: f64 = if (x < 0.0) -1.0 else 1.0;
        x = Self.Abs(x);
        
        // Newton's method for cube root
        var guess: f64 = x / 3.0;
        for (i: i32 in Range(0, 20)) {
            var new_guess: f64 = (2.0 * guess + x / (guess * guess)) / 3.0;
            if (Self.Abs(new_guess - guess) < 1e-15) {
                return sign * new_guess;
            }
            guess = new_guess;
        }
        return sign * guess;
    }
    
    fn Exp(x: f64) -> f64 {
        if (x == 0.0) { return 1.0; }
        if (x > 700.0) { return MathConstants.INFINITY; }
        if (x < -700.0) { return 0.0; }
        
        // Taylor series: e^x = 1 + x + x^2/2! + x^3/3! + ...
        var result: f64 = 1.0;
        var term: f64 = 1.0;
        
        for (n: i32 in Range(1, 50)) {
            term *= x / (n as f64);
            result += term;
            if (Self.Abs(term) < 1e-15) { break; }
        }
        
        return result;
    }
    
    fn Ln(x: f64) -> f64 {
        if (x <= 0.0) { return MathConstants.NAN; }
        if (x == 1.0) { return 0.0; }
        
        // Use series expansion for ln(1+u) where u = (x-1)/(x+1)
        var u: f64 = (x - 1.0) / (x + 1.0);
        var u2: f64 = u * u;
        var result: f64 = 0.0;
        var term: f64 = u;
        
        for (n: i32 in Range(1, 100, 2)) {
            result += term / (n as f64);
            term *= u2;
            if (Self.Abs(term) < 1e-15) { break; }
        }
        
        return 2.0 * result;
    }
    
    fn Log10(x: f64) -> f64 {
        return Self.Ln(x) / MathConstants.LN_10;
    }
    
    fn Log2(x: f64) -> f64 {
        return Self.Ln(x) / MathConstants.LN_2;
    }
    
    fn IsInteger(x: f64) -> Bool {
        return Self.Abs(x - (x as i64 as f64)) < 1e-15;
    }
    
    fn Floor(x: f64) -> f64 {
        var i: i64 = x as i64;
        return if (x >= 0.0 or (i as f64) == x) (i as f64) else ((i - 1) as f64);
    }
    
    fn Ceil(x: f64) -> f64 {
        var i: i64 = x as i64;
        return if (x <= 0.0 or (i as f64) == x) (i as f64) else ((i + 1) as f64);
    }
    
    fn Round(x: f64) -> f64 {
        return Self.Floor(x + 0.5);
    }
    
    fn Factorial(n: i32) -> f64 {
        if (n < 0) { return MathConstants.NAN; }
        if (n <= 1) { return 1.0; }
        
        var result: f64 = 1.0;
        for (i: i32 in Range(2, n + 1)) {
            result *= i as f64;
        }
        return result;
    }
    
    fn GCD(a: i64, b: i64) -> i64 {
        while (b != 0) {
            var temp: i64 = b;
            b = a % b;
            a = temp;
        }
        return Self.AbsInt(a);
    }
    
    fn LCM(a: i64, b: i64) -> i64 {
        return Self.AbsInt(a * b) / Self.GCD(a, b);
    }
    
    fn AbsInt(x: i64) -> i64 {
        return if (x < 0) -x else x;
    }
}

// Trigonometry
class Trigonometry {
    fn Sin(x: f64) -> f64 {
        // Normalize to [-2π, 2π]
        x = Self.NormalizeAngle(x);
        
        // Taylor series: sin(x) = x - x^3/3! + x^5/5! - x^7/7! + ...
        var result: f64 = 0.0;
        var term: f64 = x;
        var x2: f64 = x * x;
        
        for (n: i32 in Range(1, 50, 2)) {
            result += term;
            term *= -x2 / ((n + 1) * (n + 2)) as f64;
            if (BasicMath.Abs(term) < 1e-15) { break; }
        }
        
        return result;
    }
    
    fn Cos(x: f64) -> f64 {
        // cos(x) = sin(x + π/2)
        return Self.Sin(x + MathConstants.PI / 2.0);
    }
    
    fn Tan(x: f64) -> f64 {
        var cos_x: f64 = Self.Cos(x);
        if (BasicMath.Abs(cos_x) < 1e-15) {
            return MathConstants.INFINITY;
        }
        return Self.Sin(x) / cos_x;
    }
    
    fn Asin(x: f64) -> f64 {
        if (BasicMath.Abs(x) > 1.0) { return MathConstants.NAN; }
        if (x == 1.0) { return MathConstants.PI / 2.0; }
        if (x == -1.0) { return -MathConstants.PI / 2.0; }
        
        // Use series expansion
        var result: f64 = x;
        var term: f64 = x;
        var x2: f64 = x * x;
        
        for (n: i32 in Range(1, 50)) {
            term *= x2 * (2 * n - 1) * (2 * n - 1) / ((2 * n) * (2 * n + 1)) as f64;
            result += term;
            if (BasicMath.Abs(term) < 1e-15) { break; }
        }
        
        return result;
    }
    
    fn Acos(x: f64) -> f64 {
        return MathConstants.PI / 2.0 - Self.Asin(x);
    }
    
    fn Atan(x: f64) -> f64 {
        if (BasicMath.Abs(x) > 1.0) {
            return (MathConstants.PI / 2.0) * (if (x > 0.0) 1.0 else -1.0) - Self.Atan(1.0 / x);
        }
        
        // Taylor series: atan(x) = x - x^3/3 + x^5/5 - x^7/7 + ...
        var result: f64 = 0.0;
        var term: f64 = x;
        var x2: f64 = x * x;
        
        for (n: i32 in Range(1, 100, 2)) {
            result += term / (n as f64);
            term *= -x2;
            if (BasicMath.Abs(term) < 1e-15) { break; }
        }
        
        return result;
    }
    
    fn Atan2(y: f64, x: f64) -> f64 {
        if (x > 0.0) { return Self.Atan(y / x); }
        if (x < 0.0 and y >= 0.0) { return Self.Atan(y / x) + MathConstants.PI; }
        if (x < 0.0 and y < 0.0) { return Self.Atan(y / x) - MathConstants.PI; }
        if (x == 0.0 and y > 0.0) { return MathConstants.PI / 2.0; }
        if (x == 0.0 and y < 0.0) { return -MathConstants.PI / 2.0; }
        return MathConstants.NAN; // x == 0 and y == 0
    }
    
    fn Sinh(x: f64) -> f64 {
        return (BasicMath.Exp(x) - BasicMath.Exp(-x)) / 2.0;
    }
    
    fn Cosh(x: f64) -> f64 {
        return (BasicMath.Exp(x) + BasicMath.Exp(-x)) / 2.0;
    }
    
    fn Tanh(x: f64) -> f64 {
        var exp_2x: f64 = BasicMath.Exp(2.0 * x);
        return (exp_2x - 1.0) / (exp_2x + 1.0);
    }
    
    fn NormalizeAngle(x: f64) -> f64 {
        var two_pi: f64 = 2.0 * MathConstants.PI;
        while (x > MathConstants.PI) { x -= two_pi; }
        while (x < -MathConstants.PI) { x += two_pi; }
        return x;
    }
    
    fn DegreesToRadians(degrees: f64) -> f64 {
        return degrees * MathConstants.PI / 180.0;
    }
    
    fn RadiansToDegrees(radians: f64) -> f64 {
        return radians * 180.0 / MathConstants.PI;
    }
}

// Complex numbers
class Complex {
    var real: f64;
    var imag: f64;
    
    fn Create(real: f64, imag: f64) -> Self {
        return { .real = real, .imag = imag };
    }
    
    fn FromPolar(magnitude: f64, angle: f64) -> Self {
        return Complex.Create(magnitude * Trigonometry.Cos(angle), magnitude * Trigonometry.Sin(angle));
    }
    
    fn Add(self: Self, other: Complex) -> Complex {
        return Complex.Create(self.real + other.real, self.imag + other.imag);
    }
    
    fn Subtract(self: Self, other: Complex) -> Complex {
        return Complex.Create(self.real - other.real, self.imag - other.imag);
    }
    
    fn Multiply(self: Self, other: Complex) -> Complex {
        return Complex.Create(
            self.real * other.real - self.imag * other.imag,
            self.real * other.imag + self.imag * other.real
        );
    }
    
    fn Divide(self: Self, other: Complex) -> Complex {
        var denominator: f64 = other.real * other.real + other.imag * other.imag;
        return Complex.Create(
            (self.real * other.real + self.imag * other.imag) / denominator,
            (self.imag * other.real - self.real * other.imag) / denominator
        );
    }
    
    fn Magnitude(self: Self) -> f64 {
        return BasicMath.Sqrt(self.real * self.real + self.imag * self.imag);
    }
    
    fn Phase(self: Self) -> f64 {
        return Trigonometry.Atan2(self.imag, self.real);
    }
    
    fn Conjugate(self: Self) -> Complex {
        return Complex.Create(self.real, -self.imag);
    }
    
    fn Exp(self: Self) -> Complex {
        var exp_real: f64 = BasicMath.Exp(self.real);
        return Complex.Create(exp_real * Trigonometry.Cos(self.imag), exp_real * Trigonometry.Sin(self.imag));
    }
    
    fn Ln(self: Self) -> Complex {
        return Complex.Create(BasicMath.Ln(self.Magnitude()), self.Phase());
    }
    
    fn Pow(self: Self, exponent: Complex) -> Complex {
        return self.Ln().Multiply(exponent).Exp();
    }
    
    fn ToString(self: Self) -> String {
        if (self.imag >= 0.0) {
            return String.FromFloat64(self.real) + " + " + String.FromFloat64(self.imag) + "i";
        } else {
            return String.FromFloat64(self.real) + " - " + String.FromFloat64(-self.imag) + "i";
        }
    }
}

// Vector mathematics
class Vector2D {
    var x: f64;
    var y: f64;
    
    fn Create(x: f64, y: f64) -> Self {
        return { .x = x, .y = y };
    }
    
    fn Add(self: Self, other: Vector2D) -> Vector2D {
        return Vector2D.Create(self.x + other.x, self.y + other.y);
    }
    
    fn Subtract(self: Self, other: Vector2D) -> Vector2D {
        return Vector2D.Create(self.x - other.x, self.y - other.y);
    }
    
    fn Scale(self: Self, scalar: f64) -> Vector2D {
        return Vector2D.Create(self.x * scalar, self.y * scalar);
    }
    
    fn Dot(self: Self, other: Vector2D) -> f64 {
        return self.x * other.x + self.y * other.y;
    }
    
    fn Cross(self: Self, other: Vector2D) -> f64 {
        return self.x * other.y - self.y * other.x;
    }
    
    fn Magnitude(self: Self) -> f64 {
        return BasicMath.Sqrt(self.x * self.x + self.y * self.y);
    }
    
    fn Normalize(self: Self) -> Vector2D {
        var mag: f64 = self.Magnitude();
        if (mag == 0.0) { return Vector2D.Create(0.0, 0.0); }
        return Vector2D.Create(self.x / mag, self.y / mag);
    }
    
    fn Angle(self: Self) -> f64 {
        return Trigonometry.Atan2(self.y, self.x);
    }
    
    fn Distance(self: Self, other: Vector2D) -> f64 {
        return self.Subtract(other).Magnitude();
    }
    
    fn Lerp(self: Self, other: Vector2D, t: f64) -> Vector2D {
        return Vector2D.Create(
            self.x + (other.x - self.x) * t,
            self.y + (other.y - self.y) * t
        );
    }
}

class Vector3D {
    var x: f64;
    var y: f64;
    var z: f64;
    
    fn Create(x: f64, y: f64, z: f64) -> Self {
        return { .x = x, .y = y, .z = z };
    }
    
    fn Add(self: Self, other: Vector3D) -> Vector3D {
        return Vector3D.Create(self.x + other.x, self.y + other.y, self.z + other.z);
    }
    
    fn Subtract(self: Self, other: Vector3D) -> Vector3D {
        return Vector3D.Create(self.x - other.x, self.y - other.y, self.z - other.z);
    }
    
    fn Scale(self: Self, scalar: f64) -> Vector3D {
        return Vector3D.Create(self.x * scalar, self.y * scalar, self.z * scalar);
    }
    
    fn Dot(self: Self, other: Vector3D) -> f64 {
        return self.x * other.x + self.y * other.y + self.z * other.z;
    }
    
    fn Cross(self: Self, other: Vector3D) -> Vector3D {
        return Vector3D.Create(
            self.y * other.z - self.z * other.y,
            self.z * other.x - self.x * other.z,
            self.x * other.y - self.y * other.x
        );
    }
    
    fn Magnitude(self: Self) -> f64 {
        return BasicMath.Sqrt(self.x * self.x + self.y * self.y + self.z * self.z);
    }
    
    fn Normalize(self: Self) -> Vector3D {
        var mag: f64 = self.Magnitude();
        if (mag == 0.0) { return Vector3D.Create(0.0, 0.0, 0.0); }
        return Vector3D.Create(self.x / mag, self.y / mag, self.z / mag);
    }
}

// Matrix mathematics
class Matrix2x2 {
    var m00: f64; var m01: f64;
    var m10: f64; var m11: f64;
    
    fn Create(m00: f64, m01: f64, m10: f64, m11: f64) -> Self {
        return { .m00 = m00, .m01 = m01, .m10 = m10, .m11 = m11 };
    }
    
    fn Identity() -> Self {
        return Matrix2x2.Create(1.0, 0.0, 0.0, 1.0);
    }
    
    fn Multiply(self: Self, other: Matrix2x2) -> Matrix2x2 {
        return Matrix2x2.Create(
            self.m00 * other.m00 + self.m01 * other.m10,
            self.m00 * other.m01 + self.m01 * other.m11,
            self.m10 * other.m00 + self.m11 * other.m10,
            self.m10 * other.m01 + self.m11 * other.m11
        );
    }
    
    fn Determinant(self: Self) -> f64 {
        return self.m00 * self.m11 - self.m01 * self.m10;
    }
    
    fn Inverse(self: Self) -> Optional(Matrix2x2) {
        var det: f64 = self.Determinant();
        if (BasicMath.Abs(det) < 1e-15) {
            return Optional(Matrix2x2).None();
        }
        
        var inv_det: f64 = 1.0 / det;
        return Optional(Matrix2x2).Some(Matrix2x2.Create(
            self.m11 * inv_det, -self.m01 * inv_det,
            -self.m10 * inv_det, self.m00 * inv_det
        ));
    }
    
    fn Transform(self: Self, vector: Vector2D) -> Vector2D {
        return Vector2D.Create(
            self.m00 * vector.x + self.m01 * vector.y,
            self.m10 * vector.x + self.m11 * vector.y
        );
    }
}

class Matrix3x3 {
    var data: Array(f64); // 9 elements in row-major order
    
    fn Create() -> Self {
        var data: Array(f64) = Array(f64)();
        for (i: i32 in Range(0, 9)) {
            data.Push(0.0);
        }
        return { .data = data };
    }
    
    fn Identity() -> Self {
        var matrix: Matrix3x3 = Matrix3x3.Create();
        matrix.data.Set(0, 1.0); // [0,0]
        matrix.data.Set(4, 1.0); // [1,1]
        matrix.data.Set(8, 1.0); // [2,2]
        return matrix;
    }
    
    fn Set(self: Self, row: i32, col: i32, value: f64) {
        self.data.Set((row * 3 + col) as u64, value);
    }
    
    fn Get(self: Self, row: i32, col: i32) -> f64 {
        return self.data.Get((row * 3 + col) as u64).Unwrap();
    }
    
    fn Multiply(self: Self, other: Matrix3x3) -> Matrix3x3 {
        var result: Matrix3x3 = Matrix3x3.Create();
        
        for (i: i32 in Range(0, 3)) {
            for (j: i32 in Range(0, 3)) {
                var sum: f64 = 0.0;
                for (k: i32 in Range(0, 3)) {
                    sum += self.Get(i, k) * other.Get(k, j);
                }
                result.Set(i, j, sum);
            }
        }
        
        return result;
    }
    
    fn Determinant(self: Self) -> f64 {
        return self.Get(0, 0) * (self.Get(1, 1) * self.Get(2, 2) - self.Get(1, 2) * self.Get(2, 1)) -
               self.Get(0, 1) * (self.Get(1, 0) * self.Get(2, 2) - self.Get(1, 2) * self.Get(2, 0)) +
               self.Get(0, 2) * (self.Get(1, 0) * self.Get(2, 1) - self.Get(1, 1) * self.Get(2, 0));
    }
}

// Geometry
class Point2D {
    var x: f64;
    var y: f64;
    
    fn Create(x: f64, y: f64) -> Self {
        return { .x = x, .y = y };
    }
    
    fn Distance(self: Self, other: Point2D) -> f64 {
        var dx: f64 = self.x - other.x;
        var dy: f64 = self.y - other.y;
        return BasicMath.Sqrt(dx * dx + dy * dy);
    }
}

class Rectangle {
    var x: f64;
    var y: f64;
    var width: f64;
    var height: f64;
    
    fn Create(x: f64, y: f64, width: f64, height: f64) -> Self {
        return { .x = x, .y = y, .width = width, .height = height };
    }
    
    fn Contains(self: Self, point: Point2D) -> Bool {
        return point.x >= self.x and point.x <= self.x + self.width and
               point.y >= self.y and point.y <= self.y + self.height;
    }
    
    fn Intersects(self: Self, other: Rectangle) -> Bool {
        return not (self.x + self.width < other.x or
                   other.x + other.width < self.x or
                   self.y + self.height < other.y or
                   other.y + other.height < self.y);
    }
    
    fn Area(self: Self) -> f64 {
        return self.width * self.height;
    }
    
    fn Perimeter(self: Self) -> f64 {
        return 2.0 * (self.width + self.height);
    }
}

class Circle {
    var center: Point2D;
    var radius: f64;
    
    fn Create(center: Point2D, radius: f64) -> Self {
        return { .center = center, .radius = radius };
    }
    
    fn Contains(self: Self, point: Point2D) -> Bool {
        return self.center.Distance(point) <= self.radius;
    }
    
    fn Area(self: Self) -> f64 {
        return MathConstants.PI * self.radius * self.radius;
    }
    
    fn Circumference(self: Self) -> f64 {
        return 2.0 * MathConstants.PI * self.radius;
    }
    
    fn Intersects(self: Self, other: Circle) -> Bool {
        return self.center.Distance(other.center) <= (self.radius + other.radius);
    }
}

// Random number generation
class Random {
    var seed: u64;
    
    fn Create(seed: u64) -> Self {
        return { .seed = seed };
    }
    
    fn CreateWithTime() -> Self {
        return Random.Create(Time.GetCurrentTimeMillis() as u64);
    }
    
    fn NextU64(self: Self) -> u64 {
        // Linear congruential generator
        self.seed = (self.seed * 1103515245 + 12345) % (1 << 31);
        return self.seed;
    }
    
    fn NextF64(self: Self) -> f64 {
        return (self.NextU64() as f64) / ((1 << 31) as f64);
    }
    
    fn NextRange(self: Self, min: f64, max: f64) -> f64 {
        return min + self.NextF64() * (max - min);
    }
    
    fn NextInt(self: Self, min: i32, max: i32) -> i32 {
        return min + (self.NextU64() % ((max - min + 1) as u64)) as i32;
    }
    
    fn NextGaussian(self: Self) -> f64 {
        // Box-Muller transform
        var u1: f64 = self.NextF64();
        var u2: f64 = self.NextF64();
        
        return BasicMath.Sqrt(-2.0 * BasicMath.Ln(u1)) * Trigonometry.Cos(2.0 * MathConstants.PI * u2);
    }
}

// Statistics and probability
class Statistics {
    fn Mean(values: Array(f64)) -> f64 {
        if (values.Size() == 0) { return 0.0; }
        
        var sum: f64 = 0.0;
        for (value: f64 in values) {
            sum += value;
        }
        return sum / (values.Size() as f64);
    }
    
    fn Median(values: Array(f64)) -> f64 {
        if (values.Size() == 0) { return 0.0; }
        
        var sorted: Array(f64) = Self.Sort(values);
        var n: u64 = sorted.Size();
        
        if (n % 2 == 1) {
            return sorted.Get(n / 2).Unwrap();
        } else {
            var mid1: f64 = sorted.Get(n / 2 - 1).Unwrap();
            var mid2: f64 = sorted.Get(n / 2).Unwrap();
            return (mid1 + mid2) / 2.0;
        }
    }
    
    fn StandardDeviation(values: Array(f64)) -> f64 {
        return BasicMath.Sqrt(Self.Variance(values));
    }
    
    fn Variance(values: Array(f64)) -> f64 {
        if (values.Size() <= 1) { return 0.0; }
        
        var mean: f64 = Self.Mean(values);
        var sum_sq_diff: f64 = 0.0;
        
        for (value: f64 in values) {
            var diff: f64 = value - mean;
            sum_sq_diff += diff * diff;
        }
        
        return sum_sq_diff / ((values.Size() - 1) as f64);
    }
    
    fn Sort(values: Array(f64)) -> Array(f64) {
        var sorted: Array(f64) = Array(f64)();
        for (value: f64 in values) {
            sorted.Push(value);
        }
        
        // Bubble sort (simple implementation)
        for (i: u64 in Range(0, sorted.Size())) {
            for (j: u64 in Range(0, sorted.Size() - 1 - i)) {
                var val1: f64 = sorted.Get(j).Unwrap();
                var val2: f64 = sorted.Get(j + 1).Unwrap();
                if (val1 > val2) {
                    sorted.Set(j, val2);
                    sorted.Set(j + 1, val1);
                }
            }
        }
        
        return sorted;
    }
}

// Calculus operations
class Calculus {
    fn Derivative(f: fn(f64) -> f64, x: f64, h: f64) -> f64 {
        // Central difference approximation
        return (f(x + h) - f(x - h)) / (2.0 * h);
    }
    
    fn Integral(f: fn(f64) -> f64, a: f64, b: f64, n: i32) -> f64 {
        // Trapezoidal rule
        var h: f64 = (b - a) / (n as f64);
        var sum: f64 = (f(a) + f(b)) / 2.0;
        
        for (i: i32 in Range(1, n)) {
            sum += f(a + (i as f64) * h);
        }
        
        return sum * h;
    }
    
    fn Simpson(f: fn(f64) -> f64, a: f64, b: f64, n: i32) -> f64 {
        // Simpson's rule (n must be even)
        if (n % 2 != 0) { n += 1; }
        
        var h: f64 = (b - a) / (n as f64);
        var sum: f64 = f(a) + f(b);
        
        for (i: i32 in Range(1, n)) {
            var x: f64 = a + (i as f64) * h;
            if (i % 2 == 0) {
                sum += 2.0 * f(x);
            } else {
                sum += 4.0 * f(x);
            }
        }
        
        return sum * h / 3.0;
    }
}

// Simple math aliases for easy access
package Arythmatick.Simple api;

fn Sin(x: f64) -> f64 { return Trigonometry.Sin(x); }
fn Cos(x: f64) -> f64 { return Trigonometry.Cos(x); }
fn Tan(x: f64) -> f64 { return Trigonometry.Tan(x); }
fn Sqrt(x: f64) -> f64 { return BasicMath.Sqrt(x); }
fn Pow(base: f64, exp: f64) -> f64 { return BasicMath.Pow(base, exp); }
fn Abs(x: f64) -> f64 { return BasicMath.Abs(x); }
fn Floor(x: f64) -> f64 { return BasicMath.Floor(x); }
fn Ceil(x: f64) -> f64 { return BasicMath.Ceil(x); }
fn Round(x: f64) -> f64 { return BasicMath.Round(x); }
fn Min(a: f64, b: f64) -> f64 { return BasicMath.Min(a, b); }
fn Max(a: f64, b: f64) -> f64 { return BasicMath.Max(a, b); }
fn Exp(x: f64) -> f64 { return BasicMath.Exp(x); }
fn Ln(x: f64) -> f64 { return BasicMath.Ln(x); }
fn Log10(x: f64) -> f64 { return BasicMath.Log10(x); }