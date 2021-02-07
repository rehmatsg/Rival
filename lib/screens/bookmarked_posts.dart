import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:octo_image/octo_image.dart';
import 'package:provider/provider.dart';
import '../app.dart';

class BookmarkedPosts extends StatefulWidget {
  @override
  _BookmarkedPostsState createState() => _BookmarkedPostsState();
}

class _BookmarkedPostsState extends State<BookmarkedPosts> {

  int bookmarksLen = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bookmarks'),
      ),
      body: StreamProvider<Me>.value(
        value: me.streamX,
        initialData: me,
        updateShouldNotify: (previous, current) {
          if (bookmarksLen != current.bookmarks.length) {
            return true;
          } else {
            return false;
          }
        },
        lazy: true,
        builder: (context, child) {
          Me me = Provider.of<Me>(context);
          bookmarksLen = me.bookmarks.length;
          return PostsGridView(
            itemBuilder: (context, index) => FutureBuilder<Post>(
              future: getPost(me.bookmarks[index].id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  Post post = snapshot.data;
                  if (!post.available) {
                    me.reference.update({
                      'bookmarks': FieldValue.arrayRemove([post.reference])
                    });
                  }
                  return InkWell(
                    onTap: () => Navigator.of(context).push(RivalNavigator(page: SinglePostView(post: post,),)),
                    child: PostGridTile(
                      child: (post.available || false) ? OctoImage( // TODO
                        image: CachedNetworkImageProvider(post.items[0].url),
                        fit: BoxFit.cover,
                      ) : Container(
                        color: Colors.yellow,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning, color: Colors.black,),
                              Text('404', style: Theme.of(context).textTheme.bodyText1.copyWith(color: Colors.black, fontFamily: RivalFonts.feature))
                            ],
                          )
                        ),
                      )
                    ),
                  );
                }
                return PostGridTile(child: Container());
              },
            ),
            itemCount: me.bookmarks.length
          );
        },
      ),
    );
  }

}