// GUI Example - Atomic Carbon with AtomicUI
package GUIExample api;

import Std.Console;
import AtomicUI.Window;
import AtomicUI.Event;
import AtomicUI.Graphics;

fn Main() -> i32 {
    Console.WriteLine("Creating GUI window...");
    
    // Create main window
    var window: Window = Window.Create("Atomic GUI Example", 800, 600);
    
    // Add event handlers
    var close_handler: EventHandler = {
        .id = 1,
        .callback = OnWindowClose
    };
    window.AddEventHandler(close_handler);
    
    var paint_handler: EventHandler = {
        .id = 2,
        .callback = OnWindowPaint
    };
    window.AddEventHandler(paint_handler);
    
    // Show the window
    window.Show();
    Console.WriteLine("Window created and shown!");
    
    // Main event loop
    while (not window.IsClosed()) {
        window.ProcessEvents();
        
        // Optional: Add a small delay to prevent 100% CPU usage
        // Thread.Sleep(16); // ~60 FPS
    }
    
    Console.WriteLine("Window closed. Exiting...");
    return 0;
}

fn OnWindowClose(event: Event.WindowEvent) {
    Console.WriteLine("Window close event received");
    // The window will be closed automatically
}

fn OnWindowPaint(event: Event.WindowEvent) {
    Console.WriteLine("Window paint event received");
    
    // Get graphics context and draw something
    var context_opt: Optional(Graphics.Context) = event.window.GetGraphicsContext();
    if (context_opt.HasValue()) {
        var context: Graphics.Context = context_opt.Value();
        
        // Clear background
        context.Clear(Graphics.Color.White);
        
        // Draw some text
        context.SetColor(Graphics.Color.Black);
        context.DrawText("Hello, Atomic GUI!", 50, 50);
        
        // Draw a rectangle
        context.SetColor(Graphics.Color.Blue);
        context.DrawRect(100, 100, 200, 150);
        
        // Draw a filled circle
        context.SetColor(Graphics.Color.Red);
        context.FillCircle(400, 200, 50);
        
        context.Present();
    }
}