import 'package:flutter/material.dart';
import './example_node.dart';
import './node_base.dart';
import './node_list_view.dart';

void main() {
  runApp(MyApp());
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
            ),
            IconButton(
              icon: Icon(Icons.keyboard_arrow_up),
              onPressed: () {
                _nodeController.selectPrevious();
              },
            ),
            IconButton(onPressed: (){
              _nodeController.selectFirstVisible();
            }, icon: Icon(Icons.keyboard_double_arrow_up)),
            IconButton(onPressed: (){
              _nodeController.selectLastVisible();
            }, icon: Icon(Icons.keyboard_double_arrow_down)),
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
                    ),
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: () {
                        setState(() {
                          size.update(node.key, (value) => value - 1, ifAbsent: () => 4);
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.keyboard_double_arrow_left),
                      onPressed: () {
                        ExampleInfiniteNode n = node.left();
                        _nodeController.jumpTo(n);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.keyboard_double_arrow_right),
                      onPressed: () {
                        ExampleInfiniteNode n = node.right();
                        _nodeController.jumpTo(n);
                      },
                    ),
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
