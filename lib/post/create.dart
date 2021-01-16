import 'package:e/post/select_topic.dart';
import 'package:flutter/material.dart';

import 'dart:io';
import 'dart:math';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expandable/expandable.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:liquid_progress_indicator/liquid_progress_indicator.dart';
import 'package:octo_image/octo_image.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../app.dart';

List<String> actionButtons = [
  'Open',
  'Shop',
  'Buy',
  'Install',
  'Download',
  'Order',
  'Visit',
  'Learn More'
];

/// Return [true] if a post is in middle of being created.
/// Don't allow new posts if a previous post is being created
bool isPostBeingCreated = false;

class CreatePost extends StatefulWidget {
  CreatePost({Key key, this.sharedMediaFiles}) : super(key: key);

  final List<SharedMediaFile> sharedMediaFiles;

  @override
  _CreatePostState createState() => _CreatePostState();
}

final ImageLabeler labeler = FirebaseVision.instance.imageLabeler();
final TextRecognizer textRecognizer = FirebaseVision.instance.textRecognizer();

class _CreatePostState extends State<CreatePost> {

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final FirebaseAnalytics analytics = FirebaseAnalytics();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _descriptionCtrl = RichTextController({
    RegExp(r'@[a-z0-9_.]{4,16}'): TextStyle(fontWeight: FontWeight.bold,), // @username
    RegExp(r'\B#+([\w]+)\b'): TextStyle(fontWeight: FontWeight.bold,), // #HashTags
    RegExp(r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,12}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)'): TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline), // http://www.regex.for.url/
  }, onMatch: (match) {
    
  },);
  final TextEditingController _subtitleCtrl = TextEditingController();
  final ExpandableController advancedSettingCtrl = ExpandableController();

  List<File> images = [];
  List<String> labels = [];
  List<String> tags = [];
  List<String> ocrText = [];
  List<DocumentReference> people = [];
  List<DocumentSnapshot> peopleDocs = [];
  String topic;

  bool allowComments = true;
  bool containsAdultContent = false;
  bool showLikeCount = true;
  RivalUser sponsor;

  final _urlFormKey = GlobalKey<FormState>();
  bool isProduct = false;
  String productUrl;
  String productButtonTitle = "Open";

  bool isLoading = false;
  bool isLoadingX = false;
  String title = 'Create Post';

  int descriptionMaxLength = 1000;
  int maxTags = 15;
  int maxPeopleTagging = 10;
  int noOfImages = 10;
  
  GeoPoint geoPoint;
  String locationText;

  String loadingState;

  Widget locationSelector;

  var ratio = {
    'width': 800.0,
    'height': 800.0
  };

  Future<void> _handleSharedMedia() async {
    if (widget.sharedMediaFiles != null) {
      for (SharedMediaFile sharedFile in widget.sharedMediaFiles) {
        int index = widget.sharedMediaFiles.indexOf(sharedFile);
        File file = new File(sharedFile.path);
        await _selectImage(index, file: file);
      }
    }
  }

  @override
  void initState() {
    locationSelector = LocationSelector(onLocationSelect: (geoPointL, feature) {
      setState(() {
        geoPoint = geoPointL;
        locationText = feature;
      });
    },);
    if (me.isCreatorAccount) noOfImages = 15; // 15 images per page if I am a creator
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
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(fontFamily: RivalFonts.feature, fontSize: 20),
        ),
        actions: <Widget>[
          if (!isLoading && !isLoadingX) IconButton(
            icon: Icon(Icons.check_circle),
            tooltip: 'Finish',
            onPressed: () {
              if (_formKey.currentState.validate()) {
                _post();
              }
            },
          ),
          if (isLoadingX) Padding(
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
            child: Container(
              width: 25,
              height: 15,
              child: CircularProgressIndicator(),
            ),
          )
        ],
      ),
      body: WillPopScope(
        onWillPop: () async {
          if ((images.length > 0 || _subtitleCtrl.text != "" || _descriptionCtrl.text != "") && !isLoading) {
            return await showDialog(
              context: context,
              child: AlertDialog(
                title: Text('Discard Changes'),
                content: Text('Post will be discarded. This step cannot be undone'),
                actions: [
                  FlatButton(
                    child: Text('Cancel'),
                    onPressed: () => Navigator.of(context).maybePop(false),
                  ),
                  FlatButton(
                    child: Text('Discard'),
                    onPressed: () => Navigator.of(context).maybePop(true)
                  )
                ],
              )
            );
          } else if (isLoading) {
            return await showDialog(
              context: context,
              child: AlertDialog(
                title: Text('Return'),
                content: Text('Creating Post. Meanwhile you can go back and the process will continue in background.'),
                actions: [
                  FlatButton(
                    child: Text('Stay'),
                    onPressed: () => Navigator.of(context).maybePop(false),
                  ),
                  FlatButton(
                    child: Text('Go Back'),
                    onPressed: () => Navigator.of(context).maybePop(true)
                  )
                ],
              )
            );
          }
          return true;
        },
        child: !isLoading
        ? ListView(
          children: <Widget>[
            Center(
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 0, vertical: 20),
                    child: CarouselSlider.builder(
                      itemBuilder: (context, index) {
                        try {
                          if (images.contains(images[index])) {
                            File i = images[index];
                            return Container(
                              child: InkWell(
                                child: ClipRRect(
                                  //borderRadius: BorderRadius.all(Radius.circular(10)),
                                  child: Stack(
                                    children: [
                                      Image.file(i),
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 5),
                                          child: FlatButton.icon(
                                            onPressed: () async {
                                              File edited = await Navigator.of(context).push(RivalNavigator(page: RivalImageEditor(image: i,),));
                                              if (edited != null) setState(() {
                                                images[index] = edited;
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
                                  )
                                ),
                                onTap: () async {
                                  _selectImage(index);
                                },
                                onLongPress: () {
                                  if (images.isNotEmpty) {
                                    return showDialog(
                                      context: context,
                                      barrierDismissible: true,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: Text('Clear'),
                                          content: SingleChildScrollView(
                                            child: ListBody(
                                              children: <Widget>[
                                                Text('Do you want to clear all images?'),
                                              ],
                                            ),
                                          ),
                                          actions: <Widget>[
                                            FlatButton(
                                              onPressed: () {
                                                setState(() {
                                                  images.clear();
                                                  labels.clear();
                                                  ocrText.clear();
                                                  ratio['width'] = 800;
                                                  ratio['height'] = 800;
                                                });
                                                Navigator.pop(context);
                                              },
                                              child: Text('Clear')
                                            ),
                                            FlatButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: Text('Cancel')
                                            )
                                          ],
                                        );
                                      },
                                    );
                                  }
                                },
                              ),
                            );
                          }
                          return Container();
                        } catch (e) {
                          return Container(
                            width: MediaQuery.of(context).size.width,
                            child: InkWell(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Icon(Icons.add_circle, size: 50,),
                                  Text(
                                    'Add Image',
                                    style: TextStyle(
                                      fontFamily: RivalFonts.feature,
                                      fontSize: 25,
                                    )
                                  ),
                                  Text('${index + 1}', style: TextStyle(
                                    color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black26 : Colors.white24,
                                    fontFamily: RivalFonts.feature,
                                    fontSize: Theme.of(context).textTheme.caption.fontSize
                                  ),)
                                ],
                              ),
                              onTap: () async {
                                _selectImage(index);
                              },
                            ),
                          );
                        }
                      },
                      options: CarouselOptions(
                        height: (images.length >= 1 || ratio['height'] < (MediaQuery.of(context).size.height * 0.5)) ? MediaQuery.of(context).size.width / (ratio['width'] / ratio['height']) : (MediaQuery.of(context).size.height * 0.3),
                        viewportFraction: 1,
                        initialPage: 0,
                        enableInfiniteScroll: false,
                        reverse: false,
                        autoPlay: false,
                        enlargeCenterPage: false,
                        scrollDirection: Axis.horizontal,
                      ),
                      itemCount: noOfImages,
                    ),
                  ),
                  if (me.isCreatorAccount) ... [
                    Divider(),
                    ListTile(
                      title: Text('Creator', style: TextStyle(fontFamily: RivalFonts.feature),),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message: 'Use Rival\'s built-in creator to make custom graphics',
                            child: Icon(Icons.help)
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).push(RivalNavigator(page: PostCreator())),
                              child: Icon(Icons.arrow_forward),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                  Divider(),
                  ListTile(
                    title: Text('General', style: TextStyle(fontFamily: RivalFonts.feature),)
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: locationSelector
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: TextFormField(
                              controller: _subtitleCtrl,
                              autocorrect: true,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                filled: true,
                                labelText: 'Subtitle',
                                helperText: geoPoint != null ? 'Location will be used as subtitle' : null,
                                counterText: null
                              ),
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(500),
                              ],
                              enableSuggestions: true,
                              enableInteractiveSelection: true,
                              validator: subtitleValidator,
                              readOnly: geoPoint != null,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: TextFormField(
                              controller: _descriptionCtrl,
                              autocorrect: true,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                filled: true,
                                labelText: 'Give some description to your post',
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                counterText: null
                              ),
                              minLines: 3,
                              maxLines: 7,
                              enableSuggestions: true,
                              enableInteractiveSelection: true,
                              validator: descriptionValidator,
                              keyboardType: TextInputType.multiline,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(500),
                              ],
                              // onChanged: (desc) {
                              //   if (desc.endsWith(' ') || desc.endsWith('.')) {
                              //     List<String> descList = desc.split(' ');
                              //     tags.clear();
                              //     descList.forEach((word) {
                              //       if (word.startsWith('#') && word.length > 1) {
                              //         if (word.endsWith('.')) {
                              //           _addTag(word.substring(1, word.length - 1));
                              //         } else {
                              //           _addTag(word.substring(1, word.length));
                              //         }
                              //       }
                              //     });
                              //   }
                              // },
                            ),
                          ),
                          // if (tags.length > 0) Padding(
                          //   padding: EdgeInsets.symmetric(vertical: 10),
                          //   child: Wrap(
                          //     children: List.generate(
                          //       tags.length,
                          //       (index) => Row(
                          //         mainAxisSize: MainAxisSize.min,
                          //         children: [
                          //           Chip(
                          //             label: Text('#${tags[index]}'),
                          //           ),
                          //           Container(width: 5,)
                          //         ],
                          //       )
                          //     ),
                          //   )
                          // ),
                          // Padding(
                          //   padding: EdgeInsets.symmetric(vertical: 10),
                          //   child: TagEditor(
                          //     length: tags.length,
                          //     delimeters: [',', ' ', '.'],
                          //     tagBuilder: (context, index) => Chip(
                          //       labelPadding: const EdgeInsets.only(left: 8.0),
                          //       shape: RoundedRectangleBorder(
                          //         borderRadius: BorderRadius.all(Radius.circular(10))
                          //       ),
                          //       label: Text("#${tags[index]}"),
                          //       deleteIcon: Icon(
                          //         Icons.close,
                          //         size: 18,
                          //       ),
                          //       onDeleted: () {
                          //         try {
                          //           setState(() {
                          //             tags.removeAt(index);
                          //           });
                          //         } catch (e) {
                          //           print('Error occured while removing tag');
                          //           setState(() { });
                          //         }
                          //       },
                          //     ),
                          //     onTagChanged: (tag) {
                          //       _addTag(tag);
                          //     },
                          //     inputDecoration: InputDecoration(
                          //       filled: true,
                          //       labelText: 'Add Tags',
                          //       counterText: 'Add up to $maxTags tags',
                          //     ),
                          //   ),
                          // ),
                          // Padding(
                          //   padding: EdgeInsets.symmetric(vertical: 10),
                          //   child: TagEditor(
                          //     length: people.length,
                          //     delimeters: [',', ' '],
                          //     tagBuilder: (context, index) => Chip(
                          //       labelPadding: const EdgeInsets.only(left: 8.0),
                          //       label: Text("@${peopleDocs[index].data()['username']}"),
                          //       avatar: peopleDocs[index].data()['photoUrl'] != null
                          //       ? ClipOval(
                          //         child: OctoImage(
                          //           image: NetworkImage(peopleDocs[index].data()['photoUrl']),
                          //           progressIndicatorBuilder: (context, progress) => CircularProgressIndicator(),
                          //         ),
                          //       )
                          //       : ClipOval(child: Image.asset('assets/images/avatar.png')),
                          //       deleteIcon: Icon(
                          //         Icons.close,
                          //         size: 18,
                          //       ),
                          //       onDeleted: () {
                          //         setState(() {
                          //           people.removeAt(index);
                          //           peopleDocs.removeAt(index);
                          //         });
                          //       },
                          //     ),
                          //     onTagChanged: (person) {
                          //       _addPerson(person);
                          //     },
                          //     inputDecoration: InputDecoration(
                          //       filled: true,
                          //       labelText: 'Tag People',
                          //       counterText: 'Add up to $maxPeopleTagging people',
                          //       counter: Text('${people.length}/$maxPeopleTagging People'),
                          //     ),
                          //   ),
                          // )
                        ],
                      ),
                    ),
                  ),
                  if (me.isCreatorAccount) ListTile(
                    title: Text('Topic'),
                    subtitle: Text('Add the topic of your post'),
                    trailing: topic != null
                    ? Chip(
                      label: Text(topic),
                      onDeleted: () {
                        setState(() {
                          topic = null;
                        });
                      },
                    )
                    : IconButton(
                      icon: Icon(Icons.add_circle),
                      onPressed: () async {
                        String topicL = await Navigator.of(context).push(RivalNavigator(page: SelectTopic()));
                        if (topicL != null) setState(() {
                          topic = topicL;
                        });
                      },
                    ),
                  ),
                  Divider(),
                  ExpandablePanel(
                    controller: advancedSettingCtrl,
                    collapsed: ListTile(
                      title: Text('Advanced', style: TextStyle(fontFamily: RivalFonts.feature),),
                      trailing: Icon(Icons.keyboard_arrow_down),
                      onTap: () => advancedSettingCtrl.toggle(),
                    ),
                    expanded: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: Text('Advanced', style: TextStyle(fontFamily: RivalFonts.feature),),
                          trailing: Icon(Icons.keyboard_arrow_up),
                          onTap: () => advancedSettingCtrl.toggle(),
                        ),
                        ListTile(
                          title: Text('Enable Comments'),
                          subtitle: Text('Allow other people to comment on your post'),
                          trailing: Switch.adaptive(
                            value: allowComments,
                            onChanged: (bool value) async {
                              RivalProvider.vibrate();
                              setState(() {
                                allowComments = value;
                              });
                            },
                          ),
                        ),
                        ListTile(
                          title: Text('Show Like Count'),
                          subtitle: Text('Disabling like count will not allow others to see who liked your post'),
                          trailing: Switch.adaptive(
                            value: showLikeCount,
                            onChanged: (bool value) async {
                              RivalProvider.vibrate();
                              setState(() {
                                showLikeCount = value;
                              });
                            },
                          ),
                        ),
                        ListTile(
                          title: Text('Age Restricted?'),
                          subtitle: Text('Restricting age will hide your post from people under 18'),
                          trailing: Tooltip(
                            message: (me.age != null && me.age >= 18) ? 'Enable/Disable Age Restriction' : 'You are not qualified to create adult-rated posts',
                            child: Switch.adaptive(
                              value: containsAdultContent,
                              onChanged: (me.age != null && me.age >= 18) ? (bool value) async {
                                RivalProvider.vibrate();
                                setState(() {
                                  containsAdultContent = value;
                                });
                              } : null,
                            ),
                          ),
                        ),
                        if (me.isBusinessAccount) ListTile(
                          title: Text('Promote Product'),
                          subtitle: Text('Does this post promote a product'),
                          trailing: Switch.adaptive(
                            value: isProduct,
                            onChanged: (value) {
                              setState(() {
                                isProduct = value;
                              });
                            },
                          ),
                        ),
                        if (isProduct) ... [
                          Padding(
                            padding: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
                            child: SizedBox(
                              height: 30,
                              width: double.infinity,
                              child: ListView(
                                physics: BouncingScrollPhysics(),
                                scrollDirection: Axis.horizontal,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8, left: 5, right: 10, bottom: 5),
                                    child: Text('Action Button', style: TextStyle(fontFamily: RivalFonts.feature),),
                                  ),
                                  ... List.generate(
                                    actionButtons.length,
                                    (index) => Padding(
                                      padding: const EdgeInsets.only(right: 5),
                                      child: ChoiceChip(
                                        label: Text(actionButtons[index]),
                                        selectedColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.indigoAccent[50] : Colors.white70,
                                        selected: productButtonTitle == actionButtons[index],
                                        onSelected: (value) {
                                          if (value) setState(() {
                                            productButtonTitle = actionButtons[index];
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                            child: Form(
                              key: _urlFormKey,
                              child: TextFormField(
                                decoration: InputDecoration(
                                  filled: true,
                                  border: UnderlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(7)),
                                    borderSide: BorderSide.none
                                  ),
                                  isDense: true,
                                  labelText: 'Add Url',
                                  prefixIcon: Icon(Icons.public),
                                  suffixIcon: (productUrl != null && productUrl != "" && _validateUrl(productUrl) == null) ? Icon(Icons.done, color: Colors.green,) : null
                                ),
                                onFieldSubmitted: (url) {
                                  if (_urlFormKey.currentState.validate()) {
                                    setState(() {
                                      productUrl = url;
                                    });
                                  }
                                },
                                onChanged: (url) {
                                  if (_urlFormKey.currentState.validate()) {
                                    setState(() {
                                      productUrl = url;
                                    });
                                  }
                                },
                                validator: _validateUrl,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                textInputAction: TextInputAction.done,
                              ),
                            ),
                          )
                        ],
                        if (me.isCreatorAccount) ListTile(
                          title: Text('Sponsor'),
                          subtitle: Text('Add the sponsor of your post'),
                          trailing: sponsor != null
                          ? Chip(
                            label: Text(sponsor.username),
                            avatar: ClipOval(
                              child: OctoImage(
                                image: sponsor.photo,
                                placeholderBuilder: (context) => CircularProgressIndicator(),
                              ),
                            ),
                            onDeleted: () {
                              setState(() {
                                sponsor = null;
                              });
                            },
                          )
                          : IconButton(
                            icon: Icon(Icons.add_circle),
                            onPressed: () async {
                              RivalUser spL = await Navigator.of(context).push(RivalNavigator(page: SelectSponsor()));
                              if (spL != null) setState(() {
                                sponsor = spL;
                              });
                            }
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(),
                  Padding(
                    padding: EdgeInsets.fromLTRB(10, 10, 10, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: FlatButton(
                            child: Text('Save as draft'),
                            onPressed: () {
                            },
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: OutlineButton(
                            child: Text('Post'),
                            onPressed: () {
                              _post();
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
        : Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                height: 100,
                width: 100,
                child: LiquidCircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.indigoAccent),
                  backgroundColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.white12,
                ),
              ),
              Container(height: 20,),
              // OutlineButton(
              //   child: Text('Cancel'),
              //   onPressed: () {
              //     setState(() {
              //       isPostBeingCreated = false;
              //       isLoading = false;
              //     });
              //   },
              // ),
              Text(loadingState != null ? loadingState : '...', style: TextStyle(fontFamily: RivalFonts.feature, fontSize: 20),)
            ],
          )
        ),
      )
    );
  }

  String _validateUrl(url) {
    String pattern = RivalRegex.url;
    RegExp regex = new RegExp(pattern);
    if (!regex.hasMatch(url)) {
      return 'Invalid Url';
    } else {
      return null;
    }
  }

  // ignore: unused_element
  void _addTag(String tg) {
    String tag = tg.replaceAll(new RegExp(RivalRegex.specialChars),'');
    String pattern = RivalRegex.tag;
    RegExp regex = new RegExp(pattern);
    if (!regex.hasMatch(tag)) {
      RivalProvider.showToast(
        text: 'Unable to add tag',
      );
    } else if (tags.length >= maxTags) {
      RivalProvider.showToast(
        text: 'Max $maxTags tags',
      );
    } else if (tags.contains(tag)) {
      RivalProvider.showToast(
        text: 'Already added',
      );
    } else if (tags.length < maxTags) {
      setState(() {
        tags.add(tag);
      });
    }
  }

  // ignore: unused_element
  _addPerson(person) async {
    if (people.length < maxPeopleTagging) {
      setState(() {
        isLoadingX = true;
        title = 'Adding $person...';
      });

      String username;

      if (person.trim().toLowerCase().toString().startsWith('@')) {
        username = person.trim().toLowerCase().toString().replaceAll('@', '');
      } else {
        username = person.trim().toLowerCase();
      }

      List<String> peopleDocIds = [];  
      for (var personDoc in peopleDocs) {
        peopleDocIds.add(personDoc.id);
      }

      RivalUser user = await RivalProvider.getUserByUsername(username);
      DocumentSnapshot personDoc = user?.snapshot;
      
      if (personDoc != null){

        if (peopleDocIds.contains(personDoc.id)) {
          // Person already added
          _scaffoldKey.currentState.showSnackBar(new SnackBar(content: Text('@$username already added')));
        } else if (personDoc.id== me.user.uid) {
          _scaffoldKey.currentState.showSnackBar(new SnackBar(content: Text('Cannot tag yourself')));
        } else {
          // Add the person
          // Check if the account is private or if the person has blocked user
          if (personDoc.data()['private'] && !user.isFollowing) {
            // Account Private
            _scaffoldKey.currentState.showSnackBar(new SnackBar(content: Text('Follow @${person.toString().toLowerCase().trim()} to tag in your post')));
          } else if (user.amIBlocked) {
            // Person has blocked user
            _scaffoldKey.currentState.showSnackBar(new SnackBar(content: Text('Could not add @${person.toString().toLowerCase().trim()}')));
          } else {
            // Add the person
            setState(() {
              people.add(personDoc.reference);
              peopleDocs.add(personDoc);
            });
          }
        }
      } else if (personDoc == null) {
        // No user found with username `$person`
        _scaffoldKey.currentState.showSnackBar(new SnackBar(content: Text('No user found with username @$username')));
      }
      setState(() {
        title = "Create Post";
        isLoadingX = false;
      });
    } else if (people.length >= maxPeopleTagging) {
      _scaffoldKey.currentState.showSnackBar(new SnackBar(content: Text('Max $maxPeopleTagging people')));
    }
  }

  Future<void> _selectImage(int index, {File file}) async {
    File pickedFile;
    RivalProvider.vibrate();
    if (file == null) pickedFile = await _pickImage();
    else pickedFile = file;
    if (pickedFile != null) {
      File croppedFile = await _cropImage(file: pickedFile);
      if (croppedFile != null) {
        _parseAndFinalizeImage(file: croppedFile, index: index);
      }
    }
  }

  Future<File> _pickImage({ImageSource source = ImageSource.gallery}) async {
    PickedFile pickedFile = await ImagePicker().getImage(source: source);
    if (pickedFile != null) {
      return File(pickedFile.path);
    } else {
      return null;
    }
  }

  Future<File> _cropImage({@required File file}) async {
    File croppedFile;
    AndroidUiSettings uiSettings = AndroidUiSettings(
      backgroundColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.white : Colors.black,
      cropFrameColor: Colors.indigo,
      activeControlsWidgetColor: Colors.indigo,
      toolbarColor: Colors.indigoAccent,
      statusBarColor: Colors.indigo,
      toolbarTitle: 'Crop Image',
      lockAspectRatio: images.length > 0,
    );
    croppedFile = await ImageCropper.cropImage(sourcePath: file.path, aspectRatio: CropAspectRatio(ratioY: ratio['height'], ratioX: ratio['width']), androidUiSettings: uiSettings, compressQuality: 100);
    return croppedFile;
  }

  Future<void> _parseAndFinalizeImage({@required File file, @required int index}) async {
    ImageProperties properties = await FlutterNativeImage.getImageProperties(file.path);
    if (index == 0 && mounted) {
      setState(() {
        ratio['height'] = properties.height.toDouble();
        ratio['width'] = properties.width.toDouble();
      });
    }
    File finalImage = file;
    if (index < 9) images.add(finalImage);                        // Replace image if already exists else
    else if (index == 9) images.insert(9, finalImage);            // Check no of images and set state
    else print('Unknown condition');                              // Minimal if-elseif-else statement
    if (mounted) setState(() {});
    FirebaseVisionImage visionImage = FirebaseVisionImage.fromFile(finalImage); // Load FirebaseVision lib
    try { // Try labelling the image using Firebase Offline ML Kit
      List<ImageLabel> localLabels = await labeler.processImage(visionImage);  // Start processing the images
      localLabels.forEach((label) {
        double reqConfidenceLevel = 0.75; // Change CONFIDENCE level here
        if (label.confidence > reqConfidenceLevel) {
          if (!labels.contains(label.text.toLowerCase())) labels.add(label.text.toLowerCase()); // Add all confident and unique labels to list
        }
      });
    } catch (e) {
      print("## Error in Labelling images: $e");
    }
    try {
      final VisionText visionText = await textRecognizer.processImage(visionImage);
      String text = visionText.text.replaceAll('\n', ' ');
      ocrText.add(text);
      print("OCR: $ocrText");
    } catch (e) {
      print('Error in Scanning text from image');
    }
  }

  Future<void> _post() async {

    RivalProvider.vibrate();

    setState(() {
      isLoading = true;
      title = 'Creating Post';
      loadingState = "Building Post";
    });
    
    if (!me.user.emailVerified) {
      SnackBar snackbar = SnackBar(content: Text('Please verify your email to create a new post'));
      _scaffoldKey.currentState.showSnackBar(snackbar);
    } else if (me.username == null) {
      SnackBar snackbar = SnackBar(content: Text('Your account does not have a username'));
      _scaffoldKey.currentState.showSnackBar(snackbar);
    } else if (!(await checkInternetConnectivity())) {
      SnackBar snackbar = SnackBar(content: Text('No Internet Connection'));
      _scaffoldKey.currentState.showSnackBar(snackbar);
    } else if (me.user.emailVerified && me.username != null && me.username != '' && (me.uid == "EQs5vlC8U1XWqJxdR3dHPgUrx413" || RivalRemoteConfig.allowNewPost) && await checkInternetConnectivity() && !isPostBeingCreated) {
      isPostBeingCreated = true;
      if (images.length > 0) {

        List<String> keywords = [
          me.username.toLowerCase()
        ]; // Add a few keywords to make the post searchable.
        
        tags.addAll(_descriptionCtrl.text.replaceAll(new RegExp(RivalRegex.specialChars), '').replaceAll('\n', ' ').replaceAll('.', '').toLowerCase().split(' '));
        tags = tags.toSet().toList(); // Removes all duplicate values

        List<String> mentions = [];
        for (String username in _descriptionCtrl.text.replaceAll(new RegExp(RivalRegex.specialChars), '').replaceAll('\n', ' ').toLowerCase().split(' ')) {
          if (RegExp(RivalRegex.username).hasMatch(username)) mentions.add(username.replaceAll('@', ''));
        }

        Post postAfter = await post(
          allowComments: allowComments,
          btnTitle: productButtonTitle,
          containsAdultContent: containsAdultContent,
          description: _descriptionCtrl.text,
          geoPoint: geoPoint,
          images: images,
          labels: labels,
          location: locationText,
          ocr: ocrText,
          people: people,
          showLikeCount: showLikeCount,
          size: Size(ratio['width'], ratio['height']),
          sponsor: sponsor,
          subtitle: _subtitleCtrl.text,
          keywords: keywords,
          topic: topic,
          mentions: mentions
        );
        
        if (topic != null) await firestore.collection('rival').doc('topics').update({
          topic: FieldValue.arrayUnion([postAfter.id])
        });

        // Add all tags to this week's top list
        DocumentSnapshot topTagsDoc = await firestore.collection('rival').doc('tags').get();
        Map topTagsMap = topTagsDoc.data()[RivalProvider.weekOfYear.toString()] ?? {};
        
        for (String tag in tags) {
          if (topTagsMap.containsKey(tag)) {
            await topTagsDoc.reference.update({
              '${RivalProvider.weekOfYear}.$tag': FieldValue.increment(1)
            });
          } else {
            await topTagsDoc.reference.update({
              '${RivalProvider.weekOfYear}.$tag': 1
            });
          }
        }
        
        // Add this post to our homescreen
        List<Post> timelineL = timeline.reversed.toList();
        timelineL.add(postAfter);
        timeline = timelineL.reversed.toList();

        // Add this post to my posts in profile page if it is loaded
        if (myPosts != null) {
          List<Post> myPostsL = myPosts.reversed.toList();
          myPostsL.add(postAfter);
          myPosts = myPostsL.reversed.toList();
        }

        RivalProvider.vibrate();

        RivalProvider.showToast(text: 'Post Created');
        isPostBeingCreated = false;
        
        if (this.mounted) { // `mounted` is used to check if user has pressed back button while the post is being uploaded.
          setState(() {
            isLoading = false;
          });
          Navigator.pushAndRemoveUntil(context, RivalNavigator(page: Home(), ), (route) => false);
        }
      }
    } else if (me.uid != "EQs5vlC8U1XWqJxdR3dHPgUrx413" && !RivalRemoteConfig.allowNewPost) {
      showDialog(
        context: context,
        child: AlertDialog(
          title: Text('New Post Disabled'),
          content: Text('Sorry for inconvenience, but we have disabled new posts for a limited time. Please try again later.'),
          actions: [
            FlatButton(
              onPressed: () {
                Navigator.of(context).maybePop();
                Navigator.of(context).pushAndRemoveUntil(RivalNavigator(page: Home(),), (route) => false);
              },
              child: Text('Done')
            )
          ],
        )
      );
    } else if (isPostBeingCreated) {
      showDialog(
        context: context,
        child: AlertDialog(
          title: Text('Alert'),
          content: Text('A post is already being created. Please wait for it finish'),
          actions: [
            FlatButton(
              onPressed: () {
                Navigator.of(context).maybePop();
                Navigator.of(context).pushAndRemoveUntil(RivalNavigator(page: Home(),), (route) => false);
              },
              child: Text('Ok')
            )
          ],
        )
      );
    }

    if (this.mounted) setState(() {
      isLoading = false;
      title = 'Create Post';
      loadingState = null;
    });

  }

  Future<Post> post({
    @required List<File> images,
    @required String description,
    @required String subtitle,
    @required GeoPoint geoPoint,
    @required String location,
    @required bool allowComments,
    @required bool containsAdultContent,
    @required Size size,
    @required List labels,
    @required bool showLikeCount,
    @required List<DocumentReference> people,
    @required List<String> ocr,
    @required String btnTitle,
    @required RivalUser sponsor,
    @required List<String> keywords,
    @required String topic,
    @required List<String> mentions
  }) async {
    Post post;

    String postId = await getPostUid(); // Get a new id for post
    DocumentReference ref = firestore.collection('posts').doc(postId); // Create a reference to that post location

    List<String> imageUrls = [];
    //List blurHashes = [];

    for (File image in images) {
      var time = DateTime.now().toString();
      // Makes the app slower
      // Uint8List filePixels = file.readAsBytesSync();
      // var blurhash = await BlurHash.encode(filePixels, 9, 9);
      // print(blurhash);
      // blurHashes.add(blurhash);
      String imageUrl = await (await FirebaseStorage.instance.ref().child('posts').child("IMG-$postId-${time.replaceAll(new RegExp(r"\s+"), "")}").putFile(image).onComplete).ref.getDownloadURL();
      imageUrls.add(imageUrl);
      setState(() {
        loadingState = loadingState + ".";
      });
    }

    setState(() {
      loadingState = 'Finishing up...';
    });

    int timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;

    String shareableUrl = (await createDynamicURL(link: 'https://rival.photography/post/$postId', title: '@${me.username} | Rival | Post', description: '${_descriptionCtrl.text}\nA Post by @${me.username}')) ?? 'Post ID: $postId';

    await ref.set({
      'id': postId,
      'ratio': size.aspectRatio,
      'size': {
        'width': size.width,
        'height': size.height
      },
      'images': imageUrls,
      'labels': labels,
      'ocr': ocr,
      'people': people,
      //'blurhashes': blurHashes,
      'subtitle': subtitle,
      'description': description,
      'timestamp': timestamp,
      'keywords': keywords,
      'tags': tags,
      'mentions': mentions,
      'showLikeCount': showLikeCount,
      'likes': {},
      'allowComments': allowComments,
      'adult-rated': containsAdultContent,
      'comments': {},
      'edited': null,
      'reach': {},
      'shares': {},
      'impressions': {},
      'profile_visits': {},
      'creator': me.uid,
      'user': me.reference,
      'promoted': false,
      'sponsor': sponsor?.reference,
      'isProduct': isProduct,
      'productUrl': productUrl,
      'productTitle': btnTitle,
      'geoPoint': geoPoint,
      'locationPlaceholder': location,
      'available': true,
      'takenDown': false,
      'shareableUrl': shareableUrl,
      'topic': topic
    },);

    await me.update({
      'posts': FieldValue.arrayUnion([ref])
    });

    post = await getPost(ref.id);

    return post;
  }

}

Future<String> getPostUid() async {
  String uid = generatePostUid();
  if ((await firestore.collection('post').doc(uid).get()).exists) {
    return generatePostUid();
  } else {
    return uid;
  }
}

String generatePostUid() {
  int one = Random().nextInt(62);
  int two = Random().nextInt(62);
  int three = Random().nextInt(62);
  int four = Random().nextInt(62);
  int five = Random().nextInt(62);
  int six = Random().nextInt(62);
  String random = '${postRandomList[one]}${postRandomList[two]}${postRandomList[three]}${postRandomList[four]}${postRandomList[five]}${postRandomList[six]}';
  return random;
}

final List<String> postRandomList = [
  'A',
  'B',
  'C',
  'D',
  'E',
  'F',
  'G',
  'H',
  'I',
  'J',
  'K',
  'L',
  'M',
  'N',
  'O',
  'P',
  'Q',
  'R',
  'S',
  'T',
  'U',
  'V',
  'W',
  'X',
  'Y',
  'Z',
  'a',
  'b',
  'c',
  'd',
  'e',
  'f',
  'g',
  'h',
  'i',
  'j',
  'k',
  'l',
  'm',
  'n',
  'o',
  'p',
  'q',
  'r',
  's',
  't',
  'u',
  'v',
  'w',
  'x',
  'y',
  'z',
  '0',
  '1',
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
];

class RichTextController extends TextEditingController {
  final Map<RegExp, TextStyle> patternMap;
  final Function(List<String> match) onMatch;
  RichTextController(this.patternMap, {this.onMatch})
      : assert(patternMap != null);

  @override
  TextSpan buildTextSpan({TextStyle style, bool withComposing}) {
    List<TextSpan> children = [];
    List<String> matches = [];
    RegExp allRegex;
    allRegex = RegExp(patternMap.keys.map((e) => e.pattern).join('|'));

    text.splitMapJoin(
      allRegex,
      onMatch: (Match m) {
        RegExp k = patternMap.entries.singleWhere((element) {
          return element.key.allMatches(m[0]).isNotEmpty;
        }).key;
        children.add(
          TextSpan(
            text: m[0],
            style: patternMap[k],
          ),
        );
        if (!matches.contains(m[0])) {
          matches.add(m[0]);
          return this.onMatch(matches);
        }
        return m[0];
      },
      onNonMatch: (String span) {
        children.add(TextSpan(text: span, style: style));
        return span.toString();
      },
    );
    return TextSpan(style: style, children: children);
  }
}