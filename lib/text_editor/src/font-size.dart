import 'package:flutter/material.dart';

class FontSize extends StatefulWidget {
  final double size;
  final ValueChanged<double> onFontSizeChanged;

  FontSize({
    this.size,
    @required this.onFontSizeChanged,
  });

  @override
  _FontSizeState createState() => _FontSizeState();
}

class _FontSizeState extends State<FontSize> {
  double _currentSliderValue;

  @override
  void initState() {
    _currentSliderValue = widget.size == null ? 10 : widget.size;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: _currentSliderValue,
      min: 0,
      max: 100,
      activeColor: Colors.white,
      inactiveColor: Colors.white60,
      onChanged: (double value) {
        setState(() {
          _currentSliderValue = value;
          widget.onFontSizeChanged(_currentSliderValue);
        });
      },
    );
  }
}
