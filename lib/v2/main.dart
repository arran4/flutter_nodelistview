import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const InfiniteScrollApp());
}

class InfiniteScrollApp extends StatelessWidget {
  const InfiniteScrollApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Infinite Scroll Area'),
        ),
        body: const InfiniteScrollView(),
      ),
    );
  }
}

class InfiniteScrollView extends StatefulWidget {
  const InfiniteScrollView({Key? key}) : super(key: key);

  @override
  State<InfiniteScrollView> createState() => _InfiniteScrollViewState();
}

class _InfiniteScrollViewState extends State<InfiniteScrollView> {
  late ScrollController _scrollController;

  // Define an arbitrary offset to start in the "middle."
  static const double _scrollOffset = 100;
  static const double boxSize = 200;
  int _indexOffset = _scrollOffset.floor();
  Map<int, double> boxSizes = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(initialScrollOffset: _scrollOffset * boxSize, keepScrollOffset: true);
    _scrollController.addListener(listener);
  }

  void listener() {
    double offsetDiff = (_scrollOffset*boxSize - _scrollController.offset);
    int indexOffset = offsetDiff ~/ boxSize;
    double offsetRemainder = indexOffset * boxSize - offsetDiff;
    if (indexOffset.abs() < 1) {
      return;
    }
    print("${_indexOffset} ${_scrollOffset*boxSize+offsetRemainder}");
    setState(() {
      _indexOffset += indexOffset;
    });
    _scrollController.jumpTo(_scrollOffset*boxSize+offsetRemainder);
  }

  @override
  Widget build(BuildContext context) {
    return RawScrollbar(
      controller: _scrollController,
      interactive: true,
      trackVisibility: true,
      thumbVisibility: true,
      child: ListView.builder(
        controller: _scrollController,
        itemBuilder: (context, index) {
          final int contentIndex = index - _indexOffset;
          if (!boxSizes.containsKey(contentIndex)) {
            loadBoxSize(contentIndex);
            return Container(
              height: boxSize,
              alignment: Alignment.center,
              child: Text('Loading: Item $contentIndex', style: Theme.of(context).textTheme.bodyLarge),
            );
          }
          return Container(
            decoration: BoxDecoration(
              border: Border.all(),
              color: _indexOffset == contentIndex ? Colors.cyan : null,
            ),
            height: boxSizes[contentIndex],
            alignment: Alignment.center,
            child: Text('Item $contentIndex', style: Theme.of(context).textTheme.bodyLarge),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void loadBoxSize(int contentIndex) async {
    Timer(Duration(seconds: Random().nextInt(100)), () {
      setState(() {
        boxSizes[contentIndex] = Random().nextInt(100) + 50;
      });
    });
  }
}
