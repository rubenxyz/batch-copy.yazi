Relevant source files

-   [docs/plugins/layout.md](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/layout.md)

This document provides a complete reference for Yazi's Layout and UI API, which enables Lua plugins to build custom terminal user interfaces. These APIs are available in the `ui` namespace and provide building blocks for rendering text, creating layouts, and drawing UI components like borders, gauges, and lists.

For information about the core plugin APIs (`ya`, `ps`, `fs`, `Command`), see [Core Utilities API](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.3.1-core-utilities-api-(ya-ps-fs-command)). For data types used in plugin development, see [Type System](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.3.2-type-system).

## Overview

The Layout and UI API consists of three categories of components:

1.  **Spatial Components**: Define positions and areas in the terminal (`ui.Rect`, `ui.Pad`, `ui.Pos`)
2.  **Text Components**: Build styled text content (`ui.Span`, `ui.Line`, `ui.Text`, `ui.Style`)
3.  **Renderable Components**: Higher-level UI elements that can be displayed (`ui.List`, `ui.Bar`, `ui.Border`, `ui.Gauge`, `ui.Clear`)

The `ui.Layout` system enables dividing terminal space into regions using various constraint types. All renderable components inherit common methods for setting their display area and style.

**Sources**: [docs/plugins/layout.md1-9](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/layout.md#L1-L9)

## Component Hierarchy

The UI components form a hierarchical structure where smaller units compose into larger ones:

**Sources**: [docs/plugins/layout.md8-9](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/layout.md#L8-L9) [docs/plugins/layout.md433-491](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/layout.md#L433-L491) [docs/plugins/layout.md492-584](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/layout.md#L492-L584) [docs/plugins/layout.md585-680](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/layout.md#L585-L680)

## Spatial Components

### ui.Rect

`ui.Rect` represents a rectangular area within the terminal, defined by four integer properties: `x` (horizontal position), `y` (vertical position), `w` (width), and `h` (height). Rects are used to specify where UI components should be rendered.

```lua
-- Create a rect manually
local rect = ui.Rect {
    x = 10,  -- x position
    y = 5,   -- y position
    w = 40,  -- width
    h = 20,  -- height
}

-- Access computed properties
local left = rect.left    -- equals x
local right = rect.right  -- equals x + w
local top = rect.top      -- equals y
local bottom = rect.bottom -- equals y + h

-- Apply padding
rect:pad(ui.Pad(1, 2, 1, 2))  -- top, right, bottom, left
```

| Property | Type | Description |
| --- | --- | --- |
| `x` | `integer` | X position of the rect |
| `y` | `integer` | Y position of the rect |
| `w` | `integer` | Width of the rect |
| `h` | `integer` | Height of the rect |
| `left` | `integer` | Left edge position (read-only) |
| `right` | `integer` | Right edge position (read-only) |
| `top` | `integer` | Top edge position (read-only) |
| `bottom` | `integer` | Bottom edge position (read-only) |

**Warning**: If you create `Rect` values manually, ensure coordinates and dimensions are calculated accurately. Invalid values may cause Yazi to crash. The recommended approach is to obtain rects from [ui.Layout](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/ui.Layout#LNaN-LNaN)

**Sources**: [docs/plugins/layout.md10-110](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/layout.md#L10-L110)

### ui.Pad

`ui.Pad` represents padding around an element, specified as four integer values for each edge:

```lua
-- Full constructor
local pad = ui.Pad(1, 2, 3, 4)  -- top, right, bottom, left

-- Convenience constructors for specific edges
local pad_top = ui.Pad.top(2)       -- ui.Pad(2, 0, 0, 0)
local pad_right = ui.Pad.right(2)   -- ui.Pad(0, 2, 0, 0)
local pad_bottom = ui.Pad.bottom(2) -- ui.Pad(0, 0, 2, 0)
local pad_left = ui.Pad.left(2)     -- ui.Pad(0, 0, 0, 2)

-- Axis-based constructors
local pad_x = ui.Pad.x(3)     -- ui.Pad(0, 3, 0, 3) - horizontal
local pad_y = ui.Pad.y(2)     -- ui.Pad(2, 0, 2, 0) - vertical
local pad_xy = ui.Pad.xy(3, 2) -- ui.Pad(2, 3, 2, 3)
```

| Property | Type | Description |
| --- | --- | --- |
| `top` | `integer` | Top padding |
| `right` | `integer` | Right padding |
| `bottom` | `integer` | Bottom padding |
| `left` | `integer` | Left padding |

**Sources**: [docs/plugins/layout.md111-226](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/layout.md#L111-L226)

### ui.Pos

`ui.Pos` represents a position composed of an origin point and an offset relative to that origin. This provides an alternative to specifying absolute coordinates.

```lua
-- Position relative to center with offsets
local pos = ui.Pos {
    "center",  -- origin: "top-left" | "top-center" | "top-right" |
               --         "center-left" | "center" | "center-right" |
               --         "bottom-left" | "bottom-center" | "bottom-right"
    x = 5,     -- x-offset from origin (default: 0)
    y = 3,     -- y-offset from origin (default: 0)
    w = 20,    -- width (default: 0)
    h = 10,    -- height (default: 0)
}
```

| Property | Type | Description |
| --- | --- | --- |
| `[1]` | `Origin` | Origin point (see [Aliases](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.3.1-core-utilities-api-(ya-ps-fs-command)) for valid values) |
| `x` | `integer` | X-offset relative to origin |
| `y` | `integer` | Y-offset relative to origin |
| `w` | `integer` | Width |
| `h` | `integer` | Height |

**Sources**: [docs/plugins/layout.md227-291](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/layout.md#L227-L291)

## Text Components and Styling

### ui.Style

`ui.Style` enables applying colors and text attributes to text components. Styles use a fluent API where methods return `self` for chaining:

```lua
-- Create and chain style methods
local style = ui.Style()
    :fg("blue")
    :bg("white")
    :bold()
    :italic()

-- Available style methods:
-- Colors:
--   :fg(color)  - foreground color
--   :bg(color)  - background color
-- Attributes:
--   :bold()
--   :dim()
--   :italic()
--   :underline()
--   :blink()
--   :blink_rapid()
--   :reverse()  - swap fg/bg
--   :hidden()
--   :crossed()
--   :reset()
-- Combining:
--   :patch(another_style)
```

Colors can be specified as strings (`"red"`, `"#ff0000"`, `"255,128,0"`) or color values. See the `AsColor` type in [Type System](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.3.2-type-system) for details.

**Sources**: [docs/plugins/layout.md292-432](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/layout.md#L292-L432)

### ui.Span

`ui.Span` is the smallest unit of styled text. It inherits from `ui.Style`, enabling direct application of style methods:

```lua
-- Create spans with different constructors
local span1 = ui.Span("Hello")
local span2 = ui.Span(ui.Span("World"))  -- accepts another Span

-- Apply styling directly (inherits from ui.Style)
local styled_span = ui.Span("Error"):fg("red"):bold()

-- Or apply a full style
local style = ui.Style():fg("blue"):italic()
local span3 = ui.Span("Info"):style(style)

-- Check if span has visible content
if span:visible() then
    -- includes printable characters
end
```

| Method | Parameters | Returns | Description |
| --- | --- | --- | --- |
| `visible()` | \- | `boolean` | Whether span contains printable characters |
| `style()` | `Style` | `self` | Apply a complete style |

**Sources**: [docs/plugins/layout.md433-491](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/layout.md#L433-L491)

### ui.Line

`ui.Line` represents a single line of text composed of multiple `ui.Span` elements. Like `Span`, it inherits from `ui.Style`:

```lua
-- Create lines with various input types
local line1 = ui.Line { ui.Span("foo"), ui.Span("bar") }
local line2 = ui.Line("simple string")
local line3 = ui.Line(ui.Span("from span"))
local line4 = ui.Line(ui.Line("from line"))
local line5 = ui.Line { "mixed", ui.Span("types"), ui.Line("here") }

-- Style the entire line
local styled_line = ui.Line("Text"):fg("green"):bg("black")

-- Set area and alignment
line:area(rect)
line:align(ui.Align.CENTER)

-- Query properties
local width = line:width()  -- calculate display width
local has_content = line:visible()
```

| Method | Parameters | Returns | Description |
| --- | --- | --- | --- |
| `area()` | `Rect?` | `self` or `Rect` | Set/get the display area |
| `width()` | \- | `integer` | Calculate line width in terminal cells |
| `align()` | `Align` | `self` | Set alignment (LEFT, CENTER, RIGHT) |
| `visible()` | \- | `boolean` | Whether line contains printable characters |
| `style()` | `Style` | `self` | Apply a complete style |

**Sources**: [docs/plugins/layout.md492-584](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/layout.md#L492-L584)

### ui.Text

`ui.Text` represents multi-line text, consisting of multiple `ui.Line` elements. It also inherits from `ui.Style`:

````lua
-- Create text from various sources
local text1 = ui.Text { ui.Line("line1"), ui.Line("line2") }
local text2 = ui.Text("foo\nbar")  -- newlines split into lines
local text3 = ui.Text(ui.Line("single line"))
local text4 = ui.Text { "mixed", ui.Line("types"), ui.Span("span") }

-- Parse ANSI escape sequences
local ansi_text = ui.Text.parse("\x1b<FileRef file-url="https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/31mRed\\x1b[0m \\x1b[32mGreen\\x1b[0m\")\n\n-- Configure text display\ntext#LNaN-LNaN" NaN  file-path="31mRed\\x1b[0m \\x1b[32mGreen\\x1b[0m\")\n\n-- Configure text display\ntext">Hii</FileRef>

## Layout System

The layout system divides terminal space into regions using constraints. This is the primary way to obtain properly calculated `ui.Rect` values for rendering components.

### ui.Layout

`ui.Layout` splits a rectangular area into multiple sub-rectangles based on constraints and direction:

```lua
-- Split area horizontally (side-by-side)
local areas = ui.Layout()
    :direction(ui.Layout.HORIZONTAL)
    :constraints({
        ui.Constraint.Percentage(50),
        ui.Constraint.Percentage(50)
    })
    :split(available_area)

local left_rect = areas[1]
local right_rect = areas[2]

-- Split vertically (stacked) with margins
local areas = ui.Layout()
    :direction(ui.Layout.VERTICAL)
    :margin(2)           -- all edges
    -- OR:
    :margin_h(3)         -- horizontal margins
    :margin_v(1)         -- vertical margins
    :constraints({
        ui.Constraint.Length(3),    -- header: fixed 3 lines
        ui.Constraint.Fill(1),      -- body: fill remaining space
        ui.Constraint.Length(1)     -- footer: fixed 1 line
    })
    :split(available_area)
````

| Method | Parameters | Returns | Description |
| --- | --- | --- | --- |
| `direction()` | `Direction` | `self` | Set HORIZONTAL or VERTICAL |
| `margin()` | `integer` | `self` | Apply uniform margin to all edges |
| `margin_h()` | `integer` | `self` | Apply horizontal margins (left+right) |
| `margin_v()` | `integer` | `self` | Apply vertical margins (top+bottom) |
| `constraints()` | `Constraint[]` | `self` | Set sizing constraints |
| `split()` | `Rect` | `Rect[]` | Perform the split, returning sub-areas |

**Sources**: [docs/plugins/layout.md681-767](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/layout.md#L681-L767)

### ui.Constraint

Constraints define how layout elements should be sized. Yazi supports six constraint types with the following priority order:

1.  `ui.Constraint.Min(min)` - minimum size
2.  `ui.Constraint.Max(max)` - maximum size
3.  `ui.Constraint.Length(len)` - fixed size
4.  `ui.Constraint.Percentage(p)` - percentage of total space
5.  `ui.Constraint.Ratio(num, den)` - ratio of total space
6.  `ui.Constraint.Fill(scale)` - proportional fill of remaining space

```lua
-- Fixed sizes
ui.Constraint.Length(20)    -- exactly 20 cells
ui.Constraint.Min(10)       -- at least 10 cells
ui.Constraint.Max(30)       -- at most 30 cells

-- Proportional sizes
ui.Constraint.Percentage(50)   -- 50% of available space
ui.Constraint.Ratio(1, 3)      -- 1/3 of available space

-- Fill remaining space proportionally
-- These elements share leftover space based on their scale values:
ui.Layout()
    :constraints({
        ui.Constraint.Fill(1),   -- gets 1/6 of remaining space
        ui.Constraint.Fill(2),   -- gets 2/6 of remaining space
        ui.Constraint.Fill(3)    -- gets 3/6 of remaining space
    })
```

**Visual Examples**:

| Constraints | Result | Description |
| --- | --- | --- |
| `[Percentage(100), Min(20)]` | `[30px][20px]` | Second takes minimum, first gets rest |
| `[Percentage(0), Max(20)]` | `[30px][20px]` | Second capped at max, first gets rest |
| `[Length(20), Length(30)]` | `[20px][30px]` | Both get exact sizes |
| `[Percentage(75), Fill(1)]` | `[38px][12px]` | Percentage calculated first, fill takes remainder |
| `[Fill(1), Fill(2), Fill(3)]` | `[8px][17px][25px]` | Proportional distribution of space |

**Sources**: [docs/plugins/layout.md768-934](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/layout.md#L768-L934)

## Renderable Components

These are higher-level UI components that can be rendered to the terminal. Each accepts an area via the `area()` method.

### ui.List

`ui.List` displays a vertical list of text items:

```lua
-- Create list from various input types
local list = ui.List {
    ui.Text("Item 1"),
    ui.Text("Item 2")
}

-- Convenience: accepts strings, Spans, Lines directly
local simple_list = ui.List {
    "First item",
    ui.Line("Second item"),
    ui.Span("Third item")
}

-- Set area and style
list:area(rect)
list:style(ui.Style():fg("cyan"))
```

| Method | Parameters | Returns | Description |
| --- | --- | --- | --- |
| `area()` | `Rect?` | `self` or `Rect` | Set/get display area |
| `style()` | `Style` | `self` | Apply style to list |

**Sources**: [docs/plugins/layout.md935-989](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/layout.md#L935-L989)

### ui.Bar

`ui.Bar` renders a horizontal or vertical bar along an edge:

```lua
-- Create bar on specific edge
local top_bar = ui.Bar(ui.Edge.TOP)
local bottom_bar = ui.Bar(ui.Edge.BOTTOM)
local left_bar = ui.Bar(ui.Edge.LEFT)
local right_bar = ui.Bar(ui.Edge.RIGHT)

-- Configure bar
top_bar:area(rect)
top_bar:symbol("─")  -- custom bar character
top_bar:style(ui.Style():fg("blue"))
```

| Method | Parameters | Returns | Description |
| --- | --- | --- | --- |
| `area()` | `Rect?` | `self` or `Rect` | Set/get display area |
| `symbol()` | `string` | `self` | Set bar character |
| `style()` | `Style` | `self` | Apply style to bar |

Valid `Edge` constants: `NONE`, `TOP`, `RIGHT`, `BOTTOM`, `LEFT`, `ALL`

**Sources**: [docs/plugins/layout.md990-1040](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/layout.md#L990-L1040)

### ui.Border

`ui.Border` renders a border around an area:

```lua
-- Create border on all edges
local border = ui.Border(ui.Edge.ALL)

-- Set border type
border:type(ui.Border.ROUNDED)
-- Available types:
--   ui.Border.PLAIN
--   ui.Border.ROUNDED
--   ui.Border.DOUBLE
--   ui.Border.THICK
--   ui.Border.QUADRANT_INSIDE
--   ui.Border.QUADRANT_OUTSIDE

-- Configure border
border:area(rect)
border:style(ui.Style():fg("yellow"))
```

| Method | Parameters | Returns | Description |
| --- | --- | --- | --- |
| `area()` | `Rect?` | `self` or `Rect` | Set/get display area |
| `type()` | `integer` | `self` | Set border style (use Border constants) |
| `style()` | `Style` | `self` | Apply style to border |

**Sources**: [docs/plugins/layout.md1041-1100](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/layout.md#L1041-L1100)

### ui.Gauge

`ui.Gauge` displays a progress indicator:

```lua
-- Create and configure gauge
local gauge = ui.Gauge()
    :area(rect)
    :percent(75)         -- set completion percentage (0-100)
    -- OR:
    :ratio(0.75)         -- set completion ratio (0.0-1.0)
    :label("Loading...")
    :style(ui.Style():fg("white"))        -- background style
    :gauge_style(ui.Style():fg("green"))  -- gauge bar style
```

| Method | Parameters | Returns | Description |
| --- | --- | --- | --- |
| `area()` | `Rect?` | `self` or `Rect` | Set/get display area |
| `percent()` | `integer` | `self` | Set completion percentage (0-100) |
| `ratio()` | `number` | `self` | Set completion ratio (0.0-1.0) |
| `label()` | `string` | `self` | Set label text |
| `style()` | `Style` | `self` | Style for everything except gauge bar |
| `gauge_style()` | `Style` | `self` | Style for gauge bar itself |

**Sources**: [docs/plugins/layout.md1101-1178](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/layout.md#L1101-L1178)

### ui.Clear

`ui.Clear` clears the content of a specific area. This is useful for removing previously rendered content before drawing new components:

```lua
-- Clear an area before rendering
local components = {
    ui.Clear(rect),                  -- clear first
    ui.Text("New content"):area(rect) -- then render
}
```

**Note**: Place `ui.Clear` in the component list before the component that should be cleared.

| Method | Parameters | Returns | Description |
| --- | --- | --- | --- |
| `area()` | `Rect?` | `self` or `Rect` | Set/get the area to clear |

**Sources**: [docs/plugins/layout.md1179-1212](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/layout.md#L1179-L1212)

## Alignment and Wrapping Constants

### ui.Align

Text and line alignment constants:

```lua
-- Alignment options
ui.Align.LEFT     -- Align to the left
ui.Align.CENTER   -- Align to the center
ui.Align.RIGHT    -- Align to the right

-- Usage
line:align(ui.Align.CENTER)
text:align(ui.Align.RIGHT)
```

**Sources**: [docs/plugins/layout.md1213-1240](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/layout.md#L1213-L1240)

### ui.Wrap

Text wrapping behavior:

```lua
-- Wrapping options
ui.Wrap.NO    -- Disable wrapping
ui.Wrap.YES   -- Enable wrapping
ui.Wrap.TRIM  -- Enable wrapping and trim leading whitespace

-- Usage
text:wrap(ui.Wrap.TRIM)
```

**Sources**: [docs/plugins/layout.md1241-1268](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/layout.md#L1241-L1268)

## Complete Example: Building a Custom UI

Here's a complete example demonstrating how to combine these components to build a custom plugin UI:

```lua
-- Example plugin that renders a styled panel with border and content
return {
    entry = function()
        ya.render(function()
            -- Get available terminal area
            local area = ui.Rect { x = 0, y = 0, w = 100, h = 30 }
            
            -- Split into header, body, footer
            local areas = ui.Layout()
                :direction(ui.Layout.VERTICAL)
                :margin(1)
                :constraints({
                    ui.Constraint.Length(3),      -- header
                    ui.Constraint.Fill(1),        -- body
                    ui.Constraint.Length(2)       -- footer
                })
                :split(area)
            
            -- Split body into columns
            local columns = ui.Layout()
                :direction(ui.Layout.HORIZONTAL)
                :constraints({
                    ui.Constraint.Percentage(30),  -- sidebar
                    ui.Constraint.Fill(1)          -- main content
                })
                :split(areas[2])
            
            -- Build component tree
            return {
                -- Border around entire area
                ui.Border(ui.Edge.ALL)
                    :type(ui.Border.ROUNDED)
                    :area(area),
                
                -- Header
                ui.Text("My Custom Plugin")
                    :area(areas[1])
                    :align(ui.Align.CENTER)
                    :fg("cyan")
                    :bold(),
                
                -- Sidebar list
                ui.List {
                    ui.Line("Option 1"):fg("green"),
                    ui.Line("Option 2"):fg("yellow"),
                    ui.Line("Option 3"):fg("red")
                }
                :area(columns[1]),
                
                -- Main content
                ui.Text("Content goes here\nMultiple lines supported")
                    :area(columns[2])
                    :wrap(ui.Wrap.YES),
                
                -- Footer with gauge
                ui.Gauge()
                    :area(areas[3])
                    :percent(65)
                    :label("Progress: 65%")
                    :gauge_style(ui.Style():fg("green"))
            }
        end)
    end
}
```

**Sources**: [docs/plugins/layout.md1-1320](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/layout.md#L1-L1320)

## Integration with Plugin Rendering

These UI components are typically used with `ya.render()` or `ya.preview_widgets()` to display custom interfaces. The render function should return a table of components, which Yazi will render in order:

```lua
-- In a functional plugin
ya.render(function()
    -- Build and return component list
    return {
        ui.Text("Line 1"):area(rect1),
        ui.Border(ui.Edge.ALL):area(rect2),
        -- ...
    }
end)

-- In a previewer plugin
return {
    Peek = function(self, job, skip)
        -- Build widgets for preview
        local widgets = {
            ui.Text(content):area(job.area),
        }
        ya.preview_widgets(job, widgets)
    end
}
```

For more information about plugin rendering contexts and the `ya` API, see [Core Utilities API](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.3.1-core-utilities-api-(ya-ps-fs-command)).

**Sources**: [docs/plugins/layout.md1-9](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/layout.md#L1-L9)