import 'dart:math';

import 'package:flutter/widgets.dart';
import './node_base.dart';

abstract class HasData {
  String get data;
}

class ExampleInfiniteNode extends NodeBase implements HasData {
  @override
  final String data;

  ExampleInfiniteNode(this.data) : super(GlobalKey());

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
}

