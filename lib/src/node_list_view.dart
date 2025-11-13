import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'node_base.dart';

typedef NodeWidgetBuilder<T extends NodeBase> = Widget Function(BuildContext context, T node, { bool selected });

enum ScrollModes {
  none,
  reset,
  setOffset, fitNode,
}

class NodeListViewController<T extends NodeBase> {
  NodeListViewState<T>? _nodeListViewState;

  NodeListViewController();

  void attach(NodeListViewState<T> nodeListViewState) {
    _nodeListViewState = nodeListViewState;
  }

  void detach() {
    _nodeListViewState = null;
  }

  void jumpTo(T node, {ScrollModes scrollMode = ScrollModes.none}) {
    if (_nodeListViewState == null) return;
    ({ int? positionPos, NodePositionWrapper<
        T>? positionWrapper, int visiblePos })? index = _nodeListViewState!
        .findNode(node);
    if (index?.positionPos != null && index?.positionWrapper != null) {
      _nodeListViewState!._changeSelectedNodeToAnotherOneInPositions(
          index!.positionPos!, index.visiblePos, index.positionWrapper!, null);
      return;
    }
    if (index?.visiblePos != null) {
      _nodeListViewState!
          ._changeSelectedNodeToAnotherOneNotInPositionsButVisible(
          index!.visiblePos, null, scrollMode: ScrollModes.none);
      return;
    }
    _nodeListViewState!._resetSelectedNodeToNewNode(node);
  }

  void selectNext({ScrollModes scrollMode = ScrollModes.none}) {
    if (_nodeListViewState == null) return;
    if (_nodeListViewState!._selectedNode == null) return;
    T? next = _nodeListViewState!._selectedNode?.next();
    if (next == null) return;
    jumpTo(next, scrollMode: scrollMode);
  }

  void selectPrevious({ScrollModes scrollMode = ScrollModes.none}) {
    if (_nodeListViewState == null) return;
    if (_nodeListViewState!._selectedNode == null) return;
    T? next = _nodeListViewState!._selectedNode?.previous();
    if (next == null) return;
    jumpTo(next, scrollMode: scrollMode);
  }

  void selectFirstVisible({ScrollModes scrollMode = ScrollModes.reset}) {
    if (_nodeListViewState == null) return;
    T? next = _nodeListViewState!._positions?.firstOrNull?.node;
    if (next == null) return;
    jumpTo(next, scrollMode: scrollMode);
  }

  void selectLastVisible({ScrollModes scrollMode = ScrollModes.reset}) {
    if (_nodeListViewState == null) return;
    T? next = _nodeListViewState!._positions?.lastOrNull?.node;
    if (next == null) return;
    jumpTo(next, scrollMode: scrollMode);
  }

  void refreshNodePointers(T node,
      { bool verifyNext = true, bool verifyPrevious = true }) {
    if (_nodeListViewState == null) return;
    _nodeListViewState!._refreshNodePointers(
        node, verifyNext: verifyNext, verifyPrevious: verifyPrevious);
    _nodeListViewState!.scheduleUpdate(immediate: true);
  }

  void refreshAllNodePointers() {
    if (_nodeListViewState?._selectedNode == null) return;
    _nodeListViewState!._refreshNodePointers(
        _nodeListViewState!._selectedNode!, recurse: true);
    _nodeListViewState!.scheduleUpdate(immediate: true);
  }

  Function? _addListener<L>(List<L> listeners, L listener) {
    if (_nodeListViewState == null) return null;
    listeners.add(listener);
    return () => listeners.remove(listener);
  }

  void _notifyListeners<L>(List<L> listeners, Object a, Object b) {
    if (_nodeListViewState == null) return;
    for (var listener in List.of(listeners)) {
      Function.apply(listener as Function, [a, b]);
    }
  }

  final _onSelectedNodeChanged = <Function(T, Position)>[];
  Function? addOnSelectedNodeChangedListener(Function(T, Position) listener) =>
      _addListener(_onSelectedNodeChanged, listener);
  void _notifyOnSelectedNodeChangedListeners(T node, Position pos) =>
      _notifyListeners(_onSelectedNodeChanged, node, pos);

  final _onBufferLoadedNodeChanged = <Function(List<T>, Location)>[];
  Function? addOnBufferLoadedNodeChangedListener(Function(List<T>, Location) listener) =>
      _addListener(_onBufferLoadedNodeChanged, listener);
  void _notifyOnBufferLoadedNodeChangedListeners(List<T> nodes, Location location) =>
      _notifyListeners(_onBufferLoadedNodeChanged, nodes, location);

  final _onBufferUnloadedNodeChanged = <Function(List<T>, Location)>[];
  Function? addOnBufferUnloadedNodeChangedListener(Function(List<T>, Location) listener) =>
      _addListener(_onBufferUnloadedNodeChanged, listener);
  void _notifyOnBufferUnloadedNodeChangedListeners(List<T> nodes, Location location) =>
      _notifyListeners(_onBufferUnloadedNodeChanged, nodes, location);

  final _onNodeVisibilityChange = <Function(T, NodeVisibility)>[];
  Function? addOnNodeVisibilityChangeListener(Function(T, NodeVisibility) listener) =>
      _addListener(_onNodeVisibilityChange, listener);
  void _notifyOnNodeVisibilityChangeListeners(T node, NodeVisibility visibility) =>
      _notifyListeners(_onNodeVisibilityChange, node, visibility);

}

class NodeVisibility {
  final bool visible;
  final double coverage;

  NodeVisibility(this.visible, this.coverage);
}

enum Location {
  head,
  tail
}

class Position {
  final int position;
  final double offset;

  Position(this.position, this.offset);
}

class NodeListView<T extends NodeBase> extends StatefulWidget {
  final T? startNode;
  final NodeWidgetBuilder<T> itemBuilder;
  final int minBuffer;
  final int maxBuffer;
  final double fallbackSize;
  final SelectedNodeTracker? selectedNodeTracker;
  final NodeListViewController<T>? controller;
  final WidgetBuilder? loadingBuilder;

  const NodeListView({
    super.key,
    required this.startNode,
    required this.itemBuilder,
    this.loadingBuilder,
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
  List<NodePositionWrapper<T>>? _positions;
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
          if (_constraints == null || _constraints != constraints) {
            _constraints = constraints;
            scheduleUpdate();
          }
          return Scrollbar(
            controller: _scrollController,
            interactive: true,
            thickness: 16.0,
            thumbVisibility: true,
            trackVisibility: true,
            child: Scrollable(
              scrollBehavior: ScrollBehavior(),
              controller: _scrollController,
              viewportBuilder: (context, position) {
                if (_positions == null) {
                  if (widget.loadingBuilder != null) {
                    return widget.loadingBuilder!(context);
                  } else {
                    return Center(
                      child: Text("Loading..."),
                    );
                  }
                }
                position.applyViewportDimension(constraints.maxHeight);
                double minScrollExtent = 0;
                double maxScrollExtent = 0;
                if (_positions!.first.node.previous() == null) {
                  minScrollExtent = _positions!.first.top!;
                } else {
                  minScrollExtent = double.negativeInfinity;
                }
                if (_positions!.last.node.next() == null) {
                  maxScrollExtent = _positions!.last.bottom!;
                } else {
                  maxScrollExtent = double.infinity;
                }
                position.applyContentDimensions(minScrollExtent, maxScrollExtent);
                if (_positions!.where((e) => e.covered! > 0).isNotEmpty) {
                  return Stack(
                    fit: StackFit.expand,
                    children: (_positions ?? []).map((e) {
                      return Positioned(
                        top: e.top,
                        bottom: e.bottom,
                        left: 0,
                        key: e.node.key,
                        right: constraints.minWidth,
                        child: NodeSizeChangedMonitor(
                          node: e.node,
                          updated: () {
                            scheduleUpdate();
                          },
                          child: widget.itemBuilder(context, e.node,
                              selected: e.node == _visibleNodes[selectedNode!]), // Ensure it doesn't get reused incorrectly
                        ),
                      );
                    }).toList(),
                  );
                } else {
                  if (widget.loadingBuilder != null) {
                    return widget.loadingBuilder!(context);
                  } else {
                    return Center(
                      child: Text("Loading..."),
                    );
                  }
                }
              },
            ),
          );
        }
    );
  }

  List<NodePositionWrapper<T>> calculatePositions(BoxConstraints constraints) {
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
    List<NodePositionWrapper<T>> result = [NodePositionWrapper(top: top, height: size.height, node: selected, covered: coveredCalc(top, constraints, bottom, size.height))];
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
      result.insert(0, NodePositionWrapper(
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
      result.add(NodePositionWrapper(top: bottom, height: height, node: node, covered: coveredCalc(bottom, constraints, bottom + height, height)));
      bottom += height;
      if (size == null) {
        break;
      }
      newSelectedNode = selectedNodeTracker._forwardNodePropagationUpdate(newSelectedNode, result, visibleExtentDown!);
    }
    if (newSelectedNode.visiblePos != selectedNode!) {
      _changeSelectedNodeToAnotherOneInPositions(newSelectedNode.resultPos, newSelectedNode.visiblePos, result[newSelectedNode.resultPos], constraints, scrollMode: ScrollModes.fitNode);
    }
    balanceBuffers();
    return result;
  }

  NodePositionWrapper<T>? get _selectedPosition {
    if (_positions == null) return NodePositionWrapper(height: 0, node: _visibleNodes[selectedNode!]);
    return _positions?.where((e) => e.node == _visibleNodes[selectedNode!]).firstOrNull;
  }

  void _changeSelectedNodeToAnotherOneInPositions(int positionPos, int visiblePos, NodePositionWrapper<T> node, BoxConstraints? constraints, {ScrollModes scrollMode = ScrollModes.none, double? offset}) {
    selectedNode = visiblePos;
    if (_positions == null) {
      return;
    }
    var cons = (constraints ?? _constraints);
    if (cons == null) {
      return;
    }
    setState(() {
      switch (scrollMode) {
        case ScrollModes.setOffset:
          selectedOffset = offset;
          break;
        case ScrollModes.none:
          break;
        case ScrollModes.fitNode:
          if (node.top != null) {
            selectedOffset = (node.top! + node.height / 2) - cons.maxHeight / 2;
          } else if (node.bottom != null) {
            selectedOffset = cons.maxHeight / 2 - (node.bottom! - node.height / 2);
          }
          break;
        case ScrollModes.reset:
          selectedOffset = null;
          break;
      }
    });
  }

  double coveredCalc(double top, BoxConstraints constraints, double bottom, double height) => min((0 - min(top, 0) - min(constraints.maxHeight - bottom, 0)) / height, 1);

  void _onScroll() {
    setState(() {
      selectedOffset = (selectedOffset ?? 0) - _scrollController.offset;
    });
    _scrollController.jumpTo(0);
    scheduleUpdate();
  }

  List<NodePositionWrapper<T>>? _previousPositions;
  bool _updateScheduled = false;

  void scheduleUpdate({ immediate = false }) {
    if (_updateScheduled) return;
    _updateScheduled = true;
    if (immediate) {
      _updateScheduled = false;
      updatePositions(immediate: true);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScheduled = false;
      if (!mounted) return;
      updatePositions();
      setState(() {});
    });
  }

  void updatePositions({ bool immediate = false }) {
    if (_constraints != null) {
      if (_positions == null) {
        setState(() {});
      }
      _positions = calculatePositions(_constraints!);
      if (immediate) {
        setState(() {});
      }
      if (_previousPositions != null && _controller?._onNodeVisibilityChange.isNotEmpty == true) {
          Map<T, NodePositionWrapper<T>> w = { for (var e in _previousPositions??[]) e.node : e };
          for (NodePositionWrapper<T> newNode in _positions??[]) {
            if (w.containsKey(newNode.node)) {
              var visibility = newNode.visibilityIfChanged(w[newNode.node]!);
              if (visibility != null) {
                _controller?._notifyOnNodeVisibilityChangeListeners(newNode.node, visibility);
              }
              w.remove(newNode.node);
            }
          }
          for (var node in w.keys) {
            _controller?._notifyOnNodeVisibilityChangeListeners(node, NodeVisibility(false, 0));
          }
        }
        _previousPositions = _positions;
      }
    });
  }

  // TODO make the buffer balancer it's own class
  void balanceBuffers() {
    if (visibleExtentUp != null) {
      int change = 0;
      if (visibleExtentUp! > widget.maxBuffer) {
        var removeCount = visibleExtentUp! - widget.maxBuffer;
        change -= removeCount;
        var removed = _visibleNodes.sublist(0, removeCount);
        _visibleNodes.removeRange(0, removeCount);
        if (removed.isNotEmpty) {
          _controller?._notifyOnBufferUnloadedNodeChangedListeners(
              removed, Location.head);
        }
        for (NodeBase node in removed) {
          node.dispose();
        }
      }
      var added = <T>[];
      while (visibleExtentUp! + change < widget.minBuffer) {
        T? node = _visibleNodes.first.previous();
        if (node == null) break;
        _visibleNodes.insert(0, node);
        added.add(node);
        change++;
      }
      if (added.isNotEmpty) {
        _controller?._notifyOnBufferLoadedNodeChangedListeners(
            added, Location.head);
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

  ({ int? positionPos, NodePositionWrapper<T>? positionWrapper, int visiblePos })? findNode(T node) {
    int? visPos = _visibleNodes.indexOf(node);
    if (visPos == -1) return null;
    int? posPos = _positions?.indexWhere((e) => e.node == node);
    if (posPos == -1 || posPos == null) {
      return (visiblePos: visPos, positionWrapper: null, positionPos: null);
    }
    NodePositionWrapper<T>? position = _positions![posPos];
    return ( positionPos: posPos, positionWrapper: position, visiblePos: visPos );
  }

  void _resetSelectedNodeToNewNode(T node, {double? offset, ScrollModes scrollMode = ScrollModes.none}) {
    _visibleNodes = [node];
    selectedNode = 0;
    setState(() {
      switch (scrollMode) {
        case ScrollModes.setOffset:
          selectedOffset = offset;
          break;
        case ScrollModes.fitNode:
          break;
        case ScrollModes.none:
          break;
        case ScrollModes.reset:
          selectedOffset = null;
          break;
      }
      _positions = null;
    });
    scheduleUpdate();
  }

  void _changeSelectedNodeToAnotherOneNotInPositionsButVisible(int visiblePos, BoxConstraints? constraints, {double? offset, ScrollModes scrollMode = ScrollModes.none}) {
    selectedNode = visiblePos;
    var cons = (constraints ?? _constraints);
    if (cons == null) return;
    setState(() {
      switch (scrollMode) {
        case ScrollModes.setOffset:
          selectedOffset = offset;
          break;
        case ScrollModes.fitNode:
          // TODO this might have been forgotten
          // if (node.top != null) {
          //   selectedOffset = (node.top! + node.height / 2) - cons.maxHeight / 2;
          // } else if (node.bottom != null) {
          //   selectedOffset = cons.maxHeight / 2 - (node.bottom! - node.height / 2);
          // }
          break;
        case ScrollModes.none:
          break;
        case ScrollModes.reset:
          selectedOffset = null;
          break;
      }
    });
    scheduleUpdate();
  }

  void _refreshNodePointers(T node, { bool verifyNext = true, bool verifyPrevious = true, bool recurse = false }) {
    var visibleNodeIndex = _visibleNodes.indexWhere((e) => e == node);
    if (visibleNodeIndex == -1) return;
    if (verifyNext) {
      var visibleNext = (_visibleNodes.length ?? 0) > visibleNodeIndex + 1
          ? _visibleNodes[visibleNodeIndex + 1]
          : null;
      var nodeNext = node.next();
      if (visibleNext != null && nodeNext != visibleNext) {
        _visibleNodes.removeRange(visibleNodeIndex + 1, _visibleNodes.length);
        var index = _positions?.indexWhere((e) => e.node == visibleNext);
        if (index != null && index != -1) {
          _positions?.removeRange(index + 1, _positions!.length);
          visibleExtentDown = min(visibleExtentDown!, index);
        }
      } else if (recurse) {
        _refreshNodePointers(nodeNext!, verifyNext: true, verifyPrevious: false, recurse: true);
      }
    }
    if (verifyPrevious) {
      var visiblePrevious = visibleNodeIndex > 0 ? _visibleNodes[visibleNodeIndex-1] : null;
      var nodePrevious = node.previous();
      if (visiblePrevious != null && nodePrevious != visiblePrevious) {
        _visibleNodes.removeRange(0, visibleNodeIndex);
        var index = _positions?.indexWhere((e) => e.node == visiblePrevious);
        if (index != null && index != -1) {
          _positions?.removeRange(0, index);
        }
        visibleExtentUp = visibleExtentUp! - visibleNodeIndex;
        selectedNode = selectedNode! - visibleNodeIndex;
      } else if (recurse) {
        _refreshNodePointers(nodePrevious!, verifyNext: false, verifyPrevious: true, recurse: true);
      }
    }
  }
}

class NodePositionWrapper<T extends NodeBase> {
  double? covered;
  double height;
  T node;
  double? top;
  double? bottom;

  NodePositionWrapper({this.covered,required this.height, required this.node, this.top, this.bottom});

  NodeVisibility? visibilityIfChanged(NodePositionWrapper<T> other) {
    if (other.node!= node) return null;
    if (other.covered == covered) return null;
    return NodeVisibility(covered! > 0, covered!);
  }
}

abstract class SelectedNodeTracker {
  ({int resultPos, int visiblePos}) _backNodePropagationUpdate(({int resultPos, int visiblePos}) newSelectedNode, List<NodePositionWrapper> result, int visibleExtentUp);
  ({int resultPos, int visiblePos}) _forwardNodePropagationUpdate(({int resultPos, int visiblePos}) newSelectedNode, List<NodePositionWrapper> result, int visibleExtentDown);
}

class StickySelectedNodeTracker extends SelectedNodeTracker {
  StickySelectedNodeTracker();

  @override
  ({int resultPos, int visiblePos}) _backNodePropagationUpdate(({int resultPos, int visiblePos}) newSelectedNode, List<NodePositionWrapper> result, int visibleExtentUp) {
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
  ({int resultPos, int visiblePos}) _forwardNodePropagationUpdate(({int resultPos, int visiblePos}) newSelectedNode, List<NodePositionWrapper> result, int visibleExtentDown) {
    if (newSelectedNode.resultPos == result.length - 2 && (result[result.length - 2].covered! > result[result.length - 1].covered! || result[result.length - 2].covered! == 1)) {
      newSelectedNode = (resultPos: result.length - 1, visiblePos: visibleExtentDown);
    }
    return newSelectedNode;
  }
}

class NodeSizeChangedMonitor<T extends NodeBase> extends SingleChildRenderObjectWidget {
  final T node;
  final Function updated;

  const NodeSizeChangedMonitor({
    required this.node,
    required this.updated,
    super.key,
    super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSizeChangedWithCallback(
      onLayoutChangedCallback: (size) {
        if (size != node.size) {
          node.size = size;
          updated();
        }
      },
    );
  }
}

class _RenderSizeChangedWithCallback extends RenderProxyBox {
  _RenderSizeChangedWithCallback({
    RenderBox? child,
    required this.onLayoutChangedCallback,
  }) : super(child);

  final Function(Size? size) onLayoutChangedCallback;

  Size? _oldSize;

  @override
  void performLayout() {
    super.performLayout();
    if (size != _oldSize) {
      onLayoutChangedCallback(size);
    }
    _oldSize = size;
  }
}
