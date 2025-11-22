// AtomicUI - Widget System
package AtomicUI.Widgets api;

import Std.String;
import Std.Array;
import AtomicUI.Window;
import AtomicUI.Event;
import AtomicUI.Graphics;

// Base Widget class
class Widget {
    var id: i32;
    var parent: Optional(*Widget);
    var children: Array(*Widget);
    var rect: Rect;
    var visible: Bool;
    var enabled: Bool;
    var background_color: Graphics.Color;
    var foreground_color: Graphics.Color;
    var font: Optional(Graphics.Font);
    var event_handlers: Array(WidgetEventHandler);
    
    fn Create(x: i32, y: i32, width: i32, height: i32) -> Self {
        return {
            .id = GenerateWidgetId(),
            .parent = Optional(*Widget).None(),
            .children = Array(*Widget)(),
            .rect = {.x = x, .y = y, .width = width, .height = height},
            .visible = True,
            .enabled = True,
            .background_color = Graphics.Color.LightGray,
            .foreground_color = Graphics.Color.Black,
            .font = Optional(Graphics.Font).None(),
            .event_handlers = Array(WidgetEventHandler)()
        };
    }
    
    fn AddChild(self: Self, child: *Widget) {
        child.parent = Optional(*Widget).Some(&self);
        self.children.Push(child);
    }
    
    fn RemoveChild(self: Self, child: *Widget) {
        var i: i32 = 0;
        while (i < self.children.Size()) {
            if (self.children[i] == child) {
                self.children.RemoveAt(i);
                child.parent = Optional(*Widget).None();
                break;
            }
            i += 1;
        }
    }
    
    fn SetPosition(self: Self, x: i32, y: i32) {
        self.rect.x = x;
        self.rect.y = y;
        self.Invalidate();
    }
    
    fn SetSize(self: Self, width: i32, height: i32) {
        self.rect.width = width;
        self.rect.height = height;
        self.Invalidate();
    }
    
    fn SetVisible(self: Self, visible: Bool) {
        self.visible = visible;
        self.Invalidate();
    }
    
    fn SetEnabled(self: Self, enabled: Bool) {
        self.enabled = enabled;
        self.Invalidate();
    }
    
    fn Paint(self: Self, context: Graphics.Context) {
        if (not self.visible) { return; }
        
        // Draw background
        context.SetColor(self.background_color);
        context.FillRect(self.rect.x, self.rect.y, self.rect.width, self.rect.height);
        
        // Draw children
        var i: i32 = 0;
        while (i < self.children.Size()) {
            self.children[i].Paint(context);
            i += 1;
        }
    }
    
    fn HandleEvent(self: Self, event: WidgetEvent) -> Bool {
        if (not self.visible or not self.enabled) { return False; }
        
        // Check if event is within widget bounds
        if (not self.ContainsPoint(event.x, event.y)) { return False; }
        
        // Handle event in children first
        var i: i32 = self.children.Size() - 1;
        while (i >= 0) {
            if (self.children[i].HandleEvent(event)) {
                return True;
            }
            i -= 1;
        }
        
        // Handle event in this widget
        var j: i32 = 0;
        while (j < self.event_handlers.Size()) {
            self.event_handlers[j].callback(event);
            j += 1;
        }
        
        return True;
    }
    
    fn ContainsPoint(self: Self, x: i32, y: i32) -> Bool {
        return x >= self.rect.x and x < self.rect.x + self.rect.width and
               y >= self.rect.y and y < self.rect.y + self.rect.height;
    }
    
    fn Invalidate(self: Self) {
        // Request repaint from parent window
        if (self.parent.HasValue()) {
            self.parent.Value().Invalidate();
        }
    }
    
    fn AddEventHandler(self: Self, handler: WidgetEventHandler) {
        self.event_handlers.Push(handler);
    }
}

// Button Widget
class Button extends Widget {
    var text: String;
    var pressed: Bool;
    
    fn Create(x: i32, y: i32, width: i32, height: i32, text: String) -> Self {
        var button: Self = {
            .Widget = Widget.Create(x, y, width, height),
            .text = text,
            .pressed = False
        };
        button.background_color = Graphics.Color.ButtonFace;
        return button;
    }
    
    fn Paint(self: Self, context: Graphics.Context) {
        if (not self.visible) { return; }
        
        // Draw button background
        var bg_color: Graphics.Color = self.pressed ? Graphics.Color.DarkGray : self.background_color;
        context.SetColor(bg_color);
        context.FillRect(self.rect.x, self.rect.y, self.rect.width, self.rect.height);
        
        // Draw border
        context.SetColor(Graphics.Color.Black);
        context.DrawRect(self.rect.x, self.rect.y, self.rect.width, self.rect.height);
        
        // Draw text
        context.SetColor(self.foreground_color);
        var text_x: i32 = self.rect.x + (self.rect.width - context.MeasureText(self.text).width) / 2;
        var text_y: i32 = self.rect.y + (self.rect.height - context.GetFontHeight()) / 2;
        context.DrawText(self.text, text_x, text_y);
    }
    
    fn HandleEvent(self: Self, event: WidgetEvent) -> Bool {
        if (not self.visible or not self.enabled) { return False; }
        if (not self.ContainsPoint(event.x, event.y)) { return False; }
        
        match (event.type) {
            case (WidgetEventType.MouseDown) {
                self.pressed = True;
                self.Invalidate();
                return True;
            }
            case (WidgetEventType.MouseUp) {
                if (self.pressed) {
                    self.pressed = False;
                    self.Invalidate();
                    // Fire click event
                    var click_event: WidgetEvent = {
                        .type = WidgetEventType.Click,
                        .x = event.x,
                        .y = event.y,
                        .widget = &self
                    };
                    var i: i32 = 0;
                    while (i < self.event_handlers.Size()) {
                        self.event_handlers[i].callback(click_event);
                        i += 1;
                    }
                }
                return True;
            }
            default {
                return Widget.HandleEvent(self, event);
            }
        }
    }
    
    fn SetText(self: Self, text: String) {
        self.text = text;
        self.Invalidate();
    }
    
    fn GetText(self: Self) -> String {
        return self.text;
    }
}

// TextBox Widget
class TextBox extends Widget {
    var text: String;
    var cursor_position: i32;
    var selection_start: i32;
    var selection_end: i32;
    var focused: Bool;
    var readonly: Bool;
    var multiline: Bool;
    var scroll_x: i32;
    var scroll_y: i32;
    
    fn Create(x: i32, y: i32, width: i32, height: i32) -> Self {
        var textbox: Self = {
            .Widget = Widget.Create(x, y, width, height),
            .text = "",
            .cursor_position = 0,
            .selection_start = 0,
            .selection_end = 0,
            .focused = False,
            .readonly = False,
            .multiline = False,
            .scroll_x = 0,
            .scroll_y = 0
        };
        textbox.background_color = Graphics.Color.White;
        return textbox;
    }
    
    fn Paint(self: Self, context: Graphics.Context) {
        if (not self.visible) { return; }
        
        // Draw background
        context.SetColor(self.background_color);
        context.FillRect(self.rect.x, self.rect.y, self.rect.width, self.rect.height);
        
        // Draw border
        var border_color: Graphics.Color = self.focused ? Graphics.Color.Blue : Graphics.Color.Gray;
        context.SetColor(border_color);
        context.DrawRect(self.rect.x, self.rect.y, self.rect.width, self.rect.height);
        
        // Draw text
        context.SetColor(self.foreground_color);
        var text_x: i32 = self.rect.x + 4 - self.scroll_x;
        var text_y: i32 = self.rect.y + 4 - self.scroll_y;
        
        if (self.multiline) {
            var lines: Array(String) = self.text.Split("\n");
            var i: i32 = 0;
            while (i < lines.Size()) {
                context.DrawText(lines[i], text_x, text_y + i * context.GetFontHeight());
                i += 1;
            }
        } else {
            context.DrawText(self.text, text_x, text_y);
        }
        
        // Draw cursor if focused
        if (self.focused) {
            var cursor_x: i32 = text_x + context.MeasureText(self.text.Substring(0, self.cursor_position)).width;
            var cursor_y: i32 = text_y;
            context.SetColor(Graphics.Color.Black);
            context.DrawLine(cursor_x, cursor_y, cursor_x, cursor_y + context.GetFontHeight());
        }
        
        // Draw selection
        if (self.selection_start != self.selection_end) {
            var sel_start: i32 = Min(self.selection_start, self.selection_end);
            var sel_end: i32 = Max(self.selection_start, self.selection_end);
            var sel_x: i32 = text_x + context.MeasureText(self.text.Substring(0, sel_start)).width;
            var sel_width: i32 = context.MeasureText(self.text.Substring(sel_start, sel_end - sel_start)).width;
            
            context.SetColor(Graphics.Color.Highlight);
            context.FillRect(sel_x, text_y, sel_width, context.GetFontHeight());
        }
    }
    
    fn HandleEvent(self: Self, event: WidgetEvent) -> Bool {
        if (not self.visible or not self.enabled) { return False; }
        
        match (event.type) {
            case (WidgetEventType.MouseDown) {
                if (self.ContainsPoint(event.x, event.y)) {
                    self.focused = True;
                    // Calculate cursor position from mouse click
                    var click_x: i32 = event.x - self.rect.x - 4 + self.scroll_x;
                    self.cursor_position = self.GetCharacterIndexFromX(click_x);
                    self.selection_start = self.cursor_position;
                    self.selection_end = self.cursor_position;
                    self.Invalidate();
                    return True;
                } else {
                    self.focused = False;
                    self.Invalidate();
                }
            }
            case (WidgetEventType.KeyDown) {
                if (self.focused) {
                    return self.HandleKeyEvent(event);
                }
            }
            case (WidgetEventType.Char) {
                if (self.focused and not self.readonly) {
                    self.InsertChar(event.char_code);
                    return True;
                }
            }
            default {}
        }
        
        return Widget.HandleEvent(self, event);
    }
    
    fn HandleKeyEvent(self: Self, event: WidgetEvent) -> Bool {
        match (event.key_code) {
            case (37) { // Left arrow
                if (self.cursor_position > 0) {
                    self.cursor_position -= 1;
                    self.Invalidate();
                }
                return True;
            }
            case (39) { // Right arrow
                if (self.cursor_position < self.text.Length()) {
                    self.cursor_position += 1;
                    self.Invalidate();
                }
                return True;
            }
            case (8) { // Backspace
                if (not self.readonly and self.cursor_position > 0) {
                    self.text = self.text.Substring(0, self.cursor_position - 1) + 
                               self.text.Substring(self.cursor_position);
                    self.cursor_position -= 1;
                    self.Invalidate();
                }
                return True;
            }
            case (46) { // Delete
                if (not self.readonly and self.cursor_position < self.text.Length()) {
                    self.text = self.text.Substring(0, self.cursor_position) + 
                               self.text.Substring(self.cursor_position + 1);
                    self.Invalidate();
                }
                return True;
            }
            case (13) { // Enter
                if (self.multiline and not self.readonly) {
                    self.InsertChar('\n');
                }
                return True;
            }
            default {
                return False;
            }
        }
    }
    
    fn InsertChar(self: Self, ch: i32) {
        if (self.readonly) { return; }
        
        self.text = self.text.Substring(0, self.cursor_position) + 
                   CharToString(ch) + 
                   self.text.Substring(self.cursor_position);
        self.cursor_position += 1;
        self.Invalidate();
    }
    
    fn GetCharacterIndexFromX(self: Self, x: i32) -> i32 {
        // Simple implementation - would need proper text measurement
        var char_width: i32 = 8; // Approximate character width
        var index: i32 = x / char_width;
        return Min(Max(index, 0), self.text.Length());
    }
    
    fn SetText(self: Self, text: String) {
        self.text = text;
        self.cursor_position = Min(self.cursor_position, text.Length());
        self.Invalidate();
    }
    
    fn GetText(self: Self) -> String {
        return self.text;
    }
    
    fn SetMultiline(self: Self, multiline: Bool) {
        self.multiline = multiline;
        self.Invalidate();
    }
    
    fn SetReadonly(self: Self, readonly: Bool) {
        self.readonly = readonly;
    }
}

// Label Widget
class Label extends Widget {
    var text: String;
    var text_align: TextAlignment;
    
    fn Create(x: i32, y: i32, width: i32, height: i32, text: String) -> Self {
        var label: Self = {
            .Widget = Widget.Create(x, y, width, height),
            .text = text,
            .text_align = TextAlignment.Left
        };
        label.background_color = Graphics.Color.Transparent;
        return label;
    }
    
    fn Paint(self: Self, context: Graphics.Context) {
        if (not self.visible) { return; }
        
        // Draw background if not transparent
        if (self.background_color != Graphics.Color.Transparent) {
            context.SetColor(self.background_color);
            context.FillRect(self.rect.x, self.rect.y, self.rect.width, self.rect.height);
        }
        
        // Draw text
        context.SetColor(self.foreground_color);
        var text_size: Size = context.MeasureText(self.text);
        var text_x: i32;
        var text_y: i32 = self.rect.y + (self.rect.height - text_size.height) / 2;
        
        match (self.text_align) {
            case (TextAlignment.Left) {
                text_x = self.rect.x;
            }
            case (TextAlignment.Center) {
                text_x = self.rect.x + (self.rect.width - text_size.width) / 2;
            }
            case (TextAlignment.Right) {
                text_x = self.rect.x + self.rect.width - text_size.width;
            }
        }
        
        context.DrawText(self.text, text_x, text_y);
    }
    
    fn SetText(self: Self, text: String) {
        self.text = text;
        self.Invalidate();
    }
    
    fn GetText(self: Self) -> String {
        return self.text;
    }
    
    fn SetTextAlignment(self: Self, align: TextAlignment) {
        self.text_align = align;
        self.Invalidate();
    }
}

// CheckBox Widget
class CheckBox extends Widget {
    var text: String;
    var checked: Bool;
    var check_size: i32;
    
    fn Create(x: i32, y: i32, width: i32, height: i32, text: String) -> Self {
        var checkbox: Self = {
            .Widget = Widget.Create(x, y, width, height),
            .text = text,
            .checked = False,
            .check_size = 16
        };
        checkbox.background_color = Graphics.Color.Transparent;
        return checkbox;
    }
    
    fn Paint(self: Self, context: Graphics.Context) {
        if (not self.visible) { return; }
        
        // Draw checkbox square
        var check_x: i32 = self.rect.x;
        var check_y: i32 = self.rect.y + (self.rect.height - self.check_size) / 2;
        
        context.SetColor(Graphics.Color.White);
        context.FillRect(check_x, check_y, self.check_size, self.check_size);
        
        context.SetColor(Graphics.Color.Black);
        context.DrawRect(check_x, check_y, self.check_size, self.check_size);
        
        // Draw checkmark if checked
        if (self.checked) {
            context.SetColor(Graphics.Color.Black);
            // Simple checkmark - two lines
            context.DrawLine(check_x + 3, check_y + 8, check_x + 6, check_y + 11);
            context.DrawLine(check_x + 6, check_y + 11, check_x + 12, check_y + 5);
        }
        
        // Draw text
        context.SetColor(self.foreground_color);
        var text_x: i32 = check_x + self.check_size + 4;
        var text_y: i32 = self.rect.y + (self.rect.height - context.GetFontHeight()) / 2;
        context.DrawText(self.text, text_x, text_y);
    }
    
    fn HandleEvent(self: Self, event: WidgetEvent) -> Bool {
        if (not self.visible or not self.enabled) { return False; }
        if (not self.ContainsPoint(event.x, event.y)) { return False; }
        
        match (event.type) {
            case (WidgetEventType.MouseDown) {
                self.checked = not self.checked;
                self.Invalidate();
                
                // Fire change event
                var change_event: WidgetEvent = {
                    .type = WidgetEventType.ValueChanged,
                    .x = event.x,
                    .y = event.y,
                    .widget = &self
                };
                var i: i32 = 0;
                while (i < self.event_handlers.Size()) {
                    self.event_handlers[i].callback(change_event);
                    i += 1;
                }
                return True;
            }
            default {
                return Widget.HandleEvent(self, event);
            }
        }
    }
    
    fn SetChecked(self: Self, checked: Bool) {
        self.checked = checked;
        self.Invalidate();
    }
    
    fn IsChecked(self: Self) -> Bool {
        return self.checked;
    }
    
    fn SetText(self: Self, text: String) {
        self.text = text;
        self.Invalidate();
    }
}

// ListBox Widget
class ListBox extends Widget {
    var items: Array(String);
    var selected_index: i32;
    var scroll_position: i32;
    var item_height: i32;
    
    fn Create(x: i32, y: i32, width: i32, height: i32) -> Self {
        var listbox: Self = {
            .Widget = Widget.Create(x, y, width, height),
            .items = Array(String)(),
            .selected_index = -1,
            .scroll_position = 0,
            .item_height = 20
        };
        listbox.background_color = Graphics.Color.White;
        return listbox;
    }
    
    fn Paint(self: Self, context: Graphics.Context) {
        if (not self.visible) { return; }
        
        // Draw background
        context.SetColor(self.background_color);
        context.FillRect(self.rect.x, self.rect.y, self.rect.width, self.rect.height);
        
        // Draw border
        context.SetColor(Graphics.Color.Gray);
        context.DrawRect(self.rect.x, self.rect.y, self.rect.width, self.rect.height);
        
        // Draw items
        var visible_items: i32 = self.rect.height / self.item_height;
        var start_index: i32 = self.scroll_position;
        var end_index: i32 = Min(start_index + visible_items, self.items.Size());
        
        var i: i32 = start_index;
        while (i < end_index) {
            var item_y: i32 = self.rect.y + (i - start_index) * self.item_height;
            
            // Draw selection background
            if (i == self.selected_index) {
                context.SetColor(Graphics.Color.Highlight);
                context.FillRect(self.rect.x + 1, item_y, self.rect.width - 2, self.item_height);
            }
            
            // Draw item text
            context.SetColor(i == self.selected_index ? Graphics.Color.White : self.foreground_color);
            context.DrawText(self.items[i], self.rect.x + 4, item_y + 2);
            
            i += 1;
        }
    }
    
    fn HandleEvent(self: Self, event: WidgetEvent) -> Bool {
        if (not self.visible or not self.enabled) { return False; }
        if (not self.ContainsPoint(event.x, event.y)) { return False; }
        
        match (event.type) {
            case (WidgetEventType.MouseDown) {
                var item_index: i32 = (event.y - self.rect.y) / self.item_height + self.scroll_position;
                if (item_index >= 0 and item_index < self.items.Size()) {
                    self.selected_index = item_index;
                    self.Invalidate();
                    
                    // Fire selection change event
                    var change_event: WidgetEvent = {
                        .type = WidgetEventType.SelectionChanged,
                        .x = event.x,
                        .y = event.y,
                        .widget = &self
                    };
                    var i: i32 = 0;
                    while (i < self.event_handlers.Size()) {
                        self.event_handlers[i].callback(change_event);
                        i += 1;
                    }
                }
                return True;
            }
            default {
                return Widget.HandleEvent(self, event);
            }
        }
    }
    
    fn AddItem(self: Self, item: String) {
        self.items.Push(item);
        self.Invalidate();
    }
    
    fn RemoveItem(self: Self, index: i32) {
        if (index >= 0 and index < self.items.Size()) {
            self.items.RemoveAt(index);
            if (self.selected_index == index) {
                self.selected_index = -1;
            } else if (self.selected_index > index) {
                self.selected_index -= 1;
            }
            self.Invalidate();
        }
    }
    
    fn GetSelectedIndex(self: Self) -> i32 {
        return self.selected_index;
    }
    
    fn GetSelectedItem(self: Self) -> Optional(String) {
        if (self.selected_index >= 0 and self.selected_index < self.items.Size()) {
            return Optional(String).Some(self.items[self.selected_index]);
        }
        return Optional(String).None();
    }
    
    fn SetSelectedIndex(self: Self, index: i32) {
        if (index >= -1 and index < self.items.Size()) {
            self.selected_index = index;
            self.Invalidate();
        }
    }
}

// Supporting types and enums
choice WidgetEventType {
    MouseDown,
    MouseUp,
    MouseMove,
    KeyDown,
    KeyUp,
    Char,
    Click,
    ValueChanged,
    SelectionChanged,
    Focus,
    Blur
}

struct WidgetEvent {
    var type: WidgetEventType;
    var x: i32;
    var y: i32;
    var key_code: i32;
    var char_code: i32;
    var widget: *Widget;
}

struct WidgetEventHandler {
    var id: i32;
    var callback: fn(WidgetEvent) -> Void;
}

choice TextAlignment {
    Left,
    Center,
    Right
}

// Utility functions
var widget_id_counter: i32 = 1;

fn GenerateWidgetId() -> i32 {
    var id: i32 = widget_id_counter;
    widget_id_counter += 1;
    return id;
}

fn Min(a: i32, b: i32) -> i32 {
    return a < b ? a : b;
}

fn Max(a: i32, b: i32) -> i32 {
    return a > b ? a : b;
}