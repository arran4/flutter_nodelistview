import 'package:flutter/material.dart';
import 'package:flutter_nodelistview/flutter_nodelistview.dart';
import 'dart:math';

void main() {
  runApp(MyApp());
}

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

  ExampleInfiniteNode? _left;

  ExampleInfiniteNode left() {
    _left ??= ExampleInfiniteNode(x: x - 1, y: y, right: this);
    return _left!;
  }

  ExampleInfiniteNode? _right;

  get label => 'Node $x,$y ($name)';

  ExampleInfiniteNode right() {
    _right ??= ExampleInfiniteNode(x: x + 1, y: y, left: this);
    return _right!;
  }

  void delete() {
    _previous?._next = null;
    _previous = null;
    _next?._previous = null;
    _next = null;
    _left?._right = null;
    _left = null;
    _right?._left = null;
    _right = null;
  }
}


Map<Key, double> size = {};

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final NodeListViewController<ExampleInfiniteNode> _nodeController = NodeListViewController<ExampleInfiniteNode>();

  @override
  Widget build(BuildContext context) {
    ExampleInfiniteNode currentNode = ExampleInfiniteNode(x:0,y:0); // Start from a single node

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
            title: Text('Custom Node ListView'),
          actions: [
            IconButton(
              icon: Icon(Icons.keyboard_arrow_down),
              onPressed: () {
                _nodeController.selectNext();
              },
              tooltip: "Next",
            ),
            IconButton(
              icon: Icon(Icons.keyboard_arrow_up),
              onPressed: () {
                _nodeController.selectPrevious();
              },
              tooltip: "Previous",
            ),
            IconButton(onPressed: (){
              _nodeController.selectFirstVisible();
            }, icon: Icon(Icons.keyboard_double_arrow_up), tooltip: "First visible"),
            IconButton(onPressed: (){
              _nodeController.selectLastVisible();
            }, icon: Icon(Icons.keyboard_double_arrow_down), tooltip: "Last visible"),
            IconButton(onPressed: () {
              _nodeController.refreshAllNodePointers();
            }, icon: Icon(Icons.refresh), tooltip: "Refresh all"),
          ],
        ),
        body: NodeListView<ExampleInfiniteNode>(
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
                trailing: OverflowBar(
                  children: [
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        setState(() {
                          size.update(node.key, (value) => value + 1, ifAbsent: () => 4);
                        });
                      },
                      tooltip: "Increase size",
                    ),
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: () {
                        setState(() {
                          size.update(node.key, (value) => value - 1, ifAbsent: () => 4);
                        });
                      },
                      tooltip: "Decrease size",
                    ),
                    IconButton(
                      icon: Icon(Icons.keyboard_arrow_left),
                      onPressed: () {
                        ExampleInfiniteNode n = node.left();
                        _nodeController.jumpTo(n);
                      },
                      tooltip: "Left",
                    ),
                    IconButton(
                      icon: Icon(Icons.keyboard_arrow_right),
                      onPressed: () {
                        ExampleInfiniteNode n = node.right();
                        _nodeController.jumpTo(n);
                      },
                      tooltip: "Right",
                    ),
                    IconButton(onPressed: () {
                      _nodeController.refreshNodePointers(node);
                    }, icon: Icon(Icons.refresh), tooltip: "Refresh"),
                    IconButton(onPressed: () {
                      if (selected) {
                        _nodeController.jumpTo(ExampleInfiniteNode(x: 0, y: 0));
                      } else {
                        node.delete();
                      }
                      _nodeController.refreshAllNodePointers();
                    }, icon: Icon(Icons.delete_sweep), tooltip: "Delete"),
                  ],
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
        ),
      ),
    );
  }
}
