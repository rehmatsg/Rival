import 'dart:async';
import 'dart:io';

import 'package:animations/animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_admob/native_admob_options.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:octo_image/octo_image.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supercharged/supercharged.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter_native_admob/flutter_native_admob.dart';
import 'package:flutter_native_admob/native_admob_controller.dart';
import 'app.dart';
// import 'test.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  sharedPreferences = await SharedPreferences.getInstance();
  firestore = FirebaseFirestore.instance;
  database = FirebaseDatabase.instance;
  await initRemoteConfig();
  runApp(Rival());
}

class Rival extends StatefulWidget {
  @override
  _RivalState createState() => _RivalState();
}

class _RivalState extends State<Rival> {

  Widget initialRoute = Home();

  @override
  void initState() {
    FirebaseMessaging().setAutoInitEnabled(true);
    // Initialize 3D Touch shortcuts
    final QuickActions quickActions = QuickActions();
    quickActions.initialize((String shortcutType) {
      if (shortcutType == "new_post") {
        initialRoute = CreatePost();
      } else if (shortcutType == "account") {
        initialRoute = Account();
      } else if (shortcutType == "explore") {
        initialRoute = Explore();
      }
    });
    // quickActions.setShortcutItems(<ShortcutItem>[
    //   const ShortcutItem(
    //     type: 'account',
    //     localizedTitle: 'My Account',
    //     icon: 'account'
    //   ),
    //   const ShortcutItem(
    //     type: 'new_post',
    //     localizedTitle: 'New Post',
    //     icon: 'new_post'
    //   ),
    //   const ShortcutItem(
    //     type: 'explore',
    //     localizedTitle: 'Explore',
    //     icon: 'explore'
    //   ),
    //   const ShortcutItem(
    //     type: 'Home',
    //     localizedTitle: 'Rival',
    //     icon: 'Home'
    //   ),
    // ]);
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rival',
      color: Colors.indigo,
      theme: lightTheme,
      darkTheme: darkTheme,
      home: LandingPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LandingPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser != null) {
      me = Me();
      me.firebaseUser = FirebaseAuth.instance.currentUser;
      return FutureBuilder(
        future: me.init(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && !snapshot.hasError) {
            //getMyPosts();
            //getTopPosts();
            if ((me.data['devices'] as Map).isEmpty || (!(me.data['devices'] as Map).containsKey(me.loginTimestamp))) {
              RivalProvider.showToast(text: 'Failed to login. ERR-LGD-OT');
              FirebaseAuth.instance.signOut();
              sharedPreferences.remove('token');
              me = null;
              Future.delayed(Duration(milliseconds: 500), () => Navigator.of(context).pushReplacement(RivalNavigator(page: SignIn(),)));
            } else {
              getTopTags();
              Future.delayed(Duration(milliseconds: 500), () => Navigator.of(context).pushReplacement(RivalNavigator(page: Home(),)));
            }
          } else if (snapshot.connectionState == ConnectionState.done && snapshot.hasError) {
            RivalProvider.showToast(text: 'Failed to login. ERR-PRM-DND');
          }
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: ClipOval(
                      child: OctoImage(
                        image: me.photo,
                        height: 100,
                        width: 100,
                        placeholderBuilder: (context) => Container(
                          height: 100,
                          width: 100,
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  ),
                  Text('Rival', style: TextStyle(fontFamily: RivalFonts.rival, fontSize: Theme.of(context).textTheme.headline3.fontSize),),
                ],
              ),
            ),
          );
        },
      );
    } else {
      return SignIn();
    }
  }

}

List<Widget> postItems;
List<Post> feed;
List<RivalUser> allStories;
List<Widget> storyItems;

// class Home extends StatefulWidget {
//   @override
//   _HomeState createState() => _HomeState();
// }

// class _HomeState extends State<Home> {

//   final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
//   ScrollController scrollController = ScrollController(keepScrollOffset: true,);

//   int page = 1;

//   bool isPostLoading = true;
//   bool postsAvailable = true;
//   bool isNextPageLoading = false;
//   bool isStoriesLoading = true;

//   String title = RivalRemoteConfig.appName;

//   Future<void> initDynamicLinks() async {
//     FirebaseDynamicLinks.instance.onLink( // This occurs when app was not running before and app was started by the dynamic link
//       onSuccess: (PendingDynamicLinkData dynamicLink) async {
//         final Uri deepLink = dynamicLink?.link;
//         if (deepLink != null) {
//           deepLinkAction(deepLink);
//         }
//       },
//       onError: (OnLinkErrorException e) async {
//         print('DeepLink Error: ${e.message}');
//       },
//     );
    
//     final PendingDynamicLinkData data = await FirebaseDynamicLinks.instance.getInitialLink(); // This occurs when Dynamic Link is opened when app is already running
//     final Uri deepLink = data?.link;

//     if (deepLink != null) {
//       deepLinkAction(deepLink);
//     }
//   }

//   Future<void> deepLinkAction(Uri deepLink) async {
//     // Example https://rival.photography/posts/y6F3vJ
//     String type = deepLink.pathSegments[0]; // posts
//     String lastPath = deepLink.pathSegments.last; // y6F3vJ
//     print('$type/$lastPath'); // posts/y6F3vJ
//     if (type == 'profile') {
//       RivalProvider.showToast(text: 'Loading $lastPath Profile ...');
//       RivalUser user = await RivalProvider.getUserByUsername(lastPath.replaceAll('@', ''));
//       if (user != null && user.uid != me.uid) {
//         Navigator.of(context).push(RivalNavigator(page: ProfilePage(user: user,),));
//       } else if (user != null && user.uid == me.uid) {
//         Navigator.of(context).push(RivalNavigator(page: ProfilePage(isCurrentUser: true,),));
//       }
//     } else if (type == 'post') {
//       Navigator.of(context).push(RivalNavigator(page: SinglePostView(postId: lastPath),));
//     }
//   }

//   void _handleSharedMedia(List<SharedMediaFile> sharedMediaFiles) {
//     if (sharedMediaFiles != null) {
//       bool containsVideo = sharedMediaFiles.indexWhere((element) => element.type == SharedMediaType.VIDEO) >= 0;
//       WidgetsBinding.instance.addPostFrameCallback((_) => showModalBottomSheet(
//         context: context,
//         builder: (context) => Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Padding(
//               padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10,),
//               child: Text('Share (${sharedMediaFiles.length}) Files', style: Theme.of(context).textTheme.headline6.copyWith(fontFamily: RivalFonts.feature),),
//             ),
//             if (sharedMediaFiles.length > 1 && !containsVideo) ... [
//               // Show only Create Post option
//               ListTile(
//                 title: Text('Create Post'),
//                 trailing: Icon(Icons.keyboard_arrow_right),
//                 onTap: () => Navigator.of(context).push(RivalNavigator(page: CreatePost(sharedMediaFiles: sharedMediaFiles,),)),
//               )
//             ] else if (sharedMediaFiles.length == 1 && !containsVideo) ... [
//               // Show both Create Post and Create Story
//               ListTile(
//                 title: Text('Create Story'),
//                 trailing: Icon(Icons.keyboard_arrow_right),
//                 onTap: () => Navigator.of(context).push(RivalNavigator(page: CreateStory(sharedMediaFile: sharedMediaFiles.first,),)),
//               ),
//               ListTile(
//                 title: Text('Create Post'),
//                 trailing: Icon(Icons.keyboard_arrow_right),
//                 onTap: () => Navigator.of(context).push(RivalNavigator(page: CreatePost(sharedMediaFiles: sharedMediaFiles,),)),
//               ),
//             ] else if (sharedMediaFiles.length == 1 && containsVideo) ... [
//               // Show only Create Story
//               ListTile(
//                 title: Text('Create Story'),
//                 trailing: Icon(Icons.keyboard_arrow_right),
//                 onTap: () => Navigator.of(context).push(RivalNavigator(page: CreateStory(sharedMediaFile: sharedMediaFiles.first,),)),
//               )
//             ] else ... [
//               ListTile(
//                 title: Text('Oops, could not find suitable create option'),
//               )
//             ]
//           ],
//         ),
//       ));
//     }
//   }

//   @override
//   void initState() {
//     FirebaseMessaging().configure(
//       onMessage: (message) async {
//         await RivalProvider.showToast(text: message['notification']['title']);
//       },
//       onResume: (message) async {
//         await RivalProvider.showToast(text: message['notification']['title']);
//       },
//     );
//     // ignore: unused_local_variable, cancel_subscriptions
//     StreamSubscription _intentDataStreamSubscription;
//     // Get files shared from Gallery
//     _intentDataStreamSubscription = ReceiveSharingIntent.getMediaStream().listen((List<SharedMediaFile> sharedMediaFiles) {
//       _handleSharedMedia(sharedMediaFiles);
//     }, onError: (err) {
//       print("getIntentDataStream error: $err");
//     });
//     ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> sharedMediaFiles) {
//       _handleSharedMedia(sharedMediaFiles);
//     });
//     int postsLoadStartTime = new DateTime.now().millisecondsSinceEpoch;
//     if (feed == null) getCachedPosts().then((value) async => await getPostsFromServer(startTime: postsLoadStartTime));
//     if (storyItems == null) {
//       _getStories();
//     } else {
//       isPostLoading = false;
//       isStoriesLoading = false;
//     }
//     super.initState();
//     this.initDynamicLinks();
//   }

//   @override
//   void setState(fn) {
//     if (mounted) super.setState(fn);
//   }

//   @override
//   Widget build(BuildContext context) {
//     bool darkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
//     return Scaffold(
//       appBar: AppBar(
//         title: GestureDetector(
//           onTap: () => scrollController.animateTo(0, duration: Duration(seconds: 2), curve: Curves.easeInOut),
//           onDoubleTap: () {
//             RivalProvider.vibrate();
//             RivalProvider.showToast(text: 'Gill co');
//           },
//           onLongPress: () {
//             RivalProvider.vibrate(long: true);
//             RivalProvider.showToast(text: 'Made in India');
//           },
//           child: Text(title, style: TextStyle(
//             fontFamily: RivalFonts.rival
//           ),),
//         ),
//         backgroundColor: darkMode ? Colors.black : Colors.white,
//         actions: [
//           if (me.dob == null || me.displayName == null) IconButton(
//             icon: Icon(Icons.warning, color: Colors.yellow,),
//             tooltip: 'Complete Account Setup',
//             onPressed: () {
//               Navigator.of(context).push(RivalNavigator(page: SetupAccount(),));
//             }
//           ),
//           IconButton(
//             icon: Icon(Icons.search),
//             tooltip: 'Search',
//             onPressed: () => showSearch(
//               context: context,
//               delegate: RivalSearchDelegate()
//             )
//           ),
//           IconButton(
//             icon: Icon(Icons.explore),
//             tooltip: 'Explore',
//             onPressed: () async {
//               Navigator.of(context).push(RivalNavigator(page: ExplorePage(),));
//             }
//           ),
//           Padding(
//             padding: const EdgeInsets.all(13),
//             child: GestureDetector(
//               onTap: () {
//                 Navigator.push(
//                   context, RivalNavigator(page: ProfilePage(isCurrentUser: true)),
//                 );
//               },
//               onLongPress: () {
//                 Navigator.of(context).push(RivalNavigator(page: SettingsPage(),));
//               },
//               child: ProfilePhoto(width: 30, height: 30),
//             ),
//           )
//         ],
//       ),
//       body: WillPopScope(
//         onWillPop: () async {
//           if (scrollController.offset > 150) {
//             scrollController.animateTo(0, duration: Duration(seconds: 2), curve: Curves.ease);
//             return false;
//           } else {
//             await SystemNavigator.pop();
//             return true;
//           }
//         },
//         child: RefreshIndicator(
//           backgroundColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[100] : Colors.grey[900],
//           onRefresh: reload,
//           child: SingleChildScrollView(
//             controller: scrollController,
//             child: Column(
//               children: [
//                 _buildStories(),
//                 // if (feed != null) ListView.builder(
//                 //   shrinkWrap: true,
//                 //   physics: NeverScrollableScrollPhysics(),
//                 //   cacheExtent: 999999,
//                 //   itemCount: feed.length,
//                 //   itemBuilder: (context, index) => ViewPost(post: feed[index],),
//                 // ),
//                 if (!isPostLoading) ... [
//                   _buildPosts(),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       if (postsAvailable) ... [
//                         if (isNextPageLoading) Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 15),
//                           child: SizedBox(
//                             width: 24,
//                             height: 24,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                               valueColor: AlwaysStoppedAnimation(MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black : Colors.white),
//                             ),
//                           )
//                         ) else VisibilityDetector(
//                           key: UniqueKey(),
//                           onVisibilityChanged: (info) {
//                             if (info.visibleFraction == 1) _nextPage();
//                           },
//                           child: IconButton(
//                             tooltip: 'Load More Posts',
//                             onPressed: () async {
//                               _nextPage();
//                             },
//                             icon: Icon(Icons.add_circle),
//                           ),
//                         ),
//                       ] else ... [
//                         Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 15),
//                           child: Text(
//                             'Open Explore tab to discover more posts',
//                             style: Theme.of(context).textTheme.caption
//                           ),
//                         )
//                       ]
//                     ]
//                   )
//                 ]
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildPosts() {
//     List<Widget> widgets = [];
//     feed.forEachIndexed((index, element) {
//       // widgets.add(PostView(post: feed[index], key: ObjectKey(feed[index].id), cardMargin: EdgeInsets.symmetric(vertical: 5),));
//       widgets.add(ViewPost(post: feed[index], key: ObjectKey(feed[index].id),));
//     });
//     // widgets.insert(2, Ad(controller: adCtrl,));
//     if (!RivalRemoteConfig.allowNewPost) widgets.insert(0, MaterialBanner(
//       contentTextStyle: TextStyle(color: Colors.black),
//       leading: Icon(Icons.warning, color: Colors.black87,),
//       backgroundColor: Colors.yellow[300],
//       content: Text('New Posts have been disabled for a limited time.'),
//       forceActionsBelow: true,
//       actions: [
//         FlatButton(
//           child: Text('Learn More', style: TextStyle(color: Colors.black),),
//           onPressed: () async => await launch('https://rival.photography/help/post/new/disabled'),
//         ),
//       ]
//     ));
//     if (!RivalRemoteConfig.allowNewStory) widgets.insert(0, MaterialBanner(
//       contentTextStyle: TextStyle(color: Colors.black),
//       leading: Icon(Icons.warning, color: Colors.black87,),
//       backgroundColor: Colors.yellow[300],
//       content: Text('New Stories have been disabled for a limited time.'),
//       forceActionsBelow: true,
//       actions: [
//         FlatButton(
//           child: Text('Learn More', style: TextStyle(color: Colors.black),),
//           onPressed: () async => await launch('https://rival.photography/help/story/new/disabled'),
//         ),
//       ]
//     ));
//     if (!RivalRemoteConfig.allowEditPost) widgets.insert(0, MaterialBanner(
//       contentTextStyle: TextStyle(color: Colors.black),
//       leading: Icon(Icons.warning, color: Colors.black87,),
//       backgroundColor: Colors.yellow[300],
//       content: Text('Post Editing has been disabled for a limited time.'),
//       forceActionsBelow: true,
//       actions: [
//         FlatButton(
//           child: Text('Learn More', style: TextStyle(color: Colors.black),),
//           onPressed: () async => await launch('https://rival.photography/help/post/edit/disabled'),
//         ),
//       ]
//     ));
//     return ListView.builder(
//       itemCount: widgets.length,
//       itemBuilder: (BuildContext context, int index) => widgets[index],
//       cacheExtent: 999999,
//       shrinkWrap: true,
//       physics: NeverScrollableScrollPhysics(),
//     );
//   }

//   Future<void> getCachedPosts() async {

//     setState(() {
//       isPostLoading = true;
//     });

//     List<DocumentSnapshot> cachedDocs = await RivalProvider.getPaginatedPosts(1, source: Source.cache);
//     List<Post> cachedPosts = [];

//     for (DocumentSnapshot doc in cachedDocs) {
//       // cachedPosts.add(Post(doc: doc));
//       Post post = await Post.fetch(doc: doc);
//       print(doc.id);
//       cachedPosts.add(post);
//     }

//     setState(() {
//       feed = cachedPosts;
//       isPostLoading = false;
//     });

//     print("feed: $feed");
//     print("Cached Posts: $cachedPosts");

//     // Get ads from Rival Firestore Database
//     // And put them into feed
//     List<Post> ads = await getAds();

//     if (ads.isNotEmpty) {
//       if (feed.length >= 2 && scrollController.offset < MediaQuery.of(context).size.height) feed.insert(2, ads.elementAtOrElse(0, () => ads.first));
//       if (feed.length >= 7 && ads.length > 1) feed.insert(8, ads.elementAtOrElse(1, () => ads.first));
//       if (feed.length >= 14 && ads.length > 2) feed.insert(14, ads.elementAtOrElse(2, () => ads.first));
//       if (feed.length >= 20 && ads.length > 3) feed.insert(20, ads.elementAtOrElse(3, () => ads.first));
//       if (feed.length >= 25 && ads.length > 4) feed.insert(25, ads.elementAtOrElse(4, () => ads.first));
//       if (feed.length >= 29 && ads.length > 5) feed.insert(29, ads.elementAtOrElse(5, () => ads.first));
//     }

//     try {
//       setState(() { });
//     } catch (e) {}

//   }

//   /// This Function checks if new posts are available if they are not present in cache
//   Future<void> getPostsFromServer({bool isRefresh = false, int startTime}) async {
//     List<DocumentSnapshot> serverDocs = await RivalProvider.getPaginatedPosts(1, source: Source.server);

//     if (serverDocs == null || serverDocs.isEmpty) return;

//     /// This is the list of [Post]s only in server i.e. not cached
//     List<Post> serverPosts = [];
    
//     for (DocumentSnapshot doc in serverDocs) {
//       // serverPosts.add(Post(doc: doc));
//       Post post = await Post.fetch(doc: doc);
//       serverPosts.add(post);
//     }

//     List<Post> onlyInServerList = serverPosts.where((post) {
//       return ( (feed.indexWhere((element) => element.id == post.id) < 0) && !post.promoted );
//     }).toList();

//     bool isTimeLessThan2Sec = false;
//     int endTime = new DateTime.now().millisecondsSinceEpoch;

//     if (startTime != null) {
//       double timeElapsed = (endTime - startTime) / 1000; // in seconds
//       if (timeElapsed < 2) isTimeLessThan2Sec = true;
//     }

//     // If Server List has any new posts, show a SnackBar for user to reload
//     if (onlyInServerList.isNotEmpty && !isRefresh && !isTimeLessThan2Sec) {
//       _scaffoldKey.currentState.showSnackBar(
//         SnackBar(
//           content: Text('New Posts Available'),
//           action: SnackBarAction(
//             label: 'Refresh',
//             onPressed: () {
//               setState(() {
//                 feed = serverPosts;
//               });
//             },
//           ),
//           behavior: SnackBarBehavior.floating,
//         )
//       );
//     } else if (isRefresh || isTimeLessThan2Sec) { // If time taken to load posts from server is less than 2-sec, then set posts without asking user
//       feed = serverPosts;
//     }
//   }

//   Future<void> _nextPage() async {
//     setState(() {
//       page += 1;
//       isNextPageLoading = true;
//     });
//     List<DocumentSnapshot> localPosts = await RivalProvider.getPaginatedPosts(page);
//     List<Post> feedL = [];
//     if (localPosts.isNotEmpty) {
//       for (var doc in localPosts) {
//         // feedL.add(Post(doc: doc));
//         feedL.add(await Post.fetch(doc: doc));
//       }
//       List<Post> ads = await getAds();
//       print("Loaded ${ads.length} Ads");
//       if (ads.isNotEmpty) {
//         if (feedL.length >= 2) feedL.insert(2, ads.elementAtOrElse(0, () => ads.first));
//         if (feedL.length >= 7 && ads.length > 1) feedL.insert(8, ads.elementAtOrElse(1, () => ads.first));
//         if (feedL.length >= 14 && ads.length > 2) feedL.insert(14, ads.elementAtOrElse(2, () => ads.first));
//         if (feedL.length >= 20 && ads.length > 3) feedL.insert(20, ads.elementAtOrElse(3, () => ads.first));
//         if (feedL.length >= 25 && ads.length > 4) feedL.insert(25, ads.elementAtOrElse(4, () => ads.first));
//         if (feedL.length >= 29 && ads.length > 5) feedL.insert(29, ads.elementAtOrElse(5, () => ads.first));
//       }
//     } else {
//       postsAvailable = false;
//     }
//     feed.addAll(feedL);
//     setState(() {
//       isNextPageLoading = false;
//     });
//   }

//   Future<void> reload() async {
//     setState(() {
//       page = 1;
//       postsAvailable = true;
//     });
//     await me.reload();
//     await me.user.reload();
//     RivalProvider.reloadHomeScreen();
//     await RivalProvider.reloadStories();
//     await _getStories();
//     await getPostsFromServer(isRefresh: true);
//   }

//   Widget _buildStories() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 10),
//       child: Container(
//         height: 84, // Calculated using [height of image, padding, font size]
//         child: ListView.builder(
//           physics: BouncingScrollPhysics(),
//           scrollDirection: Axis.horizontal,
//           itemCount: isStoriesLoading ? 4 : (storyItems.length ?? 0),
//           cacheExtent: 9999,
//           itemBuilder: (context, index) => isStoriesLoading
//           ? Padding(
//             padding: EdgeInsets.only(right: 4, left: (index == 0) ? 60 : 4),
//             child: Column(
//               children: [
//                 Shimmer.fromColors(
//                   child: Container(
//                     decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(20))),
//                     height: 60,
//                     width: 60
//                   ),
//                   baseColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.white10,
//                   highlightColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.white12
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.only(top: 5,),
//                   child: Shimmer.fromColors(child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(3))), height: 14, width: 60), baseColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.white10, highlightColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black26 : Colors.white12),
//                 )
//               ],
//             ),
//           )
//           : storyItems[index]
//         ),
//       ),
//     );
//   }

//   Future<void> _getStories() async {
//     setState(() {
//       isStoriesLoading = true;
//     });
//     List<RivalUser> localStories = await RivalProvider.getStories();
//     allStories = localStories;
//     storyItems = [];

//     if (RivalRemoteConfig.allowNewStory) {
//       storyItems.add(Padding(
//         padding: const EdgeInsets.only(right: 5, left: 5),
//         child: Column(
//           children: [
//             Tooltip(
//               message: 'Create Story',
//               child: GestureDetector(
//                 onTap: () => Navigator.of(context).push(RivalNavigator(page: CreateStory(),)),
//                 child: Container(
//                   height: 84,
//                   width: 50,
//                   child: Center(
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Container(
//                           height: 30,
//                           width: 30,
//                           child: Center(child: Icon(Icons.add, color: Colors.white,)),
//                           decoration: BoxDecoration(
//                             color: Colors.indigoAccent,
//                             borderRadius: BorderRadius.all(Radius.circular(30))
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ));
//     }
//     if (me.stories.isNotEmpty) {
//       storyItems.add(
//         Padding(
//           padding: const EdgeInsets.only(right: 5),
//           child: Container(
//             width: 60,
//             height: 84,
//             child: Column(
//               children: [
//                 OpenContainer(
//                   closedBuilder: (context, action) => Container(
//                     height: 60,
//                     width: 60,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.all(Radius.circular(20))
//                     ),
//                     child: Hero(
//                       tag: 'story-${me.uid}',
//                       child: ClipRRect(
//                         borderRadius: BorderRadius.all(Radius.circular(20)),
//                         child: Image(image: me.photo, fit: BoxFit.cover,),
//                       ),
//                     ),
//                   ),
//                   closedElevation: 0,
//                   closedColor: Colors.transparent,
//                   openElevation: 0,
//                   openBuilder: (context, action) {
//                     if (me.stories.isNotEmpty) {
//                       return ViewStory(launchedFromHomeScreen: false, users: <RivalRootUser>[me],);
//                     } else {
//                       return CreateStory();
//                     }
//                   },
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.only(top: 5),
//                   child: Text('${me.username}', overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: RivalFonts.feature)),
//                 )
//               ],
//             ),
//           ),
//         )
//       );
//     }
//     for (RivalUser user in localStories) {
//       storyItems.add(
//         Padding(
//           padding: const EdgeInsets.only(right: 5),
//           child: StreamProvider<RivalUser>.value(
//             value: user.stream,
//             initialData: user,
//             lazy: false,
//             updateShouldNotify: (previous, current) {
//               if (mapEquals(previous.stories, current.stories)) {
//                 return false;
//               } else {
//                 return true;
//               }
//             },
//             builder: (context, child) {
//               RivalUser user = Provider.of<RivalUser>(context);
//               return Container(
//                 width: 60,
//                 height: 84,
//                 child: Column(
//                   children: [
//                     OpenContainer(
//                       closedBuilder: (context, action) => Container(
//                         height: 60,
//                         width: 60,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.all(Radius.circular(20)),
//                           border: user.storyViewed ? Border.all(style: BorderStyle.none) : Border.all(color: Colors.indigoAccent, width: 2, style: BorderStyle.solid)
//                         ),
//                         child: Hero(
//                           tag: 'story-${user.uid}',
//                           child: Padding(
//                             padding: EdgeInsets.all(user.storyViewed ? 0 : 2),
//                             child: ClipRRect(
//                               borderRadius: BorderRadius.all(Radius.circular(user.storyViewed ? 20 : 16)),
//                               child: Image(
//                                 image: user.photo,
//                                 fit: BoxFit.cover,
//                                 width: user.storyViewed ? 60 : 55,
//                                 height: user.storyViewed ? 60 : 55,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       closedElevation: 0,
//                       closedColor: Colors.transparent,
//                       openElevation: 0,
//                       openBuilder: (context, action) => ViewStory(initialIndex: localStories.indexWhere((RivalUser u) => u.uid == user.uid),),
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.only(top: 5),
//                       child: Text('${user.username}', overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: RivalFonts.feature)),
//                     )
//                   ],
//                 ),
//               );
//             },
//           ),
//         )
//       );
//     }
//     setState(() {
//       isStoriesLoading = false;
//     });
//   }

// }

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  ScrollController scrollController = ScrollController(keepScrollOffset: true,);

  int page = 1;

  bool isPostLoading = true;
  bool postsAvailable = true;
  bool isNextPageLoading = false;
  bool isStoriesLoading = true;

  String title = RivalRemoteConfig.appName;

  NativeAdmobController adCtrl = NativeAdmobController();

  Future<void> initDynamicLinks() async {
    FirebaseDynamicLinks.instance.onLink( // This occurs when app was not running before and app was started by the dynamic link
      onSuccess: (PendingDynamicLinkData dynamicLink) async {
        final Uri deepLink = dynamicLink?.link;
        if (deepLink != null) {
          deepLinkAction(deepLink);
        }
      },
      onError: (OnLinkErrorException e) async {
        print('DeepLink Error: ${e.message}');
      },
    );
    
    final PendingDynamicLinkData data = await FirebaseDynamicLinks.instance.getInitialLink(); // This occurs when Dynamic Link is opened when app is already running
    final Uri deepLink = data?.link;

    if (deepLink != null) {
      deepLinkAction(deepLink);
    }
  }

  Future<void> deepLinkAction(Uri deepLink) async {
    // Example https://rival.photography/posts/y6F3vJ
    String type = deepLink.pathSegments[0]; // posts
    String lastPath = deepLink.pathSegments.last; // y6F3vJ
    print('$type/$lastPath'); // posts/y6F3vJ
    if (type == 'profile') {
      String username = lastPath.replaceAll('@', '');
      if (username != me.username) {
        Navigator.of(context).push(RivalNavigator(page: ProfilePage(username: username,),));
      } else if (username != me.username) {
        Navigator.of(context).push(RivalNavigator(page: ProfilePage(isCurrentUser: true,),));
      }
    } else if (type == 'post') {
      Navigator.of(context).push(RivalNavigator(page: SinglePostView(postId: lastPath),));
    }
  }

  void _handleSharedMedia(List<SharedMediaFile> sharedMediaFiles) {
    if (sharedMediaFiles != null) {
      bool containsVideo = sharedMediaFiles.indexWhere((element) => element.type == SharedMediaType.VIDEO) >= 0;
      WidgetsBinding.instance.addPostFrameCallback((_) => showModalBottomSheet(
        context: context,
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10,),
              child: Text('Share (${sharedMediaFiles.length}) Files', style: Theme.of(context).textTheme.headline6.copyWith(fontFamily: RivalFonts.feature),),
            ),
            if (sharedMediaFiles.length > 1 && !containsVideo) ... [
              // Show only Create Post option
              ListTile(
                title: Text('Create Post'),
                trailing: Icon(Icons.keyboard_arrow_right),
                onTap: () => Navigator.of(context).push(RivalNavigator(page: CreatePost(sharedMediaFiles: sharedMediaFiles,),)),
              )
            ] else if (sharedMediaFiles.length == 1 && !containsVideo) ... [
              // Show both Create Post and Create Story
              ListTile(
                title: Text('Create Story'),
                trailing: Icon(Icons.keyboard_arrow_right),
                onTap: () => Navigator.of(context).push(RivalNavigator(page: CreateImageStory(image: File(sharedMediaFiles.first.path),),)),
              ),
              ListTile(
                title: Text('Create Post'),
                trailing: Icon(Icons.keyboard_arrow_right),
                onTap: () => Navigator.of(context).push(RivalNavigator(page: CreatePost(sharedMediaFiles: sharedMediaFiles,),)),
              ),
            ] else if (sharedMediaFiles.length == 1 && containsVideo) ... [
              // Show only Create Story
              ListTile(
                title: Text('Create Story'),
                trailing: Icon(Icons.keyboard_arrow_right),
                onTap: () => Navigator.of(context).push(RivalNavigator(page: CreateImageStory(image: File(sharedMediaFiles.first.path),),)),
              )
            ] else ... [
              ListTile(
                title: Text('Oops, could not find suitable create option'),
              )
            ]
          ],
        ),
      ));
    }
  }

  @override
  void initState() {
    FirebaseMessaging().configure(
      onMessage: (message) async {
        await RivalProvider.showToast(text: message['notification']['title']);
      },
      onResume: (message) async {
        await RivalProvider.showToast(text: message['notification']['title']);
      },
    );
    // ignore: unused_local_variable, cancel_subscriptions
    StreamSubscription _intentDataStreamSubscription;
    // Get files shared from Gallery
    _intentDataStreamSubscription = ReceiveSharingIntent.getMediaStream().listen((List<SharedMediaFile> sharedMediaFiles) {
      _handleSharedMedia(sharedMediaFiles);
    }, onError: (err) {
      print("getIntentDataStream error: $err");
    });
    ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> sharedMediaFiles) {
      _handleSharedMedia(sharedMediaFiles);
    });
    int postsLoadStartTime = new DateTime.now().millisecondsSinceEpoch;
    getCachedPosts().then((value) async {
      int tries = 0;
      if (me.following.isNotEmpty) while (feed.length < 10 && tries < 5) {
        await _nextPage();
        tries += 1;
      } // Keep getting next page posts until the feed has at least 10 posts.
      await getPostsFromServer(startTime: postsLoadStartTime);
    });
    if (storyItems == null) {
      _getStories();
    } else {
      isPostLoading = false;
      isStoriesLoading = false;
    }
    super.initState();
    this.initDynamicLinks();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: WillPopScope(
        onWillPop: () async {
          if (scrollController.offset > 150) {
            scrollController.animateTo(0, duration: Duration(seconds: 2), curve: Curves.ease);
            return false;
          } else {
            await SystemNavigator.pop();
            return true;
          }
        },
        child: RefreshIndicator(
          backgroundColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[100] : Colors.grey[900],
          onRefresh: refresh,
          child: CustomScrollView(
            cacheExtent: MediaQuery.of(context).size.height * 2, // Caches pixels of current context and two pages above and below
            controller: scrollController,
            slivers: [
              SliverAppBar(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15))
                ),
                title: GestureDetector(
                  onTap: () {
                    if (scrollController.offset > 150) {
                      scrollController.animateTo(0, duration: Duration(seconds: 2), curve: Curves.ease);
                    }
                  },
                  onVerticalDragEnd: (details) {
                    if (scrollController.offset < 150 && title != "Made in India" && title != "Gill co") {
                      setState(() {
                        title = "Made in India";
                      });
                    } else if (scrollController.offset < 150 && title == "Made in India" && title != "Gill co") {
                      setState(() {
                        title = "Gill co";
                      });
                    } else if (scrollController.offset < 150 && title != "Made in India" && title == "Gill co") {
                      setState(() {
                        title = RivalRemoteConfig.appName;
                      });
                    }
                  },
                  child: Text(title, style: TextStyle(fontFamily: title == "Rival" ? RivalFonts.rival : 'Roboto', fontSize: title == "Rival" ? 25 : 20),)
                ),
                actions: [
                  // IconButton(
                  //   icon: Icon(Icons.science),
                  //   tooltip: 'TEST',
                  //   onPressed: () async {
                  //     Navigator.of(context).push(RivalNavigator(page: Test(),));
                  //   }
                  // ),
                  if (me.dob == null || me.displayName == null) IconButton(
                    icon: Icon(Icons.warning, color: Colors.yellow,),
                    tooltip: 'Complete Account Setup',
                    onPressed: () {
                      Navigator.of(context).push(RivalNavigator(page: SetupAccount(),));
                    }
                  ),
                  IconButton(
                    icon: Icon(Icons.search),
                    tooltip: 'Search',
                    onPressed: () => showSearch(
                      context: context,
                      delegate: RivalSearchDelegate()
                    )
                  ),
                  IconButton(
                    icon: Icon(Icons.explore),
                    tooltip: 'Explore',
                    onPressed: () async {
                      Navigator.of(context).push(RivalNavigator(page: Explore(),));
                    }
                  ),
                  Padding(
                    padding: const EdgeInsets.all(13),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context, RivalNavigator(page: ProfilePage(isCurrentUser: true)),
                        );
                      },
                      onLongPress: () {
                        Navigator.of(context).push(RivalNavigator(page: SettingsPage(),));
                      },
                      child: ProfilePhoto(width: 30, height: 30),
                    ),
                  )
                ],
                floating: true,
                backgroundColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.white : Colors.black,
                forceElevated: true,
                elevation: 1.2,
              ),
              _buildStories(),
              if (!isPostLoading) ... [
                _buildPosts(),
                SliverToBoxAdapter(
                  child: Row(
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
                      ] else if (feed.isNotEmpty) ... [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: Text(
                            'Open Explore tab to discover more posts',
                            style: Theme.of(context).textTheme.caption
                          ),
                        )
                      ]
                    ]
                  ),
                ),
                if (feed != null && feed.isEmpty) ... [
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height / 3,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Nothing to show in feed', style: Theme.of(context).textTheme.caption),
                            if (me.following.isEmpty) Text('Follow someone to see their posts in your feed', style: Theme.of(context).textTheme.caption),
                            IconButton(
                              icon: Icon(Icons.refresh),
                              tooltip: 'Refresh',
                              onPressed: refresh,
                            )
                          ],
                        ),
                      ),
                    ),
                  )
                ]
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (isPostBeingCreated) {
            _scaffoldKey.currentState.showSnackBar(SnackBar(
              content: Text('Please wait for previous post to finish'),
            ));
          } else {
            Navigator.of(context).push(RivalNavigator(page: CreatePost()));
          }
        },
        child: Icon(Icons.add),
        tooltip: 'Create Post',
      ),
    );
  }

  Widget _buildStories() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Container(
          height: 84,
          child: ListView(
            physics: BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            cacheExtent: 9999,
            children: [
              if (RivalRemoteConfig.allowNewStory) Container(
                height: 84,
                width: 50,
                child: Padding(
                  padding: const EdgeInsets.only(right: 5, left: 5),
                  child: Center(
                    child: Container(
                      width: 30,
                      height: 30,
                      child: PopupMenuButton(
                        tooltip: 'Create Story',
                        itemBuilder: (context) => <PopupMenuEntry>[
                          PopupMenuItem(
                            child: Text('Image'),
                            value: 'image',
                          ),
                          PopupMenuDivider(),
                          PopupMenuItem(
                            child: Text('Text'),
                            value: 'text',
                          ),
                          PopupMenuDivider(),
                          PopupMenuItem(
                            child: Text('Creator'),
                            value: 'creator',
                          ),
                        ],
                        onSelected: (value) async {
                          switch (value) {
                            case 'image':
                              PickedFile pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);
                              if (pickedFile != null) {
                                File image = await  ImageCropper.cropImage(
                                  sourcePath: pickedFile.path,
                                  androidUiSettings: AndroidUiSettings(
                                    toolbarTitle: 'Crop',
                                    toolbarColor: Colors.indigoAccent
                                  )
                                );
                                if (image != null) Navigator.of(context).push(RivalNavigator(page: CreateImageStory(image: image,)));
                              }
                              break;
                            case 'text':
                              Navigator.of(context).push(RivalNavigator(page: CreateTextStory()));
                              break;
                            case 'creator':
                              File creator = await Navigator.of(context).push(RivalNavigator(page: StoryCreator()));
                              if (creator != null) {
                                File image = await  ImageCropper.cropImage(
                                  sourcePath: creator.path,
                                  androidUiSettings: AndroidUiSettings(
                                    toolbarTitle: 'Crop',
                                    toolbarColor: Colors.indigoAccent
                                  )
                                );
                                if (image != null) Navigator.of(context).push(RivalNavigator(page: CreateImageStory(image: image,)));
                              }
                              break;
                            default:
                          }
                        },
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                height: 30,
                                width: 30,
                                child: Center(child: Icon(Icons.add, color: Colors.white,)),
                                decoration: BoxDecoration(
                                  color: Colors.indigoAccent,
                                  borderRadius: BorderRadius.all(Radius.circular(30))
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (!isStoriesLoading && storyItems.length == 0) Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Container(
                  height: 84,
                  child: Center(
                    child: Text('No Stories', style: Theme.of(context).textTheme.caption,),
                  )
                ),
              ),
              ... List.generate(
                isStoriesLoading ? 4 : (storyItems.length ?? 0),
                (index) => isStoriesLoading
                ? Padding(
                  padding: EdgeInsets.only(right: 4, left: 4),
                  child: Column(
                    children: [
                      Shimmer.fromColors(
                        child: Container(
                          decoration: BoxDecoration(
                            color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[200] : Colors.grey[900],
                            borderRadius: BorderRadius.all(Radius.circular(20))
                          ),
                          height: 60,
                          width: 60
                        ),
                        baseColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[200] : Colors.grey[900],
                        highlightColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[200] : Colors.grey[900]
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5,),
                        child: Shimmer.fromColors(
                          child: Container(
                            decoration: BoxDecoration(
                              color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[200] : Colors.grey[900],
                              borderRadius: BorderRadius.all(Radius.circular(3))
                            ),
                            height: 14,
                            width: 60
                          ),
                          baseColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[200] : Colors.grey[900],
                          highlightColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[200] : Colors.grey[900]
                        ),
                      )
                    ],
                  ),
                )
                : storyItems[index]
              )
            ],
          ),
        ),
      ),
    );
    // ignore: dead_code
    // return SliverToBoxAdapter(
    //   child: Padding(
    //     padding: const EdgeInsets.symmetric(vertical: 10),
    //     child: Container(
    //       height: 84, // Calculated using [height of image, padding, font size]
    //       child: ListView.builder(
    //         physics: BouncingScrollPhysics(),
    //         scrollDirection: Axis.horizontal,
    //         itemCount: isStoriesLoading ? 4 : (storyItems.length ?? 0),
    //         cacheExtent: 9999,
    //         itemBuilder: (context, index) => isStoriesLoading
    //         ? Padding(
    //           padding: EdgeInsets.only(right: 4, left: (index == 0) ? 50 : 4),
    //           child: Column(
    //             children: [
    //               Shimmer.fromColors(
    //                 child: Container(
    //                   decoration: BoxDecoration(
    //                     color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[200] : Colors.grey[900],
    //                     borderRadius: BorderRadius.all(Radius.circular(20))
    //                   ),
    //                   height: 60,
    //                   width: 60
    //                 ),
    //                 baseColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[200] : Colors.grey[900],
    //                 highlightColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[200] : Colors.grey[900]
    //               ),
    //               Padding(
    //                 padding: const EdgeInsets.only(top: 5,),
    //                 child: Shimmer.fromColors(
    //                   child: Container(
    //                     decoration: BoxDecoration(
    //                       color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[200] : Colors.grey[900],
    //                       borderRadius: BorderRadius.all(Radius.circular(3))
    //                     ),
    //                     height: 14,
    //                     width: 60
    //                   ),
    //                   baseColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[200] : Colors.grey[900],
    //                   highlightColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[200] : Colors.grey[900]
    //                 ),
    //               )
    //             ],
    //           ),
    //         )
    //         : storyItems[index]
    //       ),
    //     ),
    //   ),
    // );
  }

  Future<void> _getStories() async {
    setState(() {
      isStoriesLoading = true;
    });
    List<RivalUser> localStories = await RivalProvider.getStories();
    allStories = localStories;
    storyItems = [];

    // if (RivalRemoteConfig.allowNewStory) {
    //   storyItems.add(Container(
    //     height: 84,
    //     width: 50,
    //     child: Padding(
    //       padding: const EdgeInsets.only(right: 5, left: 5),
    //       child: Center(
    //         child: Container(
    //           width: 30,
    //           height: 30,
    //           child: PopupMenuButton(
    //             tooltip: 'Create Story',
    //             itemBuilder: (context) => <PopupMenuEntry>[
    //               PopupMenuItem(
    //                 child: Text('Image'),
    //                 value: 'image',
    //               ),
    //               PopupMenuDivider(),
    //               PopupMenuItem(
    //                 child: Text('Text'),
    //                 value: 'text',
    //               ),
    //             ],
    //             onSelected: (value) async {
    //               switch (value) {
    //                 case 'image':
    //                   PickedFile pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);
    //                   if (pickedFile != null) {
    //                     File image = await  ImageCropper.cropImage(
    //                       sourcePath: pickedFile.path,
    //                       androidUiSettings: AndroidUiSettings(
    //                         toolbarTitle: 'Crop',
    //                         toolbarColor: Colors.indigoAccent
    //                       )
    //                     );
    //                     if (image != null) Navigator.of(context).push(RivalNavigator(page: CreateImageStory(image: image,)));
    //                   }
    //                   break;
    //                 case 'text':
    //                   Navigator.of(context).push(RivalNavigator(page: CreateTextStory()));
    //                   break;
    //                 default:
    //               }
    //             },
    //             child: Center(
    //               child: Column(
    //                 mainAxisSize: MainAxisSize.min,
    //                 children: [
    //                   Container(
    //                     height: 30,
    //                     width: 30,
    //                     child: Center(child: Icon(Icons.add, color: Colors.white,)),
    //                     decoration: BoxDecoration(
    //                       color: Colors.indigoAccent,
    //                       borderRadius: BorderRadius.all(Radius.circular(30))
    //                     ),
    //                   ),
    //                 ],
    //               ),
    //             ),
    //           ),
    //         ),
    //       ),
    //     ),
    //   ));
    // }

    if (me.stories.isNotEmpty) {
      storyItems.add(
        getMyStoryWidget()
      );
    }
    for (RivalUser user in localStories) {
      storyItems.add(
        Padding(
          padding: const EdgeInsets.only(right: 5),
          child: StreamProvider<RivalUser>.value(
            value: user.stream,
            initialData: user,
            lazy: false,
            updateShouldNotify: (previous, current) {
              if (mapEquals(previous.stories, current.stories)) {
                return false;
              } else {
                return true;
              }
            },
            builder: (context, child) {
              RivalUser user = Provider.of<RivalUser>(context);
              return UserStoryButton(
                user: user,
                initialIndex: localStories.indexWhere((RivalUser u) => u.uid == user.uid),
              );
            },
          ),
        )
      );
    }
    setState(() {
      isStoriesLoading = false;
    });
  }
  
  Widget _buildPosts() {
    List<Widget> widgets = [];
    feed.forEachIndexed((index, element) {
      // widgets.add(PostView(post: feed[index], key: ObjectKey(feed[index].id), cardMargin: EdgeInsets.symmetric(vertical: 5),));
      widgets.add(ViewPost(post: feed[index], key: ObjectKey(feed[index].id),));
    });
    // widgets.insert(2, Ad(controller: adCtrl,));
    if (!RivalRemoteConfig.allowNewPost) widgets.insert(0, MaterialBanner(
      contentTextStyle: TextStyle(color: Colors.black),
      leading: Icon(Icons.warning, color: Colors.black87,),
      backgroundColor: Colors.yellow[300],
      content: Text('New Posts have been disabled for a limited time.'),
      forceActionsBelow: true,
      actions: [
        FlatButton(
          child: Text('Learn More', style: TextStyle(color: Colors.black),),
          onPressed: () async => await launch('https://rival.photography/help/post/new/disabled'),
        ),
      ]
    ));
    if (!RivalRemoteConfig.allowNewStory) widgets.insert(0, MaterialBanner(
      contentTextStyle: TextStyle(color: Colors.black),
      leading: Icon(Icons.warning, color: Colors.black87,),
      backgroundColor: Colors.yellow[300],
      content: Text('New Stories have been disabled for a limited time.'),
      forceActionsBelow: true,
      actions: [
        FlatButton(
          child: Text('Learn More', style: TextStyle(color: Colors.black),),
          onPressed: () async => await launch('https://rival.photography/help/story/new/disabled'),
        ),
      ]
    ));
    if (!RivalRemoteConfig.allowEditPost) widgets.insert(0, MaterialBanner(
      contentTextStyle: TextStyle(color: Colors.black),
      leading: Icon(Icons.warning, color: Colors.black87,),
      backgroundColor: Colors.yellow[300],
      content: Text('Post Editing has been disabled for a limited time.'),
      forceActionsBelow: true,
      actions: [
        FlatButton(
          child: Text('Learn More', style: TextStyle(color: Colors.black),),
          onPressed: () async => await launch('https://rival.photography/help/post/edit/disabled'),
        ),
      ]
    ));
    if (RivalRemoteConfig.showGoogleAds) {
      if (widgets.length >= 2) widgets.insert(1, GoogleAd(controller: adCtrl,));
      if (widgets.length >= 11) widgets.insert(10, GoogleAd(controller: adCtrl,));
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) => widgets[index],
        childCount: widgets.length,
        addAutomaticKeepAlives: true,
      ),
    );
  }

  Future<void> getCachedPosts() async {

    setState(() {
      isPostLoading = true;
    });

    List<DocumentSnapshot> cachedDocs = await RivalProvider.getPaginatedPosts(1, source: Source.cache);
    List<Post> cachedPosts = [];

    for (DocumentSnapshot doc in cachedDocs) {
      // cachedPosts.add(Post(doc: doc));
      Post post = await Post.fetch(doc: doc);
      print(doc.id);
      cachedPosts.add(post);
    }

    setState(() {
      feed = cachedPosts;
      isPostLoading = false;
      print('state set');
    });

    // Get ads from Rival Firestore Database
    // And put them into feed
    List<Post> ads = await getAds();

    if (ads.isNotEmpty) {
      if (feed.length >= 2 && scrollController.offset < MediaQuery.of(context).size.height) feed.insert(2, ads.elementAtOrElse(0, () => ads.first));
      if (feed.length >= 7 && ads.length > 1) feed.insert(8, ads.elementAtOrElse(1, () => ads.first));
      if (feed.length >= 14 && ads.length > 2) feed.insert(14, ads.elementAtOrElse(2, () => ads.first));
      if (feed.length >= 20 && ads.length > 3) feed.insert(20, ads.elementAtOrElse(3, () => ads.first));
      if (feed.length >= 25 && ads.length > 4) feed.insert(25, ads.elementAtOrElse(4, () => ads.first));
      if (feed.length >= 29 && ads.length > 5) feed.insert(29, ads.elementAtOrElse(5, () => ads.first));
    }

    try {
      setState(() { });
    } catch (e) {}

  }

  /// This Function checks if new posts are available if they are not present in cache
  Future<void> getPostsFromServer({bool isRefresh = false, int startTime}) async {
    List<DocumentSnapshot> serverDocs = await RivalProvider.getPaginatedPosts(1, source: Source.server);

    if (serverDocs == null || serverDocs.isEmpty) return;

    /// This is the list of [Post]s only in server i.e. not cached
    List<Post> serverPosts = [];
    
    for (DocumentSnapshot doc in serverDocs) {
      // serverPosts.add(Post(doc: doc));
      Post post = await Post.fetch(doc: doc);
      serverPosts.add(post);
    }

    List<Post> onlyInServerList = serverPosts.where((post) {
      return ( (feed.indexWhere((element) => element.id == post.id) < 0) && !post.promoted );
    }).toList();

    bool isTimeLessThan2Sec = false;
    int endTime = new DateTime.now().millisecondsSinceEpoch;

    if (startTime != null) {
      double timeElapsed = (endTime - startTime) / 1000; // in seconds
      if (timeElapsed < 2) isTimeLessThan2Sec = true;
    }

    // If Server List has any new posts, show a SnackBar for user to reload
    if (onlyInServerList.isNotEmpty && !isRefresh && !isTimeLessThan2Sec) {
      _scaffoldKey.currentState.showSnackBar(
        SnackBar(
          content: Text('New Posts Available'),
          action: SnackBarAction(
            label: 'Refresh',
            onPressed: () {
              setState(() {
                feed = serverPosts;
              });
            },
          ),
          behavior: SnackBarBehavior.floating,
        )
      );
    } else if (isRefresh || isTimeLessThan2Sec) { // If time taken to load posts from server is less than 2-sec, then set posts without asking user
      feed = serverPosts;
    }
    setState(() {});
  }

  Future<void> _nextPage() async {
    setState(() {
      page += 1;
      isNextPageLoading = true;
    });
    List<DocumentSnapshot> localPosts = await RivalProvider.getPaginatedPosts(page);
    List<Post> feedL = [];
    if (localPosts.isNotEmpty) {
      for (var doc in localPosts) {
        // feedL.add(Post(doc: doc));
        feedL.add(await Post.fetch(doc: doc));
      }
      List<Post> ads = await getAds();
      print("Loaded ${ads.length} Ads");
      if (ads.isNotEmpty) {
        if (feedL.length >= 2) feedL.insert(2, ads.elementAtOrElse(0, () => ads.first));
        if (feedL.length >= 7 && ads.length > 1) feedL.insert(8, ads.elementAtOrElse(1, () => ads.first));
        if (feedL.length >= 14 && ads.length > 2) feedL.insert(14, ads.elementAtOrElse(2, () => ads.first));
        if (feedL.length >= 20 && ads.length > 3) feedL.insert(20, ads.elementAtOrElse(3, () => ads.first));
        if (feedL.length >= 25 && ads.length > 4) feedL.insert(25, ads.elementAtOrElse(4, () => ads.first));
        if (feedL.length >= 29 && ads.length > 5) feedL.insert(29, ads.elementAtOrElse(5, () => ads.first));
      }
    } else {
      postsAvailable = false;
    }
    feed.addAll(feedL);
    setState(() {
      isNextPageLoading = false;
    });
  }

  Future<void> refresh() async {
    setState(() {
      page = 1;
      postsAvailable = true;
    });
    await me.reload();
    await me.user.reload();
    RivalProvider.reloadHomeScreen();
    await RivalProvider.reloadStories();
    await _getStories();
    await getPostsFromServer(isRefresh: true);
  }

}

class UserStoryButton extends StatefulWidget {

  final RivalUser user;
  final int initialIndex;

  UserStoryButton({Key key, this.user, this.initialIndex}) : super(key: key);

  @override
  _UserStoryButtonState createState() => _UserStoryButtonState();
}

class _UserStoryButtonState extends State<UserStoryButton> {

  bool isTapped = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        setState(() {
          isTapped = true;
        });
      },
      onTapUp: (details) {
        setState(() {
          isTapped = false;
        });
      },
      onTapCancel: () {
        setState(() {
          isTapped = false;
        });
      },
      child: Container(
        width: 60,
        height: 84,
        child: Column(
          children: [
            OpenContainer(
              closedBuilder: (context, action) => AnimatedContainer(
                height: isTapped ? 57 : 60,
                width: isTapped ? 57 : 60,
                duration: Duration(milliseconds: 300),
                margin: isTapped ? EdgeInsets.all(1.5) : EdgeInsets.zero,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  border: (widget.user.storyViewed)
                    ? Border.all(
                      style: BorderStyle.none
                    )
                    : Border.all(
                      color: Colors.indigoAccent,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                ),
                child: Hero(
                  tag: 'story-${widget.user.uid}',
                  child: Padding(
                    padding: EdgeInsets.all(widget.user.storyViewed ? 0 : 2),
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(widget.user.storyViewed ? 20 : 16)),
                      child: Image(
                        image: widget.user.photo,
                        fit: BoxFit.cover,
                        width: widget.user.storyViewed ? 60 : 55,
                        height: widget.user.storyViewed ? 60 : 55,
                        color: isTapped ? Colors.black12 : null,
                        colorBlendMode: BlendMode.darken,
                      ),
                    ),
                  ),
                ),
              ),
              closedElevation: 0,
              closedColor: Colors.transparent,
              openElevation: 0,
              openBuilder: (context, action) => ViewStory(initialIndex: widget.initialIndex,),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text('${widget.user.username}', overflow: TextOverflow.ellipsis),
            )
          ],
        ),
      ),
    );
  }
}

Widget getMyStoryWidget() {
  return Padding(
    padding: const EdgeInsets.only(right: 5),
    child: Container(
      width: 60,
      height: 84,
      child: Column(
        children: [
          OpenContainer(
            closedBuilder: (context, action) => Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(20))
              ),
              child: Hero(
                tag: 'story-${me.uid}',
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  child: Image(image: me.photo, fit: BoxFit.cover,),
                ),
              ),
            ),
            closedElevation: 0,
            closedColor: Colors.transparent,
            openElevation: 0,
            openBuilder: (context, action) {
              if (me.stories.isNotEmpty) {
                return ViewStory(launchedFromHomeScreen: false, users: <RivalRootUser>[me],);
              } else {
                return CreateTextStory();
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text('${me.username}', overflow: TextOverflow.ellipsis),
          )
        ],
      ),
    ),
  );
}

class GoogleAd extends StatefulWidget {
  
  final NativeAdmobController controller;

  const GoogleAd({Key key, @required this.controller}) : super(key: key);

  @override
  _GoogleAdState createState() => _GoogleAdState();
}

class _GoogleAdState extends State<GoogleAd> {

  NativeAdmobController adCtrl;
  bool adLoaded = false;
  StreamSubscription adSubs;

  @override
  void initState() {
    adCtrl = widget.controller;
    adSubs = adCtrl.stateChanged.listen((event) {
      switch (event) {
        case AdLoadState.loadCompleted:
          setState(() {
            adLoaded = true;
          });
          break;
        case AdLoadState.loadError:
          print('Ad Load Error');
          break;
        default:
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    adSubs.cancel();
    adCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      height: adLoaded ? ((MediaQuery.of(context).size.height / 10) < 100 ? 100 : MediaQuery.of(context).size.height / 10) : 0,
      width: double.infinity,
      duration: Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[300] : Colors.white12, width: 0.8)
          )
        ),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: NativeAdmob(
            adUnitID: kDebugMode ? 'ca-app-pub-3940256099942544/2247696110' : 'ca-app-pub-6495897586509663/7090020321', // Test ID: ca-app-pub-3940256099942544/2247696110, Rival ID: ca-app-pub-6495897586509663/7090020321
            controller: adCtrl,
            type: NativeAdmobType.full,
            options: NativeAdmobOptions(
              showMediaContent: true,
              callToActionStyle: NativeTextStyle(
                backgroundColor: Colors.indigoAccent,
                color: Colors.white,
              ),
              headlineTextStyle: NativeTextStyle(
                fontSize: Theme.of(context).textTheme.headline6.fontSize,
              ),
              bodyTextStyle: NativeTextStyle(
                fontSize: Theme.of(context).textTheme.bodyText1.fontSize,
              ),
              priceTextStyle: NativeTextStyle(
                fontSize: Theme.of(context).textTheme.subtitle2.fontSize,
              ),
              advertiserTextStyle: NativeTextStyle(
                fontSize: Theme.of(context).textTheme.subtitle1.fontSize,
              ),
              adLabelTextStyle: NativeTextStyle(
                backgroundColor: Colors.yellow,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}