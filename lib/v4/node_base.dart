import 'package:flutter/material.dart';

abstract class NodeBase {
  NodeBase(this.key, { this.size});

  GlobalKey<State<StatefulWidget>> key;
  Size? size;

  NodeBase? previous();
  NodeBase? next();

  void dispose() {}
}
