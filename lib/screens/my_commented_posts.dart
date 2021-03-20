import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../app.dart';

class CommentedPosts extends StatefulWidget {

  CommentedPosts({Key key}) : super(key: key);

  @override
  _CommentedPostsState createState() => _CommentedPostsState();
}

class _CommentedPostsState extends State<CommentedPosts> {

  @override
  void initState() {
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
        title: Text('Commented Posts'),
      ),
      body: FutureBuilder<List<Post>>(
        future: _getMyCommentedPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return PostsGridView(
              itemBuilder: (context, index) => PostGridTile(
                key: UniqueKey(),
                child: PostGridView(post: snapshot.data[index],),
              ),
              itemCount: snapshot.data.length
            );
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 100,
                  width: 100,
                  child: CustomProgressIndicator(),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Future<List<Post>> _getMyCommentedPosts() async {
    List<Post> posts = [];
    List<DocumentSnapshot> commentDocs = (await firestore.collection('comments').where('user', isEqualTo: me.uid).get()).docs;
    List<DocumentSnapshot> docs = [];
    for (DocumentSnapshot doc in commentDocs) {
      docs.add(await doc.data()['postRef'].get());
    }
    Map<String, DocumentSnapshot> mp = {};
    for (DocumentSnapshot item in docs) {
      mp[item.id] = item;
    }
    List<DocumentSnapshot> docsDistinct = mp.values.toList(); // List of [DocumentSnapshot] without any duplicate

    for (DocumentSnapshot doc in docsDistinct) {
      Post post = await Post.fetch(doc: doc);
      posts.add(post);
    }
    return posts;
  }

}