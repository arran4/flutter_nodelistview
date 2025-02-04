import 'dart:math';

import 'package:flutter/widgets.dart';
import './node_base.dart';

class ExampleInfiniteNode extends NodeBase<ExampleInfiniteNode> {
  ExampleInfiniteNode({required this.x, required this.y}) : super(GlobalKey());
  final int x;
  final int y;

  ExampleInfiniteNode? _previous;

  @override
  ExampleInfiniteNode? previous() {
    _previous ??= ExampleInfiniteNode(x: x, y: y - 1);
    return _previous;
  }

  ExampleInfiniteNode? _next;

  @override
  ExampleInfiniteNode? next() {
    _next ??= ExampleInfiniteNode(x: x, y: y + 1);
    return _next;
  }

  ExampleInfiniteNode? _left;

  ExampleInfiniteNode left() {
    _left ??= ExampleInfiniteNode(x: x - 1, y: y);
    return _left!;
  }

  ExampleInfiniteNode? _right;

  get label => 'Node $x,$y';

  ExampleInfiniteNode right() {
    _right ??= ExampleInfiniteNode(x: x + 1, y: y);
    return _right!;
  }
}

