import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../app.dart';

class LikedPosts extends StatefulWidget {

  LikedPosts({Key key}) : super(key: key);

  @override
  _LikedPostsState createState() => _LikedPostsState();
}

class _LikedPostsState extends State<LikedPosts> {

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
        title: Text('Liked Posts'),
      ),
      body: FutureBuilder<List<Post>>(
        future: _getMyLikedPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return PostsGridView(
              itemBuilder: (context, index) => PostGridTile(
                key: UniqueKey(),
                child: PostGridTile(
                  key: UniqueKey(),
                  child: PostGridView(post: snapshot.data[index],)
                ),
              ),
              itemCount: snapshot.data.length
            );
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomProgressIndicator()
              ],
            ),
          );
        },
      ),
    );
  }

  Future<List<Post>> _getMyLikedPosts() async {
    List<Post> posts = [];
    List<DocumentSnapshot> docs = (await firestore.collection('posts').where('likes.${me.uid}.timestamp', isGreaterThanOrEqualTo: 1).get()).docs;
    print(docs.length);
    for (DocumentSnapshot doc in docs) {
      Post post = await Post.fetch(doc: doc);
      posts.add(post);
    }
    return posts;
  }

}