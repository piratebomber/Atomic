// Tests for Web Framework
package Tests.Web api;

import Atomic.Testing;
import Atomic.Web;
import Atomic.Web.WebView;

class WebFrameworkTests {
    fn RunAllTests() -> TestReport {
        var runner: TestRunner = TestRunner.Create();
        var suite: TestSuite = TestSuite.Create("Web Framework");
        
        // HTTP Request Tests
        suite.AddTest(TestCase.Create("HTTPRequest_Create", fn() -> TestResult {
            var request: HTTPRequest = HTTPRequest.Create(HTTPMethod.GET, "/test");
            return Assert.Equal("GET", Self.MethodToString(request.method), "Method should be GET");
        }));
        
        suite.AddTest(TestCase.Create("HTTPRequest_Headers", fn() -> TestResult {
            var request: HTTPRequest = HTTPRequest.Create(HTTPMethod.POST, "/api");
            request.headers.Insert("content-type", "application/json");
            var content_type: Optional(String) = request.GetHeader("content-type");
            return Assert.True(content_type.IsSome() and content_type.Unwrap() == "application/json", "Header should be set");
        }));
        
        suite.AddTest(TestCase.Create("HTTPRequest_JSON", fn() -> TestResult {
            var request: HTTPRequest = HTTPRequest.Create(HTTPMethod.POST, "/api");
            request.headers.Insert("content-type", "application/json");
            request.body = "{\"test\": \"value\"}";
            return Assert.True(request.IsJSON(), "Should detect JSON content type");
        }));
        
        // HTTP Response Tests
        suite.AddTest(TestCase.Create("HTTPResponse_Create", fn() -> TestResult {
            var response: HTTPResponse = HTTPResponse.Create(HTTPStatus.OK);
            return Assert.True(response.status as i32 == 200, "Status should be 200");
        }));
        
        suite.AddTest(TestCase.Create("HTTPResponse_JSON", fn() -> TestResult {
            var response: HTTPResponse = HTTPResponse.Create(HTTPStatus.OK);
            var json: JSONNode = JSONNode.CreateObject();
            json.ObjectSet("message", JSONNode.CreateString("hello"));
            response.SetJSON(json);
            return Assert.True(response.body.Contains("hello"), "Response should contain JSON data");
        }));
        
        suite.AddTest(TestCase.Create("HTTPResponse_Headers", fn() -> TestResult {
            var response: HTTPResponse = HTTPResponse.Create(HTTPStatus.OK);
            response.SetHeader("X-Custom", "test-value");
            var header: Optional(String) = response.headers.Get("x-custom");
            return Assert.True(header.IsSome() and header.Unwrap() == "test-value", "Custom header should be set");
        }));
        
        // Route Tests
        suite.AddTest(TestCase.Create("Route_Matching", fn() -> TestResult {
            var handler: SimpleRouteHandler = SimpleRouteHandler.Create(fn(req: HTTPRequest, res: HTTPResponse) {
                res.SetText("Hello World");
            });
            var route: Route = Route.Create(HTTPMethod.GET, "/hello", handler);
            return Assert.True(route.Matches(HTTPMethod.GET, "/hello"), "Route should match GET /hello");
        }));
        
        suite.AddTest(TestCase.Create("Route_NoMatch", fn() -> TestResult {
            var handler: SimpleRouteHandler = SimpleRouteHandler.Create(fn(req: HTTPRequest, res: HTTPResponse) {
                res.SetText("Hello World");
            });
            var route: Route = Route.Create(HTTPMethod.GET, "/hello", handler);
            return Assert.False(route.Matches(HTTPMethod.POST, "/hello"), "Route should not match POST /hello");
        }));
        
        // CORS Middleware Tests
        suite.AddTest(TestCase.Create("CORS_Middleware", fn() -> TestResult {
            var cors: CORSMiddleware = CORSMiddleware.Create();
            cors.AllowAllOrigins();
            var request: HTTPRequest = HTTPRequest.Create(HTTPMethod.GET, "/test");
            var response: HTTPResponse = HTTPResponse.Create(HTTPStatus.OK);
            
            cors.Process(request, response, fn() { });
            
            var origin_header: Optional(String) = response.headers.Get("access-control-allow-origin");
            return Assert.True(origin_header.IsSome() and origin_header.Unwrap() == "*", "CORS header should be set");
        }));
        
        suite.AddTest(TestCase.Create("CORS_Options", fn() -> TestResult {
            var cors: CORSMiddleware = CORSMiddleware.Create();
            var request: HTTPRequest = HTTPRequest.Create(HTTPMethod.OPTIONS, "/test");
            var response: HTTPResponse = HTTPResponse.Create(HTTPStatus.OK);
            
            cors.Process(request, response, fn() { });
            
            return Assert.True(response.status as i32 == 200, "OPTIONS request should return 200");
        }));
        
        runner.AddSuite(suite);
        return runner.RunAll();
    }
    
    fn MethodToString(method: HTTPMethod) -> String {
        match (method) {
            case HTTPMethod.GET => "GET",
            case HTTPMethod.POST => "POST",
            case HTTPMethod.PUT => "PUT",
            case HTTPMethod.DELETE => "DELETE",
            default => "UNKNOWN"
        }
    }
}

class WebViewTests {
    fn RunAllTests() -> TestReport {
        var runner: TestRunner = TestRunner.Create();
        var suite: TestSuite = TestSuite.Create("WebView GUI");
        
        // WebView Window Tests
        suite.AddTest(TestCase.Create("WebView_Create", fn() -> TestResult {
            var window: WebViewWindow = WebViewWindow.Create("Test Window", 800, 600);
            return Assert.True(window.width == 800 and window.height == 600, "Window dimensions should be set");
        }));
        
        suite.AddTest(TestCase.Create("WebView_Title", fn() -> TestResult {
            var window: WebViewWindow = WebViewWindow.Create("My App", 400, 300);
            return Assert.Equal("My App", window.title, "Window title should be set");
        }));
        
        // WebButton Tests
        suite.AddTest(TestCase.Create("WebButton_Create", fn() -> TestResult {
            var button: WebButton = WebButton.Create("btn1", "Click Me");
            return Assert.Equal("btn1", button.id, "Button ID should be set");
        }));
        
        suite.AddTest(TestCase.Create("WebButton_Position", fn() -> TestResult {
            var button: WebButton = WebButton.Create("btn2", "Test");
            button.SetPosition(100, 50);
            return Assert.True(button.x == 100 and button.y == 50, "Button position should be updated");
        }));
        
        suite.AddTest(TestCase.Create("WebButton_Render", fn() -> TestResult {
            var button: WebButton = WebButton.Create("btn3", "Hello");
            var html: String = button.Render();
            return Assert.True(html.Contains("btn3") and html.Contains("Hello"), "Button HTML should contain ID and text");
        }));
        
        runner.AddSuite(suite);
        return runner.RunAll();
    }
}

class WebBenchmarks {
    fn RunBenchmarks() {
        var request_bench: Benchmark = Benchmark.Create("HTTP_Request_Creation", fn() {
            var request: HTTPRequest = HTTPRequest.Create(HTTPMethod.GET, "/benchmark");
            request.headers.Insert("user-agent", "benchmark-test");
        });
        request_bench.WithIterations(1000);
        
        var response_bench: Benchmark = Benchmark.Create("HTTP_Response_JSON", fn() {
            var response: HTTPResponse = HTTPResponse.Create(HTTPStatus.OK);
            var json: JSONNode = JSONNode.CreateObject();
            json.ObjectSet("data", JSONNode.CreateString("test"));
            response.SetJSON(json);
        });
        response_bench.WithIterations(1000);
        
        var webview_bench: Benchmark = Benchmark.Create("WebView_Button_Creation", fn() {
            var button: WebButton = WebButton.Create("bench_btn", "Benchmark Button");
            button.SetPosition(10, 20);
            var html: String = button.Render();
        });
        webview_bench.WithIterations(500);
        
        Console.WriteLine("=== Web Framework Performance Benchmarks ===");
        request_bench.Run().Print();
        response_bench.Run().Print();
        webview_bench.Run().Print();
    }
}