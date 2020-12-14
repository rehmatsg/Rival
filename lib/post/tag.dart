import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:octo_image/octo_image.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../app.dart';

class PostsByTag extends StatefulWidget {
  
  final String tag;

  const PostsByTag({Key key, this.tag}) : super(key: key);

  @override
  _PostsByTagState createState() => _PostsByTagState();
}

class _PostsByTagState extends State<PostsByTag> {

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  String tag;

  List<Post> posts;

  int postsPerPage = 21;
  bool isNextPageLoading = false;
  bool postsAvailable = true;

  bool isLoading = true;
  bool isSubsLoading = false;

  @override
  void initState() {
    tag = widget.tag.replaceAll('#', '').replaceAll('.', '');
    getPostsByTag();
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Future<void> getPostsByTag() async {
    QuerySnapshot querySnapshot = await firestore.collection('posts').where('keywords', arrayContains: tag.toLowerCase()).limit(postsPerPage).get(); // Tags are kept in lower-case in field `tags`. Not valid for previous posts! All new Posts support this
    posts = [];
    for (DocumentSnapshot d in querySnapshot.docs) {
      Post post = await Post.fetch(doc: d);
      RivalUser user = await getUser(post.userId);
      if (((user.private && user.isFollowing) || !user.private || user.uid == me.uid) && post.available && !post.takenDown) {
        posts.add(post);
      }
    }
    setState(() {
      isLoading = false;
      if (posts.isEmpty) postsAvailable = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Tags'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              child: ListTile(
                leading: (topTags.keys.contains(tag.toLowerCase()) && topTags.keys.toList().indexOf(tag.toLowerCase()) <= 10) ?
                  Tooltip(
                    message: '#${topTags.keys.toList().indexOf(tag.toLowerCase()) + 1} at trending',
                    child: CircleAvatar(
                      backgroundColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.indigo[100] : Colors.indigo[900],
                      child: Center(
                        child: Text("#${topTags.keys.toList().indexOf(tag.toLowerCase()) + 1}", style: TextStyle(fontFamily: RivalFonts.feature),),
                      ),
                    ),
                  )
                  : null,
                title: Text('#$tag', style: TextStyle(fontFamily: RivalFonts.feature),),
                trailing: FlatButton(
                  color: isSubsLoading ? (MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[100] : Colors.white10) : Colors.indigoAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10))
                  ),
                  child: isSubsLoading ? Container(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2,)) : Text(me.tagsSubscribed.contains(tag.toLowerCase().trim()) ? 'Unsubscribe' : 'Subscribe', style: TextStyle(color: Colors.white),),
                  onPressed: () async {
                    setState(() {
                      isSubsLoading = true;
                    });
                    await me.update({
                      'tagsSubscribed': me.tagsSubscribed.contains(tag.toLowerCase().trim()) ? FieldValue.arrayRemove([tag.toLowerCase().trim()]) : FieldValue.arrayUnion([tag.toLowerCase().trim()])
                    });
                    await me.reload();
                    SnackBar snackBar;
                    if (me.tagsSubscribed.contains(tag.toLowerCase().trim())) {
                      await FirebaseMessaging().subscribeToTopic(tag.toLowerCase().trim());
                      snackBar = SnackBar(content: Text('Subscribed to #$tag'));
                    } else {
                      await FirebaseMessaging().unsubscribeFromTopic(tag.toLowerCase().trim());
                      snackBar = SnackBar(content: Text('Unsubscribed from #$tag'));
                    }
                    _scaffoldKey.currentState.showSnackBar(snackBar);
                    setState(() {
                      isSubsLoading = false;
                    });
                  },
                  onLongPress: () => showDialog(
                    context: context,
                    child: AlertDialog(
                      title: Text('Subscribe to #$tag'),
                      content: Text('When you subscribe to a tag, you\'ll recieve a notification whenever a new post contains #$tag'),
                      actions: [
                        FlatButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Ok'),
                        )
                      ],
                    )
                  ),
                ),
              ),
            ),
          ),
          SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) => Container(
                color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[100] : Colors.grey[900],
                width: (MediaQuery.of(context).size.width / 3) - 6,
                height: (MediaQuery.of(context).size.width / 3) - 6,
                child: !isLoading ? GestureDetector(
                  child: OctoImage(
                    image: NetworkImage(posts[index].images[0]),
                    fit: BoxFit.cover,
                  ),
                  onTap: () => Navigator.of(context).push(RivalNavigator(page: SinglePostView(post: posts[index]),)),
                ) : null,
              ),
              childCount: isLoading ? 12 : posts.length
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 1,
              mainAxisSpacing: 1
            )
          ),
          if (!isLoading) SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (postsAvailable) ... [
                  if (isNextPageLoading) Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2,),
                    )
                  ) else VisibilityDetector(
                    key: UniqueKey(),
                    onVisibilityChanged: (info) {
                      if (info.visibleFraction == 1) _nextPage();
                    },
                    child: IconButton(
                      tooltip: 'Load More Posts',
                      onPressed: () async {
                        _nextPage();
                      },
                      icon: Icon(Icons.add),
                    ),
                  ),
                ] else ... [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Divider(),
                  )
                ]
              ]
            ),
          )
        ],
      ),
    );
  }
  
  Future<void> _nextPage() async {
    setState(() {
      isNextPageLoading = true;
    });
    QuerySnapshot querySnapshot = await firestore.collection('posts').where('keywords', arrayContains: tag.toLowerCase()).limit(postsPerPage).startAfterDocument(posts.last.doc).get(); // Tags are kept in lower-case in field `tags`. Not valid for previous posts! All new Posts support this
    List<Post> postsL = [];
    for (DocumentSnapshot d in querySnapshot.docs) {
      Post post = await Post.fetch(doc: d);
      RivalUser user = await getUser(post.userId);
      if (((user.private && user.isFollowing) || !user.private || user.uid == me.uid) && post.available && !post.takenDown) {
        postsL.add(post);
      }
    }
    posts.addAll(postsL);
    setState(() {
      isNextPageLoading = false;
      if (postsL.isEmpty) postsAvailable = false;
    });
  }

}