# flutter_nodelistview

A flutter widget which uses an infinite list of double linked nodes

![simplescreenrecorder-2025-02-21_17.13.18.mp4](doc/simplescreenrecorder-2025-02-21_17.13.18.mp4)

Note: this is a work in progress; I might make big changes, let me know what you use to ensure I don't break your code. You can log it in the github "discussions."

## Getting Started

Implement a Node class which extends NodeBase and implements the abstract methods

```dart
abstract class NodeBase<T> {
  NodeBase(this.key, { this.size});

  GlobalKey<State<StatefulWidget>> key;
  Size? size;

  T? previous();
  T? next();

  void dispose() {}
}
```

Such as [example_node.dart](example/example_node.dart)

```dart
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:untitled6/node_base.dart';

class ExampleInfiniteNode extends NodeBase<ExampleInfiniteNode> {
  ExampleInfiniteNode({
    required this.x,
    required this.y,
    ExampleInfiniteNode? left,
    ExampleInfiniteNode? right,
    ExampleInfiniteNode? next,
    ExampleInfiniteNode? previous,
  }) :
        name = Random().nextInt(1000).toString(),
        _left = left,
        _right = right,
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

Then use it in a NodeListView:
```dart
    NodeListView<ExampleInfiniteNode>(
          startNode: currentNode,
          controller: _nodeController,
          minBuffer: 5, // Customize buffer size here
          maxBuffer: 5, // Customize buffer size here
          fallbackSize: 80.0, // Customize item height here
          itemBuilder: (context, node, { selected = false }) {
            Widget card = Card(
              margin: EdgeInsets.symmetric(vertical: size[node.key]??4, horizontal: size[node.key]??4),
              child: ListTile(
                leading: Icon(Icons.label),
                title: Text("${node.label}"),
                ),
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