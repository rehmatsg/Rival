import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:mime/mime.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:video_player/video_player.dart';
import '../app.dart';

class CreateStory extends StatefulWidget {

  final SharedMediaFile sharedMediaFile;

  const CreateStory({Key key, this.sharedMediaFile}) : super(key: key);

  @override
  _CreateStoryState createState() => _CreateStoryState();
}

class _CreateStoryState extends State<CreateStory> {

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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle, size: 50,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: Chip(
                              avatar: Icon(Icons.image),
                              label: Text('Image'),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: Chip(
                              avatar: Icon(Icons.videocam),
                              label: Text('Video'),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.zero,
                            child: Chip(
                              avatar: Icon(Icons.gif),
                              label: Text('GIF'),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
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
    else mediaFileL = await FilePicker.getFile(type: FileType.media);

    int maxFileSize = 100000000; // MB
    int fileSize = mediaFileL.lengthSync();

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