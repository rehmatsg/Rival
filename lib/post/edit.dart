import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:material_tag_editor/tag_editor.dart';
import 'package:octo_image/octo_image.dart';
import '../app.dart';

class EditPost extends StatefulWidget {
  EditPost({Key key, @required this.post}) : super(key: key);
  final Post post;

  @override
  _EditPostState createState() => _EditPostState();
}

class _EditPostState extends State<EditPost> {

  TextEditingController _descriptionCtrl = TextEditingController();
  TextEditingController _subtitleCtrl = TextEditingController();
  final FirebaseAnalytics analytics = FirebaseAnalytics();
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  String title = "Post";
  bool isLoadingX = false;
  bool isLoading = true;
  String loadingState = "Getting Your Post...";

  List tags = [];
    
  List<DocumentReference> people = [];
  List<DocumentSnapshot> peopleDocs = [];

  String locationText;
  GeoPoint geoPoint;

  Post post;

  Widget locationSelector;

  @override
  void initState() {
    post = widget.post;
    if (post.geoPoint != null) {
      geoPoint = post.geoPoint;
      locationText = post.location;
    }
    locationSelector = LocationSelector(onLocationSelect: (geoPointL, feature) {
      setState(() {
        geoPoint = geoPointL;
        locationText = feature;
      });
    }, selectedLocation: post.location,);
    _init();
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  _init() async {
    if (post.subtitle != null && post.subtitle != "") _subtitleCtrl.text = post.subtitle;
    if (post.description != null && post.description != "") _descriptionCtrl.text = post.description;
    if (post.tags != null && post.tags.length > 0) tags = post.tags;
    if (post.people != null && post.people.length > 0) {
      List postDocPeople = post.people;
      for (var personRef in postDocPeople) {
        people.add(personRef);
        peopleDocs.add(await personRef.get());
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[
          Visibility(
            visible: (isLoading || isLoadingX) ? false : true,
            child: FlatButton(
              child: Text(
                'SAVE',
                style: TextStyle(color: Colors.indigo),
              ),
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  _save();
                }
              },
            )
          ),
          Visibility(
            visible: isLoadingX ? true : false,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              child: Container(
                width: 25,
                height: 15,
                child: CircularProgressIndicator(),
              ),
            )
          )
        ],
      ),
      body: (isLoading == false)
      ? ListView(
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20, left: 15, right: 15, bottom: 15),
                child: Text('Edit', style: TextStyle(fontSize: Theme.of(context).textTheme.headline3.fontSize, fontFamily: RivalFonts.feature),),
              ),
            ],
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width ,
            height: MediaQuery.of(context).size.width / post.ratio,
            child: PageView.builder(
              physics: BouncingScrollPhysics(),
              itemCount: post.images.length,
              itemBuilder: (context, index) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      child: OctoImage(
                        image: NetworkImage(post.images[index]),
                        placeholderBuilder: (context) => Container(
                          color: MediaQuery.of(context).platformBrightness == Brightness.dark ? Colors.white12 : Colors.white12,
                          child: Center(
                            child: Container(
                              height: 50,
                              width: 50,
                              child: CircularProgressIndicator(strokeWidth: 2,),
                            ),
                          ),
                        ),
                        width: MediaQuery.of(context).size.width - 20,
                        height: (MediaQuery.of(context).size.width - 20) / post.ratio,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Container(height: 10,),
          Divider(),
          Form(
            key: _formKey,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: locationSelector
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: TextFormField(
                    controller: _subtitleCtrl,
                    validator: subtitleValidator,
                    decoration: InputDecoration(
                      filled: true,
                      labelText: 'Subtitle',
                      helperText: geoPoint != null ? 'Location will be used as subtitle' : null
                    ),
                    readOnly: geoPoint != null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: TextFormField(
                    controller: _descriptionCtrl,
                    decoration: InputDecoration(
                      filled: true,
                      labelText: 'Description',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                    minLines: 3,
                    maxLines: 7,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(500),
                    ],
                    validator: descriptionValidator,
                    onChanged: (desc) {
                      if (desc.endsWith(' ') || desc.endsWith('.')) {
                        List<String> descList = desc.split(' ');
                        tags.clear();
                        descList.forEach((word) {
                          if (word.startsWith('#') && word.length > 1) {
                            if (word.endsWith('.')) {
                              _addTag(word.substring(1, word.length - 1));
                            } else {
                              _addTag(word.substring(1, word.length));
                            }
                          }
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: TagEditor(
              length: peopleDocs.length,
              delimeters: [',', ' '],
              tagBuilder: (context, index) {
                RivalUser user = RivalUser(doc: peopleDocs[index]);
                return Chip(
                  labelPadding: const EdgeInsets.only(left: 8.0),
                  avatar: ClipOval(
                    child: OctoImage(
                      image: user.photo,
                      placeholderBuilder: (context) => CircularProgressIndicator(),
                    ),
                  ),
                  label: Text("@${user.username}"),
                  deleteIcon: Icon(
                    Icons.close,
                    size: 18,
                  ),
                  onDeleted: () {
                    setState(() {
                      people.removeAt(index);
                      peopleDocs.removeAt(index);
                    });
                  },
                );
              },
              onTagChanged: (person) {
                _addPerson(person);
              },
              inputDecoration: InputDecoration(
                filled: true,
                labelText: 'Tag People',
                counterText: 'Add up to 10 people',
                counter: Text('${people.length}/10 People'),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(10, 10, 10, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: FlatButton(
                    child: Text('Delete Post'),
                    onPressed: () => showDialog(
                      context: context,
                      child: AlertDialog(
                        title: Text('Delete Post?'),
                        content: Text('Are you sure you want to delete this post. You won\'t be able to recover it. Continue?'),
                        actions: [
                          FlatButton(
                            onPressed: _deletePost,
                            child: Text('Delete'),
                          ),
                          FlatButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('Cancel'),
                          )
                        ],
                      )
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: OutlineButton(
                    child: Text('Save Changes'),
                    onPressed: _save,
                  ),
                )
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
              child: CircularProgressIndicator(),
            ),
            Container(height: 20,),
            Text(loadingState ?? "...", style: TextStyle(fontFamily: RivalFonts.feature, fontSize: 20),)
          ],
        )
      )
    );
  }

  _addTag(tag) async {
    if (tags.length < 10 && !tags.contains(tag)) {
      setState(() {
        tags.add(tag);
      });
    } else if (!tags.contains(tag) && tags.length >= 10) {
      await RivalProvider.showToast(
        text: 'Max 10 tags',
      );
    }
  }

  _addPerson(person) async {
    if (people.length < 10) {
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
      DocumentSnapshot personDoc = user.snapshot;
      
      if (personDoc != null){

        if (peopleDocIds.contains(personDoc.id)) {
          // Person already added
          _scaffoldKey.currentState.showSnackBar(new SnackBar(content: Text('@$username already added')));
          setState(() {
            isLoadingX = false;
            title = "Post";
          });
        } else if (personDoc.id== me.user.uid) {
          _scaffoldKey.currentState.showSnackBar(new SnackBar(content: Text('Cannot tag yourself')));
          setState(() {
            isLoadingX = false;
            title = "Post";
          });
        } else {
          // Add the person
          // Check if the account is private or if the person has blocked user
          if (personDoc.data()['private'] && !user.isFollowing) {
            // Account Private
            _scaffoldKey.currentState.showSnackBar(new SnackBar(content: Text('Follow @${person.toString().toLowerCase().trim()} to tag in your post')));
            setState(() {
              isLoadingX = false;
              title = "Post";
            });
          } else if (personDoc.data()['blocked'] != null && personDoc.data()['blocked'].contains(me.uid)) {
            // Person has blocked user
            _scaffoldKey.currentState.showSnackBar(new SnackBar(content: Text('Could not add @${person.toString().toLowerCase().trim()}')));
            setState(() {
              isLoadingX = false;
              title = "Post";
            });
          } else {
            // Add the person
            setState(() {
              people.add(personDoc.reference);
              peopleDocs.add(personDoc);
              isLoadingX = false;
              title = "Post";
            });
          }
        }
      } else if (personDoc == null) {
        // No user found with username `$person`
        setState(() {
          title = "Post";
          isLoadingX = false;
        });
        _scaffoldKey.currentState.showSnackBar(new SnackBar(content: Text('No user found with username @$username')));
      }
    } else if (people.length >= 10) {
      _scaffoldKey.currentState.showSnackBar(new SnackBar(content: Text('Max 10 people')));
    }
  }

  _save() async {
    if (post.userId != me.uid) Navigator.of(context).pop();
    String subtitle = _subtitleCtrl.text.trim();
    String description = _descriptionCtrl.text.trim();

    setState(() {
      isLoading = true;
      loadingState = "Updating...";
    });
    DocumentSnapshot myDoc = await firestore.collection('users').doc(me.uid).get();

    if (subtitle != null && description != null && me.user.emailVerified && myDoc.data()['username'] != null) {
      List keywords = [myDoc.data()['username']];
      tags.forEach((tag) {
        keywords.add(tag.trim().toLowerCase());
      });
      var time = DateTime.now().toUtc().millisecondsSinceEpoch;
      await analytics.logEvent(name: 'edited_post');
      await post.reference.update({
        'geoPoint': geoPoint,
        'locationPlaceholder': locationText,
        'subtitle': subtitle,
        'description': description,
        'people': people,
        'keywords': keywords,
        'edited': time
      });
      Post postUpdated = await Post.fetch(ref: post.reference);

      // int myPostIndex = myPosts.indexWhere((mpost) => mpost.id == post.id);
      // if (myPostIndex >= 0) {
      //   myPosts[myPostIndex] = postUpdated; // Updated Post value after editing complete
      // }
      // No Need as we have implemented Provider method that automatically updated with new data

      // int postItemsIndex = postItems.indexWhere((w) {
      //   ObjectKey key = w.key;
      //   return key.value == post.id;
      // });
      // if (postItemsIndex >= 0) {
      //   postItems[postItemsIndex] = PostView(post: postUpdated, key: ObjectKey(post.id), cardMargin: EdgeInsets.symmetric(vertical: 5),);
      // }

      timeline[timeline.indexWhere((element) => element.id == post.id)] = postUpdated;

      setState(() {
        isLoading = false;
      });
      await RivalProvider.showToast(
        text: 'Post updated',
      );
      Navigator.of(context).pushAndRemoveUntil(RivalNavigator(page: Home(),), (route) => false);
    } else setState(() {
      isLoading = false;
      loadingState = null;
    });
  }

  _deletePost() async {
    Navigator.of(context).pop();
    setState(() {
      loadingState = "Deleting Post";
      isLoading = true;
    });
    DocumentSnapshot myDoc = await firestore.collection('users').doc(me.uid).get();
    if (myDoc.data()['username'] != null && me.user.emailVerified) {
      // Delete post
      timeline.removeWhere((postT) => postT == post); // Remove POST from Home Screen
      if (myPosts != null) {
        myPosts.removeWhere((postL) => postL.id == post.id);
      }
      await myDoc.reference .update({
        'posts': FieldValue.arrayRemove([post.reference])
      });
      List images = post.images;
      images.forEach((image) async {
        StorageReference imageRef = await FirebaseStorage.instance.getReferenceFromUrl(image);
        imageRef.delete();
      });
      QuerySnapshot commentsQuery = await firestore.collection('comments').where('postId', isEqualTo: post.id).get();
      commentsQuery.docs.forEach((commentDoc) async => await commentDoc.reference.delete());
      await post.reference.delete();
      await me.reload();
      await RivalProvider.showToast(
        text: 'Your post has been deleted',
      );
      setState(() {
        isLoading = false;
        loadingState = null;
      });
      Navigator.of(context).pushAndRemoveUntil(RivalNavigator(page: Home(),), (route) => false);
    } else setState(() {
      isLoading = false;
      loadingState = null;
    });
  }

}