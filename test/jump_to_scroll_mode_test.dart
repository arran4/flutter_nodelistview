import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_nodelistview/src/node_base.dart';
import 'package:flutter_nodelistview/src/node_list_view.dart';

class MyNode extends NodeBase<MyNode> {
  final int id;
  MyNode(this.id) : super(GlobalKey());
  MyNode? nextNode;
  MyNode? prevNode;
  @override
  MyNode? next() => nextNode;
  @override
  MyNode? previous() => prevNode;
}

void main() {
  testWidgets('jumpTo ScrollModes regression coverage',
      (WidgetTester tester) async {
    final nodes = List.generate(20, (i) => MyNode(i));
    for (int i = 0; i < 19; i++) {
      nodes[i].nextNode = nodes[i + 1];
      nodes[i + 1].prevNode = nodes[i];
    }

    final controller = NodeListViewController<MyNode>();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: NodeListView<MyNode>(
          startNode: nodes[0],
          controller: controller,
          itemBuilder: (context, node, {selected = false}) {
            return SizedBox(
                height: 50, child: Text('Node ' + node.id.toString()));
          },
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // 1. Test none (preserves physical position)
    final pos0_before = tester.getTopLeft(find.text('Node 0'));
    controller.jumpTo(nodes[2], scrollMode: ScrollModes.none);
    await tester.pumpAndSettle();
    final pos0_after_none = tester.getTopLeft(find.text('Node 0'));
    expect(pos0_after_none, pos0_before,
        reason: 'ScrollModes.none preserves viewport offset');

    // 2. Test fitNode for a node that's out of bounds (should snap)
    controller.jumpTo(nodes[15], scrollMode: ScrollModes.fitNode);
    await tester.pumpAndSettle();

    final pos15_after_fit = tester.getTopLeft(find.text('Node 15'));

    // Use constraints to verify it's dynamically fitted
    final viewportHeight = tester.getSize(find.byType(Scrollable)).height;
    expect(
        pos15_after_fit.dy >= 0.0 && pos15_after_fit.dy <= viewportHeight, true,
        reason: 'fitNode on unknown node brings it into view');

    // 3. Test reset (clears offset, centers)
    controller.jumpTo(nodes[12], scrollMode: ScrollModes.fitNode);
    await tester.pumpAndSettle();

    controller.jumpTo(nodes[12], scrollMode: ScrollModes.reset);
    await tester.pumpAndSettle();

    final pos12_after_reset = tester.getTopLeft(find.text('Node 12'));
    final centerPos = viewportHeight / 2 - 25.0; // 25 is node height / 2
    expect(pos12_after_reset.dy, centerPos,
        reason: 'reset mode centers the node');

    // 4. Repeated jumps remain stable
    controller.jumpTo(nodes[12], scrollMode: ScrollModes.reset);
    await tester.pumpAndSettle();
    final pos12_after_repeat = tester.getTopLeft(find.text('Node 12'));
    expect(pos12_after_repeat, pos12_after_reset,
        reason: 'repeated jumps are stable');

    // 5. Test setOffset via jumpTo (defaults to null since jumpTo doesn't provide offset)
    controller.jumpTo(nodes[10], scrollMode: ScrollModes.fitNode);
    await tester.pumpAndSettle();

    controller.jumpTo(nodes[10], scrollMode: ScrollModes.setOffset);
    await tester.pumpAndSettle();
    final pos10_after_setOffset = tester.getTopLeft(find.text('Node 10'));
    expect(pos10_after_setOffset.dy, centerPos,
        reason: 'setOffset without provided offset defaults to null (center)');

    // 6. Test selected node notifications
    MyNode? notifiedNode;
    Position? notifiedPos;
    int notificationCount = 0;
    controller.addOnSelectedNodeChangedListener((node, pos) {
      notifiedNode = node;
      notifiedPos = pos;
      notificationCount++;
    });

    controller.jumpTo(nodes[11], scrollMode: ScrollModes.none);
    await tester.pumpAndSettle();

    expect(notificationCount, 1,
        reason: 'Notification should be triggered once');
    expect(notifiedNode, nodes[11], reason: 'Notified node should be 11');
    expect(notifiedPos != null, true);

    controller.jumpTo(nodes[18], scrollMode: ScrollModes.fitNode);
    await tester.pumpAndSettle();

    expect(notificationCount, 2,
        reason: 'Notification should be triggered once more for new jump');
    expect(notifiedNode, nodes[18], reason: 'Notified node should be 18');
    // For a brand new node jumping with fitNode, selectedOffset is null, which evaluates to 0.0 in the callback:
    expect(notifiedPos?.offset, 0.0,
        reason: 'Reset to center should yield 0.0 offset in callback');

    final state = tester
        .state<NodeListViewState<MyNode>>(find.byType(NodeListView<MyNode>));

    // 7. Regression test for jumpTo an above node with top=null, bottom!=null
    controller.jumpTo(nodes[15], scrollMode: ScrollModes.reset);
    await tester.pumpAndSettle();

    nodes[14].size = null; // Unmeasured
    state.updatePositions(stateUpdate: true);
    await tester.pump();

    controller.jumpTo(nodes[14], scrollMode: ScrollModes.none);
    await tester.pumpAndSettle();

    final pos14_after_none = tester.getTopLeft(find.text('Node 14'));
    expect(pos14_after_none.dy, 200.0,
        reason: 'none preserves the absolute center');

    controller.jumpTo(nodes[15], scrollMode: ScrollModes.reset);
    await tester.pumpAndSettle();

    nodes[14].size = null;
    state.updatePositions(stateUpdate: true);
    await tester.pump();

    controller.jumpTo(nodes[14], scrollMode: ScrollModes.fitNode);
    await tester.pumpAndSettle();

    final pos14_after_fit2 = tester.getTopLeft(find.text('Node 14'));
    // Since it's fully visible (175 to 275 before layout, 200 to 250 after layout), fitNode should just act like none.
    expect(pos14_after_fit2.dy, 175.0,
        reason: 'fitNode handles bottom-only coordinate correctly');
  });
}
