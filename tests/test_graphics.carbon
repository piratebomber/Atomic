// Tests for Graphics and Game Engine
package Tests.Graphics api;

import Atomic.Testing;
import Atomic.Graphics;

class GraphicsTests {
    fn RunAllTests() -> TestReport {
        var runner: TestRunner = TestRunner.Create();
        var suite: TestSuite = TestSuite.Create("Graphics Engine");
        
        // Color Tests
        suite.AddTest(TestCase.Create("Color_Create", fn() -> TestResult {
            var color: Color = Color.Create(1.0, 0.5, 0.0, 1.0);
            return Assert.True(color.r == 1.0 and color.g == 0.5 and color.b == 0.0 and color.a == 1.0, "Color values should be set correctly");
        }));
        
        suite.AddTest(TestCase.Create("Color_FromRGB", fn() -> TestResult {
            var color: Color = Color.FromRGB(255, 128, 0);
            return Assert.True(color.r == 1.0 and color.g == 0.5019607843137255 and color.b == 0.0, "RGB conversion should work");
        }));
        
        suite.AddTest(TestCase.Create("Color_Presets", fn() -> TestResult {
            var red: Color = Color.Red();
            var white: Color = Color.White();
            return Assert.True(red.r == 1.0 and red.g == 0.0 and white.r == 1.0 and white.g == 1.0, "Preset colors should be correct");
        }));
        
        // Vector Tests
        suite.AddTest(TestCase.Create("Vector2_Create", fn() -> TestResult {
            var v: Vector2 = Vector2.Create(3.0, 4.0);
            return Assert.True(v.x == 3.0 and v.y == 4.0, "Vector2 should be created correctly");
        }));
        
        suite.AddTest(TestCase.Create("Vector2_Add", fn() -> TestResult {
            var v1: Vector2 = Vector2.Create(1.0, 2.0);
            var v2: Vector2 = Vector2.Create(3.0, 4.0);
            var result: Vector2 = v1.Add(v2);
            return Assert.True(result.x == 4.0 and result.y == 6.0, "Vector addition should work");
        }));
        
        suite.AddTest(TestCase.Create("Vector2_Length", fn() -> TestResult {
            var v: Vector2 = Vector2.Create(3.0, 4.0);
            var length: f32 = v.Length();
            return Assert.True(Math.Abs(length - 5.0) < 0.001, "Vector length should be 5");
        }));
        
        suite.AddTest(TestCase.Create("Vector3_Cross", fn() -> TestResult {
            var v1: Vector3 = Vector3.Create(1.0, 0.0, 0.0);
            var v2: Vector3 = Vector3.Create(0.0, 1.0, 0.0);
            var cross: Vector3 = v1.Cross(v2);
            return Assert.True(cross.x == 0.0 and cross.y == 0.0 and cross.z == 1.0, "Cross product should be (0,0,1)");
        }));
        
        // Matrix Tests
        suite.AddTest(TestCase.Create("Matrix4_Identity", fn() -> TestResult {
            var identity: Matrix4 = Matrix4.Identity();
            var m00: Optional(f32) = identity.m.Get(0);
            var m55: Optional(f32) = identity.m.Get(5);
            return Assert.True(m00.IsSome() and m00.Unwrap() == 1.0 and m55.IsSome() and m55.Unwrap() == 1.0, "Identity matrix should have 1s on diagonal");
        }));
        
        suite.AddTest(TestCase.Create("Matrix4_Translation", fn() -> TestResult {
            var translation: Vector3 = Vector3.Create(5.0, 10.0, 15.0);
            var matrix: Matrix4 = Matrix4.Translation(translation);
            var m12: Optional(f32) = matrix.m.Get(12);
            var m13: Optional(f32) = matrix.m.Get(13);
            return Assert.True(m12.IsSome() and m12.Unwrap() == 5.0 and m13.IsSome() and m13.Unwrap() == 10.0, "Translation matrix should be correct");
        }));
        
        // Mesh Tests
        suite.AddTest(TestCase.Create("Vertex_Create", fn() -> TestResult {
            var pos: Vector3 = Vector3.Create(1.0, 2.0, 3.0);
            var normal: Vector3 = Vector3.Create(0.0, 1.0, 0.0);
            var uv: Vector2 = Vector2.Create(0.5, 0.5);
            var vertex: Vertex = Vertex.Create(pos, normal, uv);
            return Assert.True(vertex.position.x == 1.0 and vertex.normal.y == 1.0 and vertex.tex_coord.x == 0.5, "Vertex should be created correctly");
        }));
        
        suite.AddTest(TestCase.Create("Mesh_Quad", fn() -> TestResult {
            var quad: Mesh = Mesh.CreateQuad();
            return Assert.True(quad.vertex_count == 4 and quad.index_count == 6, "Quad should have 4 vertices and 6 indices");
        }));
        
        // Camera Tests
        suite.AddTest(TestCase.Create("Camera_Create", fn() -> TestResult {
            var camera: Camera = Camera.Create();
            return Assert.True(camera.fov == 60.0 and camera.near_plane == 0.1, "Camera should have default values");
        }));
        
        suite.AddTest(TestCase.Create("Camera_ViewMatrix", fn() -> TestResult {
            var camera: Camera = Camera.Create();
            camera.position = Vector3.Create(0.0, 0.0, 5.0);
            var view_matrix: Matrix4 = camera.GetViewMatrix();
            return Assert.True(view_matrix.m.Size() == 16, "View matrix should be 4x4");
        }));
        
        // GameObject Tests
        suite.AddTest(TestCase.Create("GameObject_Create", fn() -> TestResult {
            var obj: GameObject = GameObject.Create("TestObject");
            return Assert.Equal("TestObject", obj.name, "GameObject name should be set");
        }));
        
        suite.AddTest(TestCase.Create("Transform_Create", fn() -> TestResult {
            var transform: Transform = Transform.Create();
            return Assert.True(transform.position.x == 0.0 and transform.scale.x == 1.0, "Transform should have default values");
        }));
        
        // Game Engine Tests
        suite.AddTest(TestCase.Create("GameEngine_Create", fn() -> TestResult {
            var engine: GameEngine = GameEngine.Create();
            return Assert.True(engine.game_objects.Size() == 0 and not engine.is_running, "Game engine should start empty");
        }));
        
        suite.AddTest(TestCase.Create("GameEngine_AddObject", fn() -> TestResult {
            var engine: GameEngine = GameEngine.Create();
            var obj: GameObject = GameObject.Create("Player");
            engine.AddGameObject(obj);
            return Assert.True(engine.game_objects.Size() == 1, "Game engine should contain one object");
        }));
        
        runner.AddSuite(suite);
        return runner.RunAll();
    }
}

class GraphicsBenchmarks {
    fn RunBenchmarks() {
        var vector_bench: Benchmark = Benchmark.Create("Vector3_Operations", fn() {
            var v1: Vector3 = Vector3.Create(1.0, 2.0, 3.0);
            var v2: Vector3 = Vector3.Create(4.0, 5.0, 6.0);
            var result: Vector3 = v1.Add(v2);
            var cross: Vector3 = v1.Cross(v2);
            var length: f32 = result.Length();
        });
        vector_bench.WithIterations(10000);
        
        var matrix_bench: Benchmark = Benchmark.Create("Matrix4_Creation", fn() {
            var translation: Vector3 = Vector3.Create(10.0, 20.0, 30.0);
            var matrix: Matrix4 = Matrix4.Translation(translation);
            var identity: Matrix4 = Matrix4.Identity();
        });
        matrix_bench.WithIterations(5000);
        
        var mesh_bench: Benchmark = Benchmark.Create("Mesh_Creation", fn() {
            var quad: Mesh = Mesh.CreateQuad();
        });
        mesh_bench.WithIterations(1000);
        
        var gameobject_bench: Benchmark = Benchmark.Create("GameObject_Update", fn() {
            var obj: GameObject = GameObject.Create("BenchObject");
            obj.Update(0.016);
        });
        gameobject_bench.WithIterations(1000);
        
        Console.WriteLine("=== Graphics Engine Performance Benchmarks ===");
        vector_bench.Run().Print();
        matrix_bench.Run().Print();
        mesh_bench.Run().Print();
        gameobject_bench.Run().Print();
    }
}