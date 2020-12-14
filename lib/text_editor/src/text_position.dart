import 'package:flutter/material.dart';
import '../text_editor.dart';

class TextPosition extends StatefulWidget {
  final ValueChanged<TextPlacement> onTextPositionChanged;

  TextPosition({
    @required this.onTextPositionChanged,
  });

  @override
  _TextPositionState createState() => _TextPositionState();
}

class _TextPositionState extends State<TextPosition> {

  Map textPlacement = {
    TextPlacement.top: 'Top',
    TextPlacement.center: 'Center',
    TextPlacement.bottom: 'Bottom',
  };

  int _currentPositionIndex = 1;

  @override
  void initState() {
    super.initState();
  }

  void _positionChangeHandler() {
    setState(() {
      _currentPositionIndex++;

      if (_currentPositionIndex >= textPlacement.length) {
        _currentPositionIndex = 0;
      }

      widget.onTextPositionChanged(textPlacement.keys.toList()[_currentPositionIndex]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _positionChangeHandler,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          textPlacement.values.toList()[_currentPositionIndex],
          style: TextStyle(color: Colors.black),
        ),
      ),
    );
  }
}
