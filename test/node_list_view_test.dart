import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_nodelistview/flutter_nodelistview.dart';


class TestNode extends NodeBase {
  final int id;
  TestNode? _next;
  TestNode? _previous;

  TestNode(this.id) : super(GlobalKey());
  @override
  TestNode? next() => _next;
  @override
  TestNode? previous() => _previous;
  @override
  String toString() => 'TestNode($id)';
}

void main() {
  TestNode createList(int count) {
    List<TestNode> nodes = List.generate(count, (i) => TestNode(i));
    for (int i = 0; i < count; i++) {
      if (i > 0) nodes[i]._previous = nodes[i - 1];
      if (i < count - 1) nodes[i]._next = nodes[i + 1];
    }
    return nodes.first;
  }

  testWidgets('NodeListView selected-node notification on manual gesture',
      (WidgetTester tester) async {
    final startNode = createList(10);
    final controller = NodeListViewController<TestNode>();
    int notificationCount = 0;
    TestNode? lastNode;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: NodeListView<TestNode>(
          startNode: startNode,
          controller: controller,
          itemBuilder: (context, node, {bool selected = false}) {
            return SizedBox(
              height: 200,
              child: Text('Node ${node.id}'),
            );
          },
        ),
      ),
    ));

    await tester.pumpAndSettle();

    // Add listener after initial render, as in real usage scenarios
    controller.addOnSelectedNodeChangedListener((node, pos) {
      notificationCount++;
      lastNode = node;
    });

    // 1. Drag to trigger scroll
    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(Scrollable)));

    // Drag by enough pixels to move to the next node (each is 200px tall)
    await gesture.moveBy(const Offset(0, -300));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    // Listener should be notified of the new effective node
    expect(notificationCount, greaterThanOrEqualTo(1));
    expect(lastNode?.id, 1);

    notificationCount = 0;

    // 2. Tiny drag that doesn't change node materially but changes offset
    final gesture2 =
        await tester.startGesture(tester.getCenter(find.byType(Scrollable)));
    await gesture2.moveBy(const Offset(0, -10));
    await tester.pump();
    await gesture2.up();
    await tester.pumpAndSettle();

    expect(notificationCount,
        greaterThanOrEqualTo(1)); // Notified of the new offset
    expect(lastNode?.id, 1);

    notificationCount = 0;

    // 3. scrolling across more than one node continues to report correct nodes
    final gesture3 =
        await tester.startGesture(tester.getCenter(find.byType(Scrollable)));
    await gesture3.moveBy(const Offset(0, -600));
    await tester.pump();
    await gesture3.up();
    await tester.pumpAndSettle();

    expect(notificationCount, greaterThanOrEqualTo(1));
    expect(lastNode?.id, 4);

    notificationCount = 0;

    // 4. Force a state update that doesn't change selection (should not trigger duplicate notification)
    tester
        .state<NodeListViewState<TestNode>>(find.byType(NodeListView<TestNode>))
        .updatePositions(stateUpdate: true);
    await tester.pumpAndSettle();
    expect(notificationCount, 0);
  });
}
