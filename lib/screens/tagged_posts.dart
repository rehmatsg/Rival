import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../app.dart';

/// TaggedPosts Screen Shows list of all Posts I'm tagged in
class TaggedPosts extends StatefulWidget {

  TaggedPosts({Key key}) : super(key: key);

  @override
  _TaggedPostsState createState() => _TaggedPostsState();
}

class _TaggedPostsState extends State<TaggedPosts> {

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
        title: Text('Tagged Posts'),
      ),
      body: FutureBuilder(
        future: firestore.collection('posts').where('people', arrayContains: me.reference).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            QuerySnapshot querySnapshot = snapshot.data;
            return PostsGridView(
              itemBuilder: (context, index) => PostGridTile(
                key: UniqueKey(),
                child: PostGridView(post: Post(doc: querySnapshot.docs[index]),)
              ),
              itemCount: querySnapshot.docs.length
            );
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 100,
                  width: 100,
                  child: CircularProgressIndicator(),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}