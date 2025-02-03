import 'package:flutter/material.dart';

abstract class NodeBase {
  GlobalKey get key;

  NodeBase? previous();
  NodeBase? next();

  void dispose() {}

  Size get size;
  set size(Size value);
}
