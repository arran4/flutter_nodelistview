import 'dart:math';

import 'package:flutter/widgets.dart';
import './node_base.dart';

abstract class HasData {
  String get data;
}

class ExampleInfiniteNode extends NodeBase implements HasData {
  final String data;
  Size? _size;
  Size? initialSize;

  GlobalKey<State<StatefulWidget>> _key;

  ExampleInfiniteNode(this.data, { this.initialSize }) : _key = GlobalKey(debugLabel: data);

  @override
  NodeBase? previous() {
    RegExp exp = RegExp(r'Node (-?\d+)');
    if (exp.hasMatch(data)) {
      final match = exp.firstMatch(data);
      final number = int.parse(match!.group(1)!);
      return ExampleInfiniteNode('Node ${number - 1}');
    }
    return null;
  }

  @override
  NodeBase? next() {
    RegExp exp = RegExp(r'Node (-?\d+)');
    if (exp.hasMatch(data)) {
      final match = exp.firstMatch(data);
      final number = int.parse(match!.group(1)!);
      return ExampleInfiniteNode('Node ${number + 1}');
    }
    return null;
  }

  @override
  Size get size {
    return _size ?? initialSize ?? Size(200, 100);
  }

  @override
  set size(Size value) {
    if (_size != null && _size == value) {
      return;
    }
    _size = value;
  }

  @override
  get key => _key;
}

