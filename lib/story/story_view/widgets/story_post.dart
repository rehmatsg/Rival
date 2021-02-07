import 'dart:async';
import 'package:flutter/material.dart';
import '../story_view.dart';
import '../../../app.dart';

class StoryPost extends StatefulWidget {
  final StoryController controller;
  final Post post;

  StoryPost({
    Key key,
    this.controller,
    @required this.post,
  }) : super(key: key ?? UniqueKey());

  /// Use this shorthand to fetch images/gifs from the provided [url]
  factory StoryPost.url({
    StoryController controller,
    Map<String, dynamic> requestHeaders,
    BoxFit fit = BoxFit.fitWidth,
    Key key,
  }) {
    return StoryPost(
      controller: controller,
      key: key, post: null,
    );
  }

  @override
  State<StatefulWidget> createState() => StoryPostState();
}

class StoryPostState extends State<StoryPost> {

  Timer _timer;

  StreamSubscription<PlaybackState> _streamSubscription;

  @override
  void initState() {
    super.initState();

    if (widget.controller != null) {
      this._streamSubscription =
          widget.controller.playbackNotifier.listen((playbackState) {

        if (playbackState == PlaybackState.pause) {
          this._timer?.cancel();
        } else {
          forward();
        }
      });
    }

  }

  @override
  void dispose() {
    _timer?.cancel();
    _streamSubscription?.cancel();

    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void forward() async {
    this._timer?.cancel();

    if (widget.controller != null &&
        widget.controller.playbackNotifier.value == PlaybackState.pause) {
      return;
    }

    setState(() {});
  }

  Widget getContentView() {
    return Center(
      child: Container(
        width: 70,
        height: 70,
        child: ViewPost(post: widget.post),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: getContentView(),
    );
  }
}