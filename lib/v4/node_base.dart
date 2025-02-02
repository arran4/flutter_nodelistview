import 'package:flutter/material.dart';

abstract class NodeBase {
  Key get key;

  ValueNotifier<NodeBase?> previous();
  ValueNotifier<NodeBase?> next();

  void dispose() {}

  Size size();
}
