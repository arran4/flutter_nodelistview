import 'package:flutter/material.dart';
import './example_node.dart';
import './node_base.dart';
import './node_list_view.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    NodeBase currentNode = ExampleInfiniteNode('Node 0'); // Start from a single node

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Custom Node ListView')),
        body: NodeListView(
          startNode: currentNode,
          minBuffer: 5, // Customize buffer size here
          maxBuffer: 5, // Customize buffer size here
          fallbackSize: 80.0, // Customize item height here
          itemBuilder: (context, node, { selected = false }) {
            final exampleNode = node as HasData;
            Widget card = Card(
              margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              child: ListTile(
                leading: Icon(Icons.label),
                title: Text(exampleNode.data),
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
