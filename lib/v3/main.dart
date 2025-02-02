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
          title: const Text('Sticky Center Scroll Area'),
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
  final Map<int, double> boxSizes = {};
  int selectedIndex = 0;
  double viewportHeight = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        viewportHeight = MediaQuery.of(context).size.height;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Scrollable area
            Listener(
              onPointerMove: (_) => _updateSelectedIndex(),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: List.generate(
                    1000,
                        (index) => _buildItem(index),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildItem(int index) {
    final isSelected = index == selectedIndex;
    final height = boxSizes[index] ?? _loadBoxSize(index);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: height,
      color: isSelected ? Colors.blue.shade100 : Colors.grey.shade300,
      alignment: Alignment.center,
      child: Text(
        'Item $index',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }

  void _updateSelectedIndex() {
    final scrollOffset = _scrollController.offset;
    final centerY = viewportHeight / 2;
    final centerOffset = scrollOffset + centerY;

    int nearestIndex = 0;
    double smallestDistance = double.infinity;

    for (int i = 0; i < 1000; i++) {
      final itemHeight = boxSizes[i] ?? _loadBoxSize(i);
      final itemTop = i * itemHeight;
      final itemBottom = itemTop + itemHeight;

      if (centerOffset >= itemTop && centerOffset <= itemBottom) {
        nearestIndex = i;
        break;
      }

      final distanceToCenter = (centerOffset - itemTop).abs();
      if (distanceToCenter < smallestDistance) {
        smallestDistance = distanceToCenter;
        nearestIndex = i;
      }
    }

    setState(() {
      selectedIndex = nearestIndex;
    });
  }

  double _loadBoxSize(int index) {
    if (!boxSizes.containsKey(index)) {
      boxSizes[index] = Random().nextDouble() * 50 + 100; // Variable heights
    }
    return boxSizes[index]!;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
