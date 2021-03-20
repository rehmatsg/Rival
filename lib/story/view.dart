import 'package:flutter/material.dart';
import 'package:rival/story/views.dart';
import 'package:supercharged/supercharged.dart';
import '../app.dart';
import 'story_view/story_view.dart';
import 'story_view/widgets/story_view.dart';

class ViewStory extends StatefulWidget {
  
  final int initialIndex;
  final bool launchedFromHomeScreen;
  final List<RivalRootUser> users;

  const ViewStory({Key key, this.initialIndex = 0, this.launchedFromHomeScreen = true, this.users}) : super(key: key);

  @override
  _ViewStoryState createState() => _ViewStoryState();
}

class _ViewStoryState extends State<ViewStory> {

  StoryController storyController = StoryController();
  List<RivalRootUser> usersWithStory;

  int currentIndex;
  int currentStoryIndex = 0;

  PageController storyPageCtrl;

  Map<RivalRootUser, List<StoryItem>> stories = {};

  @override
  void initState() {
    storyPageCtrl = PageController(initialPage: widget.initialIndex);
    currentIndex = widget.initialIndex;
    _init();
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: storyPageCtrl,
        itemCount: stories.length,
        itemBuilder: (context, index) {
          return StoryView(
            controller: storyController,
            avatar: stories.keys.toList()[index].photo,
            username: stories.keys.toList()[index].username,
            subtitle: stories.values.toList()[index].elementAtOrElse(currentStoryIndex, () => stories.values.toList()[index][0]).story.since, // Using SUPERCHARGED to avoid errors
            firstIcon: stories.keys.toList()[index].uid == me.uid
            ? TextButton.icon(
              icon: Icon(Icons.remove_red_eye, color: Colors.white),
              label: Text('${stories.values.toList()[index].elementAtOrElse(currentStoryIndex, () => stories.values.toList()[index][0]).story.views.length} Views', style: TextStyle(color: Colors.white),),
              onPressed: () => Navigator.of(context).push(RivalNavigator(page: StoryViews(story: stories.values.toList()[index].elementAtOrElse(currentStoryIndex, () => stories.values.toList()[index][0]).story),))
            )
            : null,
            secondIcon: stories.keys.toList()[index].uid == me.uid
            ? IconButton(
              icon: Icon(Icons.edit, color: Colors.white),
              onPressed: () => Navigator.of(context).push(RivalNavigator(page: EditStory(story: stories.values.toList()[index].elementAtOrElse(currentStoryIndex, () => stories.values.toList()[index][0]).story),))
            )
            : null,
            thirdIcon: IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop()
            ),
            storyItems: stories.values.toList()[index],
            onVerticalSwipeComplete: (Direction direction) {
              print("Vertical Swipe $direction");
              if (direction == Direction.down) {
                Navigator.of(context).pop();
              } else if (direction == Direction.up) {}
            },
            onComplete: () {
              if (stories.length > (currentIndex + 1)) { // Scroll to Next Story if available
                currentIndex += 1;
                storyPageCtrl.animateToPage(currentIndex, duration: Duration(milliseconds: 500), curve: Curves.easeInOut);
              } else { // Else go back
                Navigator.of(context).pop();
              }
            },
            onStoryShow: (storyItem) async {
              try {
                if (mounted && stories.values.toList()[currentIndex].indexOf(storyItem) != currentStoryIndex) setState(() {
                  currentStoryIndex = stories.values.toList()[currentIndex].indexOf(storyItem) < 0 ? 0 : stories.values.toList()[currentIndex].indexOf(storyItem);
                });
                print("Current Story Index $currentStoryIndex in try block");
              } catch (e) {
                print(e);
                currentStoryIndex = 0;
                print("Current Story Index $currentStoryIndex in catch block");
              }
              RivalRootUser user = stories.keys.toList()[currentIndex];
              Story story = storyItem.story;
              if (user.stories.containsKey(story.timestamp.toString()) && !story.views.containsKey(me.uid)) await user.update({
                'story.${story.timestamp}.views.${me.uid}': new DateTime.now().millisecondsSinceEpoch
              });
            },
          );
        },
        onPageChanged: (value) {
          setState(() {
            currentIndex = value;
            currentStoryIndex = 0;
          });
          print("Current Story Index $currentStoryIndex in page changed func");
        },
        physics: BouncingScrollPhysics(),
      ),
      backgroundColor: Colors.black,
    );
  }

  void _init() {
    if (widget.launchedFromHomeScreen == true && (widget.users == null || widget.users.isEmpty)) {
      usersWithStory = allStories; // Initialize with Home Screen Stories
    } else {
      usersWithStory = widget.users; // Initialize with provided values
    }
    usersWithStory.forEach((user) { // Get all stories from each user
      List userStories = user.stories.values.toList();
      List<StoryItem> userStoryItems = [];
      userStories.sort((a, b) => a['timestamp'].compareTo(b['timestamp'])); // Sort the stories according to upload time [DESCENDING]
      userStories.forEach((stIt) {
        Story storyItem = Story(stIt);
        if (storyItem.type == StoryType.text) {
          userStoryItems.add(
            StoryItem.text(
              story: storyItem,
              backgroundColor: storyItem.color,
              title: storyItem.caption,
              roundedTop: true,
              roundedBottom: true,
              bottomWidget: Column(
                children: [
                  //Text(storyItem.since),
                  if (storyItem.geoPoint != null) Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, color: Colors.white54),
                      Text(storyItem.location, style: TextStyle(color: Colors.white54),)
                    ],
                  )
                ],
              )
            )
          );
        } else if (storyItem.type == StoryType.video) {
          userStoryItems.add(
            StoryItem.pageVideo(
              storyItem.url,
              story: storyItem,
              controller: storyController,
              caption: storyItem.caption,
              bottomWidget: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  //Text('${storyItem.since}', style: TextStyle(color: Colors.white54),),
                  if (storyItem.geoPoint != null) Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, color: Colors.white54),
                      Text(storyItem.location, style: TextStyle(color: Colors.white54),)
                    ],
                  )
                ],
              )
            )
          );
        } else if (storyItem.type == StoryType.image) {
          userStoryItems.add(
            StoryItem.pageImage(
              story: storyItem,
              url: storyItem.url,
              controller: storyController,
              caption: storyItem.caption,
              bottomWidget: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  //Text(storyItem.since, style: TextStyle(color: Colors.white54),)
                  if (storyItem.geoPoint != null) Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, color: Colors.white54),
                      Text(storyItem.location, style: TextStyle(color: Colors.white54),)
                    ],
                  )
                ],
              )
            )
          );
        } else if (storyItem.type == StoryType.post) {
          userStoryItems.add(
            StoryItem.post(
              storyItem.postId,
              controller: storyController,
              story: storyItem,
              showSwipeUp: false
            ),
          );
        }
      });
      // Below code begins story from New Story that I have not seen yet
      List<StoryItem> unseenStories = userStoryItems.where((element) => !element.story.views.containsKey(me.uid)).toList();
      if (unseenStories.isNotEmpty) {
        int indexOfFirstUnseenStory = userStoryItems.indexOf(unseenStories.first);
        for (var i = 0; i < indexOfFirstUnseenStory; i++) {
          userStoryItems[i].shown = true;
        }
        currentStoryIndex = indexOfFirstUnseenStory;
      }
      stories[user] = userStoryItems;
    });
  }
  
}

// class ViewStory extends StatefulWidget {

//   ViewStory({Key key, this.isCurrentUser, this.user, this.isFromHomeScreen}) : super(key: key);
//   final RivalUser user;
//   final bool isCurrentUser;
//   final bool isFromHomeScreen;

//   @override
//   _ViewStoryState createState() => _ViewStoryState();
// }

// class _ViewStoryState extends State<ViewStory> {

//   StoryController storyController = StoryController();
//   List<Story> stories = [];
//   List<StoryItem> storyItem = <StoryItem>[];
//   int currentIndex = 0;
//   bool isChanged = false;
//   bool isFromHomeScreen = false;

//   @override
//   void initState() {
//     if (widget.isFromHomeScreen == true) {
//       isFromHomeScreen = true;
//     }
//     if (widget.isCurrentUser) {
//       me.stories.values.forEach((st) {
//         stories.add(Story(st));
//       });
//     } else {
//       widget.user.stories.values.forEach((st) {
//         stories.add(Story(st));
//       });
//     }
//     _init();
//     super.initState();
//   }

//   @override
//   void setState(fn) {
//     if (mounted) super.setState(fn);
//   }

//   void _init() {
//     stories.sort((a, b) => b.timestamp.compareTo(a.timestamp));
//     stories.forEach((story) {
//       if (story.type == StoryType.text) {
//         storyItem.add(StoryItem.text(
//           title: story.caption,
//           story: story,
//           backgroundColor: story.color,
//           bottomWidget: Column(
//             children: [
//               if (story.geoPoint != null) Text(story.since),
//               if (story.isPromoted && story.promotionUrl != null && !widget.isCurrentUser) ... [
//                 Container(height: 10,),
//                 Icon(Icons.keyboard_arrow_up, color: Colors.white,),
//                 Text('Swipe Up', style: TextStyle(color: Colors.white),)
//               ]
//             ],
//           )
//         ));
//       } else if (story.type == StoryType.video) {
//         storyItem.add(
//           StoryItem.pageVideo(
//             story.url,
//             story: story,
//             controller: storyController,
//             caption: story.caption,
//             bottomWidget: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 if (story.geoPoint != null) Text('${story.since}', style: TextStyle(color: Colors.white54),),
//                 if (story.isPromoted && story.promotionUrl != null && !widget.isCurrentUser) ... [
//                   Container(height: 10,),
//                   Icon(Icons.keyboard_arrow_up, color: Colors.white,),
//                   Text('Swipe Up', style: TextStyle(color: Colors.white),)
//                 ]
//               ],
//             )
//           )
//         );
//       } else if (story.type == StoryType.image) {
//         storyItem.add(
//           StoryItem.pageImage(
//             url: story.url,
//             story: story,
//             controller: storyController,
//             caption: story.caption,
//             bottomWidget: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 if (story.geoPoint != null) Text(story.since, style: TextStyle(color: Colors.white54),),
//                 if (story.isPromoted && story.promotionUrl != null) ... [
//                   Container(height: 10,),
//                   Icon(Icons.keyboard_arrow_up, color: Colors.white,),
//                   Text('Swipe Up', style: TextStyle(color: Colors.white),)
//                 ]
//               ],
//             )
//           )
//         );
//       } else if (story.type == StoryType.post) {
//         storyItem.add(
//           StoryItem.post(
//             story.postId,
//             story: story,
//             showSwipeUp: true
//           ),
//         );
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: StoryView(
//         avatar: (widget.isCurrentUser)
//           ? me.photo
//           : widget.user.photo,
//         username: (widget.isCurrentUser)
//           ? me.displayName
//           : widget.user.displayName,
//         subtitle: '',
//         // subtitle: stories[currentIndex].geoPoint != null
//         //   ? Row(
//         //     mainAxisSize: MainAxisSize.min,
//         //     children: [
//         //       Padding(
//         //         padding: const EdgeInsets.only(right: 3),
//         //         child: Icon(Icons.location_on, size: Theme.of(context).textTheme.subtitle1.fontSize, color: stories[currentIndex].type == StoryType.text ? (stories[currentIndex].color.computeLuminance() > 0.5 ? Colors.black54 : Colors.white54) : Colors.white54,),
//         //       ),
//         //       Text(stories[currentIndex].location, overflow: TextOverflow.fade, style: TextStyle(fontSize: 15, fontFamily: 'Roboto', color: stories[currentIndex].type == StoryType.text ? (stories[currentIndex].color.computeLuminance() > 0.5 ? Colors.black54 : Colors.white54) : Colors.white54),)
//         //     ],
//         //   )
//         //   : (
//         //     stories[currentIndex].paidPartner != null ? FutureBuilder<RivalUser>(
//         //       future: RivalProvider.getUserByRef(stories[currentIndex].paidPartner),
//         //       builder: (context, snapshot) {
//         //         if (snapshot.connectionState == ConnectionState.done) {
//         //           return Text('Paid Partnership with @${snapshot.data.username}', overflow: TextOverflow.fade, style: TextStyle(fontSize: 15, fontFamily: 'Roboto', color: stories[currentIndex].type == StoryType.text ? (stories[currentIndex].color.computeLuminance() > 0.5 ? Colors.black54 : Colors.white54) : Colors.white54),);
//         //         } else {
//         //           return Text('Paid Partnership', style: TextStyle(fontSize: 15, fontFamily: 'Roboto', color: stories[currentIndex].type == StoryType.text ? (stories[currentIndex].color.computeLuminance() > 0.5 ? Colors.black54 : Colors.white54) : Colors.white54),);
//         //         }
//         //       },
//         //     )
//         //     : Text(stories[currentIndex].since, overflow: TextOverflow.fade, style: TextStyle(fontSize: 15, fontFamily: 'Roboto', color: stories[currentIndex].type == StoryType.text ? (stories[currentIndex].color.computeLuminance() > 0.5 ? Colors.black54 : Colors.white54) : Colors.white54),)
//         //   ),
//         trailing: stories[currentIndex].isPromoted
//           ? Text('Promoted', overflow: TextOverflow.fade, style: TextStyle(fontSize: 12, fontFamily: 'Roboto', color: stories[currentIndex].type == StoryType.text ? (stories[currentIndex].color.computeLuminance() > 0.5 ? Colors.black54 : Colors.white54) : Colors.white54),)
//           : (
//             stories[currentIndex].paidPartner != null ? Text(stories[currentIndex].since, overflow: TextOverflow.fade, style: TextStyle(fontSize: 12, fontFamily: 'Roboto', color: stories[currentIndex].type == StoryType.text ? (stories[currentIndex].color.computeLuminance() > 0.5 ? Colors.black54 : Colors.white54) : Colors.white54),)
//             : null
//           ),
//         storyItems: storyItem,
//         onStoryShow: (s) async {
//           if (isChanged) {
//             setState(() {
//               currentIndex = storyItem.indexOf(s);
//             });
//           } else if (!isChanged && storyItem.indexOf(s) > 0) {
//             setState(() {
//               currentIndex = storyItem.indexOf(s);
//               isChanged = true;
//             });
//           }
//           if (!widget.isCurrentUser && !stories[currentIndex].views.containsKey(me.uid)) {
//             await widget.user.reference .update({
//               'story.${stories[currentIndex].timestamp}.views.${me.uid}': new DateTime.now().millisecondsSinceEpoch
//             });
//           }
//         },
//         onComplete: () {
//           _changeStory();
//         },
//         progressPosition: ProgressPosition.bottom,
//         repeat: false,
//         controller: storyController,
//         inline: true,
//         onVerticalSwipeComplete: (Direction direction) async {
//           if (direction == Direction.down) {
//             Navigator.of(context).pop();
//           } else if (direction == Direction.up) {
//             if (widget.isCurrentUser) {
//               Navigator.of(context).pushReplacement(RivalNavigator(page: EditStory(story: stories[currentIndex]), transitionType: SharedAxisTransitionType.vertical));
//             } else if (stories[currentIndex].type == StoryType.post) {
//               Post post = await stories[currentIndex].post;
//               Navigator.of(context).pushReplacement(RivalNavigator(page: SinglePostView(post: post), transitionType: SharedAxisTransitionType.vertical));
//             } else if (stories[currentIndex].isPromoted && stories[currentIndex].promotionUrl != null) {
//               // Story is promoted and contains promotion url
//               await launch(stories[currentIndex].promotionUrl);
//               if (!widget.isCurrentUser && (stories[currentIndex].swipes != null && !stories[currentIndex].swipes.containsKey(me.uid))) { // Record Swipes
//                 await widget.user.reference .update({
//                   'story.${stories[currentIndex].timestamp}.swipes.${me.uid}': new DateTime.now().millisecondsSinceEpoch
//                 });
//               }
//             }
//           } else if (direction == Direction.left) {
//             _changeStory();
//           } else if (direction == Direction.right) {
//             _previousStory();
//           }
//         },
//         onPreviousStory: () {
//           _previousStory();
//         },
//       ),
//     );
//   }

//   _previousStory() {
//     if (isFromHomeScreen && !widget.isCurrentUser && homeScreenStories.indexOf(widget.user) > 0) {
//       Navigator.of(context).pushReplacement(PageTransition(child: ViewStory(isFromHomeScreen: true, user: homeScreenStories[homeScreenStories.indexOf(widget.user) - 1], isCurrentUser: false,), type: PageTransitionType.leftToRightWithFade));
//     } else if (isFromHomeScreen && !widget.isCurrentUser && homeScreenStories.indexOf(widget.user) == 0) {
//       Navigator.of(context).pushReplacement(PageTransition(child: ViewStory(isFromHomeScreen: true, isCurrentUser: true,), type: PageTransitionType.leftToRightWithFade));
//     }
//   }

//   _changeStory() {
//     if (!isFromHomeScreen) {
//       // The story's origin is not from Home Screen
//       Navigator.of(context).pop();
//     } else if (isFromHomeScreen && !widget.isCurrentUser && (homeScreenStories.indexOf(widget.user) + 1) < homeScreenStories.length) {
//       // Story's origin is Home Screen. Now navigate to next story from Home Screen
//       Navigator.of(context).pushReplacement(PageTransition(child: ViewStory(isFromHomeScreen: true, user: homeScreenStories[homeScreenStories.indexOf(widget.user) + 1], isCurrentUser: false,), type: PageTransitionType.rightToLeftWithFade));
//     } else if (isFromHomeScreen && !widget.isCurrentUser && (homeScreenStories.indexOf(widget.user) + 1) == homeScreenStories.length) {
//       // Story is the last one from Home Screen
//       Navigator.of(context).pop();
//     } else if (isFromHomeScreen && widget.isCurrentUser && homeScreenStories.length > 0) {
//       // Story is from Home Screen but of current user.
//       Navigator.of(context).pushReplacement(PageTransition(child: ViewStory(isFromHomeScreen: true, user: homeScreenStories[0], isCurrentUser: false,), type: PageTransitionType.rightToLeftWithFade));
//     } else {
//       // Unknown Condition
//       // Just pop
//       Navigator.of(context).pop();
//     }
//   }

// }

// class ViewStory extends StatefulWidget {
  
//   ViewStory({this.isCurrentUser, this.user, this.isFromHomeScreen});
//   final bool isCurrentUser;
//   final User user;
//   final bool isFromHomeScreen;

//   @override
//   _ViewStoryState createState() => _ViewStoryState();
// }

// class _ViewStoryState extends State<ViewStory> {

//   Color _color = Colors.black;

//   List<Story> stories = [];
//   Story currentStory;
//   int totalStories;

//   VideoPlayerController videoPlayerController;
//   Future<void> initVideoPlayer;

//   CountdownController _countdownController = CountdownController();

//   int duration = 5;

//   Widget storyView;

//   _init() async {
//     totalStories = stories.length;
//     changeStory(0);
//   }

//   Future<void> changeStory(int index) async {
//     initVideoPlayer = null;
//     videoPlayerController = null;
//     Story cS = stories[index];
//     try {
//       setState(() {
//         currentStory = stories[index];
//       });
//     } catch (e) {
//       print('Error while saving state : $e');
//       currentStory = stories[index];
//     }
//     if (cS.type == StoryType.video) {
//       videoPlayerController = VideoPlayerController.network(cS.url);
//       initVideoPlayer = videoPlayerController.initialize();
//       await initVideoPlayer;
//       duration = videoPlayerController.value.duration.inSeconds;
//     } else if (cS.type == StoryType.text) {
//       _color = cS.color;
//       duration = 5;
//     } else {
//       _color = Colors.black;
//       duration = 5;
//     }
//     _countdownController.restart();
//     setState(() {});
//   }

//   @override
//   void initState() {
//     if (widget.isCurrentUser) {
//       me.stories.values.forEach((st) {
//         stories.add(Story(st));
//       });
//     } else {
//       widget.user.stories.values.forEach((st) {
//         stories.add(Story(st));
//       });
//     }
//     _init();
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.only(top: 5, left: 5, right: 5),
//               child: Countdown(
//                 controller: _countdownController,
//                 seconds: duration,
//                 build: (BuildContext context, double time) => StepProgressIndicator(
//                   totalSteps: totalStories,
//                   currentStep: stories.indexOf(currentStory),
//                   selectedColor: _color.computeLuminance() > 0.5 ? Colors.black54 : Colors.white54,
//                   unselectedColor: _color.computeLuminance() > 0.5 ? Colors.black26 : Colors.white24,
//                   roundedEdges: Radius.circular(2),
//                   progressDirection: TextDirection.ltr,
//                   customStep: (int index, Color color, double size) {
//                     print("For index $index: ${(time / duration)}, Time: $time, Duration: $duration");
//                     return LinearProgressIndicator(
//                       value: stories.indexOf(currentStory) == index ? (time / duration) : 0,
//                     );
//                   },
//                 ),
//               ),
//             ),
//             ListTile(
//               leading: widget.isCurrentUser
//               ? Hero(tag: 'story-${me.uid}', child: ClipOval(child: Image(image: me.photo, width: 40, height: 40)))
//               : Hero(tag: 'story-${widget.user.uid}', child: ClipOval(child: Image(image: widget.user.photo, width: 40, height: 40))),
//               title: Text(
//                 widget.isCurrentUser ? me.displayName : widget.user.displayName,
//                 style: TextStyle(color: _color.computeLuminance() > 0.5 ? Colors.black : Colors.white, fontFamily: RivalFonts.feature)
//               ),
//               subtitle: Text(
//                 timeago.format(new DateTime.fromMillisecondsSinceEpoch(currentStory.timestamp)),
//                 style: TextStyle(color: _color.computeLuminance() > 0.5 ? Colors.black : Colors.white)
//               ),
//             ),
//             Expanded(
//               child: Countdown(
//                 seconds: duration,
//                 controller: _countdownController,
//                 onFinished: () {
//                   if ((stories.indexOf(currentStory) + 1) < totalStories) {
//                     print('Changing story');
//                     changeStory(stories.indexOf(currentStory) + 1);
//                   } else {
//                     // Navigator.of(context).pop();
//                     // Or change to next story
//                     print('Completed Story');
//                   }
//                   if (currentStory.type == StoryType.video) {
//                     videoPlayerController.dispose();
//                   }
//                 },
//                 build: (BuildContext context, double time) {
//                   if (currentStory.type == StoryType.text) {
//                     return Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         TextParser(
//                           text: currentStory.caption,
//                           ifUsername: (word) async {

//                           },
//                           ifTag: (word) async {

//                           },
//                           ifEmail: (word) async {

//                           },
//                           ifUrl: (word) async {

//                           },
//                           textStyle: Theme.of(context).textTheme.headline6.copyWith(
//                             color: _color.computeLuminance() > 0.5 ? Colors.black : Colors.white
//                           ),
//                           matchedWordStyle: Theme.of(context).textTheme.headline6.copyWith(
//                             fontWeight: FontWeight.bold,
//                             color: _color.computeLuminance() > 0.5 ? Colors.black : Colors.white
//                           )
//                         )
//                       ],
//                     );
//                   } else if (currentStory.type == StoryType.video) {
//                     return FutureBuilder(
//                       future: initVideoPlayer,
//                       builder: (context, snapshot) {
//                         if (snapshot.connectionState == ConnectionState.done) {
//                           videoPlayerController.play();
//                           return Stack(
//                             children: [
//                               Align(
//                                 alignment: Alignment.center,
//                                 child: AspectRatio(
//                                   aspectRatio: videoPlayerController.value.aspectRatio,
//                                   child: VideoPlayer(videoPlayerController),
//                                 )
//                               ),
//                               Align(
//                                 alignment: Alignment.bottomCenter,
//                                 child: Padding(
//                                   padding: const EdgeInsets.symmetric(vertical: 20),
//                                   child: TextParser(
//                                     text: currentStory.caption,
//                                     ifUsername: (word) async {

//                                     },
//                                     ifTag: (word) async {

//                                     },
//                                     ifEmail: (word) async {

//                                     },
//                                     ifUrl: (word) async {

//                                     },
//                                     textStyle: Theme.of(context).textTheme.headline6.copyWith(
//                                       color: _color.computeLuminance() > 0.5 ? Colors.black : Colors.white
//                                     ),
//                                     matchedWordStyle: Theme.of(context).textTheme.headline6.copyWith(
//                                       fontWeight: FontWeight.bold,
//                                       color: _color.computeLuminance() > 0.5 ? Colors.black : Colors.white
//                                     )
//                                   ),
//                                 ),
//                               )
//                             ],
//                           );
//                         } else {
//                           return Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Container(
//                                 height: 50,
//                                 width: 50,
//                                 child: CustomProgressIndicator(),
//                               )
//                             ],
//                           );
//                         }
//                       },
//                     );
//                   } else if (currentStory.type == StoryType.image) {
//                     return Stack(
//                       children: [
//                         Align(
//                           alignment: Alignment.center,
//                           child: OctoImage(
//                             image: NetworkImage(currentStory.url),
//                             placeholderBuilder: (context) => Container(
//                               height: 50,
//                               width: 50,
//                               child: CustomProgressIndicator(),
//                             ),
//                           ),
//                         ),
//                         Align(
//                           alignment: Alignment.bottomCenter,
//                           child: Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 20),
//                             child: TextParser(
//                               text: currentStory.caption,
//                               ifUsername: (word) async {
//                               },
//                               ifTag: (word) async {
//                               },
//                               ifEmail: (word) async {
//                               },
//                               ifUrl: (word) async {
//                               },
//                               textStyle: Theme.of(context).textTheme.headline6.copyWith(
//                                 color: _color.computeLuminance() > 0.5 ? Colors.black : Colors.white
//                               ),
//                               matchedWordStyle: Theme.of(context).textTheme.headline6.copyWith(
//                                 fontWeight: FontWeight.bold,
//                                 color: _color.computeLuminance() > 0.5 ? Colors.black : Colors.white
//                               )
//                             ),
//                           ),
//                         )
//                       ],
//                     );
//                   } else if (currentStory.type == StoryType.post) {
//                     return Column(
//                       children: [
//                         Text('Post', style: TextStyle(color: Colors.white),)
//                       ],
//                     );
//                   } else {
//                     return Column(
//                       children: [
//                         Text('unknown', style: TextStyle(color: Colors.white),)
//                       ],
//                     );
//                   }
//                 },
//               ),
//             )
//           ],
//         ),
//       ),
//       backgroundColor: _color,
//     );
//   }
// }