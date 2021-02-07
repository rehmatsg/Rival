// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:eyro_toast/eyro_toast.dart';
// import 'package:firebase_analytics/firebase_analytics.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:octo_image/octo_image.dart';
// import 'package:pagination_view/pagination_view.dart';
// import 'package:shimmer/shimmer.dart';

// class Comments extends StatefulWidget {

//   Comments({Key key, @required this.id}) : super(key: key);
//   final String id;

//   @override
//   _CommentsState createState() => _CommentsState();
// }

// class _CommentsState extends State<Comments> {

//   DocumentSnapshot postDoc;
//   Map comments;

//   final FirebaseAnalytics analytics = FirebaseAnalytics();
  
//   bool isLoading = true;

//   TextEditingController _controller = TextEditingController();

//   List<Widget> preloadedComments = [];

//   @override
//   void initState() {
//     _init();
//     super.initState();
//   }

//   _init() async {
//     DocumentSnapshot postDocL = await firestore.collection('posts').doc(widget.id).get();
//     setState(() {
//       postDoc = postDocL;
//       comments = postDoc.data()['comments'];
//     });
//     if (comments.length < 50) {
//       comments.forEach((key, value) async {
//         String uid = key;
//         DocumentReference commentRef = value;
//         preloadedComments.add(User(uid: uid, ref: commentRef,));
//       });
//     } else {
//       for (var i = 0; i < 50; i++) {
//         String uid = comments.keys.toList()[i];
//         DocumentReference commentRef = comments.values.toList()[i];
//         preloadedComments.add(User(uid: uid, ref: commentRef,));
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: postDoc != null
//         ? StreamBuilder(
//           stream: postDoc.reference.snapshots(),
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.active && snapshot.hasData) {
//               DocumentSnapshot postDocUpdated = snapshot.data;
//               Map commentsUpdated = postDocUpdated.data()['comments'];
//               return Text('Comments (${commentsUpdated.length})');
//             }
//             return Text('Comments (${comments.length})');
//           },
//         )
//         : Text('Comments')
//       ),
//       body: postDoc != null
//       ? FutureBuilder(
//         future: FirebaseAuth.instance.currentUser(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
//             User me = snapshot.data;
//             return Column(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
//                   child: Row(
//                     children: [
//                       Padding(
//                         padding: const EdgeInsets.only(right: 7),
//                         child: ClipOval(
//                           child: OctoImage(
//                             image: me.photoUrl != null ? NetworkImage(me.photoUrl) : AssetImage('assets/images/avatar.png'),
//                             progressIndicatorBuilder: (context, progress) => CircularProgressIndicator(),
//                             width: 40,
//                             height: 40,
//                           ),
//                         ),
//                       ),
//                       Flexible(
//                         child: Padding(
//                           padding: const EdgeInsets.only(left: 7),
//                           child: TextFormField(
//                             controller: _controller,
//                             decoration: InputDecoration(
//                               filled: true,
//                               labelText: 'Comment as ${me.displayName != null ? me.displayName.split(' ')[0] : 'yourself'}',
//                               isDense: true,
//                             ),
//                             textInputAction: TextInputAction.send,
//                             inputFormatters: [
//                               LengthLimitingTextInputFormatter(50),
//                             ],
//                             onFieldSubmitted: (comment) async {
//                               DocumentReference myDocRef = firestore.collection('users').doc(me.uid);
//                               DocumentSnapshot myDoc = await myDocRef.get();
                              
//                               String username = myDoc.data()['username'];
//                               if (username != null) {
//                                 await RivalProvider.showToast(
//                                   text: 'Commenting...',
//                                   duration: ToastDuration.short,
//                                 );
//                                 int timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
//                                 String commentId = firestore.collection('comments').doc() .id;
//                                 DocumentReference commentRef = firestore.collection('comments').doc(commentId);
//                                 await analytics.logEvent(name: 'comment', parameters: {
//                                   'commenter': me.uid,
//                                   'post': postDoc .id
//                                 });
//                                 await commentRef.set({
//                                   'timestamp': timestamp,
//                                   'comment': comment,
//                                   'commenter_username': username,
//                                   'commenter_uid': me.uid,
//                                   'user': myDocRef,
//                                   'post': postDoc.reference
//                                 });
//                                 _controller.clear();
//                                 postDoc.reference .update({
//                                   'comments.${me.uid}': commentRef
//                                 });
//                                 await RivalProvider.showToast(
//                                   text: 'Comment Posted',
//                                   duration: ToastDuration.short,
//                                 );
//                               } else {
//                                 await RivalProvider.showToast(
//                                   text: 'A username is required to comment',
//                                   duration: ToastDuration.long,
//                                 );
//                               }
//                             },
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 // Show comments
//                 Expanded(
//                   child: PaginationView(
//                     preloadedItems: preloadedComments,
//                     itemBuilder: (BuildContext context, Widget widget, index) {
//                       return widget;
//                     },
//                     pageFetch: _pageFetch,
//                     onEmpty: Center(
//                       child: Text('No Comments!', style: TextStyle(fontSize: 20),),
//                     ),
//                     onError: (dynamic error) => Center(
//                       child: Text('Some error occured'),
//                     )
//                   ),
//                 )
//               ],
//             );
//           }
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   width: 100,
//                   height: 100,
//                   child: CircularProgressIndicator(),
//                 )
//               ],
//             ),
//           );
//         },
//       )
//       : Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               height: 100,
//               width: 100,
//               child: CircularProgressIndicator()
//             )
//           ]
//         )
//       )
//     );
//   }

//   Future<List<Widget>> _pageFetch(int i) async {
//     int startIndex = 1 + (i - 1) * 50;
//     int endIndex = startIndex + 50;
//     List<Widget> list = [];
//     print("Start Index: $startIndex, Last Index: $endIndex");
//     if (comments.length > startIndex && i > 0) {
//       if (endIndex > comments.length) endIndex = comments.length;
//       print(startIndex);
//       for (var i = startIndex; i < endIndex; i++) {
//         String uid = comments.keys.toList()[i];
//         DocumentReference commentRef = comments.values.toList()[i];
//         list.add(User(uid: uid, ref: commentRef,));
//       }
//       return list;
//     }
//     return [];
//   }

// }

// class User extends StatefulWidget {

//   User({Key key, @required this.uid, @required this.ref}) : super(key: key);
//   final String uid;
//   final DocumentReference ref;

//   @override
//   _UserState createState() => _UserState();
// }

// class _UserState extends State<User> {

//   DocumentSnapshot userDoc;
//   DocumentSnapshot commentDoc;

//   @override
//   void initState() {
//     super.initState();
//     firestore.collection('users').doc(widget.uid).get().then((doc) {
//       setState(() {
//         userDoc = doc;
//       });
//     });
//     widget.ref.get().then((doc) {
//       setState(() {
//         commentDoc = doc;
//       });
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (userDoc == null || commentDoc == null) {
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
//       subtitle: RichText(
//         text: TextSpan(
//           children: [
//             TextSpan(text: commentDoc.data()['comment'], style: TextStyle(color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black87 : Colors.white70)),
//             TextSpan(text: '\n'),
//             TextSpan(text: timeago.format(new DateTime.fromMillisecondsSinceEpoch(commentDoc.data()['timestamp'])), style: TextStyle(color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black54 : Colors.white30, fontWeight: FontWeight.w500))
//           ]
//         ),
//       ),
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:octo_image/octo_image.dart';
import '../app.dart';

class PostComments extends StatefulWidget {

  PostComments({Key key, this.post}) : super(key: key);
  final Post post;

  @override
  _PostCommentsState createState() => _PostCommentsState();
}

class _PostCommentsState extends State<PostComments> {

  Post post;
  Map comments;

  TextEditingController commentController = TextEditingController();

  List<DocumentSnapshot> myComments;

  /// [true] when comments are loading
  bool isLoading = false;
  /// [true] when comment is being sent
  bool isLoadingX = false;

  List<Widget> commentsByUser;

  int commentsPage = 0;
  bool moreCommentsAvailable = true;

  Widget get commentsWidget => PagedListView(
    itemsPerPage: 25,
    useSeparator: true,
    onNextPage: (startIndex, endIndex) async {
      if (startIndex > comments.length) startIndex = comments.length - 1;
      if (endIndex > comments.length) {
        endIndex = comments.length;
      }
      print('Start Index: $startIndex. End Index: $endIndex');
      List commentsRef = comments.values.toList().sublist(startIndex, endIndex);
      print('Comments Ref: ${commentsRef.length}');
      if (commentsByUser == null) commentsByUser = [];
      List<Widget> wid = [];
      for (var ref in commentsRef) {
        DocumentSnapshot doc = await ref.get();
        if (doc.exists && doc.data()['user'] != me.uid) {
          DocumentReference userRef = doc.data()['userRef'];
          RivalUser rivalUser = await getUser(userRef.id);
          wid.add(
            UserCommentView(
              user: rivalUser,
              comment: doc.data()['comment'],
              timeago: getTimeAgo(new DateTime.fromMillisecondsSinceEpoch(doc.data()['timestamp']), includeHour: true),
            )
          );
        }
      }
      return wid;
    },
    onFinish: 'No More Comments',
  );

  @override
  void initState() {
    post = widget.post;
    comments = post.comments;
    _getMyComments();
    super.initState();
  }
  
  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Future<void> _getMyComments() async {
    QuerySnapshot querySnapshot = await firestore.collection('comments').where('post', isEqualTo: post.id).where('user', isEqualTo: me.uid).get();
    myComments = [];
    setState(() {
      myComments.addAll(querySnapshot.docs);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comments'),
        bottom: (isLoading || isLoadingX) ? PreferredSize(
          child: LinearProgressIndicator(),
          preferredSize: Size(double.infinity, 0.5)
        ) : null,
      ),
      body: SingleChildScrollView(
        physics: ScrollPhysics(),
        child: Column(
          children: [
            if (post.allowComments) Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: TextFormField(
                controller: commentController,
                decoration: InputDecoration(
                  filled: true,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ProfilePhoto(width: 12, height: 12, hero: false,),
                  ),
                  suffixIcon: isLoadingX ? null : IconButton(
                    icon: Icon(Icons.send),
                    onPressed: _sendComment,
                  ),
                  labelText: 'Type a comment...',
                ),
                onFieldSubmitted: (value) => _sendComment(),
                minLines: 1,
                maxLines: 7,
              ),
            ),
            if (myComments != null) ... List.generate(
              myComments.length,
              (index) => ListTile(
                leading: ProfilePhoto(width: 30, height: 30, hero: false,),
                title: Text(myComments[index].data()['comment']),
                //isThreeLine: true,
                subtitle: Text('${me.username} • ${getTimeAgo(new DateTime.fromMillisecondsSinceEpoch(myComments[index].data()['timestamp']), includeHour: true)}'),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Text('Delete'),
                      value: 'delete',
                    )
                  ],
                  onSelected: (val) async {
                    int commentTimestamp = myComments[index].data()['timestamp'];
                    await post.reference .update({
                      'comments.$commentTimestamp': FieldValue.delete()
                    });
                    await myComments[index].reference.delete();
                    setState(() {
                      myComments.removeAt(index);
                    });
                    RivalProvider.showToast(text: 'Comment Deleted');
                  },
                ),
                visualDensity: VisualDensity.compact,
              )
            ),
            Divider(),
            commentsWidget
          ],
        ),
      ),
    );
  }

  Future<void> _sendComment() async {
    String comment = commentController.text;
    if (comment != null && comment.trim() != "") {
      commentController.clear();
      setState(() {
        isLoadingX = true;
      });
      String commentId = firestore.collection('comments').doc() .id;
      DocumentReference commentRef = firestore.collection('comments').doc(commentId);
      int timestamp = new DateTime.now().millisecondsSinceEpoch;
      Map<String, dynamic> commentData = {
        'id': commentId,
        'comment': comment,
        'user': me.uid,
        'userRef': me.reference,
        'post': post.id,
        'postRef': post.reference,
        'timestamp': timestamp,
        'likes': {},
        'token': me.token
      };
      commentRef.set(commentData);
      await post.reference .update({
        'comments.$timestamp': commentRef
      });
      await post.refresh();
      DocumentSnapshot commentDoc = await commentRef.get();
      setState(() {
        myComments.add(commentDoc);
        isLoadingX = false;
      });
      RivalProvider.showToast(text: 'Comment Sent');
    }
  }

}

class UserCommentView extends StatefulWidget {

  final String comment;
  final RivalUser user;
  final String timeago;

  const UserCommentView({Key key, this.comment, this.user, this.timeago}) : super(key: key);

  @override
  _UserCommentViewState createState() => _UserCommentViewState();
}

class _UserCommentViewState extends State<UserCommentView> {

  String comment;
  String timeago;
  RivalUser user;

  @override
  void initState() {
    comment = widget.comment;
    user = widget.user;
    timeago = widget.timeago;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              ClipOval(
                child: OctoImage(
                  width: 30,
                  height: 30,
                  image: user.photo,
                ),
              ),
              Container(width: 10,),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(user.username, style: Theme.of(context).textTheme.subtitle1),
                  Text(timeago, style: Theme.of(context).textTheme.caption),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 50, right: 10),
          child: TextParser(
            text: comment,
            textStyle: Theme.of(context).textTheme.bodyText1,
            matchedWordStyle: Theme.of(context).textTheme.bodyText1.copyWith(fontWeight: FontWeight.bold),
            regexes: [
              RivalRegex.username
            ],
          ),
        )
      ],
    );
  }
}