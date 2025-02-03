import 'package:flutter/material.dart';
import './node_base.dart';

typedef NodeWidgetBuilder = Widget Function(BuildContext context, NodeBase node, { bool selected });

class NodeListView extends StatefulWidget {
  final NodeBase? currentNode;
  final NodeWidgetBuilder itemBuilder;
  final int buffer;
  final double fallbackSize;

  const NodeListView({
    Key? key,
    required this.currentNode,
    required this.itemBuilder,
    this.fallbackSize = 100.0,
    this.buffer = 5,
  }) : super(key: key);

  @override
  _NodeListViewState createState() => _NodeListViewState();
}

class _NodeListViewState extends State<NodeListView> {
  final ScrollController _scrollController = ScrollController(
    initialScrollOffset: 100,
  );
  late List<NodeBase> _visibleNodes;
  int? selectedNode;
  int? visibleExtentUp;
  int? visibleExtentDown;
  double? selectedOffset;

  @override
  void initState() {
    super.initState();
    _visibleNodes = [];
    _initializeVisibleNodes();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeVisibleNodes() {
    if (_visibleNodes.isNotEmpty) return;
    if (widget.currentNode == null) return;
    _visibleNodes.add(widget.currentNode!);
    selectedNode = 0;
  }

  void _onScroll() {
    print("On scroll");
  }

  @override
  Widget build(BuildContext context) {
    print("_visibleNodes count: ${_visibleNodes.length}");
    return LayoutBuilder(
        builder: (context, constraints) {
          if (selectedNode == null) {
            return Expanded(
              child: Center(
                child: Text("No nodes to display"),
              ),
            );
          }
          return Scrollbar(
            controller: _scrollController,
            child: Stack(
              fit: StackFit.expand,
              children: _nodesAndPositions(constraints),
            ),
          );
        }
    );
  }

  List<Widget> _nodesAndPositions(BuildContext context, BoxConstraints constraints) {
    if (selectedNode == null) return [];
    double centerOfSelected = constraints.maxHeight / 2;
    if (selectedOffset != null) {
      centerOfSelected += selectedOffset!;
    }
    List<Positioned> headResult = [];
    List<Positioned> tailResult = [];
    NodeBase selected = _visibleNodes[selectedNode!];
    var child = widget.itemBuilder(context, selected, selected: true);
    Size size = selected.size();
    double halfHeight = size.height / 2;
    double top = centerOfSelected - halfHeight;
    double bottom = centerOfSelected + halfHeight;
    Positioned positioned = Positioned(
      top: top,
      left: 0,
      right: constraints.minWidth,
      height: size.height,
      key: selected.key,
      child: child,
    );
    tailResult.add(positioned);
    var last = selected;
    for (int n = 1; top > 0; n++) {
      NodeBase? node;
      visibleExtentUp = selectedNode! - n;
      if (visibleExtentUp! < 0) {
        node = last.previous();
        if (node == null) break;
        _visibleNodes.insert(0, node);
        selectedNode = selectedNode! + 1;
        if (visibleExtentDown != null) {
          visibleExtentDown = visibleExtentDown! + 1;
        }
      } else {
        node = _visibleNodes[visibleExtentUp!];
      }
      child = widget.itemBuilder(context, node);
      size = node.size();
      top -= size.height;
      positioned = Positioned(
        top: top,
        left: 0,
        right: constraints.minWidth,
        height: size.height,
        key: node.key,
        child: child,
      );
      headResult.add(positioned);
      last = node;
    }
    last = selected;
    for (int n = 1; bottom < constraints.maxHeight; n++) {
      NodeBase? node;
      visibleExtentDown = selectedNode! + n;
      if (visibleExtentDown! > 0) {
        node = last.next();
        if (node == null) break;
        _visibleNodes.add(node);
      } else {
        node = _visibleNodes[visibleExtentDown!];
      }
      child = widget.itemBuilder(context, node);
      size = node.size();
      positioned = Positioned(
        top: bottom,
        left: 0,
        right: constraints.minWidth,
        height: size.height,
        key: node.key,
        child: child,
      );
      bottom += size.height;
      headResult.add(positioned);
      last = node;
    }
    return headResult.reversed.toList() + tailResult;
  }
}
