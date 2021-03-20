import 'package:cached_network_image/cached_network_image.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
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
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  final ExpandableController advancedSettingCtrl = ExpandableController();

  String title = "Post";
  bool isLoading = true;
  String loadingState = "Getting Your Post...";

  bool allowComments = true;
  bool showLikeCount = true;

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
    showLikeCount = post.showLikeCount;
    allowComments = post.allowComments;
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
              itemCount: post.items.length,
              itemBuilder: (context, index) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (post.items[index].type == PostType.image) ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      child: OctoImage(
                        image: CachedNetworkImageProvider(post.items[index].url),
                        placeholderBuilder: (context) => Container(
                          color: MediaQuery.of(context).platformBrightness == Brightness.dark ? Colors.white12 : Colors.white12,
                          child: Center(
                            child: Container(
                              height: 50,
                              width: 50,
                              child: CustomProgressIndicator(strokeWidth: 2,),
                            ),
                          ),
                        ),
                        width: MediaQuery.of(context).size.width - 20,
                        height: (MediaQuery.of(context).size.width - 20) / post.ratio,
                      ),
                    ) else Container(

                    )
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
                  ),
                ),
                ExpandablePanel(
                  controller: advancedSettingCtrl,
                  collapsed: ListTile(
                    title: Text(
                      'Advanced',
                      style: TextStyle(fontFamily: RivalFonts.feature),
                    ),
                    trailing: Icon(Icons.keyboard_arrow_down),
                    onTap: () => advancedSettingCtrl.toggle(),
                  ),
                  expanded: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: Text(
                          'Advanced',
                          style: TextStyle(fontFamily: RivalFonts.feature),
                        ),
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
                            if (post.allowComments && !value) await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Disable Comments'),
                                content: Text('New comments will be disabled but existing comments on your post will be visible.'),
                                actions: [
                                  TextButton(
                                    child: Text('Ok'),
                                    onPressed: Navigator.of(context).pop,
                                  )
                                ],
                              )
                            );
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
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(10, 10, 10, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: TextButton(
                    child: Text('Delete Post'),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Delete Post?'),
                        content: Text('Are you sure you want to delete this post. This action cannot be reversed. Continue?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _deletePost();
                            },
                            child: Text('Delete'),
                          ),
                          TextButton(
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
                  child: OutlinedButton(
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
              child: CustomProgressIndicator(),
            ),
            Container(height: 20,),
            Text(loadingState ?? "...", style: TextStyle(fontFamily: RivalFonts.feature, fontSize: 20),)
          ],
        )
      )
    );
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
      int timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
      await analytics.logEvent(name: 'edited_post');
      await post.reference.update({
        'geoPoint': geoPoint,
        'locationPlaceholder': locationText,
        'subtitle': subtitle,
        'description': description,
        'edited': timestamp,
        'allowComments': allowComments,
        'showLikeCount': showLikeCount
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

      feed[feed.indexWhere((element) => element.id == post.id)] = postUpdated;

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
    setState(() {
      loadingState = "Deleting Post";
      isLoading = true;
    });
    // Delete post
    if (feed != null) feed.removeWhere((postT) => postT == post); // Remove POST from Home Screen
    if (myPosts != null) myPosts.removeWhere((postL) => postL.id == post.id);
    await me.update({
      'posts': FieldValue.arrayRemove([post.reference])
    }, reload: true);
    List<PostItem> items = post.items.where((item) => item.type == PostType.image).toList();
    items.forEach((item) async {
      String url = item.url;
      StorageReference imageRef = await FirebaseStorage.instance.getReferenceFromUrl(url);
      imageRef.delete();
    });
    for (DocumentReference ref in post.comments.values.toList()) {
      await ref.delete();
    }
    await post.reference.delete();
    await RivalProvider.showToast(text: 'Post Deleted',);
    setState(() {
      isLoading = false;
      loadingState = null;
    });
    Navigator.of(context).pushAndRemoveUntil(RivalNavigator(page: Home(),), (route) => false);
  }

}