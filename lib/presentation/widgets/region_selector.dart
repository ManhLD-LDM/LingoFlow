import 'package:flutter/material.dart';

class RegionSelector extends StatefulWidget {
  final Rect initialRect;
  final ValueChanged<Rect> onRegionChanged;

  const RegionSelector({
    super.key,
    required this.initialRect,
    required this.onRegionChanged,
  });

  @override
  State<RegionSelector> createState() => _RegionSelectorState();
}

class _RegionSelectorState extends State<RegionSelector> {
  late Rect _currentRect;

  @override
  void initState() {
    super.initState();
    _currentRect = widget.initialRect;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: _currentRect.left,
          top: _currentRect.top,
          width: _currentRect.width,
          height: _currentRect.height,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _currentRect = _currentRect.shift(details.delta);
              });
              widget.onRegionChanged(_currentRect);
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.cyanAccent, width: 2),
                color: Colors.cyanAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      color: Colors.cyanAccent,
                      child: const Text(
                        'VÙNG QUÉT (SCAN AREA)',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
