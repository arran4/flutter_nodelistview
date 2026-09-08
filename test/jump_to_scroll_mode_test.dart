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
    // Node 15 is not visible yet, so jumpTo it with fitNode
    controller.jumpTo(nodes[15], scrollMode: ScrollModes.fitNode);
    await tester.pumpAndSettle();

    final pos15_after_fit = tester.getTopLeft(find.text('Node 15'));
    // Since it's a completely new node, it gets reset to center (null offset).
    // Center of 600 viewport is 300. Node height 50. Top should be 275.
    expect(pos15_after_fit, const Offset(0.0, 275.0),
        reason: 'fitNode on unknown node defaults to center');

    // 3. Test reset (clears offset, centers)
    // First we jump to a node with fitNode to give it an offset.
    // Node 12 is above 15, so jumping to it with fitNode should snap to top!
    controller.jumpTo(nodes[12], scrollMode: ScrollModes.fitNode);
    await tester.pumpAndSettle();

    final pos12_after_fit = tester.getTopLeft(find.text('Node 12'));
    // Node 12 is at top because it was above the viewport.
    expect(pos12_after_fit.dy < 275.0, true,
        reason: 'fitNode snapped node to top edge');

    // Now jump to it again with reset
    controller.jumpTo(nodes[12], scrollMode: ScrollModes.reset);
    await tester.pumpAndSettle();

    final pos12_after_reset = tester.getTopLeft(find.text('Node 12'));
    expect(pos12_after_reset, const Offset(0.0, 275.0),
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
    expect(pos10_after_setOffset, const Offset(0.0, 275.0),
        reason: 'setOffset without provided offset defaults to null (center)');
  });
}
