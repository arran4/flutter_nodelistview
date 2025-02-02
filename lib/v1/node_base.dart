import 'package:flutter/material.dart';

abstract class NodeBase {
  ValueNotifier<NodeBase?> previous();
  ValueNotifier<NodeBase?> next();

  void dispose() {}
}
