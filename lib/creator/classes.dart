import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_icons/flutter_icons.dart';
import '../app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:property_change_notifier/property_change_notifier.dart';
import 'package:screenshot/screenshot.dart';
//import 'dart:ui' as ui;
import 'package:polygon_clipper/polygon_clipper.dart';

class CreatorPage with PropertyChangeNotifier<String> {

  final Function(File image) onSave;
  final PageSize size;
  CreatorPage({@required this.onSave, this.size = PageSize.square});

  Background bg;

  CreatorPageProperties get properties => CreatorPageProperties(this);

  CreatorWidget selected;

  // Currently selected widget
  CreatorWidget get selection => selected ?? properties;

  List<CreatorWidget> allWidgets = [];

  Background get background => bg;

  ScreenshotController screenshotController = ScreenshotController();

  Offset origin;
  Size actualSize;

  bool showGrid = false;

  double padding = 0;

  Widget build({
    List<BoxShadow> boxShadow,
    @required BuildContext context,
    @required GlobalKey key
  }) {
    if (bg == null) bg = Background(this);
    if (actualSize == null) {
      actualSize = Size(
        MediaQuery.of(context).size.width,
        MediaQuery.of(context).size.width
      ); // TODO: Change height if page type is portrait or landscape
    }
    if (origin == null) {
      origin = Offset(
        MediaQuery.of(context).size.width / 2,
        MediaQuery.of(context).size.width / 2
      ); // TODO: Change height if page type is portrait or landscape
      print('Center: $origin, Device Size: ${MediaQuery.of(context).size}');
    }
    allWidgets.forEach((widget) {
      if (!widget.hasListeners)
        widget.addListener(() {
          notifyListeners();
        });
    });
    if (!bg.hasListeners)
      bg.addListener(() {
        notifyListeners();
      });
    return Screenshot(
      controller: screenshotController,
      containerKey: key,
      child: GestureDetector(
        onTap: () => changeSelection(selection: bg),
        child: SizedBox(
          width: properties.size.width,
          height: properties.size.height,
          child: Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: bg.color,
              image: bg.type == BackgroundType.image
                ? DecorationImage(
                    fit: BoxFit.cover, image: FileImage(bg.image))
                : null,
              boxShadow: boxShadow
            ),
            child: Stack(
              children: [
                ... List.generate(
                  allWidgets.length,
                  (index) => CreatorWidgetParent(
                    child: allWidgets[index],
                    page: this,
                  )
                ),
                if (showGrid) Positioned(
                  top: 0,
                  left: 0,
                  child: IgnorePointer(
                    ignoring: true,
                    child: SizedBox(
                      width: actualSize.width,
                      height: actualSize.height,
                      child: GridView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
                        itemBuilder: (context, index) => Container(
                          width: (actualSize.width / 4) - 2,   // 2 (1 on each side) for
                          height: (actualSize.height / 4) - 2, // the padding
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.black38,
                              style: BorderStyle.solid,
                              width: 1
                            )
                          ),
                        ),
                        itemCount: 16,
                      ),
                    ),
                  ),
                )
              ]
            ),
          ),
        ),
      ),
    );
  }

  void changeSelection({@required CreatorWidget selection}) {
    this.selected = selection;
    notifyListeners();
  }

  void add(CreatorWidget widget) {
    allWidgets.add(widget);
    selected = widget;
    print('Added ${CreatorWidget.name} widget to page. Total widget are ${allWidgets.length}');
    notifyListeners();
  }

  void remove(CreatorWidget widget) {
    allWidgets.remove(widget);
    selected = properties;
  }

  void toggleGrid() {
    showGrid = !showGrid;
    notifyListeners();
  }

  Future<void> save(BuildContext context) async {
    showGrid = false;
    notifyListeners();
    File image = await screenshotController.capture(pixelRatio: MediaQuery.of(context).devicePixelRatio);
    // await ImageGallerySaver.saveImage(
    //   image.readAsBytesSync(),
    //   quality: 100
    // );
    // print('Permission: ${await Permission.storage.status}');
    if (!await Permission.storage.isGranted) {
      if (await Permission.storage.request() == PermissionStatus.granted) {
        await ImageGallerySaver.saveFile(image.path);
        onSave(image);
      }
    } else {
      await ImageGallerySaver.saveFile(image.path);
      onSave(image);
    }
    // showModal(
    //   context: context,
    //   builder: (context) => Scaffold(
    //     backgroundColor: Colors.black54,
    //     body: Column(
    //       mainAxisAlignment: MainAxisAlignment.center,
    //       children: [
    //         Center(
    //           child: Image.file(image),
    //         )
    //       ],
    //     ),
    //   ),
    // );
  }
}

enum BackgroundType { color, image }

enum PageSize {
  story,
  portrait,
  landscape,
  square
}

extension PageSizeExt on PageSize {
  Size get size {
    double height;
    double width = 1080;
    switch (this) {
      case PageSize.portrait:
        height = 1350;
        break;
      case PageSize.landscape:
        height = 608;
        break;
      case PageSize.square:
        height = 1080;
        break;
      case PageSize.story:
        height = 1920;
        break;
      default:
        height = 1080;
    }
    return Size(width, height);
  }
}

class CreatorWidget with ChangeNotifier {

  static String name = 'Rival';

  Offset offset = Offset(0, 0);

  double radius = 0;

  bool isResizable = true;

  double angle = 0;
  void updateAngle(double value) {
    if (value < 5 && value > -5) {
      angle = 0;
    } else if (value < 95 && value > 85) {
      angle = 90;
    } else if (value > -95 && value < -85) {
      angle = -90;
    } else angle = value;
    notifyListeners();
  }

  void onResizeFinished() {}

  void updateOffset(Offset offset, CreatorPage page) {
    Offset centerOffset = Offset(offset.dx + widgetSize.width / 2, offset.dy + widgetSize.height / 2);
    Offset offsetFromCenter = Offset((page.actualSize.width / 2) - centerOffset.dx, (page.actualSize.height / 2) - centerOffset.dy);
    if (offsetFromCenter.dy > -5 && offsetFromCenter.dy < 5 && offsetFromCenter.dx > -5 && offsetFromCenter.dx < 5) { // Align to center
      // RivalProvider.vibrate();
      this.offset = Offset((page.actualSize.width / 2) - (widgetSize.width / 2), (page.actualSize.height / 2) - (widgetSize.height / 2));
    } else if (offsetFromCenter.dy > -5 && offsetFromCenter.dy < 5) { // Align to center vertically
      this.offset = Offset(offset.dx, (page.actualSize.height / 2) - (widgetSize.height / 2));
    } else if (offsetFromCenter.dx > -5 && offsetFromCenter.dx < 5) { // Align to center horizontally
      this.offset = Offset((page.actualSize.width / 2) - (widgetSize.width / 2), offset.dy);
    } else this.offset = offset;
    notifyListeners();
  }

  Size widgetSize = Size(0, 0);
  void updateSize({
    /// Provide the change in width
    @required double width,
    /// Provide the change in height
    @required double height
  }) {
    widgetSize = Size(widgetSize.width + width, widgetSize.height + height);
    // Minimum height and width should be 30
    if (widgetSize.width < 30) {
      widgetSize = Size(30, widgetSize.height);
    }
    if (widgetSize.height < 30) {
      widgetSize = Size(widgetSize.width, 30);
    }
    notifyListeners();
  }

  Widget build() {
    return Container();
  }

  // Map contains `Tab Names` as keys
  // And their options as values
  Map<String, List<Option>> get options => {};
}

class CreatorPageProperties extends CreatorWidget {

  static String name = 'Page';

  final CreatorPage page;

  Size get size => page.size.size;

  CreatorPageProperties(this.page);

  @override
  Map<String, List<Option>> get options => {
    'Page': [
      Option.iconButton(
        icon: Icons.add_circle,
        label: 'Add',
        onTap: (context) {
          showDialog(
            context: context,
            child: Dialog(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text('Text'),
                    onTap: () {
                      Navigator.of(context).pop();
                      page.add(CreatorText(page));
                    },
                  ),
                  ListTile(
                    title: Text('Image'),
                    onTap: () async {
                      PickedFile pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        File croppedFile = await ImageCropper.cropImage(
                          sourcePath: pickedFile.path,
                          compressQuality: 100,
                          androidUiSettings: AndroidUiSettings(
                            toolbarTitle: 'Crop',
                            toolbarColor: Colors.indigoAccent,
                          )
                        );
                        if (croppedFile != null) {
                          var decodedImage = await decodeImageFromList(croppedFile.readAsBytesSync());
                          Size imageSize = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
                          Navigator.of(context).pop();
                          page.add(CreatorImage(page, image: croppedFile, imageSize: imageSize));
                        }
                      }
                    },
                  ),
                  ListTile(
                    title: Text('Shape'),
                    onTap: () {
                      Navigator.of(context).pop();
                      page.add(CreatorShape(page));
                    },
                  ),
                ],
              ),
            )
          );
        },
      ),
      Option.iconButton(
        icon: !page.showGrid ? Icons.grid_off : Icons.grid_on,
        label: 'Grid',
        onTap: (context) => page.toggleGrid(),
      ),
      Option.iconButton(
        icon: Icons.check_circle,
        label: 'Done',
        onTap: (context) async {
          await page.save(context);
        },
      ),
      Option.iconButton(
        icon: Icons.cancel,
        label: 'Cancel',
        onTap: (context) => Navigator.of(context).pop(),
      )
    ]
  };
}

class Background extends CreatorWidget {

  static String name = 'Background';

  File image;
  Color color = Colors.white;
  BackgroundType type = BackgroundType.color;

  Background(this.page);

  set changeColor(Color color) => this.color = color;
  set changeImage(File image) => this.image = image;

  final CreatorPage page;

  @override
  Map<String, List<Option>> get options => {
    'Background': [
      Option.iconButton(
        icon: Icons.color_lens,
        label: 'Color',
        tooltip: 'Tap to select an background color',
        onTap: (context) async {
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                contentPadding: const EdgeInsets.only(top: 20),
                title: Text('Select Color'),
                content: SingleChildScrollView(
                  child: ColorPicker(
                    pickerColor: color,
                    onColorChanged: (value) {
                      color = value;
                      type = BackgroundType.color;
                      //print('Changed color to $value');
                    },
                    colorPickerWidth: 300.0,
                    pickerAreaHeightPercent: 0.7,
                    enableAlpha: false,
                    displayThumbColor: true,
                    showLabel: true,
                    paletteType: PaletteType.hsl,
                    pickerAreaBorderRadius: const BorderRadius.only(
                      topLeft: const Radius.circular(2.0),
                      topRight: const Radius.circular(2.0),
                    ),
                  ),
                ),
                actions: [
                  FlatButton(
                    child: Text('Done'),
                    onPressed: () => Navigator.of(context).pop()
                  )
                ],
              );
            },
          );
          notifyListeners();
        },
      ),
      Option.iconButton(
        icon: Icons.image,
        label: 'Image',
        tooltip: 'Tap to select an image as background',
        onTap: (context) async {
          PickedFile pickedFile =
              await ImagePicker().getImage(source: ImageSource.gallery);
          if (pickedFile != null) {
            AndroidUiSettings uiSettings = AndroidUiSettings(
              backgroundColor: MediaQuery.of(context).platformBrightness ==
                      Brightness.light
                  ? Colors.white
                  : Colors.black,
              cropFrameColor: Colors.indigo,
              activeControlsWidgetColor: Colors.indigo,
              toolbarColor: Colors.indigoAccent,
              statusBarColor: Colors.indigo,
              toolbarTitle: 'Crop Image',
            );
            image = await ImageCropper.cropImage(
                sourcePath: pickedFile.path,
                androidUiSettings: uiSettings,
                aspectRatioPresets: [
                  CropAspectRatioPreset.ratio16x9,
                  CropAspectRatioPreset.square
                ]);
            type = BackgroundType.image;
          }
          notifyListeners();
        },
      ),
    ],
    'Padding': [
      Option.slider(
        label: 'Padding',
        onChange: (context, value) {
          page.padding = value;
          notifyListeners();
        },
        min: 0,
        max: page.actualSize.width / 7,
        value: page.padding
      )
    ]
  };
}

class CreatorText extends CreatorWidget {
  final CreatorPage page;
  CreatorText(this.page);

  static String name = 'Text';

  String text = 'Your text here';
  double size;
  String fontFamily = 'Roboto';
  Color color = Colors.grey[900];

  Color bgColor = Colors.transparent;

  TextDecoration decoration = TextDecoration.none;
  FontWeight bold = FontWeight.normal;
  FontStyle italics = FontStyle.normal;

  EdgeInsetsGeometry padding = EdgeInsets.symmetric(horizontal: 5, vertical: 3);

  @override
  bool get isResizable => false;

  Widget build() {
    if (size == null) {
      _getSizeOfText();
    }
    if (widgetSize.longestSide == 0) {
      widgetSize =
          Size(page.actualSize.width * 3 / 4, page.actualSize.height / 7);
    }
    if (offset.dx == 0 && offset.dy == 0) {
      offset = Offset(page.origin.dx - (widgetSize.width / 2),
          page.origin.dy - (widgetSize.height / 2));
    }
    return RotationTransition(
      turns: AlwaysStoppedAnimation(angle / 360),
      child: Container(
        color: bgColor,
        padding: padding,
        child: SizedBox(
          width: widgetSize.width,
          height: widgetSize.height,
          child: AutoSizeText(
            text,
            style: TextStyle(
              fontFamily: fontFamily,
              color: color,
              fontSize: size,
              decoration: decoration,
              fontStyle: italics,
              fontWeight: bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Map<String, List<Option>> get options => {
    'Text': [
      Option.iconButton(
        icon: Icons.edit,
        label: 'Edit Text',
        onTap: (context) async {
          String text = await Navigator.of(context)
              .push(RivalNavigator(page: TextEditor(text: this.text)));
          if (text != null) {
            this.text = text;
            _getSizeOfText();
            notifyListeners();
          }
        },
      ),
      Option.iconButton(
        icon: Icons.font_download,
        label: 'Font',
        onTap: (context) => toggleFont(),
      ),
      Option.iconButton(
        icon: Icons.format_color_text,
        label: 'Color',
        tooltip: 'Tap to select an text color',
        onTap: (context) async {
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                contentPadding: const EdgeInsets.only(top: 20),
                title: Text('Select Color'),
                content: SingleChildScrollView(
                  child: ColorPicker(
                    pickerColor: color,
                    onColorChanged: (value) {
                      this.color = value;
                      //print('Changed color to $value');
                    },
                    colorPickerWidth: 300.0,
                    pickerAreaHeightPercent: 0.7,
                    enableAlpha: false,
                    displayThumbColor: true,
                    showLabel: true,
                    paletteType: PaletteType.hsl,
                    pickerAreaBorderRadius: const BorderRadius.only(
                      topLeft: const Radius.circular(2.0),
                      topRight: const Radius.circular(2.0),
                    ),
                  ),
                ),
                actions: [
                  FlatButton(
                      child: Text('Done'),
                      onPressed: () => Navigator.of(context).pop())
                ],
              );
            },
          );
          notifyListeners();
        },
      ),
      Option.iconButton(
        icon: Icons.color_lens,
        label: 'BG Color',
        tooltip: 'Tap to select an background color',
        onTap: (context) async {
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                contentPadding: const EdgeInsets.only(top: 20),
                title: Text('Select Color'),
                content: SingleChildScrollView(
                  child: ColorPicker(
                    pickerColor: color,
                    onColorChanged: (value) {
                      this.bgColor = value;
                      //print('Changed color to $value');
                    },
                    colorPickerWidth: 300.0,
                    pickerAreaHeightPercent: 0.7,
                    enableAlpha: true,
                    displayThumbColor: true,
                    showLabel: true,
                    paletteType: PaletteType.hsl,
                    pickerAreaBorderRadius: const BorderRadius.only(
                      topLeft: const Radius.circular(2.0),
                      topRight: const Radius.circular(2.0),
                    ),
                  ),
                ),
                actions: [
                  FlatButton(
                      child: Text('Done'),
                      onPressed: () => Navigator.of(context).pop())
                ],
              );
            },
          );
          notifyListeners();
        },
      ),
      Option.iconButton(
        icon: Icons.delete,
        label: 'Delete',
        onTap: (context) {
          page.remove(this);
          notifyListeners();
        },
      ),
    ],
    'Format': [
      Option.iconButton(
        icon: Icons.format_bold,
        label: 'Bold',
        onTap: (context) {
          if (bold == FontWeight.bold)
            bold = FontWeight.normal;
          else
            bold = FontWeight.bold;
          notifyListeners();
        },
      ),
      Option.iconButton(
        icon: Icons.format_italic,
        label: 'Italic',
        onTap: (context) {
          if (italics == FontStyle.italic)
            italics = FontStyle.normal;
          else
            italics = FontStyle.italic;
          notifyListeners();
        },
      ),
      Option.iconButton(
        icon: Icons.format_underline,
        label: 'Underline',
        onTap: (context) => setTextDecoration(TextDecoration.underline),
      ),
      Option.iconButton(
        icon: Icons.format_strikethrough,
        label: 'Strike',
        onTap: (context) => setTextDecoration(TextDecoration.lineThrough),
      ),
    ],
    'Rotate': [
      Option.slider(
        min: -180,
        max: 180,
        label: 'Angle',
        value: angle,
        onChange: (context, value) {
          updateAngle(value);
          notifyListeners();
        }
      )
    ]
  };

  List<String> fonts = [
    'Roboto',
    'Product Sans',
    'SFPro',
    'DMSerifText',
    'Playfair Display',
    'Lobster',
    'Poppins',
    'Limelight',
    'Cookie'
  ];

  void toggleFont() {
    print('Font Size: $size');
    int indexCurrent = fonts.indexOf(fontFamily);
    int nextIndex = indexCurrent + 1;
    if (nextIndex >= fonts.length) {
      nextIndex = 0;
    }
    fontFamily = fonts[nextIndex];
    notifyListeners();
  }

  @override
  void updateSize({
    /// Provide the change in width
    @required double width,
    /// Provide the change in height
    @required double height
  }) {
    widgetSize = Size(widgetSize.width + width, widgetSize.height + height);
    // Minimum height and width should be 14
    if (widgetSize.width < 14) {
      widgetSize = Size(14, widgetSize.height);
    }
    if (widgetSize.height < 14) {
      widgetSize = Size(widgetSize.width, 14);
    }
    notifyListeners();
  }

  // void toggleSize() {
  //   int indexCurrent = fontSizes.keys.toList().indexOf(size);
  //   int nextIndex = indexCurrent + 1;
  //   if (nextIndex >= fontSizes.length) {
  //     nextIndex = 0;
  //   }
  //   size = fontSizes.keys.toList()[nextIndex];
  //   notifyListeners();
  // }

  void setTextDecoration(TextDecoration decoration) {
    if (this.decoration == decoration) {
      this.decoration = TextDecoration.none;
    } else {
      this.decoration = decoration;
    }
    notifyListeners();
  }

  void _getSizeOfText() {
    widgetSize = Size(page.actualSize.width / 2, (page.actualSize.height / 4) + padding.vertical);
    size = widgetSize.height;
    // final constraints = BoxConstraints(
    //   minHeight: 0.0,
    //   minWidth: 0.0,
    // );

    // RenderParagraph renderParagraph = RenderParagraph(
    //   TextSpan(
    //     text: text,
    //     style: TextStyle(
    //       fontSize: size,
    //       fontFamily: fontFamily,
    //     ),
    //   ),
    //   textDirection: ui.TextDirection.ltr,
    //   maxLines: text.split('\n').length
    // );
    // renderParagraph.layout(constraints);
    // widgetSize = Size(renderParagraph.getMinIntrinsicWidth(size) + padding.horizontal, renderParagraph.getMinIntrinsicHeight(size) + padding.vertical);
  }
}

class CreatorImage extends CreatorWidget {
  
  static String name = 'Image';

  File image;
  Size imageSize;
  final CreatorPage page;

  CreatorImage(this.page, {@required this.imageSize, @required this.image});

  Widget build() {
    if (widgetSize.longestSide == 0) _getWidgetSize();
    return RotationTransition(
      turns: AlwaysStoppedAnimation(angle / 360),
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(radius)),
        child: SizedBox(
          height: widgetSize.height,
          width: widgetSize.width,
          child: Image.file(
            image,
            fit: BoxFit.fitWidth,
          ),
        ),
      ),
    );
  }

  @override
  void updateSize({
    /// Provide the change in width
    @required double width,
    /// Provide the change in height
    @required double height
  }) {
    widgetSize = Size(widgetSize.width + width, widgetSize.height + height);
    // Minimum height and width should be 30
    if (widgetSize.width < 30) {
      widgetSize = Size(30, widgetSize.height);
    }
    if (widgetSize.height < 30) {
      widgetSize = Size(widgetSize.width, 30);
    }
    notifyListeners();
  }

  void _getWidgetSize() {
    if (imageSize.aspectRatio == 1 && imageSize.width >= page.actualSize.width) { // Width = Height && width | height exceeds width | height of page
      widgetSize = Size(page.actualSize.width * 2/3, page.actualSize.width * 2/3);
    } else if (imageSize.aspectRatio > 1 && imageSize.width > page.actualSize.width) { // Width > Height && width of image exceeds width of page
      widgetSize = Size(page.actualSize.width * 2/3, (page.actualSize.width * 2/3) / imageSize.aspectRatio);
    } else if (imageSize.aspectRatio < 1 && imageSize.height > page.actualSize.height) { // Height > Width && Height exceeds height of page
      widgetSize = Size(page.actualSize.width * 2/3 * imageSize.aspectRatio, page.actualSize.height * 2/3);
    } else { // Size is all good
      widgetSize = imageSize;
    }
  }
  
  void onResizeFinished() {
    _getWidgetSizeAfterResize();
    print('Resize complete');
    notifyListeners();
  }

  void _getWidgetSizeAfterResize() {
    if (imageSize.aspectRatio == 1 && widgetSize.width >= widgetSize.height) {
      widgetSize = Size(widgetSize.width, widgetSize.width);
    } else if (imageSize.aspectRatio == 1 && widgetSize.width <= widgetSize.height) {
      widgetSize = Size(widgetSize.width, widgetSize.width);
    }
    else if (imageSize.aspectRatio > 1 && widgetSize.width <= widgetSize.height) { // Width > Height
      widgetSize = Size(widgetSize.width, widgetSize.width / imageSize.aspectRatio);
    } else if (imageSize.aspectRatio > 1 && widgetSize.width >= widgetSize.height) { // Width > Height
      widgetSize = Size(widgetSize.height * imageSize.aspectRatio, widgetSize.height);
    }
    else if (imageSize.aspectRatio < 1 && widgetSize.width <= widgetSize.height) { // Height > Width
      widgetSize = Size(widgetSize.width, widgetSize.width / imageSize.aspectRatio);
    } else if (imageSize.aspectRatio < 1 && widgetSize.width >= widgetSize.height) { // Height > Width
      widgetSize = Size(widgetSize.height * imageSize.aspectRatio, widgetSize.height);
    }
    else { }
  }

  @override
  Map<String, List<Option>> get options => {
    'Image': [
      Option.iconButton(
        icon: Icons.crop,
        label: 'Crop',
        onTap: (context) async {
          File croppedFile = await ImageCropper.cropImage(
            sourcePath: image.path,
            compressQuality: 100,
            androidUiSettings: AndroidUiSettings(
              toolbarTitle: 'Crop',
              toolbarColor: Colors.indigoAccent,
              lockAspectRatio: false,
            )
          );
          if (croppedFile != null) {
            var decodedImage = await decodeImageFromList(croppedFile.readAsBytesSync());
            imageSize = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
            image = croppedFile;
            _getWidgetSize();
            notifyListeners();
          }
        },
      ),
      Option.iconButton(
        icon: FontAwesome.exchange,
        label: 'Replace',
        onTap: (context) async {
          PickedFile pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);
          if (pickedFile != null) {
            File croppedFile = await ImageCropper.cropImage(
              sourcePath: pickedFile.path,
              compressQuality: 100,
              androidUiSettings: AndroidUiSettings(
                toolbarTitle: 'Crop',
                toolbarColor: Colors.indigoAccent,
                lockAspectRatio: false,
              )
            );
            if (croppedFile != null) {
              var decodedImage = await decodeImageFromList(croppedFile.readAsBytesSync());
              imageSize = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
              image = croppedFile;
              _getWidgetSize();
              notifyListeners();
            }
          }
        },
      ),
      Option.iconButton(
        icon: Icons.delete,
        label: 'Delete',
        onTap: (context) {
          page.remove(this);
          notifyListeners();
        },
      ),
    ],
    'Rotate': [
      Option.slider(
        min: -180,
        max: 180,
        label: 'Angle',
        value: angle,
        divisions: 10,
        onChange: (context, value) {
          updateAngle(value);
        }
      )
    ],
    'Radius': [
      Option.slider(
        min: 0,
        max: widgetSize.width / 2,
        value: radius,
        label: 'Border Radius',
        onChange: (context, radius) {
          this.radius = radius;
          notifyListeners();
        }
      )
    ]
  };

}

class CreatorShape extends CreatorWidget {

  final CreatorPage page;
  CreatorShape(this.page);

  Color bgColor = Colors.indigoAccent;
  
  @override
  Size widgetSize = Size(100, 100);

  int sides = 5;

  @override
  Widget build() {
    return SizedBox(
      height: widgetSize.height,
      width: widgetSize.width,
      child: ClipPolygon(
        sides: sides,
        rotate: angle,
        borderRadius: radius,
        child: Container(
          height: widgetSize.height,
          width: widgetSize.width,
          decoration: BoxDecoration(
            color: bgColor,
          ),
        ),
      ),
    );
  }

  @override
  Map<String, List<Option>> get options => {
    'Shape': [
      Option.iconButton(
        icon: Icons.delete,
        label: 'Delete',
        tooltip: 'Delete',
        onTap: (context) {
          page.remove(this);
          notifyListeners();
        }
      )
    ],
    'Rotate': [
      Option.slider(
        min: -180,
        max: 180,
        label: 'Rotate',
        value: angle,
        onChange: (context, angle) {
          this.updateAngle(angle);
        }
      )
    ],
    'Sides': [
      Option.slider(
        min: 3,
        max: 8,
        label: 'Sides',
        value: sides.toDouble(),
        divisions: 6,
        onChange: (context, sides) {
          this.sides = sides.toInt();
          notifyListeners();
        }
      )
    ],
    'Radius': [
      Option.slider(
        min: 0,
        max: widgetSize.width / 2,
        label: 'Radius',
        value: radius,
        onChange: (context, radius) {
          this.radius = radius;
          notifyListeners();
        }
      )
    ]
  };

}

class Option {
  final String label;

  final IconData icon;
  final Function(BuildContext context) onTap;
  final String tooltip;

  final Function(BuildContext context, double value) onChange;
  final double min;
  final double max;
  final double value;
  final int divisions;

  final OptionType type;

  Option({
    @required this.label,
    this.icon,
    this.onTap,
    this.onChange,
    this.tooltip,
    this.min,
    this.max,
    this.value,
    this.divisions,
    @required this.type
  });

  static Option iconButton({
    @required IconData icon,
    @required Function(BuildContext context) onTap,
    @required String label,
    String tooltip
  }) {
    return Option(
      label: label,
      type: OptionType.iconButton,
      icon: icon,
      onTap: onTap,
      tooltip: tooltip,
    );
  }

  static Option slider({
    @required Function(BuildContext context, double value) onChange,
    @required String label,
    double min = 0,
    double max = 100,
    double value = 0,
    int divisions = null,
  }) {
    return Option(
      label: label,
      onChange: onChange,
      type: OptionType.slider,
      max: max,
      min: min,
      divisions: divisions,
      value: value
    );
  }

  Widget build(BuildContext context) {
    switch (type) {
      case OptionType.iconButton:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.indigoAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.all(Radius.circular(10))),
                child: IconButton(
                  tooltip: tooltip,
                  padding: EdgeInsets.zero,
                  icon: Icon(icon,
                      size: Theme.of(context).textTheme.headline4.fontSize),
                  onPressed: () {
                    RivalProvider.vibrate();
                    onTap(context);
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                label,
                style: Theme.of(context).textTheme
                    .button
                    .copyWith(fontFamily: RivalFonts.feature)),
            )
          ],
        );
        break;
      case OptionType.slider:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width - 10, // We use 10 because a horizontal padding of 5px has been defined in creator.dart
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                label: '$value',
                onChanged: (value) {
                  onChange(context, value);
                },
              ),
            )
          ],
        );
        break;
      default:
        return Container();
    }
  }
}

enum OptionType {
  iconButton,
  slider,
}

class CreatorWidgetParent extends StatefulWidget {
  final CreatorWidget child;
  final CreatorPage page;

  const CreatorWidgetParent(
      {Key key, @required this.child, @required this.page})
      : super(key: key);

  @override
  _CreatorWidgetParentState createState() => _CreatorWidgetParentState();
}

class _CreatorWidgetParentState extends State<CreatorWidgetParent> {
  CreatorWidget child;
  CreatorPage page;

  bool isDragging = false;

  Widget w;

  Offset tempDelta = Offset(0, 0);

  void onChange() {
    w = child.build();
    setState(() {});
  }

  @override
  void initState() {
    child = widget.child;
    page = widget.page;
    w = child.build();
    tempDelta = child.offset;
    page.addListener(onChange);
    child.addListener(onChange);
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    // return Positioned(
    //   top: child.offset.dy,
    //   left: child.offset.dx,
    //   child: Listener(
    //     onPointerUp: (event) {
    //       child.updateOffset(tempDelta);
    //       setState(() { });
    //     },
    //     onPointerMove: (event) {
    //       tempDelta = Offset(tempDelta.dx + event.delta.dx, tempDelta.dy + event.delta.dy);
    //     },
    //     child: GestureDetector(
    //       onTapDown: (details) {
    //         page.changeSelection(selection: child);
    //       },
    //       child: Draggable(
    //         maxSimultaneousDrags: 1,
    //         onDragStarted: () {
    //           isDragging = true;
    //           setState(() { });
    //         },
    //         onDragEnd: (details) {
    //           isDragging = false;
    //           setState(() { });
    //         },
    //         feedback: Material(
    //           type: MaterialType.transparency,
    //           child: Opacity(
    //             opacity: 0.4,
    //             child: w
    //           ),
    //         ),
    //         childWhenDragging: w,
    //         child: isDragging ? Container() : (
    //           page.selected == child ? ResizeableWidget(
    //             child: w
    //           ) : w
    //         ),
    //       ),
    //     ),
    //   ),
    // );
    return Positioned(
      top: child.offset.dy,
      left: child.offset.dx,
      child: GestureDetector(
        onTapDown: (details) {
          page.changeSelection(selection: child);
        },
        child: page.selected == child
          ? ResizeableWidget(
              child: child,
              page: page,
            )
          : w,
      )
    );
  }
}

class WidgetSize extends StatefulWidget {
  final Widget child;
  final Function(Size size) onChange;

  const WidgetSize({
    Key key,
    @required this.onChange,
    @required this.child,
  }) : super(key: key);

  @override
  _WidgetSizeState createState() => _WidgetSizeState();
}

class _WidgetSizeState extends State<WidgetSize> {
  @override
  Widget build(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback(postFrameCallback);
    return Container(
      key: widgetKey,
      child: widget.child,
    );
  }

  var widgetKey = GlobalKey();
  var oldSize;

  void postFrameCallback(_) {
    var context = widgetKey.currentContext;
    if (context == null) return;

    var newSize = context.size;
    if (oldSize == newSize) return;

    oldSize = newSize;
    widget.onChange(newSize);
  }
}

class ResizeableWidget extends StatefulWidget {
  final CreatorWidget child;
  final CreatorPage page;

  const ResizeableWidget({Key key, @required this.child, @required this.page}) : super(key: key);

  @override
  _ResizeableWidgetState createState() => _ResizeableWidgetState();
}

class _ResizeableWidgetState extends State<ResizeableWidget> {
  Widget w;
  CreatorWidget child;
  CreatorPage page;

  Size size;

  Offset tempDelta = Offset(0, 0);
  Offset tempResize = Offset(0, 0);

  bool isResizing = false;
  bool isDragging = false;

  void onChange() {
    w = child.build();
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    child = widget.child;
    page = widget.page;
    tempDelta = child.offset;
    w = child.build();
    page.addListener(onChange);
    child.addListener(onChange);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: _getPaddingIfResizing(),
      decoration: BoxDecoration(
        color: Colors.indigoAccent.withOpacity(0.3),
        // border: Border.all(
        //   color: Colors.indigoAccent,
        //   width: 0.5,
        //   style: BorderStyle.solid
        // )
      ),
      child: Stack(
        overflow: Overflow.visible,
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onPanUpdate: (details) {
              child.updateOffset(Offset(child.offset.dx + details.delta.dx,
                  child.offset.dy + details.delta.dy), page);
              setState(() {});
            },
            child: w
          ),
          HandleBall(
            onChange: (details) {
              //print(details.delta);
              child.updateSize(width: details.delta.dx, height: details.delta.dy);
              setState(() {});
            },
            onResizeFinished: () {
              child.onResizeFinished();
            },
          ),
        ],
      ),
    );
  }

  EdgeInsetsGeometry _getPaddingIfResizing() {
    if (isResizing) {
      print(tempResize);
      return EdgeInsets.only(bottom: 0);
    } else {
      return EdgeInsets.zero;
    }
  }
}

class HandleBall extends StatefulWidget {
  final Function(DragUpdateDetails details) onChange;
  final Function onResizeFinished;

  HandleBall({Key key, @required this.onChange, this.onResizeFinished}) : super(key: key);

  @override
  _HandleBallState createState() => _HandleBallState();
}

class _HandleBallState extends State<HandleBall> {
  bool isResizing = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      bottom: 0,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanDown: (details) {
          setState(() {
            isResizing = true;
          });
        },
        onPanUpdate: (details) {
          // Resize Widget here
          widget.onChange(details);
          setState(() {});
        },
        onPanStart: (details) {
          setState(() {
            isResizing = true;
          });
        },
        onPanEnd: (details) => _finishResizing(),
        onPanCancel: () => _finishResizing(),
        child: Align(
          alignment: Alignment.bottomRight,
          child: Container(
            width: isResizing ? 40 : 20,
            height: isResizing ? 40 : 20,
            decoration: BoxDecoration(
              color: Colors.indigoAccent,
            ),
          ),
        ),
      ),
    );
  }

  void _finishResizing() {
    setState(() {
      isResizing = false;
    });
    if (widget.onResizeFinished != null) widget.onResizeFinished();
  }

}

class TextEditor extends StatefulWidget {
  final String text;

  const TextEditor({Key key, @required this.text}) : super(key: key);

  @override
  _TextEditorState createState() => _TextEditorState();
}

class _TextEditorState extends State<TextEditor> {
  TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    textEditingController.text = widget.text;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
          child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(
                  Icons.check_circle,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(context).pop(textEditingController.text);
                },
              )
            ],
          ),
          Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: TextFormField(
              controller: textEditingController,
              style: TextStyle(
                color: Colors.white,
                fontSize: Theme.of(context).textTheme.headline5.fontSize,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                border: InputBorder.none,
              ),
            ),
          ),
          Spacer(),
        ],
      )),
    );
  }
}
