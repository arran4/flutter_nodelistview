import 'package:flutter/material.dart';

abstract class NodeBase<T> {
  NodeBase(this.key, { this.size});

  GlobalKey<State<StatefulWidget>> key;
  Size? size;

  T? previous();
  T? next();

  void dispose() {}
}
