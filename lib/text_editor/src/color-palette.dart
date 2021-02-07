import 'package:flutter/material.dart';

class ColorPalette extends StatefulWidget {
  final Color pickedColor;
  final ValueChanged<Color> onColorChanged;

  ColorPalette({
    this.pickedColor = Colors.black,
    @required this.onColorChanged,
  });

  @override
  _ColorPaletteState createState() => _ColorPaletteState();
}

class _ColorPaletteState extends State<ColorPalette> {
  Color currentColor;

  @override
  void initState() {
    currentColor = widget.pickedColor;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    void _changeColorHandler(color) {
      setState(() {
        currentColor = color;

        widget.onColorChanged(currentColor);
      });
    }

    return Container(
      child: SizedBox(
        height: 40,
        width: double.infinity,
        child: ListView(
          physics: BouncingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          children: [
            Container(
              width: 40,
              height: 40,
              margin: EdgeInsets.only(right: 7),
              decoration: BoxDecoration(
                color: currentColor,
                border: Border.all(color: Colors.white, width: 1.5),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Center(
                child: Icon(
                  Icons.palette,
                  color: currentColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                ),
              ),
            ),
            _ColorPicker(Colors.black, onColorChanged: _changeColorHandler),
            _ColorPicker(Colors.white, onColorChanged: _changeColorHandler),
            _ColorPicker(Colors.indigo, onColorChanged: _changeColorHandler),
            _ColorPicker(Colors.indigoAccent, onColorChanged: _changeColorHandler),
            _ColorPicker(Color(int.parse('0xFFF05720')), onColorChanged: _changeColorHandler),
            _ColorPicker(Color(int.parse('0xffEA2027')), onColorChanged: _changeColorHandler),
            _ColorPicker(Color(int.parse('0xff006266')), onColorChanged: _changeColorHandler),
            _ColorPicker(Color(int.parse('0xff5758BB')), onColorChanged: _changeColorHandler),
            _ColorPicker(Color(int.parse('0xff6F1E51')), onColorChanged: _changeColorHandler),
            _ColorPicker(Color(int.parse('0xffB53471')), onColorChanged: _changeColorHandler),
            _ColorPicker(Color(int.parse('0xFF5720F0')), onColorChanged: _changeColorHandler),
            _ColorPicker(Color(int.parse('0xFF4400FF')), onColorChanged: _changeColorHandler),
            _ColorPicker(Color(int.parse('0xFFF05720')), onColorChanged: _changeColorHandler),
            _ColorPicker(Color(int.parse('0xFFFF7644')), onColorChanged: _changeColorHandler),
            _ColorPicker(Color(int.parse('0xff009432')), onColorChanged: _changeColorHandler),
            _ColorPicker(Color(int.parse('0xFF0DFF6A')), onColorChanged: _changeColorHandler),
            _ColorPicker(Color(int.parse('0xff0652DD')), onColorChanged: _changeColorHandler),
            _ColorPicker(Color(int.parse('0xff1B1464')), onColorChanged: _changeColorHandler),
            _ColorPicker(Color(int.parse('0xFF1500FF')), onColorChanged: _changeColorHandler),
            _ColorPicker(Color(int.parse('0xff9980FA')), onColorChanged: _changeColorHandler),
            _ColorPicker(Color(int.parse('0xff833471')), onColorChanged: _changeColorHandler),
            _ColorPicker(Color(int.parse('0xffFDA7DF')), onColorChanged: _changeColorHandler),
            _ColorPicker(Color(int.parse('0xffED4C67')), onColorChanged: _changeColorHandler),
            _ColorPicker(Color(int.parse('0xffF79F1F')), onColorChanged: _changeColorHandler),
            _ColorPicker(Color(int.parse('0xffA3CB38')), onColorChanged: _changeColorHandler),
            _ColorPicker(Color(int.parse('0xFFBBFF00')), onColorChanged: _changeColorHandler),
            _ColorPicker(Color(int.parse('0xff1289A7')), onColorChanged: _changeColorHandler),
            _ColorPicker(Color(int.parse('0xffD980FA')), onColorChanged: _changeColorHandler),
          ],
        ),
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final Color color;
  final ValueChanged<Color> onColorChanged;

  _ColorPicker(this.color, {@required this.onColorChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onColorChanged(color),
      child: Container(
        width: 40,
        height: 40,
        margin: EdgeInsets.only(right: 7),
        decoration: BoxDecoration(
          color: color,
          border: color == Colors.black ? Border.all(color: Colors.white, width: 1) : Border.symmetric(),
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }
}
