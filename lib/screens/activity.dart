import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:octo_image/octo_image.dart';
import 'package:shimmer/shimmer.dart';
import '../app.dart';

class ActivityPage extends StatefulWidget {
  @override
  _ActivityPageState createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('@${me.username}'),
      ),
      body: Column(
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20, left: 15, right: 15, bottom: 5),
                child: Text('Activity', style: TextStyle(fontSize: Theme.of(context).textTheme.headline3.fontSize, fontFamily: RivalFonts.feature),),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: me.activity.length,
              itemBuilder: (context, index) => ActivityTile(activity: Activity(activity: me.activity[index]),),
            ),
          ),
        ],
      ),
    );
  }
}

class ActivityTile extends StatelessWidget {

  final Activity activity;

  const ActivityTile({Key key, this.activity}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Slidable(
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.25,
      secondaryActions: <Widget>[
        IconSlideAction(
          caption: 'Delete',
          color: Colors.red,
          icon: Icons.delete,
          onTap: () {},
        ),
      ],
      child: ListTile(
        title: FutureBuilder<String>(
          future: activity.title,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Text(snapshot.data);
            }
            return Shimmer.fromColors(child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(3))), height: 10, width: MediaQuery.of(context).size.width * 0.5,), baseColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.white10, highlightColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black26 : Colors.white12);
          },
        ),
        subtitle: Text(getTimeAgo(new DateTime.fromMillisecondsSinceEpoch(activity.timestamp), includeHour: false)),
        trailing: FutureBuilder<ImageProvider>(
          future: activity.photo,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Container(
                width: 40,
                height: 40,
                child: ClipRRect(
                  borderRadius: (activity.type == ActivityType.followRequest || activity.type == ActivityType.newFollower) ? BorderRadius.all(Radius.circular(40)) : BorderRadius.all(Radius.circular(13)),
                  child: OctoImage(
                    image: snapshot.data,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            }
            return Container(
              width: 40,
              height: 40,
            );
          },
        ),
        onTap: () => activity.navigateAsPerRequest(context),
        onLongPress: () => showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete Item'),
            actions: [
              FlatButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancel')
              ),
              FlatButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await me.update({
                    'activity': FieldValue.arrayRemove([activity.activity])
                  });
                  await me.reload();
                  RivalProvider.showToast(text: 'Deleted item from Activity');
                },
                child: Text('Delete')
              )
            ],
          ),
        ),
      ),
    );
  }
}

class Activity {
  final Map activity;
  Activity({this.activity});

  DocumentSnapshot postDoc;
  DocumentSnapshot userDoc;

  int get timestamp => activity['timestamp'];

  ActivityType get type {
    if (activity['type'] == "newLike") return ActivityType.newLike;
    else if (activity['type'] == "newComment") return ActivityType.newComment;
    else if (activity['type'] == "followRequest") return ActivityType.followRequest;
    else if (activity['type'] == "newFollower") return ActivityType.newFollower;
    else if (activity['type'] == "taggedInPost") return ActivityType.taggedInPost;
    else if (activity['type'] == "welcome") return ActivityType.welcome;
    else return null;
  }

  Future<DocumentSnapshot> get postDocument async {
    if (postDoc == null) {
      postDoc = await activity['postRef'].get();
    }
    return postDoc;
  }

  Future<DocumentSnapshot> get userDocument async {
    if (userDoc == null) {
      userDoc = await activity['userRef'].get();
    }
    return userDoc;
  }

  Future<String> get title async {
    String titleX;

    if (type == ActivityType.welcome) {
      titleX = "Welcome to Rival";
      return titleX;
    }

    DocumentReference userRef = activity['userRef'];

    DocumentSnapshot doc = await userRef.get();

    print('UserRef: ${userRef.path} UserData: ${doc.data}');

    RivalUser user = RivalUser(doc: doc);

    print(type);

    if (type == ActivityType.newLike) {
      titleX = "${user.username} liked your post";
    } else if (type == ActivityType.newComment) {
      titleX = "${user.username} commented on your post";
    } else if (type == ActivityType.taggedInPost) {
      titleX = "${user.username} tagged you in a post";
    } else if (type == ActivityType.followRequest) {
      titleX = "${user.username} wants to follow you";
    } else if (type == ActivityType.newFollower) {
      titleX = "${user.username} started following you";
    }
    return titleX;
  }

  Future<ImageProvider> get photo async {
    ImageProvider photo = AssetImage('assets/icon.png');
    if (type == ActivityType.newLike || type == ActivityType.newComment || type == ActivityType.taggedInPost) {
      Post post = Post(doc: await postDocument);
      photo = NetworkImage(post.images[0]);
    } else if (type == ActivityType.followRequest || type == ActivityType.newFollower) {
      RivalUser user = RivalUser(doc: await userDocument);
      photo = user.photo;
    }
    return photo;
  }

  Future<void> navigateAsPerRequest(BuildContext context) async {
    Widget page = Home();
    if (type == ActivityType.newLike) page = PostLikes();
    else if (type == ActivityType.newComment) page = PostComments();
    else if (type == ActivityType.followRequest) page = FollowRequests();
    //else if (type == ActivityType.newFollower) page = Followers(user: me.doc,);
    else if (type == ActivityType.taggedInPost) page = SinglePostView(post: Post(doc: await postDocument),);
    Navigator.of(context).push(RivalNavigator(page: page));
  }

  /// Types of data user can set
  /// [userRef]: reference to the user if activity is related to any user
  /// [postRef]: reference to the post if activity is related to any post
  /// [type]: type of activity : [newLike, newComment, followRequest, newFollower, taggedInPost, welcome],
  /// [timestamp]: and finally timestamp of activity posted
  Future<Activity> createMyActivity(Map<String, dynamic> data) async {
    await me.update({
      'activity': FieldValue.arrayUnion([data])
    });
    return Activity(activity: data);
  }

  Future<Activity> createActivity(Map<String, dynamic> data, RivalUser user) async {
    await user.reference .update({
      'activity': FieldValue.arrayUnion([data])
    });
    return Activity(activity: data);
  }

}

enum ActivityType {
  newLike,
  newComment,
  followRequest,
  newFollower,
  taggedInPost,
  welcome
}