import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:untitled6/v1/node_base.dart';

abstract class HasData {
  String get data;
}

class ExamplePrefilledNode extends NodeBase implements HasData {
  final String data;
  ValueNotifier<NodeBase?> _previous;
  ValueNotifier<NodeBase?> _next;

  ExamplePrefilledNode(this.data) : _previous = ValueNotifier(null), _next = ValueNotifier(null);

  @override
  ValueNotifier<NodeBase?> previous() => _previous;

  @override
  ValueNotifier<NodeBase?> next() => _next;

  void setPrevious(NodeBase? node) {
    _previous.value = node;
  }

  void setNext(NodeBase? node) {
    _next.value = node;
  }
}

class ExampleInfiniteNode extends NodeBase implements HasData {
  final String data;
  ValueNotifier<NodeBase?> _previous;
  ValueNotifier<NodeBase?> _next;

  ExampleInfiniteNode(this.data) : _previous = ValueNotifier(null), _next = ValueNotifier(null);

  @override
  ValueNotifier<NodeBase?> previous() {
    RegExp exp = RegExp(r'Node (-?\d+)');
    if (_previous.value != null) {
      return _previous;
    } else if (exp.hasMatch(data)) {
      final match = exp.firstMatch(data);
      final number = int.parse(match!.group(1)!);
      _previous.value ??= ExampleInfiniteNode('Node ${number - 1}');
    } else {
      _previous.value ??= ExampleInfiniteNode('Node ${Random().nextInt(1000000)}');
    }
    return _previous;
  }

  @override
  ValueNotifier<NodeBase?> next() {
    RegExp exp = RegExp(r'Node (-?\d+)');
    if (_next.value != null) {
      return _next;
    } else if (exp.hasMatch(data)) {
      final match = exp.firstMatch(data);
      final number = int.parse(match!.group(1)!);
      _next.value ??= ExampleInfiniteNode('Node ${number + 1}');
    } else {
      _next.value ??= ExampleInfiniteNode('Node ${Random().nextInt(1000000)}');
    }
    return _next;
  }

  void setPrevious(NodeBase? node) {
    _previous.value = node;
  }

  void setNext(NodeBase? node) {
    _next.value = node;
  }
}
