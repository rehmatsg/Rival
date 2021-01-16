// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
// import 'package:octo_image/octo_image.dart';
// import 'package:pagination_view/pagination_view.dart';
// import 'package:shimmer/shimmer.dart';

// class Likes extends StatefulWidget {

//   Likes({Key key, @required this.doc}) : super(key: key);
//   final DocumentSnapshot doc;

//   @override
//   _LikesState createState() => _LikesState();
// }

// class _LikesState extends State<Likes> {

//   final GlobalKey<LiquidPullToRefreshState> _refreshIndicatorKey = GlobalKey<LiquidPullToRefreshState>();
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

//   DocumentSnapshot postDoc;
//   Map likes;

//   List<Widget> preloadedUsers = [];

//   @override
//   void initState() {
//     super.initState();
//     postDoc = widget.doc;
//     likes = postDoc.data()['likes'];
//     _init();
//   }

//   _init() async {
//     if (likes.length < 50) {
//       likes.forEach((uid, timestamp) async {
//         preloadedUsers.add(User(uid: uid, timestamp: timestamp,));
//       });
//     } else {
//       for (var i = 0; i < 50; i++) {
//         String uid = likes.keys.toList()[i];
//         var timestamp = likes.values.toList()[i];
//         preloadedUsers.add(User(uid: uid, timestamp: timestamp,));
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffoldKey,
//       appBar: AppBar(
//         title: Text('Likes'),
//       ),
//       body: (preloadedUsers != null)
//       ? LiquidPullToRefresh(
//         key: _refreshIndicatorKey,
//         child: PaginationView(
//           preloadedItems: preloadedUsers,
//           itemBuilder: (BuildContext context, Widget widget, index) {
//             print("Widget $widget, Index: $index");
//             return widget;
//           },
//           pageFetch: _pageFetch,
//           onEmpty: Center(
//             child: Text('No likes on this post', style: TextStyle(fontSize: 20),),
//           ),
//           onError: (dynamic error) => Center(
//             child: Text('Some error occured'),
//           )
//         ),
//         onRefresh: _refresh
//       )
//       : Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             height: 100,
//             width: 100,
//             child: CircularProgressIndicator(),
//           )
//         ],
//       )
//     );
//   }

//   Future<void> _refresh() {
//     final Completer<void> completer = Completer<void>();
//     Timer(const Duration(seconds: 3), () {
//       completer.complete();
//     });
//     setState(() {
//     });
//     return completer.future.then<void>((_) {
//       _scaffoldKey.currentState?.showSnackBar(SnackBar(
//         content: const Text('Refresh complete'),
//         action: SnackBarAction(
//           label: 'RETRY',
//           onPressed: () {
//             _refreshIndicatorKey.currentState.show();
//           }
//         )
//       ));
//     });
//   }

//   Future<List<Widget>> _pageFetch(int i) async {
//     int startIndex = 1 + (i - 1) * 50;
//     int endIndex = startIndex + 50;
//     List<Widget> list = [];
//     print("Start Index: $startIndex, Last Index: $endIndex");
//     if (likes.length > startIndex && i > 0) {
//       if (endIndex > likes.length) endIndex = likes.length;
//       print(startIndex);
//       for (var i = startIndex; i < endIndex; i++) {
//         String uid = likes.keys.toList()[i];
//         int timestamp = likes.values.toList()[i];
//         list.add(User(uid: uid, timestamp: timestamp,));
//       }
//       return list;
//     }
//     return [];
//   }

// }

// class User extends StatefulWidget {

//   User({Key key, @required this.uid, @required this.timestamp}) : super(key: key);
//   final String uid;
//   final int timestamp;

//   @override
//   _UserState createState() => _UserState();
// }

// class _UserState extends State<User> {

//   DocumentSnapshot userDoc;

//   @override
//   void initState() {
//     super.initState();
//     firestore.collection('users').doc(widget.uid).get().then((doc) {
//       setState(() {
//         userDoc = doc;
//       });
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (userDoc == null) {
//       return ListTile(
//         leading: Shimmer.fromColors(child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(100))), height: 40, width: 40), baseColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.white10, highlightColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.white12),
//         title: Shimmer.fromColors(child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(3))), height: 10, width: MediaQuery.of(context).size.width * 0.8,), baseColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.white10, highlightColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black26 : Colors.white12),
//       );
//     }
//     return ListTile(
//       leading: (userDoc.data()['photoUrl'] != null)
//       ? ClipOval(
//         child: OctoImage(
//           image: NetworkImage(userDoc.data()['photoUrl']),
//           progressIndicatorBuilder: (context, progress) => CircularProgressIndicator(),
//           width: 40,
//           height: 40,
//         ),
//       )
//       : ClipOval(
//         child: Image.asset('assets/images/avatar.png', width: 40, height: 40,),
//       ),
//       title: Text(userDoc.data()['displayName']),
//       subtitle: Text(timeago.format(new DateTime.fromMillisecondsSinceEpoch(widget.timestamp))),
//     );
//   }
// }

import 'package:flutter/material.dart';
import '../app.dart';

class PostLikes extends StatefulWidget {

  PostLikes({Key key, this.post}) : super(key: key);
  final Post post;

  @override
  _PostLikesState createState() => _PostLikesState();
}

class _PostLikesState extends State<PostLikes> {
  
  Post post;
  Map likes;
  Map<String, Future<RivalUser>> people = {};

  @override
  void initState() {
    post = widget.post;
    likes = post.likes;
    likes.forEach((uid, timestamp) {
      people[uid] = getUser(uid);
    });
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
        title: Text('Likes'),
      ),
      body: PagedListView(
        itemsPerPage: 30,
        onFinish: 'That\'s all',
        useSeparator: false,
        onNextPage: (startIndex, endIndex) async {
          Map<String, Future<RivalUser>> rangedPeople = people.getRange(startIndex, endIndex);
          List<Widget> widgets = [];
          rangedPeople.forEach((uid, future) {
            if (uid != me.uid) widgets.add(UserListTile(
              future: future,
              subtitle: getTimeAgo(DateTime.fromMillisecondsSinceEpoch(likes[uid])),
            ));
            else widgets.add(UserListTile(
              isCurrentUser: true,
              subtitle: getTimeAgo(DateTime.fromMillisecondsSinceEpoch(likes[uid])),
            ));
          });
          return widgets;
        },
      )
    );
  }
}