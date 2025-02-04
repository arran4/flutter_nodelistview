import 'dart:math';

import 'package:flutter/material.dart';
import './node_base.dart';

typedef NodeWidgetBuilder<T> = Widget Function(BuildContext context, T node, { bool selected });

class NodeListViewController<T extends NodeBase> {
  NodeListViewState<T>? _nodeListViewState;

  NodeListViewController();

  void attach(NodeListViewState<T> nodeListViewState) {
    _nodeListViewState = nodeListViewState;
  }

  void detach() {
    _nodeListViewState = null;
  }

  void jumpTo(T node, {bool keepVisible = false}) {
    if (_nodeListViewState == null) return;
    ({ int? positionPos, _NodePositionWrapper<T>? positionWrapper, int visiblePos })? index = _nodeListViewState!.findNode(node);
    if (index?.positionPos != null && index?.positionWrapper != null) {
      _nodeListViewState!._changeSelectedNodeToAnotherOneInPositions(index!.positionPos!, index.visiblePos, index.positionWrapper!, null);
      return;
    }
    if (index?.visiblePos != null) {
      _nodeListViewState!._changeSelectedNodeToAnotherOneNotInPositionsButVisible(index!.visiblePos, null, makeVisible: keepVisible);
      return;
    }
    _nodeListViewState!._resetSelectedNodeToNewNode(node);
  }

  void selectNext() {
    if (_nodeListViewState == null) return;
    if (_nodeListViewState!._selectedNode == null) return;
    T? next = _nodeListViewState!._selectedNode?.next();
    if (next == null) return;
    jumpTo(next, keepVisible: true);
  }
  
  void selectPrevious() {
    if (_nodeListViewState == null) return;
    if (_nodeListViewState!._selectedNode == null) return;
    T? next = _nodeListViewState!._selectedNode?.previous();
    if (next == null) return;
    jumpTo(next, keepVisible: true);
  }

  void selectFirstVisible() {
    if (_nodeListViewState == null) return;
    T? next = _nodeListViewState!._positions?.firstOrNull?.node;
    if (next == null) return;
    jumpTo(next, keepVisible: true);
  }

  void selectLastVisible() {
    if (_nodeListViewState == null) return;
    T? next = _nodeListViewState!._positions?.lastOrNull?.node;
    if (next == null) return;
    jumpTo(next, keepVisible: true);
  }
}

class NodeListView<T extends NodeBase> extends StatefulWidget {
  final T? startNode;
  final NodeWidgetBuilder<T> itemBuilder;
  final int minBuffer;
  final int maxBuffer;
  final double fallbackSize;
  final SelectedNodeTracker? selectedNodeTracker;
  final NodeListViewController<T>? controller;

  const NodeListView({
    super.key,
    required this.startNode,
    required this.itemBuilder,
    this.selectedNodeTracker,
    this.controller,
    this.fallbackSize = 100.0,
    this.minBuffer = 5,
    this.maxBuffer = 5,
  });

  @override
  NodeListViewState<T> createState() => NodeListViewState();
}

class NodeListViewState<T extends NodeBase> extends State<NodeListView<T>> {
  final ScrollController _scrollController = ScrollController();
  late List<T> _visibleNodes;
  int? selectedNode;
  int? visibleExtentUp;
  int? visibleExtentDown;
  double? selectedOffset;
  late SelectedNodeTracker selectedNodeTracker;
  NodeListViewController<T>? _controller;
  List<_NodePositionWrapper<T>>? _positions;
  BoxConstraints? _constraints;

  T? get _selectedNode {
    if (selectedNode == null) return null;
    if (selectedNode! < 0 || selectedNode! >= _visibleNodes.length) return null;
    return _visibleNodes[selectedNode!];
  }

  @override
  void initState() {
    super.initState();
    _visibleNodes = [];
    _initializeVisibleNodes();
    selectedNodeTracker = widget.selectedNodeTracker ?? StickySelectedNodeTracker();
    _scrollController.addListener(_onScroll);
    _controller = widget.controller;
    _controller?.attach(this);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller?.detach();
    for (T node in _visibleNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _initializeVisibleNodes() {
    if (_visibleNodes.isNotEmpty) return;
    if (widget.startNode == null) return;
    _visibleNodes.add(widget.startNode!);
    selectedNode = 0;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) {
          if (selectedNode == null) {
            return Center(
              child: Text("No nodes to display"),
            );
          }
          return Scrollbar(
            controller: _scrollController,
            interactive: true,
            child: Scrollable(
              scrollBehavior: ScrollBehavior(),
              controller: _scrollController,
              viewportBuilder: (context, position) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    var mutated = _constraints == null || _constraints != constraints;
                    for (_NodePositionWrapper e in (_positions ?? [])) {
                      final newSize = e.node.key.currentContext?.size;
                      if (newSize != null && e.node.size != newSize) {
                        e.node.size = newSize;
                        mutated = true;
                      }
                    }
                    if (!mutated) return;
                    setState(() {
                      _constraints = constraints;
                    });
                    _positions = calculatePositions(constraints);
                  });
                if (_positions == null) {
                  return Center(
                    child: Text("Loading..."),
                  );
                }
                position.applyViewportDimension(constraints.maxHeight);
                // TODO calculate min and max scroll extent when we know where the ends are for a better experience.
                position.applyContentDimensions(
                    constraints.maxHeight * -5,
                    constraints.maxHeight * 5);
                return Stack(
                  fit: StackFit.expand,
                  children: (_positions ?? []).map((e) {
                    return Positioned(
                      top: e.top,
                      bottom: e.bottom,
                      left: 0,
                      right: constraints.minWidth,
                      key: e.node.key,
                      child: widget.itemBuilder(context, e.node,
                          selected: e.node == _visibleNodes[selectedNode!]),
                    );
                  }).toList(),
                );
              },
            ),
          );
        }
    );
  }

  List<_NodePositionWrapper<T>> calculatePositions(BoxConstraints constraints) {
    if (selectedNode == null) return [];
    double positionOfOriginalSelected = constraints.maxHeight / 2;
    if (selectedOffset != null) {
      positionOfOriginalSelected += selectedOffset!;
    }
    T selected = _visibleNodes[selectedNode!];
    Size? size = selected.size ?? Size(constraints.maxWidth, widget.fallbackSize);
    double halfHeight = size.height / 2;
    double top = positionOfOriginalSelected - halfHeight;
    double bottom = positionOfOriginalSelected + halfHeight;
    List<_NodePositionWrapper<T>> result = [_NodePositionWrapper(top: top, height: size.height, node: selected, covered: coveredCalc(top, constraints, bottom, size.height))];
    ({int resultPos, int visiblePos}) newSelectedNode = (resultPos: 0, visiblePos: selectedNode!);
    for (int selectedPos = 0; top > 0; selectedPos++) {
      T? node;
      visibleExtentUp = selectedNode! - selectedPos - 1;
      if (visibleExtentUp! < 0) {
        node = result.first.node.previous();
        if (node == null) break;
        _visibleNodes.insert(0, node);
        selectedNode = selectedNode! + 1;
        newSelectedNode = (resultPos: newSelectedNode.resultPos, visiblePos: newSelectedNode.visiblePos + 1);
        if (visibleExtentDown != null) {
          visibleExtentDown = visibleExtentDown! + 1;
        }
      } else {
        node = _visibleNodes[visibleExtentUp!];
      }
      size = node.size/* ?? Size(constraints.maxWidth, widget.fallbackSize)*/;
      var height = size?.height ?? widget.fallbackSize;
      result.insert(0, _NodePositionWrapper(
          top: size?.height != null ? top - height : null,
          bottom: size?.height == null ? constraints.maxHeight - top : null,
          height: height,
          node: node,
          covered: coveredCalc(top - height, constraints, top, height),
      ));
      top -= height;
      if (size == null) {
        break;
      }
      newSelectedNode = selectedNodeTracker._backNodePropagationUpdate(newSelectedNode, result, visibleExtentUp!);
    }
    for (int n = 1; bottom < constraints.maxHeight; n++) {
      T? node;
      visibleExtentDown = selectedNode! + n;
      if (visibleExtentDown! > _visibleNodes.length - 1) {
        node = result.last.node.next();
        if (node == null) break;
        _visibleNodes.add(node);
      } else {
        node = _visibleNodes[visibleExtentDown!];
      }
      size = node.size/* ?? Size(constraints.maxWidth, widget.fallbackSize)*/;
      var height = size?.height ?? widget.fallbackSize;
      result.add(_NodePositionWrapper(top: bottom, height: height, node: node, covered: coveredCalc(bottom, constraints, bottom + height, height)));
      bottom += height;
      if (size == null) {
        break;
      }
      newSelectedNode = selectedNodeTracker._forwardNodePropagationUpdate(newSelectedNode, result, visibleExtentDown!);
    }
    if (newSelectedNode.visiblePos != selectedNode!) {
      _changeSelectedNodeToAnotherOneInPositions(newSelectedNode.resultPos, newSelectedNode.visiblePos, result[newSelectedNode.resultPos], constraints);
    }
    balanceBuffers();
    return result;
  }

  _NodePositionWrapper<T>? get _selectedPosition {
    if (_positions == null) return _NodePositionWrapper(height: 0, node: _visibleNodes[selectedNode!]);
    return _positions?.where((e) => e.node == _visibleNodes[selectedNode!]).firstOrNull;
  }

  void _changeSelectedNodeToAnotherOneInPositions(int positionPos, int visiblePos, _NodePositionWrapper<T> node, BoxConstraints? constraints) {
    selectedNode = visiblePos;
    if (_positions == null) {
      return;
    }
    var cons = (constraints ?? _constraints);
    if (cons == null) {
      return;
    }
    setState(() {});
  }

  double coveredCalc(double top, BoxConstraints constraints, double bottom, double height) => min((0 - min(top, 0) - min(constraints.maxHeight - bottom, 0)) / height, 1);

  void _onScroll() {
    setState(() {
      selectedOffset = (selectedOffset ?? 0) - _scrollController.offset;
    });
    _scrollController.jumpTo(0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_constraints != null) {
        _positions = calculatePositions(_constraints!);
      }
    });
  }

  void balanceBuffers() {
    if (visibleExtentUp != null) {
      int change = 0;
      if (visibleExtentUp! > widget.maxBuffer) {
        var removeCount = visibleExtentUp! - widget.maxBuffer;
        change -= removeCount;
        var removed = _visibleNodes.sublist(0, removeCount);
        _visibleNodes.removeRange(0, removeCount);
        for (NodeBase node in removed) {
          node.dispose();
        }
      }
      while (visibleExtentUp! + change < widget.minBuffer) {
        T? node = _visibleNodes.first.previous();
        if (node == null) break;
        _visibleNodes.insert(0, node);
        change++;
      }
      if (change != 0) {
        if (selectedNode != null) {
          selectedNode = selectedNode! + change;
        }
        visibleExtentUp = visibleExtentUp! + change;
        if (visibleExtentDown != null) {
          visibleExtentDown = visibleExtentDown! + change;
        }
      }
    }
    if (selectedNode != null && visibleExtentDown != null) {
      while (_visibleNodes.length - visibleExtentDown! > widget.maxBuffer) {
        NodeBase node = _visibleNodes.removeLast();
        node.dispose();
      }
      while (_visibleNodes.length - visibleExtentDown! < widget.minBuffer) {
        T? node = _visibleNodes.last.next();
        if (node == null) break;
        _visibleNodes.add(node);
      }
    }
  }

  ({ int? positionPos, _NodePositionWrapper<T>? positionWrapper, int visiblePos })? findNode(T node) {
    int? visPos = _visibleNodes.indexOf(node);
    if (visPos == -1) return null;
    int? posPos = _positions?.indexWhere((e) => e.node == node);
    if (posPos == -1 || posPos == null) {
      return (visiblePos: visPos, positionWrapper: null, positionPos: null);
    }
    _NodePositionWrapper<T>? position = _positions![posPos];
    return ( positionPos: posPos, positionWrapper: position, visiblePos: visPos );
  }

  void _resetSelectedNodeToNewNode(T node, {double? offset}) {
    _visibleNodes = [node];
    selectedNode = 0;
    setState(() {
      selectedOffset = offset;
      _positions = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_constraints != null) {
        _positions = calculatePositions(_constraints!);
        setState(() {});
      }
    });
  }

  void _changeSelectedNodeToAnotherOneNotInPositionsButVisible(int visiblePos, BoxConstraints? constraints, {double? offset, bool makeVisible = false}) {
    selectedNode = visiblePos;
    if (constraints == null) return;
    setState(() {
      if (offset != null) {
        selectedOffset = offset;
      } else if (makeVisible && _selectedNode?.size != null) {
        if (selectedNode! < visiblePos) {
          selectedOffset = constraints.maxHeight / 2 - _visibleNodes[selectedNode!].size!.height / 2;
        } else {
          selectedOffset = constraints.maxHeight / -2 + _visibleNodes[selectedNode!].size!.height / 2;
        }
      } else {
        selectedOffset = null;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_constraints != null) {
        _positions = calculatePositions(_constraints!);
        setState(() {});
      }
    });
  }
}

class _NodePositionWrapper<T> {
  double? covered;
  double height;
  T node;
  double? top;
  double? bottom;

  _NodePositionWrapper({this.covered,required this.height, required this.node, this.top, this.bottom});
}

abstract class SelectedNodeTracker {
  ({int resultPos, int visiblePos}) _backNodePropagationUpdate(({int resultPos, int visiblePos}) newSelectedNode, List<_NodePositionWrapper> result, int visibleExtentUp);
  ({int resultPos, int visiblePos}) _forwardNodePropagationUpdate(({int resultPos, int visiblePos}) newSelectedNode, List<_NodePositionWrapper> result, int visibleExtentDown);
}

class StickySelectedNodeTracker extends SelectedNodeTracker {
  StickySelectedNodeTracker();

  @override
  ({int resultPos, int visiblePos}) _backNodePropagationUpdate(({int resultPos, int visiblePos}) newSelectedNode, List<_NodePositionWrapper> result, int visibleExtentUp) {
    if (newSelectedNode.resultPos == 0 && (result[1].covered! > result[0].covered! || result[1].covered! == 1)) {
      newSelectedNode = (resultPos: 0, visiblePos: visibleExtentUp);
    } else {
      newSelectedNode = (
      resultPos: newSelectedNode.resultPos + 1,
      visiblePos: newSelectedNode.visiblePos
      );
    }
    return newSelectedNode;
  }

  @override
  ({int resultPos, int visiblePos}) _forwardNodePropagationUpdate(({int resultPos, int visiblePos}) newSelectedNode, List<_NodePositionWrapper> result, int visibleExtentDown) {
    if (newSelectedNode.resultPos == result.length - 2 && (result[result.length - 2].covered! > result[result.length - 1].covered! || result[result.length - 2].covered! == 1)) {
      newSelectedNode = (resultPos: result.length - 1, visiblePos: visibleExtentDown);
    }
    return newSelectedNode;
  }
}