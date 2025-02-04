import 'dart:math';

import 'package:flutter/widgets.dart';
import './node_base.dart';

class ExampleInfiniteNode extends NodeBase<ExampleInfiniteNode> {
  ExampleInfiniteNode({
    required this.x,
    required this.y,
    ExampleInfiniteNode? left,
    ExampleInfiniteNode? right,
    ExampleInfiniteNode? next,
    ExampleInfiniteNode? previous,
  }) :
        name = Random().nextInt(1000).toString(),
        _left = left,
        _right = right,
        _next = next,
        _previous = previous,
        super(GlobalKey());
  final int x;
  final int y;
  final String name;

  ExampleInfiniteNode? _previous;

  @override
  ExampleInfiniteNode? previous() {
    _previous ??= ExampleInfiniteNode(x: x, y: y - 1, next: this);
    return _previous;
  }

  ExampleInfiniteNode? _next;

  @override
  ExampleInfiniteNode? next() {
    _next ??= ExampleInfiniteNode(x: x, y: y + 1, previous: this);
    return _next;
  }

  ExampleInfiniteNode? _left;

  ExampleInfiniteNode left() {
    _left ??= ExampleInfiniteNode(x: x - 1, y: y, right: this);
    return _left!;
  }

  ExampleInfiniteNode? _right;

  get label => 'Node $x,$y ($name)';

  ExampleInfiniteNode right() {
    _right ??= ExampleInfiniteNode(x: x + 1, y: y, left: this);
    return _right!;
  }

  void delete() {
    _previous?._next = null;
    _previous = null;
    _next?._previous = null;
    _next = null;
    _left?._right = null;
    _left = null;
    _right?._left = null;
    _right = null;
  }
}

