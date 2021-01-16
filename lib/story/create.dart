import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:geocoder/geocoder.dart';
import 'package:location/location.dart';
import 'package:mime/mime.dart';
import 'package:octo_image/octo_image.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:video_player/video_player.dart';
import '../app.dart';

class CreateTextStory extends StatefulWidget {
  @override
  _CreateTextStoryState createState() => _CreateTextStoryState();
}

class _CreateTextStoryState extends State<CreateTextStory> {

  List<Color> bgColors = [
    Colors.indigoAccent,
    Colors.amber[900],
    Colors.red,
    Colors.black,
    Colors.grey[600],
    Colors.blue,
    Colors.green,
    Colors.blueGrey,
    Colors.brown,
    Colors.cyan[600],
    Colors.deepPurple,
    Colors.orange,
    Colors.pink,
    Colors.purple,
    Colors.teal
  ];

  List<String> fonts = [
    'Roboto',
    'Product Sans',
    'Playfair Display',
    'DMSerifText',
    'Lobster',
    'Poppins',
    'Limelight'
  ];

  Color color = Colors.indigoAccent;
  String font = 'Roboto';

  GeoPoint geoPoint;
  String location;
  bool isLocationLoading = false;

  final TextEditingController textEditingController = RichTextController({
    RegExp(r'@[a-z0-9_.]{4,16}'): TextStyle(fontWeight: FontWeight.bold,), // @username
    RegExp(r'\B#+([\w]+)\b'): TextStyle(fontWeight: FontWeight.bold,), // #HashTags
  }, onMatch: (match) {
    
  },);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color,
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      tooltip: 'Go back',
                      icon: Icon(Icons.arrow_back, color: Colors.white,),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    IconButton(
                      tooltip: 'Send',
                      icon: Icon(Icons.check_circle, color: Colors.white,),
                      onPressed: _send,
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: textEditingController,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: Theme.of(context).textTheme.headline3.fontSize,
                        fontFamily: font,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'What\'s on your mind??',
                        hintStyle: TextStyle(
                          color: Colors.white
                        )
                      ),
                      keyboardType: TextInputType.multiline,
                      minLines: 1,
                      maxLines: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.color_lens, color: Colors.white,),
                          onPressed: _toggleBackgroundColor,
                        ),
                        Container(width: 10,),
                        IconButton(
                          icon: Icon(Icons.font_download, color: Colors.white,),
                          onPressed: _toggleFont,
                        ),
                        Container(width: 10,),
                        (isLocationLoading)
                        ? Container(
                          height: 22,
                          width: 22,
                          margin: EdgeInsets.symmetric(horizontal: 13),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          )
                        )
                        : IconButton(
                          tooltip: (location != null) ? 'Remove Location' : 'Add Location',
                          icon: Icon((location != null) ? Icons.location_on : Icons.location_off, color: Colors.white,),
                          onPressed: (location != null) ? () {
                            setState(() {
                              location = geoPoint = null;
                            });
                          } : _getLocation,
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            if (location != null) Align(
              alignment: Alignment.bottomCenter,
              child: Chip(
                label: Text(location, style: TextStyle(color: Colors.white,),),
                avatar: Icon(Icons.place, color: Colors.white,),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _toggleBackgroundColor() {
    int currentIndex = bgColors.indexOf(color);
    if (currentIndex < (bgColors.length - 1)) setState(() {
      color = bgColors[currentIndex + 1];
    });
    else setState(() {
      color = bgColors[0];
    });
  }

  void _toggleFont() {
    int currentIndex = fonts.indexOf(font);
    if (currentIndex < (fonts.length - 1)) setState(() {
      font = fonts[currentIndex + 1];
    });
    else setState(() {
      font = fonts[0];
    });
  }

  Future<void> _getLocation() async {
    setState(() {
      isLocationLoading = true;
    });
    // print('Getting Location...');
    Location location = new Location();
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return null;
      }
    }
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return null;
      }
    }
    _locationData = await location.getLocation();
    Coordinates coordinates = new Coordinates(_locationData.latitude, _locationData.longitude);

    List<Address> addresses = await Geocoder.local.findAddressesFromCoordinates(coordinates);
    Address address = addresses.first;

    setState(() {
      isLocationLoading = false;
      geoPoint = GeoPoint(_locationData.latitude, _locationData.longitude);
      this.location = address.subAdminArea;
    });
  }

  Future<void> _send() async {
    await RivalProvider.vibrate();
    String text = textEditingController.text.toString();
    if (text.trim() != '' && text != null) {
      await Loader.show(
        context,
        function: () async {
          await send(text.trim(), color, font);
        },
        onComplete: () {
          RivalProvider.showToast(text: 'Done');          
        }
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> send(String text, Color color, String font) async {
    int timestamp = new DateTime.now().millisecondsSinceEpoch;
    Map story = {
      'type': 'text',
      'caption': text,
      'timestamp': timestamp,
      'color': color.value,
      'views': {},
      'url': null,
      'geoPoint': geoPoint,
      'locationPlaceholder': location,
      'font': font
    };
    await me.update({
      'story.$timestamp': story
    }, reload: true);
  }

}

class CreateImageStory extends StatefulWidget {

  final File image;

  CreateImageStory({Key key, @required this.image}) : super(key: key);

  @override
  _CreateImageStoryState createState() => _CreateImageStoryState();
}

class _CreateImageStoryState extends State<CreateImageStory> {

  File image;

  GeoPoint geoPoint;
  String location;

  Widget locationSelector;

  TextEditingController captionCtrl = TextEditingController();

  @override
  void initState() {
    locationSelector = LocationSelector(
      onLocationSelect: (geoPoint, feature) {
        setState(() {
          this.geoPoint = geoPoint;
          this.location = feature;
        });
      },
    );
    image = widget.image; 
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Story'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              child: OctoImage(
                image: FileImage(image),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: locationSelector,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: TextField(
              controller: captionCtrl,
              decoration: InputDecoration(
                filled: true,
                labelText: 'Caption',
                floatingLabelBehavior: FloatingLabelBehavior.always
              ),
              minLines: 2,
              maxLines: 4,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlineButton(
                  child: Text('Send'),
                  onPressed: _send
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> _send() async {
    String text = captionCtrl.text.trim();
    int timestamp = new DateTime.now().millisecondsSinceEpoch;
    Map story = {
      'type': 'image',
      'caption': text,
      'timestamp': timestamp,
      'color': null,
      'views': {},
      'url': null,
      'geoPoint': geoPoint,
      'locationPlaceholder': location
    };

    await Loader.show(
      context,
      function: () async {
        StorageUploadTask storageUploadTask = FirebaseStorage.instance.ref().child('stories').child('STORY-' + new DateTime.now().toLocal().toString().replaceAll(' ', '.') + '-' + new DateTime.now().millisecondsSinceEpoch.toString()).putFile(image);
        StorageTaskSnapshot taskSnapshot = await storageUploadTask.onComplete;
        String downloadUrl = await taskSnapshot.ref.getDownloadURL();
        story['url'] = downloadUrl;
        story['mime'] = lookupMimeType(image.path);
        await me.update({
          'story.$timestamp': story
        }, reload: true);
      },
      onComplete: () {
        RivalProvider.showToast(text: 'Done');
      }
    );
    Navigator.of(context).pop();
  }

}

class CreateStory2 extends StatefulWidget {

  final SharedMediaFile sharedMediaFile;

  const CreateStory2({Key key, this.sharedMediaFile}) : super(key: key);

  @override
  _CreateStory2State createState() => _CreateStory2State();
}

class _CreateStory2State extends State<CreateStory2> {

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  TextEditingController _textEditingController = TextEditingController();
  bool isLoading = false;
  String loadingState;
  double loadingProgress;

  File mediaFile;
  String mime;
  String type = "text";

  VideoPlayerController videoPlayerController;

  // create some values
  Color pickerColor = Colors.indigoAccent;
  Color currentColor = Colors.indigoAccent;

  Widget locationSelector;
  GeoPoint geoPoint;
  String location;

  bool isLoadingX = false; // Loading for media file picker
  String title = 'Create Story';

  Future<void> _handleSharedMedia() async {
    if (widget.sharedMediaFile != null) {
      _selectMediaFile(file: File(widget.sharedMediaFile.path));
    }
  }

  @override
  void initState() {
    locationSelector = LocationSelector(
      onLocationSelect: (geoPoint, feature) {
        setState(() {
          this.geoPoint = geoPoint;
          this.location = feature;
        });
      },
    );
    super.initState();
    try {
      _handleSharedMedia();
    } catch (e) {
      try {
        Future.delayed(Duration(milliseconds: 500), _handleSharedMedia);
      } catch (e) {
        RivalProvider.showToast(text: 'Failed to get shared files');
      }
    }
  }

  @override
  void dispose() {
    if (videoPlayerController != null) videoPlayerController.dispose();
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    bool darkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (isLoadingX) Padding(
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
            child: Container(
              width: 25,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            tooltip: 'Send Story',
            onPressed: _sendStatus
          )
        ],
      ),
      body: Center(
        child: isLoading
        ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 100,
              width: 100,
              child: CircularProgressIndicator(
                value: loadingProgress,
              ),
            ),
            Container(height: 20,),
            Text(loadingState != null ? loadingState : '...', style: TextStyle(fontFamily: RivalFonts.feature, fontSize: 20),)
          ],
        )
        : ListView(
          children: [
            if (mediaFile != null) ... [
              if (type == "image") Container(
                margin: EdgeInsets.all(15),
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                  child: Stack(
                    children: [
                      Image.file(mediaFile),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: FlatButton.icon(
                            onPressed: () async {
                              File edited = await Navigator.of(context).push(RivalNavigator(page: RivalImageEditor(image: mediaFile,),));
                              if (edited != null) setState(() {
                                mediaFile = edited;
                              });
                            },
                            icon: Icon(Icons.edit),
                            label: Text('Edit'),
                            color: Colors.black38,
                            textColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10))
                            ),
                          ),
                        )
                      )
                    ],
                  ),
                ),
              ) else GestureDetector(
                onTap: () async {
                  await RivalProvider.vibrate();
                  SystemSound.play(SystemSoundType.click);
                  if (videoPlayerController.value.isPlaying) {
                    videoPlayerController.pause();
                  } else {
                    videoPlayerController.play();
                  }
                },
                child: SizedBox(
                  height: videoPlayerController.value.aspectRatio > 1 ? MediaQuery.of(context).size.width / videoPlayerController.value.aspectRatio : MediaQuery.of(context).size.height ,
                  width: videoPlayerController.value.aspectRatio > 1 ? MediaQuery.of(context).size.width : MediaQuery.of(context).size.height * videoPlayerController.value.aspectRatio,
                  child: VideoPlayer(videoPlayerController),
                ),
              )
            ] else InkWell(
              onTap: _selectMediaFile,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.width * 0.7,
                margin: EdgeInsets.all(10),
                child: Center(
                  child: Icon(Icons.add_circle, size: 50,),
                ),
              ),
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: locationSelector,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextFormField(
                controller: _textEditingController,
                decoration: InputDecoration(
                  filled: true,
                  labelText: 'Add Caption',
                  floatingLabelBehavior: FloatingLabelBehavior.always
                ),
                maxLength: 50,
                minLines: 3,
                maxLines: 7,
              ),
            ),
            if (mediaFile == null) ListTile(
              contentPadding: EdgeInsets.only(bottom: 5, left: 15, right: 15, top: 5),
              leading: ClipOval(child: Container(color: currentColor, width: 30, height: 30,)),
              visualDensity: VisualDensity.adaptivePlatformDensity,
              title: Text('Tap to select background color', style: TextStyle(color: darkMode ? Colors.white70 : Colors.black),),
              onTap: _showColorPicker,
            ),
          ],
        ),
      ),
    );
  }

  _selectMediaFile({File file}) async {
    setState(() {
      isLoadingX = true;
    });
    File mediaFileL;
    if (file != null) mediaFileL = file;
    else mediaFileL = await FilePicker.getFile(type: FileType.image); // Image only

    int maxFileSize = 100000000; // MB
    int fileSize = mediaFileL?.lengthSync();

    print('File Size: $fileSize');

    if (mediaFileL != null && fileSize < maxFileSize) { // i.e. size is less than 100MB
      mediaFile = mediaFileL;
      mime = lookupMimeType(mediaFileL.path);
      type = lookupMimeType(mediaFileL.path).split('/')[0];
      if (type == "video") {
        videoPlayerController = VideoPlayerController.file(mediaFile);
        await videoPlayerController.initialize();
        await videoPlayerController.setLooping(true);
        await videoPlayerController.play();
      }
      setState(() {});
    } else if (mediaFileL != null && fileSize > maxFileSize) {
      _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text('Media size should not exceed 100MB'),));
    }
    setState(() {
      isLoadingX = false;
    });
  }

  _showColorPicker() {
    showDialog(
      context: context,
      child: AlertDialog(
        title: const Text('Select Background Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (Color color) {
              setState(() {
                pickerColor = color;
              });
            },
            showLabel: true,
            pickerAreaHeightPercent: 0.8,
          ),
          // Use Material color picker:
          //
          // child: MaterialPicker(
          //   pickerColor: pickerColor,
          //   onColorChanged: changeColor,
          //   showLabel: true, // only on portrait mode
          // ),
          //
          // Use Block color picker:
          //
          // child: BlockPicker(
          //   pickerColor: currentColor,
          //   onColorChanged: changeColor,
          // ),
        ),
        actions: <Widget>[
          FlatButton(
            child: const Text('Done'),
            onPressed: () {
              setState(() => currentColor = pickerColor);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  _sendStatus() async {
    await RivalProvider.vibrate();
    String text = _textEditingController.text.trim().replaceAll(' ', '') != "" ? _textEditingController.text.trim() : null;
    if (text != null || mediaFile != null) {
      if (videoPlayerController != null) {
        videoPlayerController?.pause();
      }
      int timestamp = new DateTime.now().millisecondsSinceEpoch;
      Map story = {
        'type': type,
        'caption': text,
        'timestamp': timestamp,
        'color': currentColor.value,
        'views': {},
        'url': null,
        'geoPoint': geoPoint,
        'locationPlaceholder': location
      };
      setState(() {
        isLoading = true;
        loadingState = "Getting Things Ready";
      });
      if (type != 'text') {
        // Story contains a media file
        // Upload and change the variable to `url`
        if (type == 'video') {
          story['duration'] = videoPlayerController.value.duration.inSeconds;
        }
        StorageUploadTask storageUploadTask = FirebaseStorage.instance.ref().child('stories').child('STORY-' + new DateTime.now().toLocal().toString().replaceAll(' ', '.') + '-' + new DateTime.now().millisecondsSinceEpoch.toString()).putFile(mediaFile);
        setState(() {
          loadingState = "Sending";
        });
        storageUploadTask.events.listen((event) {
          switch (event.type) {
            case StorageTaskEventType.progress:
              setState(() {
                loadingProgress = event.snapshot.bytesTransferred / event.snapshot.totalByteCount;
              });
              break;
            default:
          }
        });
        StorageTaskSnapshot taskSnapshot = await storageUploadTask.onComplete;
        String downloadUrl = await taskSnapshot.ref.getDownloadURL();
        story['url'] = downloadUrl;
        story['mime'] = lookupMimeType(mediaFile.path);
      }
      if ((type == "text" && text != null) || type != "text") {
        setState(() {
          loadingProgress = null;
          loadingState = 'Finishing Up...';
        });
        await me.update({
          'story.$timestamp': story
        });
        await me.reload();
        setState(() {
          isLoading = false;
        });
        Navigator.of(context).pop();
      } else {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

}