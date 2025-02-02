import 'dart:math';

import 'package:flutter/material.dart';
import 'package:untitled6/v1/node_base.dart';

typedef NodeWidgetBuilder = Widget Function(BuildContext context, NodeBase node);

class NodeContainer {
  final NodeBase node;
  final ValueNotifier<Size> _size;
  final GlobalKey key = GlobalKey();
  Widget? get widget => key.currentContext?.widget;

  NodeContainer(this.node, {Size defaultSize = const Size(100, 100) }) : _size = ValueNotifier(defaultSize);

  ValueNotifier<Size> get size {
    if (widget != null) {
      final RenderBox? renderBox = key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) _size.value = renderBox.size;
    }
    return _size;
  }

  @override
  ValueNotifier<NodeBase?> previous() => node.previous();
  @override
  ValueNotifier<NodeBase?> next() => node.next();

  @override
  void dispose() {
    _size.dispose();
    node.dispose();
  }
}

class NodeListView extends StatefulWidget {
  final NodeBase? currentNode;
  final NodeWidgetBuilder itemBuilder;
  final int buffer; // Number of nodes to load as buffer on each side
  final double fallbackSize; // Default size for nodes

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
  final ScrollController _scrollController = ScrollController();
  late List<NodeContainer> _visibleNodes;
  int? selectedNode;

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
    _visibleNodes.add(NodeContainer(widget.currentNode!, defaultSize: Size(widget.fallbackSize, widget.fallbackSize)));
    selectedNode = 0;

    while (_visibleNodes.length < widget.buffer + 1) {
      final prevNotifier = _visibleNodes.firstOrNull?.previous();
      if (prevNotifier?.value != null) {
        _visibleNodes.insert(0, NodeContainer(prevNotifier!.value!, defaultSize: Size(widget.fallbackSize, widget.fallbackSize)));
        selectedNode = selectedNode! + 1;
      } else {
        break;
      }
    }

    while (_visibleNodes.length < widget.buffer*2 + 1) {
      final nextNotifier = _visibleNodes.lastOrNull?.next();
      if (nextNotifier?.value != null) {
        _visibleNodes.add(NodeContainer(nextNotifier!.value!, defaultSize: Size(widget.fallbackSize, widget.fallbackSize)));
      } else {
        break;
      }
    }
  }

  void _onScroll() {
    // if (!_scrollController.hasClients) return;
    //
    // final position = _scrollController.position;
    // final viewportHeight = position.viewportDimension;
    // final scrollOffset = position.pixels;
    //
    // // Calculate the index of the first visible node
    // int firstVisibleIndex = (scrollOffset / widget.itemExtent).floor();
    //
    // // Calculate the total number of nodes currently loaded
    // int totalLoaded = _visibleNodes.length;
    //
    // // Determine if we need to load more nodes at the top
    // if (firstVisibleIndex < widget.buffer) {
    //   _loadMorePrevious(firstVisibleIndex);
    // }
    //
    // // Determine if we need to load more nodes at the bottom
    // int lastVisibleIndex = firstVisibleIndex + (viewportHeight / widget.itemExtent).ceil();
    // if (lastVisibleIndex > totalLoaded - widget.buffer) {
    //   _loadMoreNext(lastVisibleIndex);
    // }
    //
    // _pruneExcess(firstVisibleIndex, lastVisibleIndex);
  }

  void _loadMorePrevious(int fromIndex) {
    for (int i = fromIndex; i < fromIndex + widget.buffer; i++) {
      final prevNotifier = _visibleNodes.firstOrNull?.previous();
      if (prevNotifier != null && prevNotifier.value != null) {
        _visibleNodes.insert(0, NodeContainer(prevNotifier.value!, defaultSize: Size(widget.fallbackSize, widget.fallbackSize)));
        selectedNode = selectedNode! + 1;
      } else {
        break;
      }
    }

    setState(() {});
  }

  void _loadMoreNext(int fromIndex) {
    for (int i = fromIndex; i < fromIndex + widget.buffer; i++) {
      final nextNotifier = _visibleNodes.lastOrNull?.next();
      if (nextNotifier != null && nextNotifier.value != null) {
        _visibleNodes.add(NodeContainer(nextNotifier.value!, defaultSize: Size(widget.fallbackSize, widget.fallbackSize)));
      } else {
        break;
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    print("_visibleNodes count: ${_visibleNodes.length}");
    return LayoutBuilder(
        builder: (context, constraints) {
          if (selectedNode == null) {
            return Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          double offset = 0;
          var height = constraints.maxHeight;
          return Scrollbar(
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: SizedBox(
                child: Stack(
                  children: _visibleNodes.sublist(selectedNode!).map((node) {
                    var child = widget.itemBuilder(context, node.node);
                    var renderObject = node.key.currentContext?.findRenderObject();
                    if (renderObject != null && renderObject is RenderBox) {
                      renderObject.layout(constraints, parentUsesSize: true);
                      if (renderObject.hasSize) {
                        node.size.value = renderObject.size;
                      }
                    }
                    var childWidget = Positioned(
                      top: offset,
                      left: 0,
                      right: 0,
                      key: node.key,
                      height: node.size.value.height,
                      child: child,
                    );
                    offset += node.size.value.height;
                    return childWidget;
                  }).toList(),
                ),
              ),
            ),
          );
        }
    );
  }

  void _pruneExcess(int firstVisibleIndex, int lastVisibleIndex) {
    // Prune nodes that are no longer visible
    _visibleNodes.removeWhere((node) {
      final index = _visibleNodes.indexOf(node);
      if (index < firstVisibleIndex - widget.buffer || index > lastVisibleIndex + widget.buffer) {
        node.dispose();
        if (index < selectedNode!) selectedNode = selectedNode! - 1;
        return true;
      }
      return false;
    });
  }
}
