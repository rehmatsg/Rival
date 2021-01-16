import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e/screens/subscribe_to_topics.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:like_button/like_button.dart';
import 'package:octo_image/octo_image.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter_icons/flutter_icons.dart';

import '../app.dart';

// class PostView extends StatefulWidget {

//   PostView({Key key, this.doc, this.post, this.interactive, this.cardColor, this.cardShape, this.cardElevation, this.cardMargin, this.user, this.enableCardBorder = false}) : super(key: key);
//   final DocumentSnapshot doc;
//   final Post post;
//   final bool interactive;
//   final Color cardColor;
//   final ShapeBorder cardShape;
//   final double cardElevation;
//   final EdgeInsets cardMargin;
//   /// Show card border instead of elevation
//   final bool enableCardBorder;
//   /// Provide an instance of [RivalUser] to prevent reloading
//   final RivalUser user;

//   @override
//   _PostViewState createState() => _PostViewState();
// }

// class _PostViewState extends State<PostView> with TickerProviderStateMixin {

//   bool interactive;
//   Post post;

//   RivalUser user;

//   final PreloadPageController pageController = PreloadPageController(viewportFraction: 1,);
//   final ExpandableController _expandableController = ExpandableController();

//   List<RivalUser> featuredLikes;

//   int currentImageIndex = 1;

//   Key postKey;

//   Widget userTile;
//   Widget sponsorWidget = Container();

//   Future<void> _futureGetUser() async {
//     if (post.userId == me.uid) {
//       setState(() {
//         userTile = PostUser(post: post, isCurrentUser: true,);
//       });
//     } else {
//       user = await getUser(post.userId);
//       setState(() {
//         userTile = PostUser(post: post, isCurrentUser: false, user: user,);
//       });
//     }
//   }

//   @override
//   void initState() {
//     if (widget.post != null) {
//       post = widget.post;
//     } else {
//       post = Post(doc: widget.doc);
//     }
//     _futureGetUser();
//     postKey = new Key(post.id);
//     interactive = widget.interactive != null ? widget.interactive : true;
//     _getFeaturedLikes();
//     super.initState();
//     if (post.sponsorRef!= null) sponsorWidget = FutureBuilder<RivalUser>(
//       future: RivalProvider.getUserByRef(post.sponsorRef),
//       builder: (context, snapshot) {
//         TextStyle textStyle = Theme.of(context).textTheme.caption;
//         return GestureDetector(
//           onTap: () {
//             if (snapshot.connectionState == ConnectionState.done) {
//               snapshot.data.navigateToProfile(context);
//             }
//           },
//           child: RichText(
//             text: TextSpan(
//               children: <InlineSpan>[
//                 TextSpan(text: 'Paid Partnership', style: textStyle),
//                 if (snapshot.connectionState == ConnectionState.done) ... [
//                   TextSpan(text: ' with ', style: textStyle),
//                   TextSpan(
//                     text: '@${snapshot.data.username}',
//                     style: textStyle.copyWith(
//                       fontWeight: FontWeight.bold
//                     )
//                   )
//                 ]
//               ]
//             ),
//           ),
//         );
//       },
//     );
//   }

//   @override
//   void setState(fn) {
//     if (mounted) super.setState(fn);
//   }

//   _getFeaturedLikes() async {
//     List<String> likes = post.available ? post.likes.keys.toList() : [];
//     //print(me.followingWithUids);
//     likes.removeWhere((element) => !me.followingWithUids.contains(element));
//     List<RivalUser> localFeatureLikes = [];
//     for (var like in likes) {
//       localFeatureLikes.add(await getUser(like));
//     }
//     setState(() {
//       featuredLikes = localFeatureLikes;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return StreamProvider<Post>.value( //StreamProvider<Post>.value
//       value: post.stream,
//       initialData: post,
//       lazy: false,
//       updateShouldNotify: (previous, current) {
//         if (current.available && (!previous.likes.containsKey(me.uid) && current.likes.containsKey(me.uid))) {
//           // Do Not Update if likes change. This will disrupt animation
//           return false;
//         }
//         return true;
//       },
//       catchError: (context, error) {
//         print("@@@@ Error in Post (${post.id}) StreamProvider $error");
//         return this.post;
//       },
//       builder: (context, child) { // (context, child)
//         Post post = Provider.of<Post>(context);
//         if (post.available && post.takenDown) {
//           return InfoBanner(
//             leadingIcon: Icons.warning,
//             content: Text('This post has been taken down by Rival because it violates our policies'),
//             actions: [
//               FlatButton(
//                 child: Text('Privacy Policy'),
//                 onPressed: () async => await launch('https://rival.photography/policy'),
//               ),
//             ]
//           );
//         } else if (!post.available) {
//           return InfoBanner(
//             leadingIcon: Icons.warning,
//             content: Text('Oops, this post is not available. It may have been deleted. By the time you can discover top posts in Explore Page.'),
//             actions: [
//               FlatButton(
//                 child: Text('Learn More'),
//                 onPressed: () async => await launch('https://rival.photography/help/post/unavailable'),
//               ),
//             ]
//           );
//         } else if (user != null && (user.private && !user.isFollowing)) { // The user has a private account and I am not following him
//           return InfoBanner(
//             leadingIcon: Icons.error,
//             content: Text('This Post is hidden because @${user.username} has a private account. Follow @${user.username} to view this post.'),
//             actions: [
//               FlatButton(
//                 child: Text('Learn More'),
//                 onPressed: () async => await launch('https://rival.photography/help/post/unavailable'),
//               ),
//             ]
//           );
//         } else if (user != null && user.amIBlocked) {
//           return InfoBanner(
//             leadingIcon: Icons.error,
//             content: Text('Oops, failed to load this post'),
//             actions: [
//               FlatButton(
//                 child: Text('Learn More'),
//                 onPressed: () async => await launch('https://rival.photography/help/post/unavailable'),
//               ),
//             ]
//           );
//         } else if (user != null && user.isBlocked) {
//           return InfoBanner(
//             leadingIcon: Icons.error,
//             content: Text('This Post is hidden because you have blocked @${user.username}. Unblock @${user.username} to view this post.'),
//             actions: [
//               FlatButton(
//                 child: Text('Unblock'),
//                 onPressed: () async {
//                   await user.blockUnblock();
//                   setState(() { });
//                 },
//               ),
//             ]
//           );
//         } else if (post.adultRated && me.age == null) {
//           return InfoBanner(
//             leadingIcon: Icons.warning,
//             content: Text('This Post is rated 18+. Please add your DOB to check if you can view this post.'),
//             actions: [
//               FlatButton(
//                 child: Text('Learn More'),
//                 onPressed: () async => await launch('https://rival.photography/help/post/adult-rated'),
//               ),
//             ]
//           );
//         } else if (post.adultRated && me.age < 18) {
//           return InfoBanner(
//             leadingIcon: Icons.warning,
//             content: Text('This Post is rated 18+. You cannot view this post.'),
//             actions: [
//               FlatButton(
//                 child: Text('Learn More'),
//                 onPressed: () async => await launch('https://rival.photography/help/post/adult-rated'),
//               ),
//             ]
//           );
//         } else if (post.available && !post.takenDown) {
//           return VisibilityDetector(
//             key: postKey,
//             onVisibilityChanged: (info) async {
//               try {
//                 double visibility = info.visibleFraction;
//                 if (visibility == 1.0 && !post.isPromoted) {
//                   // Got an impression for (Timeline, Profile Post, Trending, Explore)
//                   if(post.impressions[me.uid] == null && post.userId != me.uid) {
//                     await analytics.logEvent(name: 'new_impression', parameters: {
//                       me.uid: new DateTime.now().millisecondsSinceEpoch
//                     });
//                     post.reference.update({
//                       'impressions.${me.uid}': new DateTime.now().millisecondsSinceEpoch
//                     });
//                     post.refresh();
//                   }
//                   if (post.userId != me.uid && post.labels.isNotEmpty) {
//                     for (String label in post.labels) {
//                       if (me.interests.containsKey(label.toLowerCase())) {
//                         await me.update({
//                           'interests.${label.toLowerCase()}': FieldValue.increment(1)
//                         });
//                       } else {
//                         await me.update({
//                           'interests.${label.toLowerCase()}': 0
//                         });
//                       }
//                     }
//                   }
//                 } else if (visibility == 1.0 && post.isPromoted) {
//                   // Got an impression for AD
//                   if(post.adImpressions[me.uid] == null && post.userId != me.uid) {
//                     await analytics.logEvent(name: 'new_ad_impression', parameters: {
//                       me.uid: new DateTime.now().millisecondsSinceEpoch
//                     });
//                     post.adRef.update({
//                       'impressions.${me.uid}': new DateTime.now().millisecondsSinceEpoch
//                     });
//                     post.refresh();
//                   }
//                 } else {
//                   // Post reach will be decided by Firebase Cloud Functions
//                   // The post reached the user
//                   // if(post.reach[me.user.uid] == null) await analytics.logEvent(name: 'new_reach', parameters: {
//                   //   me.user.uid: new DateTime.now().millisecondsSinceEpoch
//                   // });
//                   // if(post.reach[me.user.uid] == null) post.ref .update({
//                   //   'reach.${me.user.uid}': new DateTime.now().millisecondsSinceEpoch
//                   // });
//                   // post.refresh();
//                 }
//               } catch (e) {
//                 print('Error $e');
//               }
//             },
//             child: Card(
//               color: widget.cardColor ?? (MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[50] : Colors.white10),
//               shape: widget.cardShape ?? RoundedRectangleBorder(
//                 borderRadius: BorderRadius.all(Radius.circular(20)),
//                 side: widget.enableCardBorder ? BorderSide(color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[200] : Colors.white10, width: 0.7,) : BorderSide.none
//               ),
//               elevation: widget.enableCardBorder ? 0 : (widget.cardElevation ?? 0), // Don't show elevation if card border is enabled
//               shadowColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black38 : Colors.white12,
//               margin: widget.cardMargin ?? EdgeInsets.zero,
//               child: Column(
//                 children: [
//                   AnimatedSwitcher(
//                     duration: Duration(milliseconds: 200),
//                     child: userTile ?? ListTile( // This widget is in-case user tile has not yet loaded. NULL SAFETY
//                       leading: Shimmer.fromColors(
//                         child: Container(
//                           decoration: BoxDecoration(
//                             color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black87 : Colors.white70,
//                             borderRadius: BorderRadius.all(Radius.circular(100))
//                           ),
//                           height: 40,
//                           width: 40
//                         ),
//                         baseColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.white10,
//                         highlightColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.white12
//                       ),
//                       title: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           SizedBox(
//                             height: 10,
//                             width: MediaQuery.of(context).size.width / 2,
//                             child: Shimmer.fromColors(
//                               child: Container(
//                                 height: 10,
//                                 decoration: BoxDecoration(
//                                   color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black87 : Colors.white70,
//                                   borderRadius: BorderRadius.all(Radius.circular(5))
//                                 ),
//                               ),
//                               baseColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.white10,
//                               highlightColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black26 : Colors.white12
//                             ),
//                           ),
//                         ],
//                       ),
//                       subtitle: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           SizedBox(
//                             height: 8,
//                             width: MediaQuery.of(context).size.width / 3,
//                             child: Shimmer.fromColors(
//                               child: Container(
//                                 decoration: BoxDecoration(
//                                   color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black87 : Colors.white70,
//                                   borderRadius: BorderRadius.all(Radius.circular(5))
//                                 ),
//                               ),
//                               baseColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.white10,
//                               highlightColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black26 : Colors.white12
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   _buildDescription(),
//                   Container(
//                     decoration: BoxDecoration(
//                       border: Border.symmetric(horizontal: BorderSide(color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[200] : Colors.white10, width: 0.7))
//                     ),
//                     child: SizedBox(
//                       width: MediaQuery.of(context).size.width,
//                       height: (MediaQuery.of(context).size.width / post.ratio > (MediaQuery.of(context).size.height * 0.75)) ? MediaQuery.of(context).size.height * 0.55 : MediaQuery.of(context).size.width / post.ratio,
//                       child: Stack(
//                         children: [
//                           PreloadPageView.builder(
//                             controller: pageController,
//                             preloadPagesCount: 10,
//                             itemCount: post.images.length,
//                             itemBuilder: (context, index) => Container(
//                               child: OctoImage(
//                                 image: CachedNetworkImageProvider(post.images[index]),
//                                 progressIndicatorBuilder: (context, progress) {
//                                   double value;
//                                   if (progress != null && progress.expectedTotalBytes != null) {
//                                     value = progress.cumulativeBytesLoaded / progress.expectedTotalBytes;
//                                   }
//                                   return Container(
//                                     width: 50,
//                                     height: 50,
//                                     child: CircularProgressIndicator(
//                                       value: value,
//                                       valueColor: new AlwaysStoppedAnimation<Color>(MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black : Colors.white),
//                                       strokeWidth: 2,
//                                     ),
//                                   );
//                                 }
//                               ),
//                             ),
//                           ),
//                           if (post.images.length > 1) Align(
//                             alignment: Alignment.bottomRight,
//                             child: Padding(
//                               padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
//                               child: Container(
//                                 child: PageNotifier(controller: pageController, pages: post.images.length,),
//                               ),
//                             ),
//                           )
//                         ],
//                       ),
//                     ),
//                   ),
//                   if (interactive) Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             GestureDetector(
//                               onLongPress: (post.showLikeCount || post.isMyPost) ? () => Navigator.of(context).push(RivalNavigator(page: PostLikes(post: post,), )) : null,
//                               child: LikeButton(
//                                 isLiked: post.isLiked,
//                                 likeCount: post.likes.length,
//                                 countBuilder: (likeCount, isLiked, text) {
//                                   if (post.showLikeCount || post.isMyPost) return Text(likeCount.toString(), style: Theme.of(context).textTheme.button.copyWith(
//                                     color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[700] : Colors.white
//                                   ),);
//                                   else return Container();
//                                 },
//                                 bubblesColor: BubblesColor(dotPrimaryColor: Colors.indigo, dotSecondaryColor: Colors.redAccent),
//                                 onTap: (isLiked) {
//                                   return _like(isLiked);
//                                 },
//                               ),
//                             ),
//                             if (post.allowComments) ... [
//                               HDivider(),
//                               GestureDetector(
//                                 onTap: () => Navigator.of(context).push(RivalNavigator(page: PostComments(post: post), )),
//                                 child: const Text('comments'),
//                               ),
//                             ],
//                             HDivider(),
//                             GestureDetector(
//                               onTap: () async {
//                                 // Share
//                                 await Share.share('${post.description}. View Post on Rival: ${post.shareableUrl}');
//                                 if (post.userId != me.uid && !post.shares.containsKey(me.uid)) await post.reference .update({
//                                   'shares.${me.uid}': new DateTime.now().millisecondsSinceEpoch
//                                 });
//                               },
//                               child: const Text('share'),
//                             )
//                           ]
//                         ),
//                         Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Padding(
//                               padding: const EdgeInsets.symmetric(horizontal: 10),
//                               child: TaggedPeople(post: post),
//                             ),
//                             // Padding(
//                             //   padding: const EdgeInsets.symmetric(horizontal: 10),
//                             //   child: BookmarkPost(post: post),
//                             // ),
//                             Padding(
//                               padding: const EdgeInsets.only(left: 5),
//                               child: PopupMenuButton(
//                                 child: Icon(Icons.more_horiz),
//                                 itemBuilder: (context) => <PopupMenuEntry<dynamic>>[
//                                   if (post.userId == me.uid) ... [
//                                     PopupMenuItem(
//                                       child: Text('Edit'),
//                                       value: 'edit',
//                                     ),
//                                     PopupMenuItem(
//                                       child: Text('View Insights'),
//                                       value: 'insights',
//                                     ),
//                                   ],
//                                   if (post.userId != me.uid && user != null) PopupMenuItem(
//                                     child: Text('View Profile'),
//                                     value: 'visitProfile',
//                                   ),
//                                   PopupMenuItem(
//                                     child: Text('Copy Post URL'),
//                                     value: 'copyUrl',
//                                   ),
//                                   if (post.userId != me.uid) PopupMenuItem(
//                                     child: Text('Report Post'),
//                                     value: 'report',
//                                   ),
//                                   if (post.userId != me.uid && post.isPromoted) PopupMenuItem(
//                                     child: Text('Report Ad'),
//                                     value: 'reportAd',
//                                   ),
//                                   PopupMenuItem(
//                                     child: Text('Add to My Story'),
//                                     value: 'addAsStory',
//                                   ),
//                                   if (post.userId != me.uid && user != null) PopupMenuItem(
//                                     child: Text('Block ${user.username}'),
//                                     value: 'block',
//                                   ),
//                                 ],
//                                 onSelected: (value) async {
//                                   switch (value) {
//                                     case 'edit':
//                                       RivalProvider.vibrate();
//                                       if (RivalRemoteConfig.allowEditPost) {
//                                         Navigator.of(context).push(RivalNavigator(page: EditPost(post: post), ));
//                                       } else {
//                                         showDialog(
//                                           context: context,
//                                           child: AlertDialog(
//                                             title: Text('Edit Post Disabled'),
//                                             content: Text('Post editing has been disabled for a limited time. Please try again later'),
//                                             actions: [
//                                               FlatButton(
//                                                 onPressed: () => Navigator.of(context).pop(),
//                                                 child: Text('OK')
//                                               )
//                                             ],
//                                           )
//                                         );
//                                       }
//                                       break;
//                                     case 'insights':
//                                       RivalProvider.vibrate();
//                                       Navigator.of(context).push(RivalNavigator(page: PostInsights(post: post), ));
//                                       break;
//                                     case 'visitProfile':
//                                       user.navigateToProfile(context);
//                                       break;
//                                     case 'copyUrl':
//                                       await Clipboard.setData(ClipboardData(text: post.shareableUrl));
//                                       RivalProvider.showToast(text: 'Copied to Clipboard');
//                                       break;
//                                     case 'addAsStory':
//                                       await post.shareAsStory();
//                                       break;
//                                     case 'report':
//                                       showDialog(
//                                         context: context,
//                                         child: AlertDialog(
//                                           title: Text('Report'),
//                                           content: Text('Do you want to report this post?'),
//                                           actions: [
//                                             FlatButton(
//                                               onPressed: () async {
//                                                 Navigator.of(context).pop();
//                                                 await post.report();
//                                               },
//                                               child: Text('Report')
//                                             ),
//                                             FlatButton(
//                                               onPressed: () => Navigator.of(context).pop(),
//                                               child: Text('Cancel')
//                                             )
//                                           ],
//                                         )
//                                       );
//                                       break;
//                                     case 'reportAd':
//                                       showDialog(
//                                         context: context,
//                                         child: AlertDialog(
//                                           title: Text('Report Ad'),
//                                           content: Text('Do you want to report this Ad?'),
//                                           actions: [
//                                             FlatButton(
//                                               onPressed: () async {
//                                                 Navigator.of(context).pop();
//                                                 await post.reportAd();
//                                               },
//                                               child: Text('Report')
//                                             ),
//                                             FlatButton(
//                                               onPressed: () => Navigator.of(context).pop(),
//                                               child: Text('Cancel')
//                                             )
//                                           ],
//                                         )
//                                       );
//                                       break;
//                                     case 'block':
//                                       await user.blockUnblock();
//                                       break;
//                                     default:
//                                   }
//                                 },
//                               ),
//                             ),
//                           ],
//                         )
//                       ],
//                     ),
//                   ) else Container(height: 10,),
//                   Container(
//                     child: AnimatedSize(
//                       duration: Duration(milliseconds: 300),
//                       vsync: this,
//                       curve: Curves.easeIn,
//                       child: AnimatedOpacity(
//                         opacity: (featuredLikes != null && featuredLikes.length > 0) ? 1 : 0,
//                         duration: Duration(milliseconds: 700),
//                         child: (featuredLikes != null && featuredLikes.length > 0 && (post.showLikeCount || post.isMyPost))
//                         ? Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 15),
//                           child: Row(
//                             children: [
//                               RichText(
//                                 text: TextSpan(
//                                   children: <TextSpan>[
//                                     TextSpan(
//                                       text: 'Liked by ',
//                                       style: Theme.of(context).textTheme.bodyText2
//                                     ),
//                                     TextSpan(
//                                       text: '${featuredLikes[0].username}${featuredLikes.length >= 2 ? ', ' : ' '}',
//                                       style: Theme.of(context).textTheme.bodyText2.copyWith(fontWeight: FontWeight.bold)
//                                     ),
//                                     if (featuredLikes.length >= 2) TextSpan(
//                                       text: '${featuredLikes[1].username} ',
//                                       style: Theme.of(context).textTheme.bodyText2.copyWith(fontWeight: FontWeight.bold)
//                                     ),
//                                     TextSpan(
//                                       text: post.likes.length - (featuredLikes.length >= 2 ? 2 : 1) == 0 ? '' : 'and ' + (post.likes.length - (featuredLikes.length >= 2 ? 2 : 1)).toString() + ' others',
//                                       style: Theme.of(context).textTheme.bodyText2
//                                     )
//                                   ]
//                                 ),
//                               ),
//                             ],
//                           ),
//                         )
//                         : Container(),
//                       )
//                     ),
//                   ),
//                   if (interactive && false) _buildTaggedPeople(),
//                   // buildTopComment(),
//                   Padding(
//                     padding: const EdgeInsets.only(left: 15, top: 5, right: 15, bottom: 15),
//                     child: Row(
//                       mainAxisAlignment: post.sponsorRef!= null ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
//                       children: [
//                         Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             if (post.isPromoted) Tooltip(
//                               message: 'Promoted Post',
//                               child: Container(
//                                 margin: EdgeInsets.only(right: 5),
//                                 decoration: BoxDecoration(
//                                   color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.yellow[300] : Colors.yellow[700],
//                                   borderRadius: BorderRadius.all(Radius.circular(4))
//                                 ),
//                                 padding: EdgeInsets.symmetric(vertical: 1, horizontal: 4),
//                                 child: Text(
//                                   'Ad',
//                                   style: Theme.of(context).textTheme.caption,
//                                 ),
//                               ),
//                             ),
//                             Text(
//                               getTimeAgo(new DateTime.fromMillisecondsSinceEpoch(post.timestamp), includeHour: false),
//                               style: Theme.of(context).textTheme.caption,
//                             ),
//                           ],
//                         ),
//                         sponsorWidget
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         } else {
//           return InfoBanner(
//             leadingIcon: Icons.error,
//             content: Text('Oops, could not load post.'),
//             actions: [
//               FlatButton(
//                 child: Text('Learn More'),
//                 onPressed: () async => await launch('https://rival.photography/help/post/unavailable'),
//               ),
//             ]
//           );
//         }
//       },
//     );
//   }

//   Future<bool> _like(bool liked) async {
//     if (liked) {
//       await post.reference.update({
//         'likes.${me.user.uid}': FieldValue.delete()
//       });
//       await post.refresh();
//       return !liked;
//     } else {
//       await post.reference.update({
//         'likes.${me.user.uid}': new DateTime.now().millisecondsSinceEpoch
//       });
//       await post.refresh();
//       return !liked;
//     }
//   }

//   Widget _buildDescription() {
//     if (post.description != null && post.description.toString().trim() != "") {
//       return Container(
//         child: Padding(
//           padding: const EdgeInsets.only(left: 15, right: 15, top: 5, bottom: 15),
//           child: ExpandablePanel(
//             controller: _expandableController,
//             collapsed: (post.description.toString().length > 40)
//             ? GestureDetector(
//               onTap: () => _expandableController.toggle(),
//               child: RichText(
//                 text: TextSpan(
//                   children: [
//                     TextSpan(text: "${post.description.substring(0, 40).replaceAll('\n', ' ')}... ", style: Theme.of(context).textTheme.bodyText2),
//                     TextSpan(text: "read more", style: TextStyle(color: Colors.indigo))
//                   ]
//                 ),
//               ),
//             )
//             : TextParser(
//               text: post.description,
//               textStyle: Theme.of(context).textTheme.bodyText2,
//               matchedWordStyle: TextStyle(fontWeight: FontWeight.bold),
//             ),
//             expanded: TextParser(
//               matchedWordStyle: TextStyle(fontWeight: FontWeight.bold),
//               text: post.description,
//               textStyle: TextStyle(color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black87 : Colors.white70),
//             ),
//           ),
//         ),
//       );
//     } else {
//       return Container();
//     }
//   }

//   Widget _buildTaggedPeople() {
//     return Align(
//       alignment: Alignment.centerLeft,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
//         child: Wrap(
//           crossAxisAlignment: WrapCrossAlignment.start,
//           children: List.generate(
//             post.people.length,
//             (index) => FutureBuilder(
//               future: RivalProvider.getUserByRef(post.people[index]),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.done) {
//                   RivalUser taggedUser = snapshot.data;
//                   return Padding(
//                     padding: const EdgeInsets.only(right: 10),
//                     child: GestureDetector(
//                       onTap: () async {
//                         RivalProvider.vibrate();
//                         taggedUser.navigateToProfile(context);
//                       },
//                       child: Chip(
//                         backgroundColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.black26,
//                         label: Text(taggedUser.username),
//                         avatar: ClipOval(
//                           child: OctoImage(
//                             image: taggedUser.photo,
//                             placeholderBuilder: (context) => CircularProgressIndicator(strokeWidth: 2,),
//                           ),
//                         ),
//                       ),
//                     ),
//                   );
//                 }
//                 return Padding(
//                   padding: const EdgeInsets.only(right: 10),
//                   child: Chip(
//                     backgroundColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.black26,
//                     label: Shimmer.fromColors(
//                       child: Container(
//                         decoration: BoxDecoration(
//                           color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black87 : Colors.white70,
//                           borderRadius: BorderRadius.all(Radius.circular(5))
//                         ),
//                         height: 10,
//                         width: 40,
//                       ),
//                       baseColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.white10, highlightColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black26 : Colors.white12
//                     ),
//                     avatar: Shimmer.fromColors(
//                       child: Container(
//                         decoration: BoxDecoration(
//                           color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black87 : Colors.white70,
//                           borderRadius: BorderRadius.all(Radius.circular(100))
//                         ),
//                       ),
//                       baseColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.white10,
//                       highlightColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.white12
//                     ),
//                   ),
//                 );
//               },
//             )
//           ),
//         ),
//       ),
//     );
//   }
  
//   Future<List> getTopCommenter() async {
//     DocumentSnapshot topComment = await post.comments.values.toList().first.get();
//     RivalUser topCommenter = RivalUser(doc: await topComment.data()['userRef'].get());
//     print([topComment.data, topCommenter.username]);
//     return [topComment, topCommenter];
//   }

//   Widget buildTopComment() {
//     if (post.allowComments && post.comments.values.isNotEmpty) {
//       return FutureBuilder(
//         future: getTopCommenter(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.done) {
//             RivalUser user = snapshot.data()[1];
//             DocumentSnapshot comment = snapshot.data()[0];
//             return Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
//               child: RichText(
//                 text: TextSpan(
//                   children: <TextSpan>[
//                     TextSpan(
//                       text: '${user.username}: ',
//                       style: Theme.of(context).textTheme.subtitle2.copyWith(
//                         fontWeight: FontWeight.bold,
//                       )
//                     ),
//                     TextSpan(
//                       text: comment.data()['comment'],
//                       style: Theme.of(context).textTheme.bodyText2
//                     )
//                   ]
//                 ),
//               ),
//             );
//           } else if (snapshot.connectionState == ConnectionState.done && snapshot.hasError) {
//             print(snapshot.error);
//           }
//           return Container();
//         },
//       );
//     }
//     return Container();
//   }

// }

class PostUser extends StatefulWidget {

  final bool isCurrentUser;
  final RivalUser user;
  final Post post;

  const PostUser({Key key, this.isCurrentUser = true, this.user, @required this.post}) : super(key: key);

  @override
  _PostUserState createState() => _PostUserState();
}

class _PostUserState extends State<PostUser> {

  var user;
  Post post;

  @override
  void initState() {
    if (widget.isCurrentUser) {
      user = me;
    } else {
      user = widget.user;
    }
    post = widget.post;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        user.navigateToProfile(context);
        if (!post.isPromoted && !post.profileVisits.containsKey(me.uid) && !widget.isCurrentUser) await post.reference.update({
          'profile_visits.${me.uid}': new DateTime.now().millisecondsSinceEpoch
        }); // Record Profile Visit of non-PROMOTED Post
        else if (post.isPromoted && !post.adProfileVisits.containsKey(me.uid) && !widget.isCurrentUser) await post.adRef.update({
          'profile_visits.${me.uid}': new DateTime.now().millisecondsSinceEpoch
        }); // Record Profile Visit of PROMOTED Post
      },
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 10),
        visualDensity: VisualDensity.compact,
        leading: _getLeadingWidget(),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              fit: FlexFit.loose,
              flex: 1,
              child: Text('${user.displayName}', overflow: TextOverflow.ellipsis,)
            ),
            if (user.isVerified) Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 5),
                VerifiedBadge()
              ],
            )
          ],
        ),
        subtitle: _getPostSubtitle(),
        trailing: (post.isPromoted) ? Tooltip(
          message: 'Promoted Post',
          child: Container(
            margin: EdgeInsets.only(right: 5),
            decoration: BoxDecoration(
              color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.yellow[300] : Colors.yellow[700],
              borderRadius: BorderRadius.all(Radius.circular(4))
            ),
            padding: EdgeInsets.symmetric(vertical: 1, horizontal: 4),
            child: Text(
              'Ad',
              style: Theme.of(context).textTheme.caption.copyWith(
                color: Colors.black
              ),
            ),
          ),
        ) : null,
      ),
    );
  }

  Widget _getLeadingWidget() {
    if (widget.isCurrentUser) {
      return ProfilePhoto(width: 40, height: 40, hero: false);
    } else {
      return ClipOval(
        child: OctoImage(
          height: 40,
          width: 40,
          image: user.photo,
          progressIndicatorBuilder: (context, progress) {
            double value;
            if (progress != null && progress.expectedTotalBytes != null) {
              value = progress.cumulativeBytesLoaded / progress.expectedTotalBytes;
            }
            return CircularProgressIndicator(
              value: value,
              strokeWidth: 2,
            );
          },
        ),
      );
    }
  }

  Widget _getPostSubtitle() {
    if (post.geoPoint != null) { // Return geoPoint
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Icon(Icons.location_on, size: Theme.of(context).textTheme.subtitle2.fontSize, color: Theme.of(context).textTheme.caption.color,),
          ),
          Text(post.location)
        ],
      );
    } else if (post.subtitle != null && post.subtitle.trim() != "") { // Return Subtitle of Post
      return Text(
        post.subtitle,
        overflow: TextOverflow.ellipsis,
      );
    } else { // Return User's Username
      return Text(
        user.username,
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  Widget getTrailingWidget() {
    if (post.isProduct && post.productUrl != null) {
      return FlatButton(
        color: Colors.indigoAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10))
        ),
        child: Text(
          post.productTitle,
          style: TextStyle(color: Colors.white, fontFamily: RivalFonts.feature),
        ),
        onPressed: () async {
          if (await canLaunch(post.productUrl)) {
            await launch(post.productUrl);
          } else {
            await RivalProvider.showToast(text: 'Could not launch URL');
          }
        },
      );
    } else {
      return null;
    }
  }

}

class PostUserView extends StatefulWidget {

  final Post post;
  final bool interactive;

  const PostUserView({Key key, this.post, this.interactive}) : super(key: key);

  @override
  _PostUserViewState createState() => _PostUserViewState();
}

class _PostUserViewState extends State<PostUserView> {

  Post post;
  bool interactive;
  RivalUser user;

  Future<RivalUser> _futureGetUser() async {
    if (user != null) {
      return user;
    } else {
      user = await getUser(post.userId);
      return user;
    }
  }

  @override
  void initState() {
    post = widget.post;
    interactive = widget.interactive;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (post.userId != me.user.uid) {
      return FutureBuilder<RivalUser>(
        future: _futureGetUser(),
        builder: (context, snapshot) {
          bool loaded = snapshot.connectionState == ConnectionState.done;
          return GestureDetector(
            onTap: () async {
              if (loaded) {
                await RivalProvider.vibrate();
                snapshot.data.navigateToProfile(context);
                if (snapshot.data.uid != me.user.uid && !post.reach.containsKey(me.user.uid)) {
                  await post.reference .update({
                    'profile_visits.${me.user.uid}': new DateTime.now().millisecondsSinceEpoch
                  });
                }
              }
            },
            child: ListTile(
              leading: loaded ? ClipOval(
                child: OctoImage(
                  image: snapshot.data.photo,
                  width: 40,
                  height: 40,
                  placeholderBuilder: (context) => CircularProgressIndicator(),
                ),
              )
              : Shimmer.fromColors(
                child: Container(
                  decoration: BoxDecoration(
                    color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black87 : Colors.white70,
                    borderRadius: BorderRadius.all(Radius.circular(100))
                  ),
                  height: 40,
                  width: 40
                ),
                baseColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.white10,
                highlightColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.white12
              ),
              title: loaded ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(snapshot.data.displayName),
                  if (snapshot.data.isVerified) ... [
                    Container(width: 5,),
                    VerifiedBadge()
                  ]
                ],
                ) : Shimmer.fromColors(
                  child: Container(
                    decoration: BoxDecoration(
                      color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black87 : Colors.white70,
                      borderRadius: BorderRadius.all(Radius.circular(5))
                    ),
                    height: 9,
                  ),
                  baseColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.white10, highlightColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black26 : Colors.white12
                ),
              subtitle: post.geoPoint == null ? ((post.subtitle != null && post.subtitle.trim() != "") ? Text(post.subtitle) : Text(loaded ? user.username : '...')) : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Icon(Icons.location_on, size: Theme.of(context).textTheme.subtitle2.fontSize, color: Theme.of(context).textTheme.caption.color,),
                  ),
                  Text(post.location)
                ],
              ),
              trailing: (post.isProduct && interactive) ? FlatButton(
                color: Colors.indigoAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10))
                ),
                onPressed: () async {
                  if (await canLaunch(post.productUrl)) {
                    launch(post.productUrl);
                    if (!post.doc.data()['clicks'].keys.toList().contains(me.uid)) await post.reference .update({
                      'click.${me.uid}': new DateTime.now().millisecondsSinceEpoch
                    });
                  } else {
                    RivalProvider.showToast(text: 'Could not launch url');
                  }
                },
                child: Text(post.productTitle, style: TextStyle(color: Colors.white),)
              ) : null
            ),
          );
        },
      );
    } else {
      return GestureDetector(
        onTap: () => Navigator.of(context).push(RivalNavigator(page: ProfilePage(isCurrentUser: true,))),
        child: ListTile(
          contentPadding: EdgeInsets.fromLTRB(15, 5, 15, 0),
          leading: ProfilePhoto(width: 40, height: 40, hero: false,),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(me.user.displayName),
              if (me.isVerified) ... [
                Container(width: 5,),
                VerifiedBadge()
              ]
            ],
          ),
          subtitle: post.geoPoint == null ? ((post.subtitle != null && post.subtitle.trim() != "") ? Text(post.subtitle) : Text(me.username)) : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Icon(Icons.location_on, size: Theme.of(context).textTheme.subtitle2.fontSize, color: Theme.of(context).textTheme.caption.color,),
              ),
              Text(post.location)
            ],
          ),
          trailing: (post.isProduct && interactive) ? FlatButton(
            color: Colors.indigoAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10))
            ),
            onPressed: () async {
              if (await canLaunch(post.productUrl)) {
                launch(post.productUrl);
              } else {
                RivalProvider.showToast(text: 'Could not launch url');
              }
            },
            child: Text(post.productTitle, style: TextStyle(color: Colors.white),)
          ) : null
        ),
      );
    }
  }
}

class BookmarkPost extends StatefulWidget {

  final Post post;

  const BookmarkPost({Key key, this.post}) : super(key: key);

  @override
  _BookmarkPostState createState() => _BookmarkPostState();
}

class _BookmarkPostState extends State<BookmarkPost> {

  bool isPostBookmarked = false;
  Post post;

  @override
  void initState() {
    post = widget.post;
    if (me.bookmarksById.contains(post.id)) {
      isPostBookmarked = true;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamProvider<Me>.value(
      value: me.streamX,
      initialData: me,
      updateShouldNotify: (previous, current) {
        if (current.bookmarksById.contains(post.id)) {
          if (mounted) setState(() {
            isPostBookmarked = true;
          });
        } else {
          if (mounted) setState(() {
            isPostBookmarked = false;
          });
        }
        return false;
      },
      lazy: false,
      builder: (context, child) {
        return child;
      },
      child: GestureDetector(
        child: Tooltip(
          message: isPostBookmarked ? 'Remove this Post from Bookmarks' : 'Bookmark this Post',
          child: isPostBookmarked ? Icon(Icons.bookmark) : Icon(Icons.bookmark_outline),
        ),
        onTap: () async {
          if (isPostBookmarked) {
            // Remove from Bookmarks
            setState(() {
              isPostBookmarked = false;
            });
            await me.reference.update({
              'bookmarks': FieldValue.arrayRemove([post.reference])
            });
            await RivalProvider.showToast(text: 'Removed from Bookmarks');
            await me.reload();
          } else {
            // Add to bookmarks
            setState(() {
              isPostBookmarked = true;
            });
            await me.reference.update({
              'bookmarks': FieldValue.arrayUnion([post.reference])
            });
            await RivalProvider.showToast(text: 'Added to Bookmarks');
            await me.reload();
          }
        },
      ),
    );
  }
}

class TaggedPeople extends StatefulWidget {

  final Post post;

  const TaggedPeople({Key key, this.post}) : super(key: key);

  @override
  _TaggedPeopleState createState() => _TaggedPeopleState();
}

class _TaggedPeopleState extends State<TaggedPeople> {

  List<RivalUser> users;
  Post post;

  Future<void> _init() async {
    users = [];
    for (DocumentReference ref in post.people) {
      RivalUser user = await RivalProvider.getUserByRef(ref);
      users.add(user);
    }
    setState(() { });
  }

  @override
  void initState() { 
    super.initState();
    post = widget.post;
    _init();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    if (users == null || users.length == 0) return Container();
    return IconButton(
      onPressed: () => showModalBottomSheet(
        context: context,
        builder: (context) => BottomSheet(
          onClosing: () {},
          builder: (context) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
                  child: Text('Tagged People', style: Theme.of(context).textTheme.headline6.copyWith(fontFamily: RivalFonts.feature),),
                ),
                ... List.generate(
                  users.length,
                  (index) => UserListTile(
                    user: users[index],
                    isCurrentUser: users[index].uid == me.uid,
                  )
                )
              ],
            ),
          ),
        ),
      ),
      icon: Icon(Icons.alternate_email),
      tooltip: users.length > 1 ? 'View all ${users.length} tagged people' : 'View 1 tagged person',
    );
  }
}

class ViewPost extends StatefulWidget {

  final Post post;
  /// If [true], border will be automatically assigned to both top and end
  final bool isSingleWidget;
  /// Provide this string to inform the user why he/she is getting this post in their timeline or explore
  /// Leave empty to hide this option
  final String whyThisPost;

  const ViewPost({Key key, @required this.post, this.isSingleWidget = false, this.whyThisPost}) : super(key: key);

  @override
  _ViewPostState createState() => _ViewPostState();
}

class _ViewPostState extends State<ViewPost> {

  Post post;

  Key key;

  final PreloadPageController _pageController = PreloadPageController(viewportFraction: 1,);
  final ExpandableController _expandableController = ExpandableController();

  @override
  void initState() {
    post = widget.post;
    key = ObjectKey(post?.id);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (post == null || (!post.available)) { // Post is not available due to some reason
      return InfoBanner(
        leadingIcon: Icons.error,
        content: Text('Post Unavailable'),
        actions: [
          FlatButton(
            child: Text('Learn More'),
            onPressed: () async {
              await launch('https://rival.photography/post/unavailable');
            },
          )
        ],
      );
    } else if (post.user == null) {
      return InfoBanner(
        leadingIcon: Icons.error,
        content: Text('Failed to load this post. ERR-LD-USR'),
        actions: [
          FlatButton(
            child: Text('Learn More'),
            onPressed: () async {
              await launch('https://rival.photography/post/err-ld-usr');
            },
          )
        ],
      );
    } else if (post.takenDown) { // Post has been taken down by Rival
      return InfoBanner(
        leadingIcon: Icons.warning,
        content: Text('This post has been taken down by Rival because it does not comply by our policies'),
        actions: [
          FlatButton(
            child: Text('Privacy Policy'),
            onPressed: () async {
              await launch('https://rival.photography/privacy-policy');
            },
          )
        ],
      );
    } else if (!post.isMyPost && post.user.private && !post.user.isFollowing) { // User has PRIVATE account and I'm not following
      return InfoBanner(
        leadingIcon: Icons.warning,
        content: Text('You cannot view this post because @${post.user.username} has a private account. Follow @${post.user.username} to view this post'),
        actions: [
          FlatButton(
            child: Text(post.user.followUnfollow),
            onPressed: () async {
              await post.user.followUnfollowRequest();
              setState(() { });
            },
          )
        ],
      );
    } else if (!post.isMyPost && post.user.amIBlocked) { // User has blocked me
      return InfoBanner(
        leadingIcon: Icons.warning,
        content: Text('You cannot view this post'),
        actions: [
          FlatButton(
            child: Text('Learn More'),
            onPressed: () async {
              await launch('https://rival.photography/post/unavailable');
            },
          )
        ],
      );
    } else if (!post.isMyPost && post.user.isBlocked) { // I have blocked the user
      return InfoBanner(
        leadingIcon: Icons.warning,
        content: Text('This post is hidden because you have blocked @${post.user.username}. Unblock to view their posts'),
        actions: [
          FlatButton(
            child: Text('Unblock'),
            onPressed: () async {
              await post.user.blockUnblock();
            },
          )
        ],
      );
    } else if (post.adultRated && me.age < 18) { // Age Restricted Post
      return InfoBanner(
        leadingIcon: Icons.warning,
        content: Text('This post is age restricted'),
        actions: [
          FlatButton(
            child: Text('Privacy Policy'),
            onPressed: () async {
              await launch('https://rival.photography/post/age-restricted');
            },
          )
        ],
      );
    } else { // All Good
      BorderSide borderSide = BorderSide(color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[300] : Colors.white12, width: 0.8);
      return Container(
        decoration: BoxDecoration(
          border: Border(top: borderSide, bottom: widget.isSingleWidget ? borderSide : BorderSide.none)
        ),
        child: VisibilityDetector(
          key: key,
          onVisibilityChanged: (info) async {
            double visibility = info.visibleFraction;
            if (visibility == 1.0 && !post.isPromoted) {
              // Got an impression for (Timeline, Profile Post, Trending, Explore)
              if(post.impressions[me.uid] == null && post.userId != me.uid) {
                await analytics.logEvent(name: 'new_impression', parameters: {
                  me.uid: new DateTime.now().millisecondsSinceEpoch
                });
                post.reference.update({
                  'impressions.${me.uid}': new DateTime.now().millisecondsSinceEpoch
                });
                post.refresh();
              }
              if (post.userId != me.uid && post.labels.isNotEmpty) {
                for (String label in post.labels) {
                  if (me.interests.containsKey(label.toLowerCase())) {
                    await me.update({
                      'interests.${label.toLowerCase()}': FieldValue.increment(1)
                    });
                  } else {
                    await me.update({
                      'interests.${label.toLowerCase()}': 0
                    });
                  }
                }
              }
            } else if (visibility == 1.0 && post.isPromoted) {
              // Got an impression for AD
              if(post.adImpressions[me.uid] == null && post.userId != me.uid) {
                await analytics.logEvent(name: 'new_ad_impression', parameters: {
                  me.uid: new DateTime.now().millisecondsSinceEpoch
                });
                post.adRef.update({
                  'impressions.${me.uid}': new DateTime.now().millisecondsSinceEpoch
                });
                post.refresh();
              }
            }
          },
          child: Container(
            child: Column(
              children: [
                if (post.isMyPost) PostUser(post: post, isCurrentUser: true,)
                else PostUser(post: post, user: post.user, isCurrentUser: false,),
                Container(
                  padding: EdgeInsets.only(bottom: 0),
                  decoration: BoxDecoration(
                    border: Border.symmetric(horizontal: BorderSide(color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[200] : Colors.white10, width: 0.4))
                  ),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: (MediaQuery.of(context).size.width / post.ratio > (MediaQuery.of(context).size.height * 0.75)) ? MediaQuery.of(context).size.height * 0.55 : MediaQuery.of(context).size.width / post.ratio,
                    child: Stack(
                      children: [
                        PreloadPageView.builder(
                          controller: _pageController,
                          preloadPagesCount: 10,
                          itemCount: post.images.length,
                          itemBuilder: (context, index) => Container(
                            child: OctoImage(
                              image: CachedNetworkImageProvider(post.images[index]),
                              progressIndicatorBuilder: (context, progress) {
                                double value;
                                if (progress != null && progress.expectedTotalBytes != null) {
                                  value = progress.cumulativeBytesLoaded / progress.expectedTotalBytes;
                                }
                                return Container(
                                  width: 50,
                                  height: 50,
                                  child: CircularProgressIndicator(
                                    value: value,
                                    valueColor: new AlwaysStoppedAnimation<Color>(MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black : Colors.white),
                                    strokeWidth: 2,
                                  ),
                                );
                              }
                            ),
                          ),
                        ),
                        if (post.images.length > 1) Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                            child: Container(
                              child: PageNotifier(controller: _pageController, pages: post.images.length,),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                if (post.description != null && post.description.trim() != "") Padding(
                  padding: EdgeInsets.only(left: 10, right: 10, top: 10,),
                  child: ExpandablePanel(
                    controller: _expandableController,
                    collapsed: (post.description.toString().length > 40)
                    ? GestureDetector(
                      onTap: () => _expandableController.toggle(),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(text: "${post.description.substring(0, 40).replaceAll('\n', ' ')}... ", style: Theme.of(context).textTheme.bodyText2),
                            TextSpan(text: "read more", style: TextStyle(color: Colors.indigo))
                          ]
                        ),
                      ),
                    )
                    : TextParser(
                      text: post.description,
                      textStyle: Theme.of(context).textTheme.bodyText2,
                      matchedWordStyle: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    expanded: TextParser(
                      matchedWordStyle: TextStyle(fontWeight: FontWeight.bold),
                      text: post.description,
                      textStyle: TextStyle(color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black87 : Colors.white70),
                    ),
                  ),
                ),
                if (post.isProduct || post.sponsor != null) Padding(
                  padding: EdgeInsets.only(top: 5, left: 10, right: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (post.isProduct) ... [
                            Icon(Icons.shopping_bag),
                            Container(width: 5,),
                          ],
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (post.isProduct) Text('Product', style: Theme.of(context).textTheme.button,),
                              if (post.sponsor != null) Text(
                                'Sponsored by @${post.sponsor.username}',
                                style: Theme.of(context).textTheme.caption,
                              ),
                            ],
                          )
                        ],
                      ),
                      if (post.isProduct && post.productUrl != null) FlatButton(
                        color: Colors.indigoAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10))
                        ),
                        child: Text(
                          post.productTitle,
                          style: TextStyle(color: Colors.white, fontFamily: RivalFonts.feature),
                        ),
                        onPressed: () async {
                          if (await canLaunch(post.productUrl)) {
                            await launch(post.productUrl);
                          } else {
                            await RivalProvider.showToast(text: 'Could not launch URL');
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onLongPress: (post.showLikeCount || post.isMyPost) ? () => Navigator.of(context).push(RivalNavigator(page: PostLikes(post: post,), )) : null,
                            child: LikeButton(
                              isLiked: post.isLiked,
                              likeCount: post.likes.length,
                              countBuilder: (likeCount, isLiked, text) {
                                if ((post.showLikeCount || post.isMyPost) && post.likes.length > 0) return Text(likeCount.toString(), style: Theme.of(context).textTheme.button.copyWith(
                                  color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[700] : Colors.white
                                ),);
                                else return Container();
                              },
                              bubblesColor: BubblesColor(dotPrimaryColor: Colors.indigo, dotSecondaryColor: Colors.redAccent),
                              onTap: (isLiked) {
                                return _like(isLiked);
                              },
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            onPressed: () async {
                              // Share
                              await Share.share('${post.description}. View Post on Rival: ${post.shareableUrl}');
                              if (post.userId != me.uid && !post.shares.containsKey(me.uid)) await post.reference .update({
                                'shares.${me.uid}': new DateTime.now().millisecondsSinceEpoch
                              });
                            },
                            tooltip: 'Share',
                            icon: Icon(FontAwesome.share, color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[500] : Colors.grey[400]),
                          ),
                          if (post.allowComments) IconButton(
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            icon: Icon(FontAwesome.comment, color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[500] : Colors.grey[400]),
                            tooltip: 'Comment',
                            onPressed: () => Navigator.of(context).push(RivalNavigator(page: PostComments(post: post,)))
                          )
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TaggedPeople(post: post,),
                          Padding(
                            padding: const EdgeInsets.only(left: 5),
                            child: PopupMenuButton(
                              child: Icon(Icons.more_vert),
                              itemBuilder: (context) => <PopupMenuEntry<dynamic>>[
                                if (post.userId == me.uid) ... [
                                  PopupMenuItem(
                                    child: Text('Edit'),
                                    value: 'edit',
                                  ),
                                  if (me.isBusinessAccount || me.isCreatorAccount) PopupMenuItem(
                                    child: Text('View Insights'),
                                    value: 'insights',
                                  ),
                                ],
                                if (post.userId != me.uid && post.user != null) PopupMenuItem(
                                  child: Text('View Profile'),
                                  value: 'visitProfile',
                                ),
                                PopupMenuItem(
                                  child: Text('Copy URL'),
                                  value: 'copyUrl',
                                ),
                                if (post.userId != me.uid) PopupMenuItem(
                                  child: Text('Report Post'),
                                  value: 'report',
                                ),
                                if (post.userId != me.uid && post.isPromoted) PopupMenuItem(
                                  child: Text('Report Ad'),
                                  value: 'reportAd',
                                ),
                                PopupMenuItem(
                                  child: Text('Add to Story'),
                                  value: 'addAsStory',
                                ),
                                if (post.userId != me.uid && post.user != null) PopupMenuItem(
                                  child: Text('${post.user.isBlocked ? 'Unblock' : 'Block'} ${post.user.username}'),
                                  value: 'block',
                                ),
                                if (widget.whyThisPost != null) PopupMenuItem(
                                  child: Text('Why this post?'),
                                  value: 'whyThisPost'
                                )
                              ],
                              onSelected: (value) async {
                                switch (value) {
                                  case 'edit':
                                    RivalProvider.vibrate();
                                    if (RivalRemoteConfig.allowEditPost) {
                                      Navigator.of(context).push(RivalNavigator(page: EditPost(post: post), ));
                                    } else {
                                      showDialog(
                                        context: context,
                                        child: AlertDialog(
                                          title: Text('Edit Post Disabled'),
                                          content: Text('Post editing has been disabled for a limited time. Please try again later'),
                                          actions: [
                                            FlatButton(
                                              onPressed: () => Navigator.of(context).pop(),
                                              child: Text('OK')
                                            )
                                          ],
                                        )
                                      );
                                    }
                                    break;
                                  case 'insights':
                                    RivalProvider.vibrate();
                                    Navigator.of(context).push(RivalNavigator(page: PostInsights(post: post), ));
                                    break;
                                  case 'visitProfile':
                                    post.user.navigateToProfile(context);
                                    break;
                                  case 'copyUrl':
                                    await Clipboard.setData(ClipboardData(text: post.shareableUrl));
                                    RivalProvider.showToast(text: 'Copied to Clipboard');
                                    break;
                                  case 'addAsStory':
                                    await post.shareAsStory();
                                    break;
                                  case 'report':
                                    showDialog(
                                      context: context,
                                      child: AlertDialog(
                                        title: Text('Report'),
                                        content: Text('Do you want to report this post?'),
                                        actions: [
                                          FlatButton(
                                            onPressed: () async {
                                              Navigator.of(context).pop();
                                              await post.report();
                                            },
                                            child: Text('Report')
                                          ),
                                          FlatButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            child: Text('Cancel')
                                          )
                                        ],
                                      )
                                    );
                                    break;
                                  case 'reportAd':
                                    showDialog(
                                      context: context,
                                      child: AlertDialog(
                                        title: Text('Report Ad'),
                                        content: Text('Do you want to report this Ad?'),
                                        actions: [
                                          FlatButton(
                                            onPressed: () async {
                                              Navigator.of(context).pop();
                                              await post.reportAd();
                                            },
                                            child: Text('Report')
                                          ),
                                          FlatButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            child: Text('Cancel')
                                          )
                                        ],
                                      )
                                    );
                                    break;
                                  case 'block':
                                    await post.user.blockUnblock();
                                    break;
                                  case 'whyThisPost':
                                    showDialog(
                                      context: context,
                                      child: AlertDialog(
                                        title: Text('Why this post?'),
                                        content: Text(widget.whyThisPost),
                                        actions: [
                                          FlatButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            child: Text('Ok')
                                          )
                                        ],
                                      )
                                    );
                                    break;
                                  default:
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 10, right: 10, bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        '${getTimeAgo(new DateTime.fromMillisecondsSinceEpoch(post.timestamp))} • ${post.user.username}',
                        style: Theme.of(context).textTheme.caption,
                      ),
                    ],
                  ),
                ),
                if (post.label != null) Padding(
                  padding: EdgeInsets.only(bottom: 5,),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.yellow[400],
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(Icons.warning, color: Colors.black,),
                        Container(width: 5),
                        Text('This post has been marked as unofficial', style: Theme.of(context).textTheme.bodyText2.copyWith(color: Colors.black))
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Future<bool> _like(bool liked) async {
    // Don't use await because it will make the animation (Like) useless.
    if (liked) {
      post.reference.update({
        'likes.${me.user.uid}': FieldValue.delete()
      });
      post.refresh();
      return !liked;
    } else {
      post.reference.update({
        'likes.${me.user.uid}': new DateTime.now().millisecondsSinceEpoch
      });
      post.refresh();
      return !liked;
    }
  }

}

class SinglePostView extends StatefulWidget {

  final Post post;
  final String postId;

  const SinglePostView({Key key, this.post, this.postId}) : super(key: key);

  @override
  _SinglePostViewState createState() => _SinglePostViewState();
}

class _SinglePostViewState extends State<SinglePostView> {

  Post post;
  bool isLoading = false;

  Key key;

  Future<void> _getPostFromId() async {
    setState(() {
      isLoading = true;
    });
    post = await getPost(widget.postId);
    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    if (widget.post != null) {
      post = widget.post;
    } else {
      _getPostFromId();
    }
    key = ObjectKey(post?.id);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isLoading ? Text('Post') : Text('@${post.user.username}'),
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
      : ViewPost(
        post: post,
        isSingleWidget: true,
      ),
    );
  }

}

class PostsByTopic extends StatefulWidget {

  final String topic;

  PostsByTopic({Key key, @required this.topic}) : super(key: key);

  @override
  _PostsByTopicState createState() => _PostsByTopicState();
}

class _PostsByTopicState extends State<PostsByTopic> {

  List<Post> loaded = [];
  int postsPerPage = 10;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Posts'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              title: Text(widget.topic),
              trailing: SubscribedTopicsBtn(
                topic: widget.topic,
              ),
            ),
            PagedListView(
              autoNextPage: true,
              itemsPerPage: postsPerPage,
              loadingWidget: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(),
              ),
              onFinish: 'That\'s it',
              onNextPage: _getNextPage,
            )
          ],
        ),
      ),
    );
  }

  Future<List<Widget>> _getNextPage(int start, int end) async {
    List<Widget> widgets = [];
    List<Post> local = [];
    Query query = firestore.collection('posts').where('topic', isEqualTo: widget.topic).limit(postsPerPage).orderBy('timestamp', descending: true);
    if (loaded.isNotEmpty) {
      query = query.startAfterDocument(loaded.last.doc);
    }
    QuerySnapshot querySnapshot = await query.get();
    for (DocumentSnapshot doc in querySnapshot.docs) {
      Post post = await Post.fetch(doc: doc);
      if (post.isMyPost || (post.user.private && post.user.isFollowing) || !post.user.private) local.add(post);
    }
    loaded.addAll(local);
    for (Post post in local) {
      widgets.add(ViewPost(
        post: post,
      ));
    }
    return widgets;
  }

}