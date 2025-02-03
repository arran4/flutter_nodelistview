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
              margin: EdgeInsets.symmetric(vertical: size[node.key]??4, horizontal: size[node.key]??4),
              child: ListTile(
                leading: Icon(Icons.label),
                title: Text(exampleNode.data),
                onTap: () {
                  setState(() {
                    size.update(node.key, (value) => value + 1, ifAbsent: () => 4);
                  });
                },
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
