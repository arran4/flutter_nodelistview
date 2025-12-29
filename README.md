# flutter_nodelistview

A Flutter widget that renders an infinite list of items using a double-linked list of nodes. This package allows for dynamic, bidirectional infinite scrolling with programmatic control over the viewport and buffer.

![Demo](doc/simplescreenrecorder-2025-02-21_17.13.18.mp4)

## Features

*   **Infinite Scrolling:** Supports infinite lists in both directions (up/down).
*   **Double Linked List:** Uses a linked list structure (`next()` and `previous()`) instead of an index-based list, making it ideal for graph-like data structures or scenarios where index calculation is expensive or impossible.
*   **Dynamic Sizing:** Supports items with variable heights.
*   **Buffer Control:** Customizable `minBuffer` and `maxBuffer` to manage how many items are kept in memory outside the viewport.
*   **Programmatic Control:** `NodeListViewController` allows jumping to nodes, selecting next/previous items, and refreshing the list.
*   **Selection Tracking:** Built-in support for tracking the "selected" or "focused" node.

## Installation

Add `flutter_nodelistview` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_nodelistview: ^1.0.0
```

## Usage

### 1. Define your Node

Create a class that extends `NodeBase`. This class represents an item in your list. You must implement `next()` and `previous()` to define the structure of your list.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_nodelistview/flutter_nodelistview.dart';

class MyNode extends NodeBase<MyNode> {
  final String data;
  
  // Linked list pointers
  MyNode? _next;
  MyNode? _previous;

  MyNode(this.data, {MyNode? next, MyNode? previous})
      : _next = next,
        _previous = previous,
        super(GlobalKey()); // Important: Pass a GlobalKey to super

  @override
  MyNode? next() {
    // Return the next node in the list, or create it if it doesn't exist
    _next ??= MyNode("Next Data", previous: this);
    return _next;
  }

  @override
  MyNode? previous() {
    // Return the previous node in the list
    _previous ??= MyNode("Previous Data", next: this);
    return _previous;
  }
}
```

### 2. Implement the Widget

Use `NodeListView` in your widget tree.

```dart
import 'package:flutter_nodelistview/flutter_nodelistview.dart';

class MyInfiniteList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Start node
    MyNode startNode = MyNode("Start");

    return Scaffold(
      body: NodeListView<MyNode>(
        startNode: startNode,
        itemBuilder: (context, node, {selected = false}) {
          return ListTile(
            title: Text(node.data),
            selected: selected, // Highlight the currently 'selected' node
          );
        },
      ),
    );
  }
}
```

## Advanced Usage

### Controlling the List

Use `NodeListViewController` to programmatically control the list.

```dart
final NodeListViewController<MyNode> controller = NodeListViewController<MyNode>();

// ... inside your build method ...
NodeListView<MyNode>(
  controller: controller,
  // ... other parameters
)

// ... elsewhere ...
controller.selectNext(); // Scroll to next item
controller.selectPrevious(); // Scroll to previous item
controller.jumpTo(someNode); // Jump to a specific node
controller.refreshAllNodePointers(); // Refresh list if structure changes
```

### Customizing Buffer & Size

You can tune the performance and behavior by adjusting the buffer sizes and fallback size.

```dart
NodeListView<MyNode>(
  minBuffer: 10, // Minimum items to keep in buffer
  maxBuffer: 20, // Maximum items to keep before disposing
  fallbackSize: 100.0, // Estimated height for items before they are rendered
  // ...
)
```

## Contributing

Contributions are welcome! If you find a bug or want to add a feature, please open an issue or submit a pull request.

1.  Fork the repository.
2.  Create your feature branch (`git checkout -b feature/my-feature`).
3.  Commit your changes (`git commit -am 'Add some feature'`).
4.  Push to the branch (`git push origin feature/my-feature`).
5.  Open a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
