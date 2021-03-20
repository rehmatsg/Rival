import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoder/geocoder.dart';
import 'package:location/location.dart';
import 'package:mime/mime.dart';
import 'package:octo_image/octo_image.dart';
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
    'SFPro',
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
                          child: CustomProgressIndicator(
                            strokeWidth: 2,
                            valueColor: Colors.white,
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
    print('Step 1');
    try {
      print('Step 2');
      // await RivalProvider.vibrate();
      String text = textEditingController.text.toString();
      print('Step 3');
      if (text.trim() != '' && text != null) {
        print('Step 4');
        await Loader.show(
          context,
          function: () async {
            print('Step 5');
            bool isMyFirstStory = false;
            if (me.stories.isEmpty) isMyFirstStory = true;
            print('Step 6');
            await send(text.trim(), color, font);
            print('Step 7');
            if (isMyFirstStory) {
              print('Step 8');
              storyItems.insert(0, getMyStoryWidget());
              print('Step 9');
            }
            print('Step 10');
          },
          onComplete: () {
            print('Step 11');
            RivalProvider.showToast(text: 'Done');
            print('Step 12');
          }
        );
        print('Step 13');
        Navigator.of(context).pop();
        print('Step 14');
      }
    } catch (e) {
      print('Error: $e');
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
    // await database.reference().child(me.uid).child('stories').update({
    //   timestamp.toString(): story
    // });
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
                OutlinedButton(
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