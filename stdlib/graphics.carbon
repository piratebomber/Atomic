// Atomic Graphics and Game Engine
package Atomic.Graphics api;

import Std.String;
import Std.Array;
import Std.Collections;
import Std.Math;
import Std.Platform;

class Color {
    var r: f32;
    var g: f32;
    var b: f32;
    var a: f32;
    
    fn Create(r: f32, g: f32, b: f32, a: f32) -> Self {
        return { .r = r, .g = g, .b = b, .a = a };
    }
    
    fn FromRGB(r: u8, g: u8, b: u8) -> Self {
        return Self.Create(r as f32 / 255.0, g as f32 / 255.0, b as f32 / 255.0, 1.0);
    }
    
    fn White() -> Self { return Self.Create(1.0, 1.0, 1.0, 1.0); }
    fn Black() -> Self { return Self.Create(0.0, 0.0, 0.0, 1.0); }
    fn Red() -> Self { return Self.Create(1.0, 0.0, 0.0, 1.0); }
    fn Green() -> Self { return Self.Create(0.0, 1.0, 0.0, 1.0); }
    fn Blue() -> Self { return Self.Create(0.0, 0.0, 1.0, 1.0); }
}

class Vector2 {
    var x: f32;
    var y: f32;
    
    fn Create(x: f32, y: f32) -> Self {
        return { .x = x, .y = y };
    }
    
    fn Zero() -> Self { return Self.Create(0.0, 0.0); }
    fn One() -> Self { return Self.Create(1.0, 1.0); }
    
    fn Add(self: Self, other: Vector2) -> Vector2 {
        return Vector2.Create(self.x + other.x, self.y + other.y);
    }
    
    fn Length(self: Self) -> f32 {
        return Math.Sqrt(self.x * self.x + self.y * self.y);
    }
}

class Vector3 {
    var x: f32;
    var y: f32;
    var z: f32;
    
    fn Create(x: f32, y: f32, z: f32) -> Self {
        return { .x = x, .y = y, .z = z };
    }
    
    fn Zero() -> Self { return Self.Create(0.0, 0.0, 0.0); }
    fn One() -> Self { return Self.Create(1.0, 1.0, 1.0); }
    fn Up() -> Self { return Self.Create(0.0, 1.0, 0.0); }
    
    fn Add(self: Self, other: Vector3) -> Vector3 {
        return Vector3.Create(self.x + other.x, self.y + other.y, self.z + other.z);
    }
    
    fn Cross(self: Self, other: Vector3) -> Vector3 {
        return Vector3.Create(
            self.y * other.z - self.z * other.y,
            self.z * other.x - self.x * other.z,
            self.x * other.y - self.y * other.x
        );
    }
    
    fn Length(self: Self) -> f32 {
        return Math.Sqrt(self.x * self.x + self.y * self.y + self.z * self.z);
    }
}

class Matrix4 {
    var m: Array(f32);
    
    fn Create() -> Self {
        var matrix: Array(f32) = Array(f32)();
        for (i: i32 in Range(0, 16)) {
            matrix.Push(0.0);
        }
        return { .m = matrix };
    }
    
    fn Identity() -> Self {
        var matrix: Matrix4 = Matrix4.Create();
        matrix.m.Set(0, 1.0);
        matrix.m.Set(5, 1.0);
        matrix.m.Set(10, 1.0);
        matrix.m.Set(15, 1.0);
        return matrix;
    }
    
    fn Translation(translation: Vector3) -> Self {
        var matrix: Matrix4 = Matrix4.Identity();
        matrix.m.Set(12, translation.x);
        matrix.m.Set(13, translation.y);
        matrix.m.Set(14, translation.z);
        return matrix;
    }
    
    fn Perspective(fov: f32, aspect: f32, near: f32, far: f32) -> Self {
        var matrix: Matrix4 = Matrix4.Create();
        var tan_half_fov: f32 = Math.Tan(fov / 2.0);
        
        matrix.m.Set(0, 1.0 / (aspect * tan_half_fov));
        matrix.m.Set(5, 1.0 / tan_half_fov);
        matrix.m.Set(10, -(far + near) / (far - near));
        matrix.m.Set(11, -1.0);
        matrix.m.Set(14, -(2.0 * far * near) / (far - near));
        
        return matrix;
    }
}

choice TextureFormat { RGB8, RGBA8, Depth24 }

class Texture {
    var id: u32;
    var width: i32;
    var height: i32;
    var format: TextureFormat;
    
    fn Create(width: i32, height: i32, format: TextureFormat) -> Self {
        var texture: Texture = { .id = 0, .width = width, .height = height, .format = format };
        texture.id = GraphicsDevice.CreateTexture(width, height, format);
        return texture;
    }
    
    fn SetData(self: Self, data: Array(u8)) {
        GraphicsDevice.SetTextureData(self.id, data);
    }
    
    fn Bind(self: Self, slot: i32) {
        GraphicsDevice.BindTexture(self.id, slot);
    }
}

choice ShaderType { Vertex, Fragment }

class Shader {
    var program_id: u32;
    
    fn Create(vertex_source: String, fragment_source: String) -> Result(Self, String) {
        var vertex_id: u32 = GraphicsDevice.CompileShader(ShaderType.Vertex, vertex_source);
        if (vertex_id == 0) {
            return Result(Self, String).Error("Failed to compile vertex shader");
        }
        
        var fragment_id: u32 = GraphicsDevice.CompileShader(ShaderType.Fragment, fragment_source);
        if (fragment_id == 0) {
            return Result(Self, String).Error("Failed to compile fragment shader");
        }
        
        var program_id: u32 = GraphicsDevice.CreateShaderProgram(vertex_id, fragment_id);
        if (program_id == 0) {
            return Result(Self, String).Error("Failed to link shader program");
        }
        
        return Result(Self, String).Ok({ .program_id = program_id });
    }
    
    fn Use(self: Self) {
        GraphicsDevice.UseShaderProgram(self.program_id);
    }
    
    fn SetUniform(self: Self, name: String, value: f32) {
        var location: i32 = GraphicsDevice.GetUniformLocation(self.program_id, name);
        GraphicsDevice.SetUniform1f(location, value);
    }
    
    fn SetUniformMatrix4(self: Self, name: String, value: Matrix4) {
        var location: i32 = GraphicsDevice.GetUniformLocation(self.program_id, name);
        GraphicsDevice.SetUniformMatrix4f(location, value.m);
    }
}

class Vertex {
    var position: Vector3;
    var normal: Vector3;
    var tex_coord: Vector2;
    
    fn Create(position: Vector3, normal: Vector3, tex_coord: Vector2) -> Self {
        return { .position = position, .normal = normal, .tex_coord = tex_coord };
    }
}

class Mesh {
    var vertex_array_id: u32;
    var vertex_count: i32;
    var index_count: i32;
    
    fn Create(vertices: Array(Vertex), indices: Array(u32)) -> Self {
        var vao: u32 = GraphicsDevice.CreateVertexArray();
        var vbo: u32 = GraphicsDevice.CreateBuffer();
        var ebo: u32 = GraphicsDevice.CreateBuffer();
        
        GraphicsDevice.BindVertexArray(vao);
        GraphicsDevice.BindBuffer(0, vbo);
        GraphicsDevice.SetBufferData(0, vertices);
        GraphicsDevice.BindBuffer(1, ebo);
        GraphicsDevice.SetIndexBufferData(indices);
        
        return { .vertex_array_id = vao, .vertex_count = vertices.Size() as i32, .index_count = indices.Size() as i32 };
    }
    
    fn CreateQuad() -> Self {
        var vertices: Array(Vertex) = Array(Vertex)();
        vertices.Push(Vertex.Create(Vector3.Create(-1.0, -1.0, 0.0), Vector3.Create(0.0, 0.0, 1.0), Vector2.Create(0.0, 0.0)));
        vertices.Push(Vertex.Create(Vector3.Create(1.0, -1.0, 0.0), Vector3.Create(0.0, 0.0, 1.0), Vector2.Create(1.0, 0.0)));
        vertices.Push(Vertex.Create(Vector3.Create(1.0, 1.0, 0.0), Vector3.Create(0.0, 0.0, 1.0), Vector2.Create(1.0, 1.0)));
        vertices.Push(Vertex.Create(Vector3.Create(-1.0, 1.0, 0.0), Vector3.Create(0.0, 0.0, 1.0), Vector2.Create(0.0, 1.0)));
        
        var indices: Array(u32) = Array(u32)();
        indices.Push(0); indices.Push(1); indices.Push(2);
        indices.Push(2); indices.Push(3); indices.Push(0);
        
        return Mesh.Create(vertices, indices);
    }
    
    fn Render(self: Self) {
        GraphicsDevice.BindVertexArray(self.vertex_array_id);
        GraphicsDevice.DrawElements(0, self.index_count);
    }
}

class Camera {
    var position: Vector3;
    var rotation: Vector3;
    var fov: f32;
    var aspect_ratio: f32;
    var near_plane: f32;
    var far_plane: f32;
    
    fn Create() -> Self {
        return { .position = Vector3.Zero(), .rotation = Vector3.Zero(), .fov = 60.0, .aspect_ratio = 16.0 / 9.0, .near_plane = 0.1, .far_plane = 1000.0 };
    }
    
    fn GetViewMatrix(self: Self) -> Matrix4 {
        var translation: Matrix4 = Matrix4.Translation(Vector3.Create(-self.position.x, -self.position.y, -self.position.z));
        return translation;
    }
    
    fn GetProjectionMatrix(self: Self) -> Matrix4 {
        return Matrix4.Perspective(Math.ToRadians(self.fov), self.aspect_ratio, self.near_plane, self.far_plane);
    }
}

class GraphicsDevice {
    var is_initialized: Bool = False;
    
    fn Initialize(width: i32, height: i32) -> Result(Bool, String) {
        if (Platform.IsWindows()) {
            var result: i32 = Self.InitializeD3D11(width, height);
            if (result == 0) {
                Self.is_initialized = True;
                return Result(Bool, String).Ok(True);
            }
        } else {
            var result: i32 = Self.InitializeOpenGL(width, height);
            if (result == 0) {
                Self.is_initialized = True;
                return Result(Bool, String).Ok(True);
            }
        }
        return Result(Bool, String).Error("Failed to initialize graphics");
    }
    
    fn Clear(color: Color) {
        if (Platform.IsWindows()) {
            Self.D3D11Clear(color.r, color.g, color.b, color.a);
        } else {
            Self.OpenGLClear(color.r, color.g, color.b, color.a);
        }
    }
    
    fn CreateTexture(width: i32, height: i32, format: TextureFormat) -> u32 {
        if (Platform.IsWindows()) {
            return Self.D3D11CreateTexture(width, height, format as i32) as u32;
        } else {
            return Self.OpenGLCreateTexture(width, height, format as i32) as u32;
        }
    }
    
    fn SetTextureData(texture_id: u32, data: Array(u8)) {
        if (Platform.IsWindows()) {
            Self.D3D11SetTextureData(texture_id as i64, Platform.ArrayToPtr(data), data.Size() as i32);
        } else {
            Self.OpenGLSetTextureData(texture_id as i32, Platform.ArrayToPtr(data), data.Size() as i32);
        }
    }
    
    fn BindTexture(texture_id: u32, slot: i32) {
        if (Platform.IsWindows()) {
            Self.D3D11BindTexture(texture_id as i64, slot);
        } else {
            Self.OpenGLBindTexture(texture_id as i32, slot);
        }
    }
    
    fn CompileShader(shader_type: ShaderType, source: String) -> u32 {
        if (Platform.IsWindows()) {
            return Self.D3D11CompileShader(shader_type as i32, Platform.StringToPtr(source)) as u32;
        } else {
            return Self.OpenGLCompileShader(shader_type as i32, Platform.StringToPtr(source)) as u32;
        }
    }
    
    fn CreateShaderProgram(vertex_shader: u32, fragment_shader: u32) -> u32 {
        if (Platform.IsWindows()) {
            return Self.D3D11CreateShaderProgram(vertex_shader as i64, fragment_shader as i64) as u32;
        } else {
            return Self.OpenGLCreateShaderProgram(vertex_shader as i32, fragment_shader as i32) as u32;
        }
    }
    
    fn UseShaderProgram(program_id: u32) {
        if (Platform.IsWindows()) {
            Self.D3D11UseShaderProgram(program_id as i64);
        } else {
            Self.OpenGLUseShaderProgram(program_id as i32);
        }
    }
    
    fn GetUniformLocation(program_id: u32, name: String) -> i32 {
        if (Platform.IsWindows()) {
            return Self.D3D11GetUniformLocation(program_id as i64, Platform.StringToPtr(name)) as i32;
        } else {
            return Self.OpenGLGetUniformLocation(program_id as i32, Platform.StringToPtr(name));
        }
    }
    
    fn SetUniform1f(location: i32, value: f32) {
        if (Platform.IsWindows()) {
            Self.D3D11SetUniform1f(location as i64, value);
        } else {
            Self.OpenGLSetUniform1f(location, value);
        }
    }
    
    fn SetUniformMatrix4f(location: i32, matrix: Array(f32)) {
        if (Platform.IsWindows()) {
            Self.D3D11SetUniformMatrix4f(location as i64, Platform.ArrayToPtr(matrix));
        } else {
            Self.OpenGLSetUniformMatrix4f(location, Platform.ArrayToPtr(matrix));
        }
    }
    
    fn CreateVertexArray() -> u32 {
        if (Platform.IsWindows()) {
            return Self.D3D11CreateVertexArray() as u32;
        } else {
            return Self.OpenGLCreateVertexArray() as u32;
        }
    }
    
    fn CreateBuffer() -> u32 {
        if (Platform.IsWindows()) {
            return Self.D3D11CreateBuffer() as u32;
        } else {
            return Self.OpenGLCreateBuffer() as u32;
        }
    }
    
    fn BindVertexArray(vao_id: u32) {
        if (Platform.IsWindows()) {
            Self.D3D11BindVertexArray(vao_id as i64);
        } else {
            Self.OpenGLBindVertexArray(vao_id as i32);
        }
    }
    
    fn BindBuffer(buffer_type: i32, buffer_id: u32) {
        if (Platform.IsWindows()) {
            Self.D3D11BindBuffer(buffer_type, buffer_id as i64);
        } else {
            Self.OpenGLBindBuffer(buffer_type, buffer_id as i32);
        }
    }
    
    fn SetBufferData(buffer_type: i32, vertices: Array(Vertex)) {
        if (Platform.IsWindows()) {
            Self.D3D11SetBufferData(buffer_type, Platform.ArrayToPtr(vertices), vertices.Size() as i32);
        } else {
            Self.OpenGLSetBufferData(buffer_type, Platform.ArrayToPtr(vertices), vertices.Size() as i32);
        }
    }
    
    fn SetIndexBufferData(indices: Array(u32)) {
        if (Platform.IsWindows()) {
            Self.D3D11SetIndexBufferData(Platform.ArrayToPtr(indices), indices.Size() as i32);
        } else {
            Self.OpenGLSetIndexBufferData(Platform.ArrayToPtr(indices), indices.Size() as i32);
        }
    }
    
    fn DrawElements(primitive_type: i32, count: i32) {
        if (Platform.IsWindows()) {
            Self.D3D11DrawElements(primitive_type, count);
        } else {
            Self.OpenGLDrawElements(primitive_type, count);
        }
    }
    
    fn Present() {
        if (Platform.IsWindows()) {
            Self.D3D11Present();
        } else {
            Self.OpenGLSwapBuffers();
        }
    }
    
    // Platform implementations
    fn InitializeD3D11(width: i32, height: i32) -> i32 { return 0; }
    fn InitializeOpenGL(width: i32, height: i32) -> i32 { return 0; }
    fn D3D11Clear(r: f32, g: f32, b: f32, a: f32) { }
    fn OpenGLClear(r: f32, g: f32, b: f32, a: f32) { }
    fn D3D11CreateTexture(width: i32, height: i32, format: i32) -> i64 { return 1; }
    fn OpenGLCreateTexture(width: i32, height: i32, format: i32) -> i32 { return 1; }
    fn D3D11SetTextureData(texture_id: i64, data: i64, size: i32) { }
    fn OpenGLSetTextureData(texture_id: i32, data: i64, size: i32) { }
    fn D3D11BindTexture(texture_id: i64, slot: i32) { }
    fn OpenGLBindTexture(texture_id: i32, slot: i32) { }
    fn D3D11CompileShader(shader_type: i32, source: i64) -> i64 { return 1; }
    fn OpenGLCompileShader(shader_type: i32, source: i64) -> i32 { return 1; }
    fn D3D11CreateShaderProgram(vertex: i64, fragment: i64) -> i64 { return 1; }
    fn OpenGLCreateShaderProgram(vertex: i32, fragment: i32) -> i32 { return 1; }
    fn D3D11UseShaderProgram(program_id: i64) { }
    fn OpenGLUseShaderProgram(program_id: i32) { }
    fn D3D11GetUniformLocation(program_id: i64, name: i64) -> i64 { return 0; }
    fn OpenGLGetUniformLocation(program_id: i32, name: i64) -> i32 { return 0; }
    fn D3D11SetUniform1f(location: i64, value: f32) { }
    fn OpenGLSetUniform1f(location: i32, value: f32) { }
    fn D3D11SetUniformMatrix4f(location: i64, matrix: i64) { }
    fn OpenGLSetUniformMatrix4f(location: i32, matrix: i64) { }
    fn D3D11CreateVertexArray() -> i64 { return 1; }
    fn OpenGLCreateVertexArray() -> i32 { return 1; }
    fn D3D11CreateBuffer() -> i64 { return 1; }
    fn OpenGLCreateBuffer() -> i32 { return 1; }
    fn D3D11BindVertexArray(vao_id: i64) { }
    fn OpenGLBindVertexArray(vao_id: i32) { }
    fn D3D11BindBuffer(buffer_type: i32, buffer_id: i64) { }
    fn OpenGLBindBuffer(buffer_type: i32, buffer_id: i32) { }
    fn D3D11SetBufferData(buffer_type: i32, data: i64, size: i32) { }
    fn OpenGLSetBufferData(buffer_type: i32, data: i64, size: i32) { }
    fn D3D11SetIndexBufferData(data: i64, size: i32) { }
    fn OpenGLSetIndexBufferData(data: i64, size: i32) { }
    fn D3D11DrawElements(primitive_type: i32, count: i32) { }
    fn OpenGLDrawElements(primitive_type: i32, count: i32) { }
    fn D3D11Present() { }
    fn OpenGLSwapBuffers() { }
}

class GameObject {
    var id: u64;
    var name: String;
    var transform: Transform;
    var components: Array(Component);
    var active: Bool;
    
    fn Create(name: String) -> Self {
        return { .id = 1, .name = name, .transform = Transform.Create(), .components = Array(Component)(), .active = True };
    }
    
    fn AddComponent(self: Self, component: Component) {
        self.components.Push(component);
    }
    
    fn Update(self: Self, delta_time: f32) {
        if (not self.active) { return; }
        
        for (component: Component in self.components) {
            component.Update(delta_time);
        }
    }
}

class Transform {
    var position: Vector3;
    var rotation: Vector3;
    var scale: Vector3;
    
    fn Create() -> Self {
        return { .position = Vector3.Zero(), .rotation = Vector3.Zero(), .scale = Vector3.One() };
    }
    
    fn GetMatrix(self: Self) -> Matrix4 {
        return Matrix4.Translation(self.position);
    }
}

interface Component {
    fn Update(delta_time: f32) -> Void;
    fn Render() -> Void;
}

class GameEngine {
    var game_objects: Array(GameObject);
    var camera: Camera;
    var is_running: Bool;
    
    fn Create() -> Self {
        return { .game_objects = Array(GameObject)(), .camera = Camera.Create(), .is_running = False };
    }
    
    fn Initialize(self: Self, width: i32, height: i32) -> Result(Bool, String) {
        var graphics_result: Result(Bool, String) = GraphicsDevice.Initialize(width, height);
        if (graphics_result.IsError()) {
            return graphics_result;
        }
        
        self.camera.aspect_ratio = (width as f32) / (height as f32);
        return Result(Bool, String).Ok(True);
    }
    
    fn AddGameObject(self: Self, game_object: GameObject) {
        self.game_objects.Push(game_object);
    }
    
    fn Run(self: Self) {
        self.is_running = True;
        
        while (self.is_running) {
            self.Update();
            self.Render();
        }
    }
    
    fn Update(self: Self) {
        for (game_object: GameObject in self.game_objects) {
            game_object.Update(0.016); // 60 FPS
        }
    }
    
    fn Render(self: Self) {
        GraphicsDevice.Clear(Color.Create(0.2, 0.3, 0.3, 1.0));
        
        for (game_object: GameObject in self.game_objects) {
            for (component: Component in game_object.components) {
                component.Render();
            }
        }
        
        GraphicsDevice.Present();
    }
}