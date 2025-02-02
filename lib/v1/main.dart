import 'package:flutter/material.dart';
import 'package:untitled6/v1/example_node.dart';
import 'package:untitled6/v1/node_base.dart';
import 'package:untitled6/v1/node_list_view.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // Generate a linked list of ExampleNodes for demonstration
  List<NodeBase> _generateNodes(int count) {
    List<ExamplePrefilledNode> nodes = List.generate(count, (index) => ExamplePrefilledNode('Node ${index + 1}'));
    for (int i = 0; i < nodes.length; i++) {
      if (i > 0) {
        nodes[i].setPrevious(nodes[i - 1]);
        nodes[i - 1].setNext(nodes[i]);
      }
    }
    return nodes.map((e) => e as NodeBase).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Create 100 nodes for testing
    // List<NodeBase> nodes = _generateNodes(100);
    // NodeBase currentNode = nodes[50]; // Start from the middle
    NodeBase currentNode = ExampleInfiniteNode('Node 0'); // Start from a single node

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Custom Node ListView')),
        body: NodeListView(
          currentNode: currentNode,
          buffer: 5, // Customize buffer size here
          fallbackSize: 80.0, // Customize item height here
          itemBuilder: (context, node) {
            final exampleNode = node as HasData;
            return Card(
              margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              child: ListTile(
                leading: Icon(Icons.label),
                title: Text(exampleNode.data),
              ),
            );
          },
        ),
      ),
    );
  }
}
