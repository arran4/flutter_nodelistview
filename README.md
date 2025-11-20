# flutter_nodelistview

A Flutter widget which uses an infinite list of double linked nodes.

![Demo](doc/simplescreenrecorder-2025-02-21_17.13.18.mp4)

> **Note:** This is a work in progress. APIs are subject to change. Please use GitHub discussions for feedback.

## Getting Started

### 1. Define your Node

Implement a Node class which extends `NodeBase` and implements the abstract methods.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_nodelistview/flutter_nodelistview.dart';

abstract class NodeBase<T> {
  NodeBase(this.key, { this.size});

  GlobalKey<State<StatefulWidget>> key;
  Size? size;

  T? previous();
  T? next();

  void dispose() {}
}
```

Example implementation (see [example/lib/main.dart](example/lib/main.dart) for full code):

```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_nodelistview/flutter_nodelistview.dart';

class ExampleInfiniteNode extends NodeBase<ExampleInfiniteNode> {
  ExampleInfiniteNode({
    required this.x,
    required this.y,
    ExampleInfiniteNode? next,
    ExampleInfiniteNode? previous,
  }) :
        name = Random().nextInt(1000).toString(),
        _next = next,
        _previous = previous,
        super(GlobalKey());
  
  final int x;
  final int y;
  final String name;

  ExampleInfiniteNode? _previous;

  @override
  ExampleInfiniteNode? previous() {
    _previous ??= ExampleInfiniteNode(x: x, y: y - 1, next: this);
    return _previous;
  }

  ExampleInfiniteNode? _next;

  @override
  ExampleInfiniteNode? next() {
    _next ??= ExampleInfiniteNode(x: x, y: y + 1, previous: this);
    return _next;
  }
}
```

### 2. Usage in Widget

Then use it in a `NodeListView`:

```dart
NodeListView<ExampleInfiniteNode>(
  startNode: currentNode,
  controller: _nodeController,
  minBuffer: 5, // Customize buffer size here
  maxBuffer: 5, // Customize buffer size here
  fallbackSize: 80.0, // Customize item height here
  itemBuilder: (context, node, { selected = false }) {
    Widget card = Card(
      child: ListTile(
        leading: Icon(Icons.label),
        title: Text("Node ${node.x},${node.y} (${node.name})"),
      ),
    );
    if (selected) {
      card = Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red),
        ),
        child: card,
      );
    }
    return card;
  },
)
```

## Installation

Add `flutter_nodelistview` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_nodelistview: ^1.0.0
```
