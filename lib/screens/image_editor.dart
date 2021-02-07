import 'dart:io';
import 'dart:typed_data';

import 'package:bitmap/bitmap.dart';
import 'package:bitmap/transformations.dart' as transformations;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:expandable/expandable.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:octo_image/octo_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supercharged/supercharged.dart';
import 'package:image_editor/image_editor.dart' hide ImageSource;
import 'dart:ui' as ui;
import '../app.dart';
import '../text_editor/text_editor.dart';

class RivalImageEditor extends StatefulWidget {
  final File image;
  const RivalImageEditor({Key key, @required this.image}) : super(key: key);
  @override
  _RivalImageEditorState createState() => _RivalImageEditorState();
}

class _RivalImageEditorState extends State<RivalImageEditor> {
  final GlobalKey<ExtendedImageEditorState> editorKey =
      GlobalKey<ExtendedImageEditorState>();

  File file;

  Uint8List u8l;

  int width;
  int height;

  Map<String, String> fonts = {
    'Cookie': 'Cookie-Regular.ttf',
    'Limelight': 'Limelight-Regular.ttf',
    'Lobster': 'Lobster-Regular.ttf',
    RivalFonts.rival: 'PlayfairDisplay.ttf',
    'Poppins': 'Poppins-Regular.ttf',
    RivalFonts.feature: 'Product-Sans-Regular.ttf'
  };
  Map<String, String> fontsByManager = {
    'Cookie': 'Cookie-Regular.ttf',
    'Limelight': 'Limelight-Regular.ttf',
    'Lobster': 'Lobster-Regular.ttf',
    RivalFonts.rival: 'PlayfairDisplay.ttf',
    'Poppins': 'Poppins-Regular.ttf',
    RivalFonts.feature: 'Product-Sans-Regular.ttf'
  };

  bool isLoading = true;

  double saturation = 1;
  double brightness = 1;
  double contrast = 1;

  @override
  void initState() {
    file = widget.image;
    u8l = file.readAsBytesSync();
    ui.decodeImageFromList(u8l, (result) async {
      await loadAllFonts();
      try {
        if (mounted)
          setState(() {
            height = result.height;
            width = result.width;
            isLoading = false;
          });
      } catch (e) {
        height = result.height;
        width = result.width;
        isLoading = false;
      }
      print("Got Results: $result");
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: darkTheme,
      child: Scaffold(
          appBar: AppBar(
            title: Text(
              'Edit',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.check_circle),
                tooltip: 'Save',
                onPressed: () async {
                  // Save and Go Back
                  setState(() {
                    isLoading = true;
                  });
                  String path = (await getTemporaryDirectory()).path +
                      "/${new DateTime.now().millisecondsSinceEpoch}.png";
                  File savedFile = File(path);
                  await savedFile.writeAsBytes(u8l);
                  Navigator.of(context).pop(savedFile);
                },
              )
            ],
          ),
          body: isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      )
                    ],
                  ),
                )
              : ListView(
                  children: [
                    Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        child: OctoImage(
                          image: MemoryImage(u8l),
                          placeholderBuilder: (context) {
                            return Container(
                              width: MediaQuery.of(context).size.width - 20,
                              height: (MediaQuery.of(context).size.width - 20) /
                                  (width / height),
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: FileImage(widget.image),
                                  fit: BoxFit.contain,
                                ),
                              ),
                              child: BackdropFilter(
                                filter:
                                    ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                                child: Container(
                                  color: Colors.black.withOpacity(0),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                            onPressed: () async {
                              RivalProvider.vibrate();
                              _flipImage(horizontal: true);
                            },
                            icon: Icon(Icons.flip_to_back)),
                        IconButton(
                            onPressed: () {
                              RivalProvider.vibrate();
                              _flipImage(vertical: true);
                            },
                            icon: Icon(Icons.flip_to_front)),
                        IconButton(
                            onPressed: () {
                              RivalProvider.vibrate();
                              _rotateImage(left: true);
                            },
                            icon: Icon(Icons.rotate_left)),
                        IconButton(
                            onPressed: () {
                              RivalProvider.vibrate();
                              _rotateImage(right: true);
                            },
                            icon: Icon(Icons.rotate_right)),
                        IconButton(
                            onPressed: () {
                              RivalProvider.vibrate();
                              _addText();
                            },
                            icon: Icon(Icons.text_fields))
                      ],
                    ),
                    SliderTheme(
                      data: SliderThemeData(
                        showValueIndicator: ShowValueIndicator.always,
                      ),
                      child: Column(
                        children: [
                          Slider(
                            min: 0,
                            max: 2,
                            label:
                                'Brightness  ${(brightness / 2 * 100).toInt()}%',
                            onChanged: (value) {
                              setState(() {
                                brightness = value;
                              });
                            },
                            onChangeEnd: (value) async {
                              setState(() {
                                brightness = value;
                              });
                              await _applyEffects();
                            },
                            value: brightness,
                          ),
                          Slider(
                            min: 0,
                            max: 2,
                            label:
                                'Saturation ${(saturation / 2 * 100).toInt()}%',
                            onChanged: (value) {
                              setState(() {
                                saturation = value;
                              });
                            },
                            onChangeEnd: (value) async {
                              setState(() {
                                saturation = value;
                              });
                              await _applyEffects();
                            },
                            value: saturation,
                          ),
                          Slider(
                            min: 0,
                            max: 4,
                            label: 'Contrast ${(contrast / 4 * 100).toInt()}%',
                            onChanged: (value) {
                              setState(() {
                                contrast = value;
                              });
                            },
                            onChangeEnd: (value) async {
                              setState(() {
                                contrast = value;
                              });
                              await _applyEffects();
                            },
                            value: contrast,
                          ),
                        ],
                      ),
                    )
                  ],
                )),
    );
  }

  _flipImage({bool horizontal = false, bool vertical = false}) async {
    final editorOption = ImageEditorOption();
    editorOption.addOptions(
        <Option>[FlipOption(horizontal: horizontal, vertical: vertical)]);
    Uint8List u8L = await ImageEditor.editImage(
        image: u8l, imageEditorOption: editorOption);
    setState(() {
      u8l = u8L;
    });
  }

  _rotateImage({bool right = false, bool left = false}) async {
    final editorOption = ImageEditorOption();
    editorOption.addOptions(<Option>[RotateOption(right ? 90 : -90)]);
    Uint8List u8L = await ImageEditor.editImage(
        image: u8l, imageEditorOption: editorOption);
    setState(() {
      u8l = u8L;
    });
  }

  Future<void> _applyEffects() async {
    final editorOption = ImageEditorOption();
    editorOption.addOptions(<Option>[
      ColorOption.contrast(contrast),
      ColorOption.brightness(brightness),
      ColorOption.saturation(saturation),
    ]);
    Uint8List u8L = await ImageEditor.editFileImage(
        file: file, imageEditorOption: editorOption);
    setState(() {
      u8l = u8L;
    });
  }

  Future<void> _addText() async {
    List list = await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      pageBuilder: (_, __, ___) {
        // your widget implementation
        return Container(
          color: Colors.black.withOpacity(0.6),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              // top: false,
              child: Container(
                child: TextEditor(
                  fonts: fonts.keys.toList(),
                  text: 'Hello World',
                  textStyle: TextStyle(
                      fontFamily: RivalFonts.feature,
                      color: Colors.white,
                      fontSize: 50),
                  textAlingment: TextAlign.center,
                  onEditCompleted: (style, align, text, textPlacement) {
                    Navigator.of(context)
                        .pop([style, align, text, textPlacement]);
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    if (list != null) {
      TextStyle textStyle = list[0];
      TextAlign alignment = list[1];
      String text = list[2];
      TextPlacement textPlacement = list[3];

      //double deviceRatio = MediaQuery.of(context).size.width / MediaQuery.of(context).size.height; // Ratio of device
      double textRatio = textStyle.fontSize /
          MediaQuery.of(context).size.width; // Ratio of text on device's screen
      //double imageRatio = width / height; // Ratio of Image

      double fontSize = textRatio *
          width; // If size of text per pixel is `x`, then size for image width is `x * imageRatio * device pixel ratio`

      double dX = width / 30; // Left Margin with a (width / 30)px padding
      double dY = width / 30; // Top Margin width a (width / 30)px padding

      if (textPlacement == TextPlacement.top) {
        dY = width / 30; // Just add a padding above
      } else if (textPlacement == TextPlacement.center) {
        dY = (height / 2) - (calcHeightOfText(text, fontSize) / 2);
      } else if (textPlacement == TextPlacement.bottom) {
        dY = (height - calcHeightOfText(text, fontSize) / 2) -
            (width /
                30); // Subtract fontSize from height and remove some area for padding below
      }

      if (alignment == TextAlign.center) {
        dX = (width - calcWidthOfText(text, fontSize)) / 2;
      } else if (alignment == TextAlign.right) {
        dX = (width - calcWidthOfText(text, fontSize)) -
            (width / 30); // Keep a padding of (width / 30) on right side
      } else if (alignment == TextAlign.left) {
        dX = width / 30; // Jusr add a padding to left
      }

      final textOption = AddTextOption();
      textOption.addText(
        EditorText(
            offset: Offset(dX, dY), // Does not work
            text: text,
            fontSizePx: fontSize.floor(),
            fontName: fontsByManager[
                textStyle.fontFamily], // You must register font before use.
            textColor: textStyle.color),
      );

      final editorOption = ImageEditorOption();
      editorOption.addOption(textOption);
      Uint8List u8L = await ImageEditor.editImage(
          image: u8l, imageEditorOption: editorOption);
      setState(() {
        u8l = u8L;
      });
    }
  }

  // This concept has been taken from StackOverflow Answer https://stackoverflow.com/a/56997641/13169908
  double calcWidthOfText(String text, double fontSize) {
    final constraints = BoxConstraints(
      maxWidth: width.toDouble(), // maxwidth calculated
      minHeight: 0.0,
      minWidth: 0.0,
    );

    RenderParagraph renderParagraph = RenderParagraph(
        TextSpan(
          text: text,
          style: TextStyle(
            fontSize: fontSize,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
        maxLines: text.split('\n').length);
    renderParagraph.layout(constraints);
    return renderParagraph.getMinIntrinsicWidth(fontSize).ceilToDouble();
  }

  double calcHeightOfText(String text, double fontSize) {
    final constraints = BoxConstraints(
        maxWidth: width.toDouble(), // maxwidth calculated
        maxHeight: height.toDouble(),
        minWidth: 0.0,
        minHeight: 0.0);

    RenderParagraph renderParagraph = RenderParagraph(
        TextSpan(
          text: text,
          style: TextStyle(
            fontSize: fontSize,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
        maxLines: text.split('\n').length);
    renderParagraph.layout(constraints);
    return renderParagraph.getMinIntrinsicHeight(fontSize).ceilToDouble();
  }

  Future<File> loadFont(String fontName) async {
    final byteData = await rootBundle.load('assets/fonts/$fontName');

    final file = File('${(await getTemporaryDirectory()).path}/$fontName');
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

    return file;
  }

  Future<void> loadAllFonts() async {
    for (String font in fonts.values.toList()) {
      File fontFile = await loadFont(font);
      String fontReadableName =
          fonts.keys.toList()[fonts.values.toList().indexOf(font)];
      fontsByManager[fontReadableName] =
          await FontManager.registerFont(fontFile);
    }
  }
}

class RivalImageEditor2 extends StatefulWidget {
  final File image;

  const RivalImageEditor2({Key key, @required this.image}) : super(key: key);

  @override
  _RivalImageEditor2State createState() => _RivalImageEditor2State();
}

class _RivalImageEditor2State extends State<RivalImageEditor2> {
  ExpandableController expandableController = ExpandableController();

  bool isLoading = true;
  Bitmap originalBitmap;
  Bitmap bitmap;

  Uint8List u8l;

  double saturation = 1;
  double brightness = 0;
  double exposure = 0;
  double contrast = 1;
  int blacks = 0;
  int whites = 0;

  @override
  void initState() {
    Bitmap.fromProvider(FileImage(widget.image)).then((btmp) {
      originalBitmap = bitmap = btmp;
      u8l = originalBitmap.buildHeaded();
      setState(() {
        isLoading = false;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: ListView(
          physics: BouncingScrollPhysics(),
          children: [
            if (isLoading)
              LinearProgressIndicator(backgroundColor: Colors.black12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                IconButton(
                  icon: Icon(
                    Icons.check_circle,
                    color: Colors.white,
                  ),
                  tooltip: 'Save',
                  onPressed: () async {
                    try {
                      Permission storage = Permission.storage;
                      var status = await storage.status;
                      if (status.isUndetermined) {
                        // We didn't ask for permission yet.
                        await storage.request();
                      }

                      // You can can also directly ask the permission about its status.
                      if (await storage.isRestricted) {
                        // The OS restricts access, for example because of parental controls.
                        await RivalProvider.showToast(
                            text: 'Permission Denied');
                        return;
                      }

                      if (await storage.isGranted) {
                        setState(() {
                          isLoading = true;
                        });
                        String result = await ImageGallerySaver.saveImage(u8l,
                            quality: 100);
                        try {
                          File finalFile = File(result.allAfter(
                              'file://')); // Result will return path to file
                          RivalProvider.showToast(text: 'Saved to Gallery');
                          Navigator.of(context).pop(finalFile);
                        } catch (e) {
                          print(e);
                          RivalProvider.showToast(text: 'Failed to Save image');
                        }
                        setState(() {
                          isLoading = false;
                        });
                      }
                    } catch (e) {
                      print(e);
                    }
                  },
                )
              ],
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                child: OctoImage(
                  image: isLoading ? FileImage(widget.image) : MemoryImage(u8l),
                  placeholderBuilder: (context) {
                    return Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: OctoImage(
                            image: FileImage(widget.image),
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Center(child: LinearProgressIndicator()),
                        )
                      ],
                    );
                  },
                ),
              ),
            ),
            ButtonBar(
              alignment: MainAxisAlignment.spaceEvenly,
              children: [
                FlatButton.icon(
                    label: Text(
                      'Flip Vertical',
                      style: TextStyle(color: Colors.white),
                    ),
                    icon: Icon(
                      Icons.flip_to_front_outlined,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        bitmap = transformations.flipVertical(bitmap);
                        u8l = bitmap.buildHeaded();
                      });
                    }),
                FlatButton.icon(
                    label: Text(
                      'Flip Horizontal',
                      style: TextStyle(color: Colors.white),
                    ),
                    icon: Icon(
                      Icons.flip_to_back_outlined,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        bitmap = transformations.flipHorizontal(bitmap);
                        u8l = bitmap.buildHeaded();
                      });
                    }),
              ],
            ),
            Divider(),
            ExpandablePanel(
              controller: expandableController,
              collapsed: ListTile(
                  title: Text('Adjust',
                      style: Theme.of(context).textTheme.bodyText1.copyWith(
                          fontFamily: RivalFonts.feature, color: Colors.white)),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                    ),
                    onPressed: () => expandableController.toggle(),
                  )),
              expanded: Column(
                children: [
                  ListTile(
                    title: Text('Adjust',
                        style: Theme.of(context).textTheme.bodyText1.copyWith(
                            fontFamily: RivalFonts.feature,
                            color: Colors.white)),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.keyboard_arrow_up,
                        color: Colors.white,
                      ),
                      onPressed: () => expandableController.toggle(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Text('Brightness',
                        style: Theme.of(context)
                            .textTheme
                            .bodyText2
                            .copyWith(color: Colors.white)),
                  ),
                  Slider.adaptive(
                      value: brightness,
                      label: 'Brightness',
                      min: -0.55,
                      onChanged: (double val) {
                        setState(() {
                          brightness = val;
                        });
                      },
                      onChangeEnd: (double val) {
                        // Change Brightness Now
                        setState(() {
                          brightness = val;
                        });
                        _adjustImage();
                        print('Set Brightness to $val');
                      }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Text('Contrast',
                        style: Theme.of(context)
                            .textTheme
                            .bodyText2
                            .copyWith(color: Colors.white)),
                  ),
                  Slider.adaptive(
                      value: contrast,
                      label: 'Contrast',
                      min: 0.75,
                      max: 1.5,
                      onChanged: (double val) {
                        setState(() {
                          contrast = val;
                        });
                      },
                      onChangeEnd: (double val) {
                        // Change Contrast Now
                        setState(() {
                          contrast = val;
                        });
                        _adjustImage();
                        print('Set Contrast to $val');
                      }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Text('Saturation',
                        style: Theme.of(context)
                            .textTheme
                            .bodyText2
                            .copyWith(color: Colors.white)),
                  ),
                  Slider.adaptive(
                    value: saturation,
                    label: 'Saturation',
                    max: 2,
                    onChanged: (double val) {
                      setState(() {
                        saturation = val;
                      });
                    },
                    onChangeEnd: (double val) {
                      // Change Saturation Now
                      setState(() {
                        saturation = val;
                      });
                      _adjustImage();
                      print('Set Saturation to $val');
                    },
                  ),
                ],
              ),
            ),
            Divider(),
          ],
        ));
  }

  void _adjustImage() {
    setState(() {
      Bitmap btmp = transformations.brightness(originalBitmap, brightness);
      btmp = transformations.contrast(btmp, contrast);
      btmp = transformations.adjustColor(btmp, saturation: saturation);
      btmp = transformations.adjustColor(btmp, exposure: exposure);
      bitmap = btmp;
      u8l = btmp.buildHeaded();
    });
  }
}

class NumberSelector extends StatefulWidget {
  final int min;
  final int max;
  final Function(int selected) onSelect;
  final Axis scrollAxis;
  final int defaultValue;

  const NumberSelector(
      {Key key,
      @required this.min,
      @required this.max,
      @required this.onSelect,
      this.scrollAxis = Axis.vertical,
      @required this.defaultValue})
      : assert(min != null && max != null,
            "Min, Max or Default Value should not be [NULL]"),
        assert(onSelect != null, "Function Onselect should not be null"),
        super(key: key);

  @override
  _NumberSelectorState createState() => _NumberSelectorState();
}

class _NumberSelectorState extends State<NumberSelector> {
  List<int> values;
  CarouselController controller = CarouselController();

  @override
  void initState() {
    values = widget.min.rangeTo(widget.max + 1).toList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Container(
        decoration: BoxDecoration(
            color: Colors.indigoAccent.withOpacity(0.5),
            borderRadius: BorderRadius.all(Radius.circular(15))),
        child: CarouselSlider(
          carouselController: controller,
          items: List.generate(
              values.length,
              (index) => Container(
                    width: 60,
                    height: 60,
                    child: Center(
                        child: Text('${values[index]}',
                            style: TextStyle(
                                fontFamily: RivalFonts.feature,
                                color: Colors.white,
                                fontSize: 25))),
                  )),
          options: CarouselOptions(
            scrollDirection: widget.scrollAxis,
            height: 50,
            aspectRatio: 1,
            initialPage: values.contains(widget.defaultValue)
                ? values.indexOf(widget.defaultValue)
                : 0,
            scrollPhysics: BouncingScrollPhysics(),
            enableInfiniteScroll: false,
            onPageChanged: (index, reason) {
              if (reason == CarouselPageChangedReason.manual) {
                widget.onSelect(values[index]);
              }
            },
          ),
        ),
      ),
    );
  }
}

class Filter {
  final double brightness;
  final double contrast;
  final double saturation;
  final int whites;
  final int blacks;
  final String name;

  Filter(
      {this.brightness,
      this.contrast,
      this.saturation,
      this.name,
      this.whites,
      this.blacks});

  void apply() {}
}
