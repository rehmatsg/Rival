import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:intl/intl.dart';
import 'package:octo_image/octo_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app.dart';

// class ProfilePage extends StatefulWidget {

//   const ProfilePage({
//     Key key,
//     @required this.user
//   }) : super(key: key);
//   final RivalUser user;

//   @override
//   _ProfilePageState createState() => _ProfilePageState();
// }

// class _ProfilePageState extends State<ProfilePage> {

//   final ExpandableController _expandableController = ExpandableController();
//   final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

//   bool isFollowing = false;
//   bool isInWaitList = false;
//   bool isLoading = true;

//   RivalUser user;

//   List<Post> postsByRivalUser = [];

//   @override
//   void initState() {
//     user = widget.user;
//     _init();
//     super.initState();
//   }

//   Future<void> _init() async {
//     if (user.isFollowing) {
//       setState(() {
//         isFollowing = true;
//         isLoading = false;
//       });
//     } else if (user.isInWaitList) {
//       setState(() {
//         isLoading = false;
//         isFollowing = false;
//         isInWaitList = true;
//       });
//     } else {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffoldKey,
//       body: SafeArea(
//         child: user.isBlocked
//         ? Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 15),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Text('@${user.username}', style: Theme.of(context).textTheme.headline3.copyWith(fontFamily: RivalFonts.feature)),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
//                 child: Text('Oops! you cannot view this profile because you have blocked it. Unblock @${user.username} to view profile'),
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   FlatButton(
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.all(Radius.circular(10))
//                     ),
//                     onPressed: () => Navigator.of(context).pop(),
//                     child: Text('Go back')
//                   ),
//                   FlatButton(
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.all(Radius.circular(10))
//                     ),
//                     color: isLoading ? Colors.white : Colors.indigoAccent,
//                     onPressed: () async {
//                       setState(() {
//                         isLoading = true;
//                       });
//                       await user.blockUnblock();
//                       setState(() {
//                         isLoading = false;
//                       });
//                     },
//                     child: isLoading ? Container(
//                       height: 15,
//                       width: 15,
//                       child: CircularProgressIndicator(strokeWidth: 1,)
//                     ) : Text('Unblock')
//                   )
//                 ],
//               )
//             ],
//           ),
//         )
//         : (
//           user.amIBlocked
//           ? Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 15),
//             child: Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text('Error 404', style: Theme.of(context).textTheme.headline3.copyWith(fontFamily: RivalFonts.feature)),
//                 ],
//               ),
//             ),
//           )
//           : SingleChildScrollView(
//             child: Column(
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     IconButton(
//                       icon: const Icon(Icons.arrow_back),
//                       onPressed: () => Navigator.of(context).pop(),
//                     ),
//                     PopupMenuButton(
//                       itemBuilder: (context) => <PopupMenuEntry<dynamic>>[
//                         PopupMenuItem(
//                           child: Text(user.followUnfollow),
//                           value: 'followUnfollowRequest',
//                         ),
//                         PopupMenuItem(
//                           child: Text('Copy Profile URL'),
//                           value: 'copyUrl',
//                         ),
//                         PopupMenuItem(
//                           child: Text('Report'),
//                           value: 'report',
//                         ),
//                         PopupMenuItem(
//                           child: Text('Block'),
//                           value: 'block',
//                         ),
//                       ],
//                       onSelected: (value) async {
//                         switch (value) {
//                           case 'followUnfollowRequest':
//                             await user.followUnfollowRequest();
//                             break;
//                           case 'copyUrl':
//                             print(await createDynamicURL(link: 'https://rival.photography/profile', uriPrefix: 'https://rival.page.link/profile'));
//                             // if (await ClipboardManager.copyToClipBoard('https://rival.photography/profile/@${user.username}')) {
//                             //   RivalProvider.showToast(text: 'Copied to Clipboard');
//                             // } else {
//                             //   RivalProvider.showToast(text: 'Failed to Copy');
//                             // }
//                             break;
//                           case 'report':
//                             showDialog(
//                               context: context,
//                               child: AlertDialog(
//                                 title: Text('Report'),
//                                 content: Text('Do you want to report @${user.username}? We won\'t tell them if you report. If we find something unusual, we\'ll block them. For detailed report mail us at help@rival.photography. @${user.username} will also be blocked after reporting'),
//                                 actions: [
//                                   FlatButton(
//                                     onPressed: () async {
//                                       await user.report();
//                                       setState(() {});
//                                       Navigator.of(context).pop();
//                                       _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text('Reported @${user.username}. For futher enquiry mail us at help@rival.photography')));
//                                     },
//                                     child: Text('Report', style: TextStyle(color: Colors.red)),
//                                   ),
//                                   FlatButton(
//                                     onPressed: () => Navigator.of(context).pop(),
//                                     child: Text('Cancel')
//                                   )
//                                 ],
//                               )
//                             );
//                             break;
//                           case 'block':
//                             await user.blockUnblock();
//                             await user.reload();
//                             await me.reload();
//                             Navigator.of(context).maybePop();
//                             break;
//                           default:
//                         }
//                       },
//                     ),
//                   ],
//                 ),
//                 Row(
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
//                       child: (user.doc.data()['photoUrl'] != null)
//                       ? (
//                         (user.stories != null && user.stories.isNotEmpty) ? GestureDetector(
//                           onTap: () => Navigator.of(context).push(RivalNavigator(page: ViewStory(isCurrentUser: false, user: user, isFromHomeScreen: false,), )),
//                           child: CircularStepProgressIndicator(
//                             totalSteps: user.stories.length,
//                             unselectedColor: (user.storyViewed || user.uid == me.user.uid) ? (MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black38 : Colors.white38) : Colors.indigoAccent,
//                             height: MediaQuery.of(context).size.width * 0.2,
//                             width: MediaQuery.of(context).size.width * 0.2,
//                             padding: user.stories.length > 1 ? (22/7) / 15 : 0,
//                             customStepSize: (intn, boo) => 2,
//                             child: Padding(
//                               padding: const EdgeInsets.all(2.0),
//                               child: Hero(
//                                 tag: 'story-${user.uid}',
//                                 child: ClipOval(
//                                   child: OctoImage(
//                                     image: NetworkImage(user.doc.data()['photoUrl'].toString()),
//                                     height: MediaQuery.of(context).size.width * 0.2,
//                                     width: MediaQuery.of(context).size.width * 0.2,
//                                     progressIndicatorBuilder: (context, progress) => const CircularProgressIndicator(),
//                                   )
//                                 ),
//                               ),
//                             ),
//                           ),
//                         )
//                         : ClipOval(
//                           child: OctoImage(
//                             image: NetworkImage(user.doc.data()['photoUrl'].toString()),
//                             height: MediaQuery.of(context).size.width * 0.2,
//                             width: MediaQuery.of(context).size.width * 0.2,
//                             progressIndicatorBuilder: (context, progress) => const CircularProgressIndicator(),
//                           )
//                         )
//                       )
//                       : ClipOval(
//                         child: Image.asset('assets/images/avatar.png', width: MediaQuery.of(context).size.width * 0.2, height: MediaQuery.of(context).size.width * 0.2,),
//                       ),
//                     ),
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Text(user.displayName, style: TextStyle(fontFamily: RivalFonts.feature, fontSize: Theme.of(context).textTheme.headline5.fontSize),),
//                             if (user.isVerified) ... [
//                               Container(width: 10,),
//                               VerifiedBadge(width: 20, height: 20),
//                             ]
//                           ],
//                         ),
//                         Text('@${user.username}', style: Theme.of(context).textTheme.subtitle1.copyWith(
//                           color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black87 : Colors.grey[200]
//                         )),
//                         if (user.isBusinessAccount && user.businessCategory != null) Text('${user.businessCategory}', style: Theme.of(context).textTheme.subtitle2.copyWith(
//                           color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black54 : Colors.grey[500]
//                         )),
//                       ],
//                     )
//                   ],
//                 ),
//                 if (user.doc.data()['bio'] != null) Padding(
//                   padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
//                   child: ExpandablePanel(
//                     controller: _expandableController,
//                     collapsed: Wrap(
//                       children: [
//                         if (user.doc.data()['bio'].toString().length > 40) ... [
//                           TextParser(
//                             text: "${user.doc.data()['bio'].toString().substring(0, 40).replaceAll('\n', '')}...",
//                             ifUsername: (String word) {
//                               showSearch(
//                                 context: context,
//                                 delegate: RivalSearchDelegate(),
//                                 query: word
//                               );
//                             },
//                             ifTag: (String word) {
//                               showSearch(
//                                 context: context,
//                                 delegate: RivalSearchDelegate(),
//                                 query: word
//                               );
//                             },
//                             ifEmail: (String word) async {
//                               if (await canLaunch('mailto:$word')) {
//                                 await launch('mailto:$word');
//                               } else {
//                                 //print('Could not launch email mailto:$word');
//                               }
//                             },
//                             ifUrl: (String word) async {
//                               if (await canLaunch(word)) {
//                                 await launch(word);
//                               } else {
//                                 //print('Could not launch $word');
//                               }
//                             },
//                             textStyle: TextStyle(color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black87 : Colors.white70),
//                             matchedWordStyle: TextStyle(color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black87 : Colors.white70, fontWeight: FontWeight.bold)
//                           ),
//                           GestureDetector(
//                             onTap: () => _expandableController.toggle(),
//                             child: const Text('read more', style: TextStyle(color: Colors.indigoAccent),),
//                           )
//                         ] else ... [
//                           TextParser(
//                             text: user.doc.data()['bio'].toString(),
//                             ifUsername: (String word) {
//                               showSearch(
//                                 context: context,
//                                 delegate: RivalSearchDelegate(),
//                                 query: word
//                               );
//                             },
//                             ifTag: (String word) {
//                               showSearch(
//                                 context: context,
//                                 delegate: RivalSearchDelegate(),
//                                 query: word
//                               );
//                             },
//                             ifEmail: (String word) async {
//                               if (await canLaunch('mailto:$word')) {
//                                 await launch('mailto:$word');
//                               } else {
//                                 print('Could not launch email mailto:$word');
//                               }
//                             },
//                             ifUrl: (String word) async {
//                               if (await canLaunch(word)) {
//                                 await launch(word);
//                               } else {
//                                 //print('Could not launch $word');
//                               }
//                             },
//                             textStyle: TextStyle(color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black87 : Colors.white70),
//                             matchedWordStyle: TextStyle(color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black87 : Colors.white70, fontWeight: FontWeight.bold)
//                           ),
//                         ]
//                       ],
//                     ),
//                     expanded: TextParser(
//                       text: user.doc.data()['bio'].toString(),
//                       ifUsername: (String word) {
//                         showSearch(
//                           context: context,
//                           delegate: RivalSearchDelegate(),
//                           query: word
//                         );
//                       },
//                       ifTag: (String word) {
//                         showSearch(
//                           context: context,
//                           delegate: RivalSearchDelegate(),
//                           query: word
//                         );
//                       },
//                       ifEmail: (String word) async {
//                         if (await canLaunch('mailto:$word')) {
//                           await launch('mailto:$word');
//                         } else {
//                           //print('Could not launch email mailto:$word');
//                         }
//                       },
//                       ifUrl: (String word) async {
//                         if (await canLaunch(word)) {
//                           await launch(word);
//                         } else {
//                           //print('Could not launch $word');
//                         }
//                       },
//                       textStyle: TextStyle(color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black87 : Colors.white70),
//                       matchedWordStyle: TextStyle(color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black87 : Colors.white70, fontWeight: FontWeight.bold)
//                     ),
//                   ),
//                 ),
//                 Container(
//                   margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//                   decoration: BoxDecoration(
//                     color: Colors.indigoAccent[100],
//                     borderRadius: const BorderRadius.all(Radius.circular(10))
//                   ),
//                   child: Container(
//                     decoration: const BoxDecoration(
//                       color: Colors.transparent,
//                       borderRadius: BorderRadius.all(Radius.circular(10))
//                     ),
//                     child: Row(
//                       children: <Widget>[
//                         const Spacer(),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 20),
//                           child: GestureDetector(
//                             onTap: () async {
//                               if ((user.private && user.isFollowing) || (!user.private)) {
//                                 if (await Vibration.hasVibrator()) Vibration.vibrate(duration: 5);
//                                 Navigator.of(context).push(RivalNavigator(page: Followers(user: user.doc,),));
//                               }
//                             },
//                             child: Column(
//                               children: <Widget>[
//                                 Text(NumberFormat.compact().format(user.doc.data()['followers'].length), style: const TextStyle(fontFamily: RivalFonts.feature, color: Colors.white, fontSize: 20),),
//                                 const Text('followers', style: TextStyle(color: Colors.white38, fontSize: 15),),
//                               ],
//                             ),
//                           ),
//                         ),
//                         const Spacer(),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 20),
//                           child: GestureDetector(
//                             onTap: () async {
//                               if ((user.private && user.isFollowing) || (!user.private)) {
//                                 if (await Vibration.hasVibrator()) Vibration.vibrate(duration: 5);
//                                 Navigator.of(context).push(RivalNavigator(page: Following(user: user.doc,),));
//                               }
//                             },
//                             child: Column(
//                               children: <Widget>[
//                                 Text(NumberFormat.compact().format(user.doc.data()['following'].length), style: const TextStyle(fontFamily: RivalFonts.feature, color: Colors.white, fontSize: 20),),
//                                 const Text('following', style: TextStyle(color: Colors.white38, fontSize: 15),),
//                               ],
//                             ),
//                           ),
//                         ),
//                         const Spacer(),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 20),
//                           child: GestureDetector(
//                             onTap: () async {
//                               if ((user.private && user.isFollowing) || (!user.private)) {
//                                 if (await Vibration.hasVibrator()) Vibration.vibrate(duration: 5);
//                                 Navigator.of(context).push(RivalNavigator(page: PostsByUser(user: RivalUser(doc: user.doc), isCurrentUser: false, posts: postsByRivalUser,),));
//                               }
//                             },
//                             child: Column(
//                               children: <Widget>[
//                                 Text(user.doc.data()['posts'].length.toString(), style: const TextStyle(fontFamily: RivalFonts.feature, color: Colors.white, fontSize: 20),),
//                                 const Text('posts', style: TextStyle(color: Colors.white38, fontSize: 15),),
//                               ],
//                             ),
//                           ),
//                         ),
//                         const Spacer(),
//                       ],
//                     ),
//                   ),
//                 ),
//                 Container(height: 10,),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     Container(
//                       width: MediaQuery.of(context).size.width * 0.5 - 30,
//                       child: StreamBuilder<DocumentSnapshot>(
//                         stream: user.doc.reference.snapshots(),
//                         builder: (context, snapshot) {
//                           if (snapshot.connectionState == ConnectionState.active) {
//                             final DocumentSnapshot userDocUpdated = snapshot.data;
//                             user = RivalUser(doc: userDocUpdated);
//                             return OutlineButton(
//                               shape: const RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.all(Radius.circular(10))
//                               ),
//                               onPressed: () async {
//                                 await RivalProvider.vibrate();
//                                 await user.followUnfollowRequest();
//                               },
//                               color: Colors.indigoAccent,
//                               child: Text(user.followUnfollow),
//                             );
//                           }
//                           return OutlineButton(
//                             shape: const RoundedRectangleBorder(
//                               borderRadius: BorderRadius.all(Radius.circular(10))
//                             ),
//                             child: Container(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2,)),
//                             onPressed: () {
                              
//                             },
//                             color: Colors.indigoAccent,
//                           );
//                         },
//                       )
//                     ),
//                     Container(
//                       width: MediaQuery.of(context).size.width * 0.5 - 30,
//                       // ignore: missing_required_param
//                       child: const OutlineButton(
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.all(Radius.circular(10))
//                         ),
//                         color: Colors.indigoAccent,
//                         child: Text('Message'),
//                       ),
//                     )
//                   ],
//                 ),
//                 const Divider(),
//                 // ignore: avoid_bool_literals_in_conditional_expressions
//                 if (user.isFollowing ? true : (!user.private)) Column(
//                   children: [
//                     GridView.count(
//                       shrinkWrap: true,
//                       physics: const ScrollPhysics(),
//                       crossAxisCount: 3,
//                       padding: const EdgeInsets.all(5),
//                       children: List.generate(
//                         user.posts.length,
//                         (index) {
//                         return Padding(
//                           padding: const EdgeInsets.all(1),
//                           child: FutureBuilder<DocumentSnapshot>(
//                             future: user.posts.reversed.toList()[index].get(),
//                             builder: (context, snapshot) {
//                               if(snapshot.connectionState == ConnectionState.done) {
//                                 final DocumentSnapshot postDoc = snapshot.data;
//                                 postsByRivalUser.removeWhere((post) => post.id == postDoc.id);
//                                 postsByRivalUser.add(Post(doc: postDoc));
//                                 postsByRivalUser.sort((a, b) => b.timestamp.compareTo(a.timestamp));
//                                 return InkWell(
//                                   onTap: () => Navigator.of(context).push(RivalNavigator(page: PostsByUser(user: user, index: index, posts: postsByRivalUser, isCurrentUser: false,),)),
//                                   child: Stack(
//                                     children: [
//                                       OctoImage(
//                                         width: double.infinity,
//                                         height: double.infinity,
//                                         image: NetworkImage(postDoc.data()['images'][0].toString()),
//                                         fit: BoxFit.cover,
//                                         progressIndicatorBuilder: (context, progress) {
//                                           return Center(
//                                             child: Container(
//                                               width: MediaQuery.of(context).size.width * 0.1,
//                                               height: MediaQuery.of(context).size.width * 0.1,
//                                               child: const CircularProgressIndicator(strokeWidth: 2),
//                                             ),
//                                           );
//                                         },
//                                       ),
//                                       if(postDoc.data()['images'].length > 1) const Align(alignment: Alignment.bottomRight, child: Icon(Icons.view_module),)
//                                     ]
//                                   ),
//                                 );
//                               }
//                               return Container(
//                                 color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.white12,
//                                 child: Center(
//                                   child: Container(
//                                     width: MediaQuery.of(context).size.width * 0.15,
//                                     height: MediaQuery.of(context).size.width * 0.15,
//                                     child: CircularProgressIndicator(strokeWidth: 2),
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                         );
//                       }),
//                     ),
//                   ],
//                 ),
//                 (!user.isFollowing)
//                 ? (
//                   user.private
//                   ? (
//                     isLoading
//                     ? Container(
//                       child: CircularProgressIndicator(),
//                     )
//                     : Container(
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(Icons.person_add),
//                           Container(width: 10,),
//                           Text('Follow this account to view posts'),
//                         ],
//                       ),
//                     )
//                   )
//                   : Container()
//                 )
//                 : Container()
//                 // Expanded(
//                 //   child: Container(
//                 //     decoration: BoxDecoration(
//                 //       color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.white10,
//                 //       borderRadius: BorderRadius.vertical(top: Radius.circular(30))
//                 //     ),
//                 //   ),
//                 // )
//               ],
//             ),
//           )
//         ),
//       ),
//     );
//   }
// }

// class MyProfilePage extends StatefulWidget {

//   MyProfilePage({
//     Key key,
//   }) : super(key: key);

//   @override
//   _MyProfilePageState createState() => _MyProfilePageState();
// }

// class _MyProfilePageState extends State<MyProfilePage> {

//   ExpandableController _expandableController = ExpandableController();

//   @override
//   void initState() {
//     if (myPosts == null) _init();
//     super.initState();
//   }

//   _init() async {
//     await getMyPosts();
//     setState(() {});
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   IconButton(
//                     icon: Icon(Icons.arrow_back),
//                     onPressed: () => Navigator.of(context).pop(),
//                   ),
//                   Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       // IconButton(
//                       //   icon: Icon(Icons.favorite_border),
//                       //   tooltip: 'Activity',
//                       //   onPressed: () => Navigator.of(context).push(RivalNavigator(page: ActivityPage(),)),
//                       // ),
//                       IconButton(
//                         icon: Icon(Icons.settings),
//                         onPressed: () => Navigator.of(context).push(RivalNavigator(page: SettingsPage(),)),
//                       ),
//                     ],
//                   )
//                 ],
//               ),
//               Row(
//                 children: [
//                   Padding(
//                     padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
//                     child: ProfilePhoto(height: MediaQuery.of(context).size.width * 0.2, width: MediaQuery.of(context).size.width * 0.2,),
//                   ),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Text(me.displayName, style: TextStyle(fontFamily: RivalFonts.feature, fontSize: Theme.of(context).textTheme.headline6.fontSize),),
//                           if (me.isVerified) ... [
//                             Container(width: 10,),
//                             VerifiedBadge(width: 20, height: 20)
//                           ]
//                         ],
//                       ),
//                       Text('@${me.username}', style: Theme.of(context).textTheme.subtitle1.copyWith(
//                         color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black87 : Colors.grey[200]
//                       )),
//                       if (me.isBusinessAccount && me.businessCategory != null) Text('${me.businessCategory}', style: Theme.of(context).textTheme.subtitle2.copyWith(
//                         color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black54 : Colors.grey[500]
//                       )),
//                     ],
//                   )
//                 ],
//               ),
//               if (me.doc.data()['bio'] != null && me.doc.data()['bio'].toString().length > 40) Padding(
//                 padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
//                 child: ExpandablePanel(
//                   controller: _expandableController,
//                   collapsed: Wrap(
//                     children: [
//                       TextParser(
//                         text: "${me.doc.data()['bio'].toString().substring(0, 40).replaceAll('\n', '')}...",
//                         ifUsername: (word) {
//                           showSearch(
//                             context: context,
//                             delegate: RivalSearchDelegate(),
//                             query: word
//                           );
//                         },
//                         ifTag: (word) {
//                           showSearch(
//                             context: context,
//                             delegate: RivalSearchDelegate(),
//                             query: word
//                           );
//                         },
//                         ifEmail: (word) async {
//                           if (await canLaunch('mailto:$word')) {
//                             await launch('mailto:$word');
//                           } else {
//                             print('Could not launch email mailto:$word');
//                           }
//                         },
//                         ifUrl: (word) async {
//                           if (await canLaunch('$word')) {
//                             await launch('$word');
//                           } else {
//                             print('Could not launch $word');
//                           }
//                         },
//                         textStyle: TextStyle(color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black87 : Colors.white70),
//                         matchedWordStyle: TextStyle(color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black87 : Colors.white70, fontWeight: FontWeight.bold)
//                       ),
//                       GestureDetector(
//                         onTap: () => _expandableController.toggle(),
//                         child: Text('read more', style: TextStyle(color: Colors.indigoAccent),),
//                       )
//                     ],
//                   ),
//                   expanded: TextParser(
//                     text: me.doc.data()['bio'],
//                     ifUsername: (word) {
//                       showSearch(
//                         context: context,
//                         delegate: RivalSearchDelegate(),
//                         query: word
//                       );
//                     },
//                     ifTag: (word) {
//                       showSearch(
//                         context: context,
//                         delegate: RivalSearchDelegate(),
//                         query: word
//                       );
//                     },
//                     ifEmail: (word) async {
//                       if (await canLaunch('mailto:$word')) {
//                         await launch('mailto:$word');
//                       } else {
//                         print('Could not launch email mailto:$word');
//                       }
//                     },
//                     ifUrl: (word) async {
//                       if (await canLaunch('$word')) {
//                         await launch('$word');
//                       } else {
//                         print('Could not launch $word');
//                       }
//                     },
//                     textStyle: TextStyle(color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black87 : Colors.white70),
//                     matchedWordStyle: TextStyle(color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black87 : Colors.white70, fontWeight: FontWeight.bold)
//                   ),
//                 ),
//               ),
//               if (me.doc.data()['bio'] != null && me.doc.data()['bio'].toString().length < 40) Padding(
//                 padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
//                 child: Row(
//                   children: [
//                     Text("${me.doc.data()['bio'].toString().replaceAll('\n', '')}"),
//                   ],
//                 ),
//               ),
//               Container(
//                 margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//                 decoration: BoxDecoration(
//                   color: Colors.indigoAccent[100],
//                   borderRadius: BorderRadius.all(Radius.circular(10))
//                 ),
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: Colors.transparent,
//                     borderRadius: BorderRadius.all(Radius.circular(10))
//                   ),
//                   child: Row(
//                     children: <Widget>[
//                       Spacer(
//                         flex: 1,
//                       ),
//                       Padding(
//                         padding: EdgeInsets.symmetric(vertical: 20),
//                         child: GestureDetector(
//                           onTap: () async {
//                             if (await Vibration.hasVibrator()) Vibration.vibrate(duration: 5);
//                             Navigator.of(context).push(RivalNavigator(page: Followers(user: me.doc,),));
//                           },
//                           child: Column(
//                             children: <Widget>[
//                               Text(NumberFormat.compact().format(me.followers.length), style: TextStyle(fontFamily: RivalFonts.feature, color: Colors.white, fontSize: 20),),
//                               Text('followers', style: TextStyle(color: Colors.white38, fontSize: 15),),
//                             ],
//                           ),
//                         ),
//                       ),
//                       Spacer(
//                         flex: 1,
//                       ),
//                       Padding(
//                         padding: EdgeInsets.symmetric(vertical: 20),
//                         child: GestureDetector(
//                           onTap: () async {
//                             if (await Vibration.hasVibrator()) Vibration.vibrate(duration: 5);
//                             Navigator.of(context).push(RivalNavigator(page: Following(user: me.doc,),));
//                           },
//                           child: Column(
//                             children: <Widget>[
//                               Text(NumberFormat.compact().format(me.following.length), style: TextStyle(fontFamily: RivalFonts.feature, color: Colors.white, fontSize: 20),),
//                               Text('following', style: TextStyle(color: Colors.white38, fontSize: 15),),
//                             ],
//                           ),
//                         ),
//                       ),
//                       Spacer(
//                         flex: 1,
//                       ),
//                       Padding(
//                         padding: EdgeInsets.symmetric(vertical: 20),
//                         child: GestureDetector(
//                           onTap: () async {
//                             if (await Vibration.hasVibrator()) Vibration.vibrate(duration: 5);
//                             Navigator.of(context).push(RivalNavigator(page: PostsByUser(user: RivalUser(doc: me.doc), isCurrentUser: false, posts: myPosts,),));
//                           },
//                           child: Column(
//                             children: <Widget>[
//                               Text(me.doc.data()['posts'].length.toString(), style: TextStyle(fontFamily: RivalFonts.feature, color: Colors.white, fontSize: 20),),
//                               Text('posts', style: TextStyle(color: Colors.white38, fontSize: 15),),
//                             ],
//                           ),
//                         ),
//                       ),
//                       Spacer(
//                         flex: 1,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               Container(height: 10,),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   Container(
//                     width: MediaQuery.of(context).size.width * 0.5 - 30,
//                     child: OutlineButton(
//                       onPressed: () => Navigator.of(context).push(RivalNavigator(page: Account(),)),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.all(Radius.circular(10))
//                       ),
//                       child: Text('Account'),
//                       color: Colors.indigoAccent,
//                     ),
//                   ),
//                   Container(
//                     width: MediaQuery.of(context).size.width * 0.5 - 30,
//                     child: OutlineButton(
//                       onPressed: () => Navigator.of(context).push(RivalNavigator(page: SettingsPage(),)),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.all(Radius.circular(10))
//                       ),
//                       child: Text('Settings'),
//                       color: Colors.indigoAccent,
//                     ),
//                   ),
//                 ],
//               ),
//               Container(height: 10,),
//               Divider(),
//               Column(
//                 children: [
//                   GridView.builder(
//                     gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
//                     itemBuilder: (context, index) {
//                       if (myPosts == null) {
//                         return Container(
//                           margin: EdgeInsets.all(1),
//                           color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[100] : Colors.grey[900],
//                           child: Shimmer.fromColors(
//                             child: Container(color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.grey[900],),
//                             baseColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.grey[900],
//                             highlightColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.grey[900]
//                           ),
//                         );
//                       } else {
//                         return Container(
//                           width: (MediaQuery.of(context).size.width * 0.3) - 2,
//                           margin: EdgeInsets.all(1),
//                           child: InkWell(
//                             onTap: () => Navigator.of(context).push(RivalNavigator(page: PostsByUser(index: index, isCurrentUser: true,))),
//                             child: Stack(
//                               children: [
//                                 OctoImage(
//                                   width: double.infinity,
//                                   height: double.infinity,
//                                   image: NetworkImage(myPosts[index].images[0]),
//                                   fit: BoxFit.cover,
//                                   progressIndicatorBuilder: (context, progress) {
//                                     return Center(
//                                       child: Container(
//                                         width: MediaQuery.of(context).size.width * 0.1,
//                                         height: MediaQuery.of(context).size.width * 0.1,
//                                         child: CircularProgressIndicator(strokeWidth: 2),
//                                       ),
//                                     );
//                                   },
//                                 ),
//                                 if(myPosts[index].images.length > 1) Align(alignment: Alignment.bottomRight, child: Icon(Icons.photo_library),)
//                               ]
//                             ),
//                           ),
//                         );
//                       }
//                     },
//                     itemCount: myPosts != null ? myPosts.length : me.posts.length,
//                     shrinkWrap: true,
//                     physics: ScrollPhysics(),
//                     padding: EdgeInsets.all(5),
//                   ),
//                 ],
//               )
//               // Expanded(
//               //   child: Container(
//               //     decoration: BoxDecoration(
//               //       color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.white10,
//               //       borderRadius: BorderRadius.vertical(top: Radius.circular(30))
//               //     ),
//               //   ),
//               // )
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }






// -------------------------------------------------------------------------------------------------------------------

class ProfilePage extends StatefulWidget {
  
  final RivalUser user;
  final bool isCurrentUser;
  final String username;
  final String uid;

  const ProfilePage({Key key, this.user, this.isCurrentUser = false, this.username, this.uid}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final ExpandableController descriptionCtrl = ExpandableController();

  bool isCurrentUser = true;

  var user;

  //Widget postsView;

  bool isLoading = true;

  bool isUserButton1Loading = false;

  Future<List<Post>> postsFuture;
  bool arePostsLoading = true;

  Future<void> _getUser() async {
    if (widget.isCurrentUser) {
      user = me;
      isCurrentUser = true;
      //postsView = MyPostsView();
    } else if (widget.user != null) {
      user = widget.user;
      isCurrentUser = false;
      //postsView = UserPostsView(user: user);
    } else if (widget.username != null) {
      String username = widget.username.replaceAll(new RegExp(RivalRegex.specialChars), '').toLowerCase().trim();
      if (username == me.username) {
        user = me;
        isCurrentUser = true;
        //postsView = MyPostsView();
      } else {
        user = await RivalProvider.getUserByUsername(username);
        isCurrentUser = false;
        //postsView = UserPostsView(user: user);
      }
    } else if (widget.uid != null) {
      if (widget.uid == me.uid) {
        user = me;
        isCurrentUser = true;
        //postsView = MyPostsView();
      } else {
        user = await getUser(widget.uid);
        isCurrentUser = false;
        //postsView = UserPostsView(user: user);
      }
    }
    if (!isCurrentUser && user != null) {
      await user.reference.update({
        'visits': FieldValue.arrayUnion([new DateTime.now().millisecondsSinceEpoch])
      });
    }
    if (user != null) {
      postsFuture = _getUserPosts();
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    _getUser();
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    if (user != null && user.uid != me.uid && user.isBlocked) {
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text('Profile'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('@${user.username}', style: Theme.of(context).textTheme.headline3.copyWith(fontFamily: RivalFonts.feature),),
                Container(height: 10,),
                Text('You have blocked ${user.displayName}. Unblock @${user.username} to view profile. ${user.username} will be able to see your posts and stories if you unblock them.', style: Theme.of(context).textTheme.bodyText1),
                Container(height: 10,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FlatButton(
                      child: Text('Go Back', style: TextStyle(color: Colors.indigoAccent)),
                      onPressed: () => Navigator.of(context).pop(),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10))
                      ),
                    ),
                    FlatButton(
                      child: Text('Unblock', style: TextStyle(color: Colors.white)),
                      onPressed: () async {
                        await user.blockUnblock();
                        setState(() {});
                      },
                      color: Colors.indigoAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10))
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ),
      );
    } else if (!isCurrentUser && user != null && user.amIBlocked) {
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text('Profile'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.report, size: Theme.of(context).textTheme.headline2.fontSize,),
                Text('You cannot view @${user.username} profile because you have been blocked.', style: Theme.of(context).textTheme.bodyText1,),
              ],
            ),
          )
        ),
      );
    } else if (user == null && isLoading) {
      return Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop()
                    ),
                  ]
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Center(
                  child: Container(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.white)
                    )
                  ),
                ),
              )
            ],
          ),
        ),
      );
    } else if (user == null && !isLoading) {
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text('Profile'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.report, size: Theme.of(context).textTheme.headline1.fontSize,),
                Text('User Not Found', style: Theme.of(context).textTheme.headline4.copyWith(fontFamily: RivalFonts.feature),),
              ],
            ),
          )
        ),
      );
    }
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ProfilePhoto(height: 70, width: 70, hero: false,),
                  Text('@${me.username}', style: Theme.of(context).textTheme.headline5.copyWith(fontFamily: RivalFonts.feature))
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.bookmark_rounded),
              title: Text('Bookmarks'),
              onTap: () => Navigator.of(context).push(RivalNavigator(page: BookmarkedPosts(),))
            ),
            ListTile(
              leading: Icon(FontAwesome.hashtag),
              title: Text('Tag Subscriptions'),
              onTap: () => Navigator.of(context).push(RivalNavigator(page: TagSubscription(),))
            ),
            ListTile(
              leading: Icon(Icons.view_list),
              title: Text('Topic Subscriptions'),
              onTap: () => Navigator.of(context).push(RivalNavigator(page: SubscribeToTopics(),))
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Account'),
              onTap: () => Navigator.of(context).push(RivalNavigator(page: Account(),),)
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () => Navigator.of(context).push(RivalNavigator(page: SettingsPage(),),)
            ),
          ],
        ),
      ),
      endDrawerEnableOpenDragGesture: false,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: ScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop()
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isCurrentUser) FlatButton(
                        splashColor: Colors.indigoAccent.withOpacity(0.6),
                        onPressed: (user.amIBlocked && !isUserButton1Loading)
                          ? null // Do Nothing if I am blocked
                          : () async { // Else Follow / Unfollow / Request
                            setState(() {
                              isUserButton1Loading = true;
                            });
                            await user.followUnfollowRequest();
                            setState(() {
                              isUserButton1Loading = false;
                            });
                          },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 5, horizontal: 7),
                          child: isUserButton1Loading ? Container(width: Theme.of(context).textTheme.button.fontSize, height: Theme.of(context).textTheme.button.fontSize, child: CircularProgressIndicator(strokeWidth: 2,)) : Text(user.followUnfollow, style: Theme.of(context).textTheme.button,),
                        ),
                      ),
                      if (isCurrentUser) IconButton(
                        icon: Icon(Icons.menu),
                        onPressed: () {
                          _scaffoldKey.currentState.openEndDrawer();
                        }
                      ) else PopupMenuButton(
                        itemBuilder: (context) => <PopupMenuEntry<dynamic>>[
                          PopupMenuItem(
                            child: Text('Copy Profile URL'),
                            value: 'copyUrl',
                          ),
                          PopupMenuItem(
                            child: Text('Report Account'),
                            value: 'report',
                          ),
                          PopupMenuItem(
                            child: Text('Block'),
                            value: 'block',
                          ),
                        ],
                        onSelected: (value) async {
                          switch (value) {
                            case 'copyUrl':
                              String url = await createDynamicURL(link: 'https://rival.photography/profile/@${user.username}', title: '${user.displayName}', description: 'View @${user.username} profile on Rival');
                              await Clipboard.setData(ClipboardData(text: url));
                              RivalProvider.showToast(text: 'Copied to Clipboard');
                              break;
                            case 'report':
                              showDialog(
                                context: context,
                                child: AlertDialog(
                                  title: Text('Report'),
                                  content: Text('Do you want to report @${user.username}? We won\'t tell them if you report. If we find something unusual, we\'ll block them. For detailed report mail us at help@rival.photography. @${user.username} will also be blocked after reporting'),
                                  actions: [
                                    FlatButton(
                                      onPressed: () async {
                                        await user.report();
                                        setState(() {});
                                        Navigator.of(context).pop();
                                        _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text('Reported @${user.username}. For futher enquiry mail us at help@rival.photography')));
                                      },
                                      child: Text('Report', style: TextStyle(color: Colors.red)),
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
                              Loader.show(
                                context,
                                function: () async {
                                  await user.blockUnblock();
                                  await user.reload();
                                  await me.reload();
                                },
                                onComplete: () {
                                  Navigator.of(context).pop();
                                }
                              );
                              break;
                            default:
                          }
                        },
                      ),
                    ],
                  ),
                ]
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Row(
                  children: [
                    if (isCurrentUser) ProfilePhoto(width: 80, height: 80,)
                    else ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(50)),
                      child: OctoImage(
                        image: user.photo,
                        width: 80,
                        height: 80,
                        placeholderBuilder: (context) => CircularProgressIndicator(),
                      ),
                    ),
                    Container(width: 15,),
                    Flexible(
                      flex: 1,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            flex: 1,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  flex: 1,
                                  fit: FlexFit.loose,
                                  child: Text(
                                    user.displayName,
                                    style: Theme.of(context).textTheme.headline6,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                  ),
                                ),
                                if (user.isVerified) Padding(
                                  padding: EdgeInsets.only(left: 5),
                                  child: VerifiedBadge(height: 20, width: 20,),
                                )
                              ],
                            ),
                          ),
                          Text('@${user.username ?? 'rivaluser'}', style: Theme.of(context).textTheme.subtitle1),
                          if (user.isBusinessAccount) Container(
                            child: Text('Business'),
                            margin: EdgeInsets.symmetric(vertical: 3),
                            padding: EdgeInsets.symmetric(vertical: 3, horizontal: 5),
                            decoration: BoxDecoration(
                              color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[300] : Colors.grey[900],
                              borderRadius: BorderRadius.all(Radius.circular(5))
                            ),
                          )
                          else if (user.isCreatorAccount) Container(
                            child: Text('Creator'),
                            margin: EdgeInsets.symmetric(vertical: 3),
                            padding: EdgeInsets.symmetric(vertical: 3, horizontal: 5),
                            decoration: BoxDecoration(
                              color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[300] : Colors.grey[900],
                              borderRadius: BorderRadius.all(Radius.circular(5))
                            ),
                          )
                          else if (user.category != null) Container(
                            child: Text(user.category),
                            margin: EdgeInsets.symmetric(vertical: 3),
                            padding: EdgeInsets.symmetric(vertical: 3, horizontal: 5),
                            decoration: BoxDecoration(
                              color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[300] : Colors.grey[900],
                              borderRadius: BorderRadius.all(Radius.circular(5))
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (user.bio != null) Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (user.bio.length <= 40) TextParser(
                      text: user.bio.toString().trim(),
                      textStyle: Theme.of(context).textTheme.bodyText2,
                      matchedWordStyle: Theme.of(context).textTheme.bodyText2.copyWith(fontWeight: FontWeight.bold)
                    )
                    else if (user.bio.length > 40) ExpandablePanel(
                      controller: descriptionCtrl,
                      collapsed: GestureDetector(
                        onTap: () => descriptionCtrl.toggle(),
                        child: RichText(
                          text: TextSpan(
                            children: <TextSpan>[
                              TextSpan(text: '${user.bio.toString().substring(0, 40).replaceAll('\n', ' ').trim()}... ', style: Theme.of(context).textTheme.bodyText2,),
                              TextSpan(text: 'read more', style: Theme.of(context).textTheme.bodyText2.copyWith(color: Colors.indigoAccent))
                            ]
                          ),
                        ),
                      ),
                      expanded: TextParser(
                        text: user.bio.toString().trim(),
                        textStyle: Theme.of(context).textTheme.bodyText2,
                        matchedWordStyle: Theme.of(context).textTheme.bodyText2.copyWith(fontWeight: FontWeight.bold)
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                margin: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                decoration: BoxDecoration(
                  color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.indigoAccent.withOpacity(0.95) : Colors.indigoAccent,
                  borderRadius: BorderRadius.all(Radius.circular(20))
                ),
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (isCurrentUser) {
                          RivalProvider.vibrate();
                          Navigator.of(context).push(RivalNavigator(page: PostsByUser(isCurrentUser: true)));
                        } else if (!user.private) {
                          RivalProvider.vibrate();
                          Navigator.of(context).push(RivalNavigator(page: PostsByUser(isCurrentUser: false, user: user,)));
                        }
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width / 6,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Column(
                            children: [
                              Text(NumberFormat.compact().format(user.posts.length), style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.white,),),
                              Text('Posts', style: Theme.of(context).textTheme.bodyText1.copyWith(color: Colors.white),)
                            ],
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (isCurrentUser || !user.private || (user.private && user.isFollowing)) {
                          RivalProvider.vibrate();
                          Navigator.of(context).push(RivalNavigator(page: Followers(user: user,)));
                        }
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width / 6,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Column(
                            children: [
                              Text(NumberFormat.compact().format(user.followers.length), style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.white),),
                              Text('Followers', style: Theme.of(context).textTheme.bodyText1.copyWith(color: Colors.white),)
                            ],
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (isCurrentUser || !user.private || (user.private && user.isFollowing)) {
                          RivalProvider.vibrate();
                          Navigator.of(context).push(RivalNavigator(page: Following(user: user)));
                        }
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width / 6,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Column(
                            children: [
                              Text(NumberFormat.compact().format(user.following.length), style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.white),),
                              Text('Following', style: Theme.of(context).textTheme.bodyText1.copyWith(color: Colors.white),)
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isCurrentUser && user.isBusinessAccount && (user.showContactCall || user.showContactEmail)) Padding(
                padding: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
                child: Row(
                  children: <Widget>[
                    if (user.showContactCall) Expanded(
                      flex: 1,
                      child: OutlineButton(
                        onPressed: () async {
                          if (await canLaunch('tel:${user.phoneNumber}')) {
                            launch('tel:${user.phoneNumber}');
                          }
                        },
                        child: Text('Call'),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10))
                        ),
                      ),
                    ),
                    if (user.showContactCall && user.showContactEmail) Container(width: 10,),
                    if (user.showContactEmail) Expanded(
                      flex: 1,
                      child: OutlineButton(
                        onPressed: () async {
                          if (await canLaunch('mailto:${user.email}')) {
                            launch('mailto:${user.email}');
                          }
                        },
                        child: Text('Email'),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10))
                        ),
                      ),
                    ),
                    // Container(
                    //   width: (MediaQuery.of(context).size.width / 2) - 22.5,
                    //   child: OutlineButton(
                    //     child: isCurrentUser ? Text('Account') : (isUserButton1Loading ? Container(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2,)) : Text(user.followUnfollow)),
                    //     onPressed: isCurrentUser
                    //     ? () => Navigator.of(context).push(RivalNavigator(page: Account(),)) // IF Current User
                    //     : (
                    //       user.amIBlocked
                    //       ? null // Do Nothing if I am blocked
                    //       : () async { // Else Follow / Unfollow / Request
                    //         setState(() {
                    //           isUserButton1Loading = true;
                    //         });
                    //         await user.followUnfollowRequest();
                    //         setState(() {
                    //           isUserButton1Loading = false;
                    //         });
                    //       }
                    //     ),
                    //     shape: RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.all(Radius.circular(10))
                    //     ),
                    //   ),
                    // ),
                    // Container(
                    //   width: (MediaQuery.of(context).size.width / 2) - 22.5,
                    //   child: OutlineButton(
                    //     child: Text(isCurrentUser ? 'Settings' : 'Message'),
                    //     onPressed: isCurrentUser ? () => Navigator.of(context).push(RivalNavigator(page: SettingsPage(),)) : null,
                    //     shape: RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.all(Radius.circular(10))
                    //     ),
                    //   ),
                    // )
                  ],
                ),
              ),
              if (!isCurrentUser && user.private && !user.isFollowing) Padding( // Private Account
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock),
                    Container(width: 10,),
                    Text('Account is Private. Follow to See Posts')
                  ],
                ),
              ) else FutureBuilder<List<Post>>(
                future: postsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return ListView.builder(
                      itemBuilder: (context, index) => ViewPost(post: snapshot.data[index]),
                      itemCount:  snapshot.data?.length ?? 0,
                      cacheExtent: 999,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                    );
                  } else {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: Container(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black : Colors.white),
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
              if (!arePostsLoading && user.posts.length >= 3) ... [
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FlatButton(
                      onPressed: () {
                        if (isCurrentUser) {
                          RivalProvider.vibrate();
                          Navigator.of(context).push(RivalNavigator(page: PostsByUser(isCurrentUser: true)));
                        } else {
                          RivalProvider.vibrate();
                          Navigator.of(context).push(RivalNavigator(page: PostsByUser(isCurrentUser: false, user: user,)));
                        }
                      },
                      child: Text('View all posts'),
                      splashColor: Colors.indigoAccent.withOpacity(0.3)
                    )
                  ],
                )
              ]
              // if (isCurrentUser || !user.private || (user.private && user.isFollowing) && !user.amIBlocked) postsView // Show Posts if (Current User) or (User is not private) or (User is private and I am following) or (User has not blocked me)
              // else if (user.private && !user.isFollowing && !user.amIBlocked) Padding(
              //   padding: const EdgeInsets.symmetric(vertical: 20),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.center,
              //     children: [
              //       Icon(Icons.lock),
              //       Container(width: 10,),
              //       Text('Account is Private. Follow to See Posts')
              //     ],
              //   ),
              // ) else Padding(
              //   padding: const EdgeInsets.symmetric(vertical: 20),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.center,
              //     children: [
              //       Icon(Icons.error, color: Colors.red),
              //       Container(width: 10,),
              //       Text('Oops! Failed to load Posts')
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Post>> _getUserPosts() async {
    List refs = user.posts.reversed.toList();
    List<Post> posts = [];

    if (user.uid == me.uid) {
      if (refs.length < 3 && myPosts.length == refs.length) {
        setState(() {
          arePostsLoading = false;
        });
        return myPosts;
      } else if (refs.length >= 3 && myPosts.length >= 3) {
        setState(() {
          arePostsLoading = false;
        });
        return myPosts.getRange(0, 3).toList();
      }
    }

    if (refs.length < 3) {
      for (DocumentReference ref in refs) {
        posts.add(await Post.fetch(ref: ref, user: user));
      }
      if (user.uid == me.uid) myPosts = posts;
    } else {
      if (user.uid == me.uid) {
        myPosts = []; // My Posts is already empty or null
        for (DocumentReference ref in refs.getRange(0, refs.length >= 10 ? 10 : refs.length).toList()) {
          Post post = await Post.fetch(ref: ref);
          if (refs.getRange(0, refs.length >= 10 ? 10 : refs.length).toList().indexOf(ref) < 3) posts.add(post);
          myPosts.add(post);
        }
      } else for (DocumentReference ref in refs.getRange(0, 3).toList()) {
        posts.add(await Post.fetch(ref: ref, user: user));
      }
    }

    setState(() {
      arePostsLoading = false;
    });

    return posts;
  }

}

// class MyPostsView extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<List<Post>>(
//       future: getMyPosts(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.done) {
//           List<Post> posts = snapshot.data;
//           return PostsGridView(
//             itemCount: posts.length,
//             itemBuilder: (context, index) => PostGridTile(
//               child: InkWell(
//                 child: OctoImage(
//                   image: CachedNetworkImageProvider(posts[index].images[0]),
//                   placeholderBuilder: (context) => CircularProgressIndicator(),
//                   fit: BoxFit.cover,
//                 ),
//                 onTap: () => Navigator.of(context).push(RivalNavigator(page: SinglePostView(post: posts[index]),))
//               )
//             ),
//           );
//         } else {
//           return Center(
//             child: Padding(
//               padding: const EdgeInsets.all(100.0),
//               child: Container(
//                 width: 50,
//                 height: 50,
//                 child: CircularProgressIndicator(
//                   strokeWidth: 2,
//                 ),
//               ),
//             ),
//           );
//         }
//       },
//     );
//   }
// }

// class UserPostsView extends StatelessWidget {
  
//   const UserPostsView({
//     Key key,
//     @required this.user,
//   }) : super(key: key);

//   final user;

//   @override
//   Widget build(BuildContext context) {
//     List posts = user.posts;
//     posts = posts.reversed.toList();
//     return PostsGridView(
//       itemCount: posts.length,
//       itemBuilder: (context, index) => PostGridTile(
//         child: FutureBuilder<Post>(
//           future: Post.fetch(ref: posts[index]),
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.done) {
//               return InkWell(
//                 child: OctoImage(
//                   image: NetworkImage(snapshot.data.images[0]),
//                   placeholderBuilder: (context) => CircularProgressIndicator(),
//                   fit: BoxFit.cover,
//                 ),
//                 onTap: () => Navigator.of(context).push(RivalNavigator(page: SinglePostView(post: snapshot.data),))
//               );
//             }
//             return Container();
//           },
//         ),
//       ),
//     );
//   }
// }

class PostsGridView extends StatelessWidget {

  final Function(BuildContext context, int index) itemBuilder;
  final int itemCount;

  const PostsGridView({Key key, @required this.itemBuilder, @required this.itemCount}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 1, mainAxisSpacing: 1),
      physics: BouncingScrollPhysics(),
      shrinkWrap: true,
    );
  }
}

class PostGridTile extends StatelessWidget {

  final Widget child;

  const PostGridTile({Key key, @required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width / 3) - 2,
      height: (MediaQuery.of(context).size.width / 3) - 2,
      color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[100] : Colors.white10,
      child: child,
    );
  }
}

class PostGridView extends StatefulWidget {

  final Post post;
  const PostGridView({Key key, @required this.post}) : super(key: key);

  @override
  _PostGridViewState createState() => _PostGridViewState();
}

class _PostGridViewState extends State<PostGridView> {

  Post post;

  @override
  void initState() {
    post = widget.post;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(RivalNavigator(page: SinglePostView(post: post,),)),
      child: Container(
        margin: EdgeInsets.all(1.5),
        color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[100] : Colors.white10,
        child: FutureBuilder<RivalUser>(
          future: getUser(post.userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              RivalUser user = snapshot.data;
              if (user.private && !user.isFollowing && user.uid != me.uid) {
                return Center(
                  child: Tooltip(
                    message: '@${user.username} has a private account',
                    child: Icon(Icons.warning, color: Colors.yellow,)
                  ),
                );
              } else if (!post.available || post.takenDown) {
                return Center(
                  child: Tooltip(
                    message: 'Post Unavailable',
                    child: Icon(Icons.error, color: Colors.red[400],)
                  ),
                );
              } else {
                return Stack(
                  children: [
                    OctoImage(
                      image: CachedNetworkImageProvider(post.images[0]),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    if (post.isPromoted) Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        decoration: BoxDecoration(
                          color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.yellow[300] : Colors.yellow[700],
                          borderRadius: BorderRadius.all(Radius.circular(4))
                        ),
                        padding: EdgeInsets.symmetric(vertical: 1, horizontal: 4),
                        child: Text(
                          'Ad',
                          style: Theme.of(context).textTheme.caption,
                        ),
                      ),
                    ),
                    if (post.isProduct) Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 3, horizontal: 3),
                        decoration: BoxDecoration(
                          color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.white70 : Colors.white70,
                          borderRadius: BorderRadius.all(Radius.circular(5))
                        ),
                        padding: EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                        child: Icon(Icons.shopping_bag, color: Colors.black,),
                      ),
                    )
                  ],
                );
              }
            }
            return Container();
          },
        )
      ),
    );
  }
}