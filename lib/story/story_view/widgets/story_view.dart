import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:flutter/material.dart';
import 'package:octo_image/octo_image.dart';
import 'package:preload_page_view/preload_page_view.dart';

import '../../provider.dart';
import '../controller/story_controller.dart';
import '../utils.dart';
import 'story_image.dart';
import 'story_video.dart';
import '../../../app.dart';

/// Indicates where the progress indicators should be placed.
enum ProgressPosition { top, bottom }

/// This is used to specify the height of the progress indicator. Inline stories
/// should use [small]
enum IndicatorHeight { small, large }

/// This is a representation of a story item (or page).
class StoryItem {
  /// Specifies how long the page should be displayed. It should be a reasonable
  /// amount of time greater than 0 milliseconds.
  final Duration duration;

  final Story story;

  /// Has this page been shown already? This is used to indicate that the page
  /// has been displayed. If some pages are supposed to be skipped in a story,
  /// mark them as shown `shown = true`.
  ///
  /// However, during initialization of the story view, all pages after the
  /// last unshown page will have their `shown` attribute altered to false. This
  /// is because the next item to be displayed is taken by the last unshown
  /// story item.
  bool shown;

  /// The page content
  final Widget view;

  StoryItem(
    this.view, {
    @required this.story,
    this.duration,
    this.shown = false,
  }) : assert(duration != null, "[duration] should not be null");

  Story get rivalStory => story;

  /// Short hand to create text-only page.
  ///
  /// [title] is the text to be displayed on [backgroundColor]. The text color
  /// alternates between [Colors.black] and [Colors.white] depending on the
  /// calculated contrast. This is to ensure readability of text.
  ///
  /// Works for inline and full-page stories. See [StoryView.inline] for more on
  /// what inline/full-page means.
  static StoryItem text(
      {@required String title,
      @required Color backgroundColor,
      @required Story story,
      TextStyle textStyle,
      bool shown = false,
      bool roundedTop = false,
      bool roundedBottom = false,
      Duration duration,
      Widget bottomWidget}) {
    double contrast = ContrastHelper.contrast([
      backgroundColor.red,
      backgroundColor.green,
      backgroundColor.blue,
    ], [
      255,
      255,
      255
    ] /** white text */);

    return StoryItem(
      Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(roundedTop ? 8 : 0),
            bottom: Radius.circular(roundedBottom ? 8 : 0),
          ),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Text(
              //   title,
              //   style: textStyle?.copyWith(
              //     color: contrast > 1.8 ? Colors.white : Colors.black,
              //   ) ?? TextStyle(
              //     color: contrast > 1.8 ? Colors.white : Colors.black,
              //     fontSize: 35,
              //   ),
              //   textAlign: TextAlign.center,
              // ),
              TextParser(
                text: title,
                textAlign: TextAlign.center,
                textStyle: textStyle?.copyWith(
                        color: contrast > 1.8 ? Colors.white : Colors.black,
                        fontFamily: story.font) ??
                    TextStyle(
                      color: contrast > 1.8 ? Colors.white : Colors.black,
                      fontFamily: story.font,
                      fontSize: 35,
                    ),
                matchedWordStyle: TextStyle(fontWeight: FontWeight.bold),
                ifEmail: (email) {},
                ifUrl: (url) {},
              ),
              bottomWidget ?? Container()
            ],
          ),
        ),
        //color: backgroundColor,
      ),
      shown: shown,
      duration: duration ?? Duration(seconds: 3),
      story: story,
    );
  }

  /// Factory constructor for page images. [controller] should be same instance as
  /// one passed to the `StoryView`
  factory StoryItem.pageImage(
      {@required String url,
      @required StoryController controller,
      @required Story story,
      BoxFit imageFit = BoxFit.fitWidth,
      String caption,
      bool shown = false,
      Map<String, dynamic> requestHeaders,
      Duration duration,
      Widget bottomWidget}) {
    return StoryItem(
      Container(
        color: Colors.black,
        child: Stack(
          children: <Widget>[
            StoryImage.url(
              url,
              controller: controller,
              fit: imageFit,
              requestHeaders: requestHeaders,
            ),
            // SafeArea(
            //   child: Align(
            //     alignment: Alignment.bottomCenter,
            //     child: Container(
            //       width: double.infinity,
            //       margin: EdgeInsets.only(
            //         bottom: 24,
            //       ),
            //       padding: EdgeInsets.symmetric(
            //         horizontal: 24,
            //         vertical: 8,
            //       ),
            //       color: caption != null ? Colors.black54 : Colors.transparent,
            //       child: Column(
            //         mainAxisSize: MainAxisSize.min,
            //         children: [
            //           caption != null
            //               ? Text(
            //                   caption,
            //                   style: TextStyle(
            //                     fontSize: 15,
            //                     color: Colors.white,
            //                   ),
            //                   textAlign: TextAlign.center,
            //                 )
            //               : SizedBox(),
            //           bottomWidget ?? Container()
            //         ],
            //       ),
            //     ),
            //   ),
            // )
          ],
        ),
      ),
      shown: shown,
      duration: duration ?? Duration(seconds: 3),
      story: story,
    );
  }

  /// Shorthand for creating inline image. [controller] should be same instance as
  /// one passed to the `StoryView`
  factory StoryItem.inlineImage(
      {@required String url,
      @required Text caption,
      @required StoryController controller,
      @required Story story,
      BoxFit imageFit = BoxFit.cover,
      Map<String, dynamic> requestHeaders,
      bool shown = false,
      bool roundedTop = true,
      bool roundedBottom = false,
      Duration duration,
      Widget bottomWidget}) {
    return StoryItem(
      ClipRRect(
        child: Container(
          color: Colors.grey[100],
          child: Container(
            color: Colors.black,
            child: Stack(
              children: <Widget>[
                StoryImage.url(
                  url,
                  controller: controller,
                  fit: imageFit,
                  requestHeaders: requestHeaders,
                ),
                Container(
                  margin: EdgeInsets.only(bottom: 16),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          caption == null ? SizedBox() : caption,
                          bottomWidget
                        ],
                      ),
                      width: double.infinity,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(roundedTop ? 8 : 0),
          bottom: Radius.circular(roundedBottom ? 8 : 0),
        ),
      ),
      shown: shown,
      duration: duration ?? Duration(seconds: 3),
      story: story,
    );
  }

  /// Shorthand for creating page video. [controller] should be same instance as
  /// one passed to the `StoryView`
  factory StoryItem.pageVideo(String url,
      {@required StoryController controller,
      @required Story story,
      BoxFit imageFit = BoxFit.fitWidth,
      String caption,
      bool shown = false,
      Map<String, dynamic> requestHeaders,
      Widget bottomWidget}) {
    return StoryItem(
        Container(
          color: Colors.black,
          child: Stack(
            children: <Widget>[
              StoryVideo.url(
                url,
                controller: controller,
                requestHeaders: requestHeaders,
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: 24),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    color:
                        caption != null ? Colors.black54 : Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        caption != null
                            ? Text(
                                caption,
                                style: TextStyle(
                                    fontSize: 15, color: Colors.white),
                                textAlign: TextAlign.center,
                              )
                            : SizedBox(),
                        bottomWidget ?? Container()
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
        shown: shown,
        duration: Duration(seconds: story.duration),
        story: story);
  }

  /// Shorthand for creating a story item from an image provider such as `AssetImage`
  /// or `NetworkImage`. However, the story continues to play while the image loads
  /// up.
  factory StoryItem.pageProviderImage(
    ImageProvider image, {
    BoxFit imageFit = BoxFit.fitWidth,
    @required Story story,
    String caption,
    bool shown = false,
    Duration duration,
  }) {
    assert(imageFit != null, "[imageFit] should not be null");
    return StoryItem(
        Container(
          color: Colors.black,
          child: Stack(
            children: <Widget>[
              Center(
                child: Image(
                  image: image,
                  height: double.infinity,
                  width: double.infinity,
                  fit: imageFit,
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(
                      bottom: 24,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    color:
                        caption != null ? Colors.black54 : Colors.transparent,
                    child: caption != null
                        ? Text(
                            caption,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          )
                        : SizedBox(),
                  ),
                ),
              )
            ],
          ),
        ),
        shown: shown,
        duration: duration ?? Duration(seconds: 3),
        story: story);
  }

  /// Shorthand for creating an inline story item from an image provider such as `AssetImage`
  /// or `NetworkImage`. However, the story continues to play while the image loads
  /// up.
  factory StoryItem.inlineProviderImage(
    ImageProvider image, {
    @required Story story,
    Text caption,
    bool shown = false,
    bool roundedTop = true,
    bool roundedBottom = false,
    Duration duration,
  }) {
    return StoryItem(
      Container(
        decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(roundedTop ? 8 : 0),
              bottom: Radius.circular(roundedBottom ? 8 : 0),
            ),
            image: DecorationImage(
              image: image,
              fit: BoxFit.cover,
            )),
        child: Container(
          margin: EdgeInsets.only(
            bottom: 16,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 8,
          ),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              child: caption == null ? SizedBox() : caption,
              width: double.infinity,
            ),
          ),
        ),
      ),
      shown: shown,
      duration: duration ?? Duration(seconds: 3),
      story: story,
    );
  }

  /// Custom Made Story for adding Post
  factory StoryItem.post(
    String postId, {
    @required Story story,
    @required StoryController controller,
    Text caption,
    bool shown = false,
    bool showSwipeUp = false,
    Duration duration,
  }) {
    return StoryItem(
        Container(
          child: Center(
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FutureBuilder<Post>(
                        future: getPost(postId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            return CustomPostView(
                                id: postId, controller: controller);
                          }
                          return CustomProgressIndicator();
                        },
                      ),
                    ],
                  ),
                ),
                Visibility(
                  visible: showSwipeUp,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.keyboard_arrow_up,
                            color: Colors.white,
                          ),
                          Text(
                            'Swipe Up',
                            style: TextStyle(color: Colors.white),
                          )
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
        shown: shown,
        duration: duration ?? Duration(seconds: 5),
        story: story);
  }
}

/// Widget to display stories just like Whatsapp and Instagram. Can also be used
/// inline/inside [ListView] or [Column] just like Google News app. Comes with
/// gestures to pause, forward and go to previous page.
class StoryView extends StatefulWidget {
  /// The pages to displayed.
  final List<StoryItem> storyItems;

  /// ImageProvider to display user's avatar
  final ImageProvider avatar;

  /// Generally used to show name of the user
  final String username;

  /// A subtitle. Maybe any widget. Like for showing how much time ago the story was created
  final String subtitle;

  /// A trailing widget for any purpose
  final Widget trailing;

  /// Extra Icon Button to add more functionality
  /// * Number of view
  /// * Edit
  /// * Exit
  final Widget firstIcon;
  final Widget secondIcon;
  final Widget thirdIcon;

  /// Double tap on left side make the story go back
  final Function onPreviousStory;

  /// Callback for when a full cycle of story is shown. This will be called
  /// each time the full story completes when [repeat] is set to `true`.
  final VoidCallback onComplete;

  /// Callback for when a vertical swipe gesture is detected. If you do not
  /// want to listen to such event, do not provide it. For instance,
  /// for inline stories inside ListViews, it is preferrable to not to
  /// provide this callback so as to enable scroll events on the list view.
  final Function(Direction) onVerticalSwipeComplete;

  /// Callback for when a story is currently being shown.
  final ValueChanged<StoryItem> onStoryShow;

  /// Where the progress indicator should be placed.
  final ProgressPosition progressPosition;

  /// Should the story be repeated forever?
  final bool repeat;

  /// If you would like to display the story as full-page, then set this to
  /// `false`. But in case you would display this as part of a page (eg. in
  /// a [ListView] or [Column]) then set this to `true`.
  final bool inline;

  // Controls the playback of the stories
  final StoryController controller;

  StoryView({
    @required this.storyItems,
    @required this.controller,
    @required this.username,
    @required this.avatar,
    @required this.subtitle,
    this.onPreviousStory,
    this.trailing,
    this.onComplete,
    this.onStoryShow,
    this.progressPosition = ProgressPosition.top,
    this.repeat = false,
    this.inline = false,
    this.onVerticalSwipeComplete,
    this.firstIcon,
    this.secondIcon,
    this.thirdIcon
  })
  : assert(storyItems != null && storyItems.length > 0, "[storyItems] should not be null or empty"),
  assert(progressPosition != null, "[progressPosition] cannot be null"),
  assert(repeat != null, "[repeat] cannot be null",),
  assert(inline != null, "[inline] cannot be null");

  @override
  State<StatefulWidget> createState() {
    return StoryViewState();
  }
}

class StoryViewState extends State<StoryView> with TickerProviderStateMixin {
  AnimationController _animationController;
  Animation<double> _currentAnimation;
  Timer _nextDebouncer;

  StreamSubscription<PlaybackState> _playbackSubscription;

  VerticalDragInfo verticalDragInfo;

  StoryItem get _currentStory =>
      widget.storyItems.firstWhere((it) => !it.shown, orElse: () => null);

  // ignore: unused_element
  Widget get _currentView => widget.storyItems
      .firstWhere((it) => !it.shown, orElse: () => widget.storyItems.last)
      .view;

  PreloadPageController pageController;

  @override
  void initState() {
    pageController = PreloadPageController(
      initialPage: widget.storyItems.indexOf(widget.storyItems
          .firstWhere((it) => !it.shown, orElse: () => widget.storyItems.last)),
    );
    super.initState();

    // All pages after the first unshown page should have their shown value as
    // false

    final firstPage = widget.storyItems.firstWhere((it) {
      return !it.shown;
    }, orElse: () {
      widget.storyItems.forEach((it2) {
        it2.shown = false;
      });

      return null;
    });

    if (firstPage != null) {
      final lastShownPos = widget.storyItems.indexOf(firstPage);
      widget.storyItems.sublist(lastShownPos).forEach((it) {
        it.shown = false;
      });
    }

    this._playbackSubscription =
        widget.controller.playbackNotifier.listen((playbackStatus) {
      switch (playbackStatus) {
        case PlaybackState.play:
          _removeNextHold();
          this._animationController?.forward();
          break;

        case PlaybackState.pause:
          _holdNext(); // then pause animation
          this._animationController?.stop(canceled: false);
          break;

        case PlaybackState.next:
          _removeNextHold();
          _goForward();
          break;

        case PlaybackState.previous:
          _removeNextHold();
          _goBack();
          break;
      }
    });

    _play();
  }

  @override
  void dispose() {
    _clearDebouncer();

    _animationController?.dispose();
    _playbackSubscription?.cancel();

    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  void _play() {
    _animationController?.dispose();
    // get the next playing page
    final storyItem = widget.storyItems.firstWhere((it) {
      return !it.shown;
    });

    if (widget.onStoryShow != null) {
      widget.onStoryShow(storyItem);
    }

    _animationController =
        AnimationController(duration: storyItem.duration, vsync: this);

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        storyItem.shown = true;
        if (widget.storyItems.last != storyItem) {
          _beginPlay();
          pageController.animateToPage(widget.storyItems.indexOf(_currentStory),
              duration: Duration(milliseconds: 100), curve: Curves.easeInOut);
        } else {
          // done playing
          _onComplete();
        }
      }
    });

    _currentAnimation =
        Tween(begin: 0.0, end: 1.0).animate(_animationController);

    widget.controller.play();
  }

  void _beginPlay() {
    setState(() {});
    _play();
  }

  void _onComplete() {
    if (widget.onComplete != null) {
      widget.controller.pause();
      widget.onComplete();
    }

    if (widget.repeat) {
      widget.storyItems.forEach((it) {
        it.shown = false;
      });

      _beginPlay();
    }
  }

  void _goBack() {
    _animationController.stop();

    if (this._currentStory == null) {
      widget.storyItems.last.shown = false;
    }

    if (this._currentStory != widget.storyItems.first) {
      this._currentStory.shown = false;
      int lastPos = widget.storyItems.indexOf(this._currentStory);
      final previous = widget.storyItems[lastPos - 1];

      previous.shown = false;

      pageController.animateToPage(widget.storyItems.indexOf(previous),
          duration: Duration(milliseconds: 100), curve: Curves.easeInOut);

      _beginPlay();
    }

    pageController.animateToPage(pageController.page.toInt() - 1,
        duration: Duration(milliseconds: 100), curve: Curves.easeInOut);
  }

  void _goForward() {
    if (this._currentStory != widget.storyItems.last) {
      _animationController.stop();

      // get last showing
      final _last = this._currentStory;

      if (_last != null) {
        _last.shown = true;
        print(widget.storyItems.indexOf(_currentStory));
        pageController.animateToPage(widget.storyItems.indexOf(_currentStory),
            duration: Duration(milliseconds: 100), curve: Curves.easeInOut);
        if (_last != widget.storyItems.last) {
          _beginPlay();
        }
      }
    } else {
      // this is the last page, progress animation should skip to end
      _animationController.animateTo(1.0, duration: Duration(milliseconds: 10));
    }
  }

  void _clearDebouncer() {
    _nextDebouncer?.cancel();
    _nextDebouncer = null;
  }

  void _removeNextHold() {
    _nextDebouncer?.cancel();
    _nextDebouncer = null;
  }

  void _holdNext() {
    _nextDebouncer?.cancel();
    _nextDebouncer = Timer(Duration(milliseconds: 500), () {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: <Widget>[
          PreloadPageView.builder(
            preloadPagesCount: widget.storyItems.length > 10 ? 10 : widget.storyItems.length,
            controller: pageController,
            itemBuilder: (context, index) => widget.storyItems[index].view,
            itemCount: widget.storyItems.length,
            pageSnapping: false,
            physics: NeverScrollableScrollPhysics(),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: StreamBuilder(
              stream: widget.controller.playbackNotifier,
              builder: (context, snapshot) => AnimatedOpacity(
                duration: snapshot.data == PlaybackState.play
                  ? Duration(milliseconds: 0)
                  : Duration(milliseconds: 500),
                opacity: snapshot.data == PlaybackState.play ? 1 : 0,
                child: Container(
                  color: Colors.black26,
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PageBar(
                          widget.storyItems
                              .map((it) => PageData(it.duration, it.shown))
                              .toList(),
                          this._currentAnimation,
                          key: UniqueKey(),
                          indicatorHeight: widget.inline
                              ? IndicatorHeight.small
                              : IndicatorHeight.large,
                        ),
                        Container(height: 10,),
                        Row(
                          mainAxisAlignment: (widget.firstIcon != null) ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
                          children: [
                            if (widget.firstIcon != null) widget.firstIcon,
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.secondIcon != null) ... [
                                  Container(width: 10,),
                                  widget.secondIcon,
                                ],
                                if (widget.thirdIcon != null) widget.thirdIcon,
                              ],
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              StreamBuilder<PlaybackState>(
                stream: widget.controller.playbackNotifier,
                builder: (context, snapshot) {
                  return DelayedDisplay(
                    delay: snapshot.data == PlaybackState.play
                      ? Duration(milliseconds: 0)
                      : Duration(milliseconds: 50),
                    child: AnimatedOpacity(
                      opacity: snapshot.data == PlaybackState.play ? 1 : 0,
                      duration: snapshot.data == PlaybackState.play
                        ? Duration(milliseconds: 0)
                        : Duration(milliseconds: 500),
                      child: Container(
                        color: Colors.black26,
                        child: SafeArea(
                          top: false,
                          child: ListTile(
                            visualDensity: VisualDensity.compact,
                            leading: ClipOval(
                              child: OctoImage(
                                width: 40,
                                height: 40,
                                image: widget.avatar,
                                placeholderBuilder: (context) =>
                                    CustomProgressIndicator(),
                              ),
                            ),
                            title: Text(widget.username,
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle1
                                    .copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                            subtitle: Text(widget.subtitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle2
                                    .copyWith(color: Colors.white70)),
                            trailing: widget.trailing,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              )
            ]),
          ),
          Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: MediaQuery.of(context).size.width / 4,
                child: GestureDetector(
                  child: Container(
                    color: Colors.redAccent
                        .withOpacity(0), // Turn up the opacity to see hot area
                  ),
                  onTapDown: (details) {
                    widget.controller.pause();
                  },
                  onTapCancel: () {
                    widget.controller.play();
                  },
                  onTapUp: (details) {
                    // if debounce timed out (not active) then continue anim
                    if (_nextDebouncer?.isActive == false) {
                      widget.controller.play();
                    } else {
                      widget.controller.next();
                    }
                  },
                ),
                height: MediaQuery.of(context).size.height / 2,
              )),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              child: GestureDetector(
                onTapDown: (details) {
                  widget.controller.pause();
                },
                onTapCancel: () {
                  widget.controller.play();
                },
                onTapUp: (details) {
                  if (_nextDebouncer?.isActive == false) {
                    widget.controller.play();
                  } else {
                    widget.controller.previous();
                  }
                },
                child: Container(
                  color: Colors.blueAccent
                      .withOpacity(0), // Turn up the opacity to see hot area
                ),
                //onDoubleTap: widget.onPreviousStory,
              ),
              width: MediaQuery.of(context).size.width / 4,
              height: MediaQuery.of(context).size.height / 2,
            ),
          )
        ],
      ),
    );
  }
}

/// Capsule holding the duration and shown property of each story. Passed down
/// to the pages bar to render the page indicators.
class PageData {
  Duration duration;
  bool shown;

  PageData(this.duration, this.shown);
}

/// Horizontal bar displaying a row of [StoryProgressIndicator] based on the
/// [pages] provided.
class PageBar extends StatefulWidget {
  final List<PageData> pages;
  final Animation<double> animation;
  final IndicatorHeight indicatorHeight;

  PageBar(
    this.pages,
    this.animation, {
    this.indicatorHeight = IndicatorHeight.large,
    Key key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return PageBarState();
  }
}

class PageBarState extends State<PageBar> {
  double spacing = 4;

  @override
  void initState() {
    super.initState();

    int count = widget.pages.length;
    spacing = count > 15
        ? 1
        : count > 10
            ? 2
            : 4;

    widget.animation.addListener(() {
      setState(() {});
    });
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  bool isPlaying(PageData page) {
    return widget.pages.firstWhere((it) => !it.shown, orElse: () => null) ==
        page;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: widget.pages.map((it) {
        return Expanded(
          child: Container(
            padding: EdgeInsets.only(
                right: widget.pages.last == it ? 0 : this.spacing),
            child: StoryProgressIndicator(
              isPlaying(it)
                  ? widget.animation.value
                  : it.shown
                      ? 1
                      : 0,
              indicatorHeight:
                  widget.indicatorHeight == IndicatorHeight.large ? 5 : 3,
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Custom progress bar. Supposed to be lighter than the
/// original [ProgressIndicator], and rounded at the sides.
class StoryProgressIndicator extends StatelessWidget {
  /// From `0.0` to `1.0`, determines the progress of the indicator
  final double value;
  final double indicatorHeight;

  StoryProgressIndicator(
    this.value, {
    this.indicatorHeight = 5,
  }) : assert(indicatorHeight != null && indicatorHeight > 0,
            "[indicatorHeight] should not be null or less than 1");

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.fromHeight(
        2,
      ),
      foregroundPainter: IndicatorOval(
        Colors.white.withOpacity(0.8),
        this.value,
      ),
      painter: IndicatorOval(
        Colors.white.withOpacity(0.4),
        1.0,
      ),
    );
  }
}

class IndicatorOval extends CustomPainter {
  final Color color;
  final double widthFactor;

  IndicatorOval(this.color, this.widthFactor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = this.color;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.width * this.widthFactor, size.height),
            Radius.circular(3)),
        paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

/// Concept source: https://stackoverflow.com/a/9733420
class ContrastHelper {
  static double luminance(int r, int g, int b) {
    final a = [r, g, b].map((it) {
      double value = it.toDouble() / 255.0;
      return value <= 0.03928
          ? value / 12.92
          : pow((value + 0.055) / 1.055, 2.4);
    }).toList();

    return a[0] * 0.2126 + a[1] * 0.7152 + a[2] * 0.0722;
  }

  static double contrast(rgb1, rgb2) {
    return luminance(rgb2[0], rgb2[1], rgb2[2]) /
        luminance(rgb1[0], rgb1[1], rgb1[2]);
  }
}

/// Custom Designed PostView to show posts in Story
/// See the ORIGINAL PostView in post/view.dart
class CustomPostView extends StatefulWidget {
  final String id;
  final StoryController controller;
  const CustomPostView({Key key, this.id, this.controller}) : super(key: key);

  @override
  _CustomPostViewState createState() => _CustomPostViewState();
}

class _CustomPostViewState extends State<CustomPostView> {
  StoryController controller;
  Post post;

  bool isLoading = true;
  bool isPostHidden = true;
  bool available = true;

  _init() async {
    controller.pause();
    post = await getPost(widget.id);
    if (post != null) {
      if (post.available) {
        setState(() {
          isLoading = false;
          if ((post.isMyPost ||
                  (post.user.private && post.user.isFollowing) ||
                  post.available) &&
              !post.takenDown) {
            isPostHidden = false;
          }
        });
      } else {
        setState(() {
          isLoading = false;
          isPostHidden = false;
          available = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
        isPostHidden = false;
        available = false;
      });
    }
    controller.play();
  }

  @override
  void initState() {
    controller = widget.controller;
    super.initState();
    _init();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: isLoading
            ? Container(
                width: 70,
                height: 70,
                child: CustomProgressIndicator(
                  valueColor: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                child: GestureDetector(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isPostHidden) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                  '@${post.user.username} has a private account. Follow @${post.user.username} to view this post')),
                        )
                      ] else if (!available) ...[
                        Column(
                          children: [
                            Icon(
                              Icons.warning,
                              color: Colors.yellow,
                              size: Theme.of(context)
                                  .textTheme
                                  .headline3
                                  .fontSize,
                            ),
                            Text(
                              'Post Not Found',
                              style: Theme.of(context)
                                  .textTheme
                                  .headline5
                                  .copyWith(
                                      color: Colors.white,
                                      fontFamily: RivalFonts.feature),
                            ),
                          ],
                        )
                      ] else if (post.items.indexWhere((item) => item.type == PostType.image) >= 0) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          child: OctoImage(
                            image: CachedNetworkImageProvider(post.items[post.items.indexWhere((item) => item.type == PostType.image)].url),
                            width: MediaQuery.of(context).size.width,
                            progressIndicatorBuilder: (context, progress) {
                              double value;
                              if (progress != null && progress.expectedTotalBytes != null) {
                                value = progress.cumulativeBytesLoaded / progress.expectedTotalBytes;
                              }
                              return Container(
                                width: double.infinity,
                                child: LinearProgressIndicator(
                                  value: value,
                                  valueColor: new AlwaysStoppedAnimation<Color>(
                                    MediaQuery.of(context).platformBrightness == Brightness.light
                                      ? Colors.black
                                      : Colors.white
                                  ),
                                  minHeight: 2,
                                ),
                              );
                            }
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Post by @${post.user.username}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption
                                      .copyWith(color: Colors.white70)),
                              Text(
                                getTimeAgo(
                                    new DateTime.fromMillisecondsSinceEpoch(
                                        post.timestamp),
                                    includeHour: false),
                                style: Theme.of(context)
                                    .textTheme
                                    .caption
                                    .copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ]
                    ],
                  ),
                  onLongPress: () {
                    if (!isPostHidden) {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => BottomSheet(
                          onClosing: () {},
                          backgroundColor:
                              MediaQuery.of(context).platformBrightness ==
                                      Brightness.light
                                  ? Colors.white
                                  : Colors.grey[900],
                          builder: (context) => Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 13, horizontal: 15),
                            child: ListTile(
                              title: Text('View Post'),
                              subtitle: Text('Tap to open post'),
                              onTap: () => Navigator.of(context)
                                  .pushReplacement(RivalNavigator(
                                page: SinglePostView(post: post),
                              )),
                            ),
                          ),
                          elevation: 0,
                          key: UniqueKey(),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20))),
                        ),
                      );
                    }
                  },
                ),
              ));
  }
}
