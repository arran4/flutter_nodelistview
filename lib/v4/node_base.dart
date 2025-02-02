import 'package:flutter/material.dart';

abstract class NodeBase {
  Key get key;

  NodeBase? previous();
  NodeBase? next();

  void dispose() {}

  Size size();
}
