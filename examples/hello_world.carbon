// Hello World Example - Atomic Carbon
package HelloWorld api;

import Std.Console;

fn Main() -> i32 {
    Console.WriteLine("Hello, Atomic Carbon!");
    Console.WriteLine("This is a simple example program.");
    
    var name: String = "World";
    Console.WriteLine("Hello, " + name + "!");
    
    var numbers: Array(i32) = Array(i32)();
    numbers.Push(1);
    numbers.Push(2);
    numbers.Push(3);
    
    var i: i32 = 0;
    while (i < numbers.Size()) {
        Console.WriteLine("Number: " + IntToString(numbers[i]));
        i += 1;
    }
    
    return 0;
}