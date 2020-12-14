import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../post/post.dart';
import '../providers.dart';

List<Post> myPosts = [];

class PostsByUser extends StatefulWidget {

  PostsByUser({
    Key key,
    this.index,
    this.posts,
    this.user,
    this.isCurrentUser = true
  }) : super(key: key);
  final int index;
  final List<Post> posts;
  final RivalUser user;
  final bool isCurrentUser;

  @override
  _PostsByUserState createState() => _PostsByUserState();
}

class _PostsByUserState extends State<PostsByUser> {

  List<Post> posts;
  List refs;
  var user;

  int page = 1;
  bool postsAvailable = true;
  bool isNextPageLoading = false;

  bool isLoading = true;

  Future<void> _init() async {
    if (widget.isCurrentUser) user = me;
    else user = widget.user;
    refs = user.posts.reversed.toList();
    posts = [];
    if (refs.length < 10) {
      if (widget.isCurrentUser && myPosts.length == refs.length) {
        posts = myPosts;
      } else {
        for (DocumentReference ref in refs) {
          Post post = await Post.fetch(ref: ref, user: user);
          posts.add(post);
          if (widget.isCurrentUser) myPosts.add(post);
        }
      }
    } else {
      if (widget.isCurrentUser && myPosts.length >= 10) {
        posts = myPosts.getRange(0, 10).toList();
      } else {
        for (DocumentReference ref in refs.getRange(0, 10)) {
          Post post;
          if (widget.isCurrentUser) post = await Post.fetch(ref: ref);
          else post = await Post.fetch(ref: ref, user: user);
          posts.add(post);
          if (widget.isCurrentUser) myPosts.add(post);
        }
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _nextPage() async {
    setState(() {
      isNextPageLoading = true;
    });
    page += 1;
    int startIndex = (page - 1) * 10;
    int endIndex = startIndex + 9;

    if (refs.length >= startIndex) {
      if (endIndex > refs.length) {
        endIndex = refs.length - 1;
      }
      if (widget.isCurrentUser && myPosts.length >= endIndex) {
        posts.addAll(myPosts.getRange(startIndex, endIndex + 1));
      } else {
        for (DocumentReference ref in refs.getRange(startIndex, endIndex + 1)) {
          Post post;
          if (widget.isCurrentUser) {
            post = await Post.fetch(ref: ref);
            myPosts.add(post);
          } else post = await Post.fetch(ref: ref, user: user);
          posts.add(post);
        }
      }
    }
    setState(() {
      isNextPageLoading = false;
      if (endIndex > refs.length) postsAvailable = false;
    });
  }

  @override
  void initState() {
    _init();
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isCurrentUser ? '@${me.username}' : '@${widget.user.username}'),
      ),
      body: isLoading
      ? Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: CircularProgressIndicator(),
          )
        ],
      )
      : SingleChildScrollView(
        child: Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) => ViewPost(post: posts[index],),
              itemCount: posts.length,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (postsAvailable) ... [
                  if (isNextPageLoading) Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black : Colors.white),
                      ),
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
                      icon: Icon(Icons.add_circle),
                    ),
                  ),
                ] else ... [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Text(
                      'Open Explore tab to discover more posts',
                      style: Theme.of(context).textTheme.caption
                    ),
                  )
                ]
              ]
            )
          ],
        ),
      ),
    );
  }
}