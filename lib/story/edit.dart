import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:octo_image/octo_image.dart';
import 'package:video_player/video_player.dart';
import '../app.dart';

class EditStory extends StatefulWidget {

  EditStory({Key key, @required this.story}) : super(key: key);
  final Story story;

  @override
  _EditStoryState createState() => _EditStoryState();
}

class _EditStoryState extends State<EditStory> {

  Story story;

  VideoPlayerController videoPlayerController;
  TextEditingController captionController = new TextEditingController();
  bool isLoading = true;

  Color pickerColor;
  Color currentColor;

  _init() async {
    if (story.type == StoryType.video) {
      videoPlayerController = VideoPlayerController.network(story.url);
      await videoPlayerController.initialize();
    } else if (story.type == StoryType.text) {
      pickerColor = currentColor= story.color;
    }
    if (story.caption != null) {
      captionController.text = story.caption;
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    story = widget.story;
    _init();
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    if (videoPlayerController != null) videoPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Story'),
            HDivider(),
            if (story.type == StoryType.image) Icon(Icons.image)
            else if (story.type == StoryType.text) Icon(Icons.text_fields)
            else if (story.type == StoryType.video) Icon(Icons.videocam)
            else if (story.type == StoryType.post) Text('Post', style: TextStyle(fontFamily: RivalFonts.rival))
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            tooltip: 'Delete Story',
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Delete Story?'),
                content: Text('This action cannot be undone. Are you sure you want to delete?'),
                actions: [
                  FlatButton(
                    child: Text('Delete'),
                    onPressed: () async {
                      RivalProvider.vibrate();
                      await story.delete();
                      Navigator.of(context).pushAndRemoveUntil(RivalNavigator(page: Home()), (route) => false);
                    },
                  ),
                  FlatButton(
                    child: Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
            )
          )
        ],
      ),
      body: ListView(
        children: [
          Container(height: 15,),
          if (story.type == StoryType.text) Container(
            margin: EdgeInsets.symmetric(horizontal: 10),
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: currentColor,
              borderRadius: BorderRadius.all(Radius.circular(20))
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 25),
                child: Text(story.caption, style: TextStyle(fontSize: 18, color: currentColor.computeLuminance() > 0.5 ? Colors.black : Colors.white),),
              ),
            ),
          )
          else if (story.type == StoryType.image) Container(
            margin: EdgeInsets.symmetric(horizontal: 10),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.65,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              child: OctoImage(
                image: NetworkImage(story.url),
                placeholderBuilder: (context) => CircularProgressIndicator(),
              ),
            ),
          )
          else if (story.type == StoryType.video) (
            isLoading
            ? SizedBox(
              height: MediaQuery.of(context).size.width * 0.5,
              width: MediaQuery.of(context).size.width,
              child: Center(
                child: Container(
                  height: 50,
                  width: 50,
                  child: CircularProgressIndicator()
                )
              ),
            )
            : AspectRatio(
              aspectRatio: videoPlayerController.value.aspectRatio,
              child: GestureDetector(
                onTap: () {
                  if (videoPlayerController.value.isPlaying) videoPlayerController.pause();
                  else videoPlayerController.play();
                },
                child: VideoPlayer(videoPlayerController)
              ),
            )
          ) else if (story.type == StoryType.post) FutureBuilder(
            future: getPost(story.postId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return ViewPost(post: snapshot.data);
              }
              return SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.width,
                child: Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            },
          ),
          Divider(),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20, left: 15, right: 15, bottom: 5),
                child: Text('Insigths', style: TextStyle(fontSize: Theme.of(context).textTheme.headline3.fontSize, fontFamily: RivalFonts.feature),),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
            child: Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10))
              ),
              color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.white : Colors.white10,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: 'Number of people who viewed your story',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Icon(Icons.remove_red_eye),
                              ),
                              Text('Views', style: TextStyle(fontFamily: RivalFonts.feature, fontSize: Theme.of(context).textTheme.headline6.fontSize),),
                            ],
                          ),
                          Text(story.views.length.toString(), style: TextStyle(fontSize: Theme.of(context).textTheme.bodyText1.fontSize),)
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Divider(),
          if (story.type == StoryType.image || story.type == StoryType.video) ... [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20, left: 15, right: 15, bottom: 10),
                  child: Text('Edit', style: TextStyle(fontSize: Theme.of(context).textTheme.headline3.fontSize, fontFamily: RivalFonts.feature),),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextFormField(
                controller: captionController,
                decoration: InputDecoration(
                  filled: true,
                  labelText: 'Caption',
                  floatingLabelBehavior: FloatingLabelBehavior.always
                ),
                minLines: 3,
                maxLines: 5,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  child: OutlineButton(
                    onPressed: () async {
                      await RivalProvider.vibrate();
                      await story.updateCaption(captionController.text);
                      await me.reload();
                      await RivalProvider.showToast(text: 'Saved Changes');
                      Navigator.of(context).pushAndRemoveUntil(RivalNavigator(page: Home()), (route) => false);
                    },
                    child: Text('Save'),
                  ),
                )
              ],
            )
          ] else if (story.type == StoryType.text) ... [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20, left: 15, right: 15, bottom: 10),
                  child: Text('Edit', style: TextStyle(fontSize: Theme.of(context).textTheme.headline3.fontSize, fontFamily: RivalFonts.feature),),
                ),
              ],
            ),
            ListTile(
              contentPadding: EdgeInsets.only(bottom: 5, left: 10, right: 10, top: 5),
              leading: ClipOval(child: Container(color: currentColor, width: 40, height: 40,)),
              title: Text('Tap to select background color', style: TextStyle(color: MediaQuery.of(context).platformBrightness == Brightness.dark ? Colors.white70 : Colors.black),),
              onTap: _showColorPicker,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  child: OutlineButton(
                    onPressed: () async {
                      await RivalProvider.vibrate();
                      await story.updateColor(currentColor);
                      await me.reload();
                      await RivalProvider.showToast(text: 'Saved Changes');
                      Navigator.of(context).pushAndRemoveUntil(RivalNavigator(page: Home()), (route) => false);
                    },
                    child: Text('Save'),
                  ),
                )
              ],
            )
          ]
        ],
      ),
    );
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

}