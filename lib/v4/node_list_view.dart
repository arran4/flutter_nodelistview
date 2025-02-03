import 'dart:math';

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
    keepScrollOffset: false,
  );
  late List<NodeBase> _visibleNodes;
  int? selectedNode;
  int? visibleExtentUp;
  int? visibleExtentDown;
  double? selectedOffset;
  List<VisibleType>? _positions;
  BoxConstraints? _constraints;

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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) {
          if (_constraints == null || _constraints != constraints) {
            _constraints = constraints;
            _positions = calculatePositions(constraints);
          }
          if (selectedNode == null) {
            return Expanded(
              child: Center(
                child: Text("No nodes to display"),
              ),
            );
          }
          if (_positions == null) {
            return Expanded(
              child: Center(
                child: Text("Loading..."),
              ),
            );
          }
          return Scrollbar(
            controller: _scrollController,
            interactive: true,
            child: Scrollable(
              scrollBehavior: ScrollBehavior(),
              // physics: AlwaysScrollableScrollPhysics(),
              controller: _scrollController,
                viewportBuilder: (context, position) {
                  position.applyViewportDimension(constraints.maxHeight);
                  // TODO calculate min and max scroll extent when we know where the ends are for a better experience.
                  position.applyContentDimensions(constraints.maxHeight * -2 - (selectedOffset??0), constraints.maxHeight * 2 - (selectedOffset??0));
                  return Stack(
                    fit: StackFit.expand,
                    children: (_positions??[]).map((e) {
                      return Positioned(
                        top: e.top,
                        left: 0,
                        right: constraints.minWidth,
                        height: e.height,
                        key: e.node.key,
                        child: widget.itemBuilder(context, e.node, selected: e.node == _visibleNodes[selectedNode!]),
                      );
                    }).toList(),
                  );
                },
              ),
          );
        }
    );
  }

  List<VisibleType> calculatePositions(BoxConstraints constraints) {
    if (selectedNode == null) return [];
    double positionOfOriginalSelected = constraints.maxHeight / 2;
    if (selectedOffset != null) {
      positionOfOriginalSelected += selectedOffset!;
    }
    NodeBase selected = _visibleNodes[selectedNode!];
    Size size = selected.size();
    double halfHeight = size.height / 2;
    double top = positionOfOriginalSelected - halfHeight;
    double bottom = positionOfOriginalSelected + halfHeight;
    List<VisibleType> result = [VisibleType(top: top, height: size.height, node: selected, covered: coveredCalc(top, constraints, bottom, size.height))];
    ({int resultPos, int visiblePos}) newSelectedNode = (resultPos: 0, visiblePos: selectedNode!);
    for (int selectedPos = 0; top > 0; selectedPos++) {
      NodeBase? node;
      visibleExtentUp = selectedNode! - selectedPos - 1;
      if (visibleExtentUp! < 0) {
        node = result.first.node.previous();
        if (node == null) break;
        _visibleNodes.insert(0, node);
        selectedNode = selectedNode! + 1;
        newSelectedNode = (resultPos: selectedPos, visiblePos: newSelectedNode.visiblePos + 1);
        if (visibleExtentDown != null) {
          visibleExtentDown = visibleExtentDown! + 1;
        }
      } else {
        node = _visibleNodes[visibleExtentUp!];
      }
      size = node.size();
      top -= size.height;
      result.insert(0, VisibleType(top: top, height: size.height, node: node, covered: coveredCalc(top, constraints, top + size.height, size.height)));
      if (newSelectedNode.resultPos == 0 && (result[1].covered! > result[0].covered! || result[1].covered! == 1)) {
        newSelectedNode = (resultPos: 0, visiblePos: visibleExtentUp!);
      } else {
        newSelectedNode = (
          resultPos: newSelectedNode.resultPos + 1,
          visiblePos: newSelectedNode.visiblePos
        );
      }
    }
    for (int n = 1; bottom < constraints.maxHeight; n++) {
      NodeBase? node;
      visibleExtentDown = selectedNode! + n;
      if (visibleExtentDown! > _visibleNodes.length - 1) {
        node = result.last.node.next();
        if (node == null) break;
        _visibleNodes.add(node);
      } else {
        node = _visibleNodes[visibleExtentDown!];
      }
      size = node.size();
      result.add(VisibleType(top: bottom, height: size.height, node: node, covered: coveredCalc(bottom, constraints, bottom + size.height, size.height)));
      bottom += size.height;
      if (newSelectedNode.resultPos == result.length - 2 && (result[result.length - 2].covered! > result[result.length - 1].covered! || result[result.length - 2].covered! == 1)) {
        newSelectedNode = (resultPos: result.length - 1, visiblePos: visibleExtentDown!);
      }
    }
    if (newSelectedNode.visiblePos != selectedNode!) {
      _changeSelectedNodeToAnotherOneInPositions(newSelectedNode.resultPos, newSelectedNode.visiblePos, result[newSelectedNode.resultPos], constraints);
    }
    return result;
  }

  void _changeSelectedNodeToAnotherOneInPositions(int positionPos, int visiblePos, VisibleType node, BoxConstraints constraints) {
    selectedNode = visiblePos;
    setState(() {
      selectedOffset = (node.top + node.height / 2) - constraints.maxHeight / 2;
    });
  }

  double coveredCalc(double top, BoxConstraints constraints, double bottom, double height) => min((0 - min(top, 0) - min(constraints.maxHeight - bottom, 0)) / height, 1);

  void _onScroll() {
    setState(() {
      selectedOffset = (selectedOffset??0) - _scrollController.offset;
    });
    if (_constraints != null) {
      _positions = calculatePositions(_constraints!);
    }
    _scrollController.jumpTo(0);
  }
}

class VisibleType {
  double? covered;
  double height;
  NodeBase node;
  double top;

  VisibleType({this.covered,required this.height, required this.node, required this.top});
}
