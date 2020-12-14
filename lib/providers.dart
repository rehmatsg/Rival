import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:eyro_toast/eyro_toast.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:octo_image/octo_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';
import 'package:supercharged/supercharged.dart';
import 'package:vibration/vibration.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'post/post.dart';
import 'screens/explore.dart';
import 'story/view.dart';
import 'users.dart';
import 'widgets/widgets.dart';

export 'users.dart';
export 'theme.dart';

final List<String> months = [
  'Unknown Month', // DateTime months start from 1. So 0 cannot be accessed
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'Decemeber'
];

class RivalRegex {
  static String username = r'@[a-z0-9_.]{4,16}|\B#+([\w]+)\b';
  static String tag = r'\B#+([\w]+)\b';
  static String email = r'^([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})';
  static String url = r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)';
  static String phone = r'[\d]{3}[ ]{1}[\d]{3}';
}

FirebaseFirestore firestore;
FirebaseAnalytics analytics = FirebaseAnalytics();

SharedPreferences sharedPreferences;

List<RivalUser> homeScreenStories;
List<DocumentSnapshot> homeScreenPosts;

Map<String, int> topTags;

Me me;

class RivalProvider {

  static Future<List<DocumentSnapshot>> getPosts(int page) async {
    if (homeScreenPosts == null) {
      homeScreenPosts = await getPaginatedPosts(1);
      return homeScreenPosts;
    } else {
      homeScreenPosts.addAll(await getPaginatedPosts(page));
      return homeScreenPosts;
    }
  }
  static Future<List<DocumentSnapshot>> getPaginatedPosts(int page, {Source source}) async {
    int startTime = new DateTime.now().millisecondsSinceEpoch;
    // -------------------------------
    List<DocumentSnapshot> posts = [];
    // Evaluate time
    int daysPerPage = 30; // Get last 1 month's posts
    DateTime now = new DateTime.now();
    int startDay = now.subtract(Duration(days: daysPerPage * page)).millisecondsSinceEpoch; // Smaller than endDay
    int endDay = now.subtract(Duration(days: daysPerPage * (page - 1))).millisecondsSinceEpoch;

    /// List of [String] UID of all people I follow
    List<String> people = [me.uid]; // Actually contains User IDs
    me.following.forEach((person) {
      people.add(person.id);
    });

    for (var uid in people) {
      List<DocumentSnapshot> documents = (await firestore.collection('posts').where('creator', isEqualTo: uid).where('timestamp', isGreaterThanOrEqualTo: startDay).where('timestamp', isLessThanOrEqualTo: endDay).get(GetOptions(source: source ?? Source.serverAndCache,))).docs;
      if (source == Source.cache && documents.isEmpty) {
        documents = (await firestore.collection('posts').where('creator', isEqualTo: uid).where('timestamp', isGreaterThanOrEqualTo: startDay).where('timestamp', isLessThanOrEqualTo: endDay).get(GetOptions(source: Source.server,))).docs;
      }
      posts.addAll(documents);
    }

    // We got all posts. Now sort it according to timestamp
    posts.sort((a, b) => b.data()['timestamp'].compareTo(a.data()['timestamp']));

    posts.removeWhere((postDoc) {
      Post post = Post(doc: postDoc);
      if (!post.available || post.takenDown) {
        return true;
      } else {
        return false;
      }
    });
    
    if (page == 1 && posts.isEmpty) {
      posts.add(await firestore.collection('posts').doc('7l3jrRLJN2rhWKQRGTAE').get());
    }

    // -------------------------------
    int endTime = new DateTime.now().millisecondsSinceEpoch;
    double secondsEvaluated = (endTime - startTime) / 1000;
    print('Took $secondsEvaluated seconds to get (${source == Source.cache ? 'Cached' : 'Server'}) posts');

    // Finally return all posts
    return posts;
  }

  static void reloadHomeScreen() {
    homeScreenPosts = null;
  }
  static removeHomeScreenPosts() {
    homeScreenPosts = [];
  }

  static Future<void> vibrate({bool long = false}) async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: long ? 10 : 3);
    }
  }

  /// Get User [RivalUser] by @username
  /// Return [NULL] if no user is found
  static Future<RivalUser> getUserByUsername(String username) async {
    username = username.replaceAll('@', '').toLowerCase().trim(); // Remove @ from username

    if (allLoadedUsers.indexWhere((element) => element.username == username) > 0) return allLoadedUsers[allLoadedUsers.indexWhere((element) => element.username == username)];

    try {
      QuerySnapshot querySnapshot = await firestore.collection('users').where('username', isEqualTo: username).get();
      return RivalUser(doc: querySnapshot.docs.first);
    } catch (e) {
      return null;
    }
  }
  static Future<RivalUser> getUserByRef(DocumentReference ref) async {
    return await getUser(ref.id);
  }
  static Future<List<RivalUser>> getStories() async {
    if (homeScreenStories == null) {
      List following = me.following;
      homeScreenStories = [];
      for (var dummy in following) {
        DocumentReference person = dummy;
        RivalUser user = await getUser(person.id);
        if (user.stories != null && user.stories.isNotEmpty) {
          homeScreenStories.add(user);
        }
      }
      if (homeScreenStories.isEmpty && (me.stories == null || me.stories.isEmpty)) {
        homeScreenStories.add(RivalUser(doc: await firestore.collection('users').doc('EQs5vlC8U1XWqJxdR3dHPgUrx413').get()));
      }
      homeScreenStories..sort((a, b) {
        if(b.storyViewed) {
          return -1;
        }
        return 1;
      });
    }
    return homeScreenStories.toSet().toList();
  }
  static Future<void> reloadStories() async {
    homeScreenStories = null;
    await getStories();
  }
  static Future<void> showToast({@required String text}) async {
    await EyroToast.showToast(
      text: text,
    );
  }

}

class UserListTile extends StatefulWidget {

  UserListTile({Key key, this.user, this.doc, this.id, this.ref, this.isCurrentUser, this.subtitle}) : super(key: key);
  final RivalUser user;
  /// UID of [RivalUser]. Initializing this class using UID automatically gets user by UID.
  final String id;
  final DocumentSnapshot doc;
  final DocumentReference ref;
  final bool isCurrentUser;
  final String subtitle;

  @override
  _UserListTileState createState() => _UserListTileState();
}

class _UserListTileState extends State<UserListTile> {

  RivalUser user;
  String id;
  DocumentSnapshot doc;
  
  bool isCurrentUser = false;
  bool isLoading = true;

  _init() async {
    if (widget.user != null) {
      user = widget.user;
      id = user.uid;
      doc = user.doc;
      isLoading = false;
    } else if (widget.id != null) {
      user = await getUser(widget.id);
      id = widget.id;
      doc = user.doc;
      isLoading = false;
    } else if (widget.doc != null) {
      doc = widget.doc;
      user = RivalUser(doc: doc);
      id = doc.id;
      isLoading = false;
    } else if (widget.ref != null) {
      await _getUserFromRef();
    }

    if (widget.isCurrentUser != null) {
      isCurrentUser = widget.isCurrentUser;
    } else if (user.uid == me.uid) {
      isCurrentUser = true;
    } else {
      isCurrentUser = false;
    }
    setState(() {});
  }

  @override
  void initState() {
    _init();
    super.initState();
  }

  Future<void> _getUserFromRef() async {
    doc = await widget.ref.get();
    id = doc.id;
    user = RivalUser(doc: doc);
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: (isLoading || isCurrentUser) ? true : (user.amIBlocked ? false : true),
      child: ListTile(
        visualDensity: VisualDensity.compact,
        leading: isCurrentUser
        ? ((me.stories != null && me.stories.length > 0)
          ? GestureDetector(
            onTap: () async {
              await RivalProvider.vibrate();
              Navigator.of(context).push(RivalNavigator(page: ViewStory(launchedFromHomeScreen: false, users: [me])));
            },
            child: CircularStepProgressIndicator(
              totalSteps: me.stories.length,
              unselectedColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black38 : Colors.white38,
              width: 40,
              height: 40,
              padding: me.stories.length > 1 ? (22/7) / 15 : 0,
              customStepSize: (intn, boo) => 2,
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: ClipOval(
                  child: ProfilePhoto(width: 30, height: 30,),
                ),
              ),
            ),
          )
          : ClipOval(
            child: ProfilePhoto(width: 40, height: 40,),
          )
        )
        : (
          isLoading
          ? Shimmer.fromColors(child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(100))), height: 40, width: 40), baseColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.white10, highlightColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.white12)
          : ((user.stories != null && user.stories.length > 0)
            ? GestureDetector(
              onTap: () async {
                await RivalProvider.vibrate();
                Navigator.of(context).push(RivalNavigator(page: ViewStory(launchedFromHomeScreen: false, users: [user],)));
              },
              child: CircularStepProgressIndicator(
                totalSteps: user.stories.length,
                unselectedColor: (user.storyViewed || user.uid == me.user.uid) ? (MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black38 : Colors.white38) : Colors.indigoAccent,
                width: 40,
                height: 40,
                padding: user.stories.length > 1 ? (22/7) / 15 : 0,
                customStepSize: (intn, boo) => 2,
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: ClipOval(
                    child: OctoImage(
                      image: user.photo,
                      placeholderBuilder: (context) => CircularProgressIndicator()
                    ),
                  ),
                ),
              ),
            )
            : ClipOval(
              child: OctoImage(
                image: user.photo,
                placeholderBuilder: (context) => CircularProgressIndicator(),
                width: 40,
                height: 40,
              ),
            )
          )),
        title: isCurrentUser
          ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.subtitle != null) Text(me.username)
              else Flexible(
                flex: 1,
                child: Text(me.displayName, overflow: TextOverflow.ellipsis,)
              ),
              if (me.isVerified) ... [
                Container(width: 10,),
                VerifiedBadge()
              ]
            ],
          )
          : (isLoading
          ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 11,
                width: MediaQuery.of(context).size.width / 2,
                child: Shimmer.fromColors(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(2))
                    ),
                    width: MediaQuery.of(context).size.width * 0.8,
                  ),
                  baseColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.white10,
                  highlightColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black26 : Colors.white12
                ),
              ),
            ],
          )
          : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.subtitle != null ? user.username : user.displayName),
              if (user.isVerified) ... [
                Container(width: 10,),
                VerifiedBadge()
              ]
            ],
          )),
        subtitle: isCurrentUser ? Text(widget.subtitle != null ? widget.subtitle : me.username) : (isLoading ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 11,
              width: MediaQuery.of(context).size.width / 3,
              child: Shimmer.fromColors(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(2))
                  ),
                  width: MediaQuery.of(context).size.width * 0.8,
                ),
                baseColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.white10,
                highlightColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black26 : Colors.white10
              ),
            ),
          ],
        ) : Text(widget.subtitle != null ? widget.subtitle : user.username)),
        trailing: (isLoading || isCurrentUser) ? null : FlatButton(
          onPressed: () async {
            await RivalProvider.vibrate();
            user.followUnfollowRequest();
          },
          child: StreamBuilder<DocumentSnapshot>(
            stream: user.reference.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active) {
                user = RivalUser(doc: snapshot.data);
                return Text(user.followUnfollow, style: TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold),);
              }
              return Text(user.followUnfollow, style: TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold),);
            },
          ),
          splashColor: Colors.indigoAccent.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10))
          ),
        ),
        onTap: () {
          if (!isLoading) {
            user.navigateToProfile(context);
          }
        },
      ),
    );
  }
}


// -----------------------------------------------Functions---------------------------------------------------

RemoteConfig remoteConfig;
Map<String, dynamic> rivalDefaults = {
  'app_available': true,
  'app_name': 'Rival',
  'allow_new_post': true,
  'allow_edit_post': true,
  'allow_new_story': true,
  'allow_name_change': true,
};
Future<void> initRemoteConfig() async {
  remoteConfig = await RemoteConfig.instance;
  await remoteConfig.setDefaults(rivalDefaults);
  await remoteConfig.fetch(expiration: Duration(hours: 1));
  await remoteConfig.activateFetched();
  print('Remote Config: ${remoteConfig.getAll()}');
  print('App Name from Remote Config: ${remoteConfig.getString('app_name')}');
  print('Loaded Remote Config for Rival');
}
class RivalRemoteConfig {
  static bool get appAvailable => remoteConfig.getBool('app_available');
  static String get appName => remoteConfig.getString('app_name');
  static bool get allowNewPost => remoteConfig.getBool('allow_new_post');
  static bool get allowEditPost => remoteConfig.getBool('allow_edit_post');
  static bool get allowNewStory => remoteConfig.getBool('allow_new_story');
  static bool get allowNameChange => remoteConfig.getBool('allow_name_change');
}

List<Post> topPosts;
Future<List> getTopPosts({int page = 1, bool returnNextPageOnly = false}) async {
  int postsPerPage = 21;

  if (topPosts != null && page == 1) {
    if (topPosts.length > 21) {
      return topPosts.getRange(0, 21).toList(); // Posts of required page are already loaded. Return Range
    } else {
      return topPosts; // Posts of required page are already loaded. Return Range
    }
  } else if (topPosts != null && page > 1 && topPosts.length >= (postsPerPage * page)) {
    return topPosts.getRange(postsPerPage * (page - 1), postsPerPage * page).toList(); // Posts of required page are already loaded. Return Range
  }

  List<Post> topPostsL = [];

  int timestamp = DateTime.now().subtract(Duration(days: 7)).millisecondsSinceEpoch; // (Method 1) Get Top Posts from last 7 Days

  Query query = firestore.collection('posts').orderBy('timestamp', descending: true).limit(postsPerPage);

  if (getTop10Interests().isEmpty) {
    query = query.where('timestamp', isGreaterThanOrEqualTo: timestamp);
  } else {
    query = query.where('labels', arrayContainsAny: getTop10Interests()); // (Method 2) Or get according to my interests
  }

  if (page > 1) query = query.startAfterDocument(topPosts.last.doc);

  QuerySnapshot querySnapshot = await query.get();

  for (DocumentSnapshot doc in querySnapshot.docs) {
    Post post = await Post.fetch(doc: doc);
    RivalUser postOwner = await getUser(post.userId);
    if (((postOwner.private && postOwner.isFollowing) || !postOwner.private) && post.available && !post.takenDown) {
      topPostsL.add(post);
    }
  }
  
  if (page == 1) {
    List<Post> ads = await getAds();
  
    if (ads.isNotEmpty) {
      if (topPostsL.length >= 2) topPostsL.insert(1, ads.first);
      if (topPostsL.length >= 14) topPostsL.insert(13, ads.elementAtOrElse(1, () => ads.first));
      if (topPostsL.length >= 27) topPostsL.insert(26, ads.elementAtOrElse(2, () => ads.first));
      if (topPostsL.length >= 38) topPostsL.insert(38, ads.elementAtOrElse(3, () => ads.first));
    }

  }

  if (topPosts == null) topPosts = topPostsL;
  else topPosts.addAll(topPostsL);

  if (returnNextPageOnly) {
    return topPostsL;
  } else {
    return topPosts;
  }

  // if (topPosts != null || topPostsCompleter.isCompleted) return topPosts;
  // topPostsCompleter = Completer<List<Post>>();
  // List<Post> topPostsL = [];
  // int timestamp = DateTime.now().subtract(Duration(days: 7)).millisecondsSinceEpoch;
  // QuerySnapshot q = await firestore.collection('posts').where('timestamp', isGreaterThanOrEqualTo: timestamp).orderBy('timestamp', descending: true).get();
  // for (DocumentSnapshot d in q.docs) {
  //   Post post = Post(doc: d);
  //   RivalUser u = await getUser(post.userId);
  //   if (!u.private && u.uid != me.uid && post.available && !post.takenDown) {
  //     topPostsL.add(post);
  //   } else if (u.private && u.isFollowing && u.uid != me.uid && !post.takenDown) {
  //     topPostsL.add(post);
  //   }
  // }
  // topPosts = topPostsL;
  // if (topPostsCompleter.isCompleted) topPostsCompleter.complete(topPosts);
  // return topPostsCompleter.future;
}

Future<List<Post>> getAds({int limit = 10}) async {
  List<Post> ads = [];
  List<String> top10Interests = getTop10Interests();
  QuerySnapshot querySnapshot;
  if (top10Interests.isEmpty) {
    querySnapshot = await firestore.collection('posts').where('promoted', isEqualTo: true).orderBy('timestamp', descending: true).limit(limit).get();
  } else {
    querySnapshot = await firestore.collection('posts').where('promoted', isEqualTo: true).where('labels', arrayContainsAny: getTop10Interests()).orderBy('timestamp', descending: true).limit(limit).get();
  }
  for (DocumentSnapshot doc in querySnapshot.docs) {
    DocumentSnapshot adDoc = await firestore.collection('rival').doc('promotions').collection('posts').doc(doc.id).get();
    if (adDoc != null && adDoc.exists) {
      Post post = await Post.fetch(doc: doc, ad: adDoc);
      print('Posts\' Ad Document: ${post.ad.data()}. Post is an AD: ${post.isPromoted}. Is AD Valid: ${post.isAdValid}');
      ads.add(post);
    }
  }
  return ads;
}

Future<String> createDynamicURL({
  String uriPrefix = 'https://rival.page.link',
  String link,
  String title,
  String description
}) async {
  try {
    Response response = await Dio().post("https://firebasedynamiclinks.googleapis.com/v1/shortLinks?key=AIzaSyBlZY0sCjz_eC_qMn1H9kwIy42oiB6ZStI", data: {
      "dynamicLinkInfo": {
        "domainUriPrefix": '$uriPrefix',
        "link": '$link',
        "androidInfo": {
          "androidPackageName": "photography.rival"
        },
        "socialMetaTagInfo": {
          "socialTitle": '$title',
          "socialDescription": '$description',
        }
      }
    }, options: Options(responseType: ResponseType.json));
    if (response.statusCode.isBetween(200, 299)) {
      // SUCCESS
      String url = response.data['shortLink'];
      return url;
    }
    print("Status Code: ${response.statusCode}, Message: ${response.statusMessage}");
    // Failed due to some reason
    return null;
  } catch (e) {
    print(e);
    return null;
  }
}

Future<Map<String, int>> getTopTags() async {
  if (topTags != null) return topTags;
  Map tagsOfWeek = (await firestore.collection('rival').doc('tags').get()).data()[weekOfYear().toString()] ?? {};
  List sortedKeys = tagsOfWeek.keys.toList(growable:false)..sort((k1, k2) => tagsOfWeek[k1].compareTo(tagsOfWeek[k2]));
  LinkedHashMap sortedMap = new LinkedHashMap.fromIterable(sortedKeys, key: (k) => k, value: (k) => tagsOfWeek[k]);
  topTags = {};
  int atLeastPostsForTrending = 50;
  for(var i = 0; i < sortedMap.length; i++) {
    String key = sortedMap.keys.toList()[i];
    int value = sortedMap.values.toList()[i];
    if (value >= atLeastPostsForTrending) topTags[key] = value;
  }
  return topTags;
}

Future<Map<String, int>> getTopTags2() async {
  if (topTags != null) return topTags;
  List tagsOfWeek = (await firestore.collection('rival').doc('tags').get()).data()[weekOfYear().toString()] ?? [];
  List list = tagsOfWeek.map((e) => e).toList();
  Map topTagsL = {};
  var maxOccurrence = 0;
  var i = 0;
  while (i < list.length) {
    String tag = list[i];
    var occurrence = 1;
    for (int j = 0; j < list.length; j++) {
      if (j == i) {
        continue;
      }
      else if (tag == list[j]) {
        occurrence++;
      }
    }
    list.removeWhere((it) => it == tag);
    topTagsL[tag] = occurrence;
    if (maxOccurrence < occurrence) {
      maxOccurrence = occurrence;
    }
  }
  topTagsL.removeWhere((key, value) => value < 5); // Remove Tag if it has less than 5 Posts
  var sortedKeys = topTagsL.keys.toList(growable:false)
  ..sort((k1, k2) => topTagsL[k2].compareTo(topTagsL[k1]));
  LinkedHashMap sortedMap = new LinkedHashMap.fromIterable(sortedKeys, key: (k) => k, value: (k) => topTagsL[k]);
  topTags = {};
  for(var i = 0; i < sortedMap.length; i++) {
    String key = sortedMap.keys.toList()[i];
    int value = sortedMap.values.toList()[i];
    topTags[key] = value;
  }
  print(topTags);
  return topTags;
}

String getTimeAgo(DateTime date, {bool includeHour = false}) {
  String timeAgo = timeago.format(date);

  int timestamp = date.millisecondsSinceEpoch;

  if (new DateTime.now().subtract(Duration(days: 30)).millisecondsSinceEpoch > timestamp) {
    // More than a month ago
    timeAgo = "${date.day} ${months[date.month]}${date.year != DateTime.now().year ? ' ' + date.year.toString() : ''}" + (includeHour ? (" at ${date.hour}.${date.minute}") : "");
  }

  return timeAgo;
}

/// Check internet connectivity
Future<bool> checkInternetConnectivity() async {
  try {
    final result = await InternetAddress.lookup('google.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  } on SocketException catch (_) {
    return false;
  }
}

List<String> getTop10Interests() {
  var sortedKeys = me.interests.keys.toList(growable:false)
   ..sort((k1, k2) => me.interests[k2].compareTo(me.interests[k1]));
  LinkedHashMap sortedMap = new LinkedHashMap.fromIterable(sortedKeys, key: (k) => k, value: (k) => me.interests[k]);

  List<String> top10Interests = [];

  int length = sortedMap.length >= 10 ? 10 : sortedMap.length;

  for(var i = 0; i < length; i++) {
    top10Interests.add(sortedMap.keys.toList()[i]);
  }
  return top10Interests;
}

/// Crop Profile Picture
Future<File> cropProfilePicture({@required String path}) async {
  final File file = await ImageCropper.cropImage(
    sourcePath: path,
    aspectRatioPresets: [
      CropAspectRatioPreset.square,
    ],
    maxHeight: 512,
    maxWidth: 512,
    androidUiSettings: const AndroidUiSettings(
      toolbarTitle: 'Crop Profile Photo',
      toolbarColor: Colors.indigo,
      toolbarWidgetColor: Colors.white,
      initAspectRatio: CropAspectRatioPreset.original,
      lockAspectRatio: true
    ),
    iosUiSettings: const IOSUiSettings(
      minimumAspectRatio: 1.0,
    )
  );
  return file;
}

extension RivalListsExtension<T> on List<T> {
  T getRandom() {
    int lth = this.length;
    int random = Random().nextInt(lth);
    return this[random];
  }
}