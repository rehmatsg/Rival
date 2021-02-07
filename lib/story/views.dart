import 'package:flutter/material.dart';
import '../app.dart';

class StoryViews extends StatefulWidget {

  final Story story;

  StoryViews({Key key, @required this.story}) : super(key: key);

  @override
  _StoryViewsState createState() => _StoryViewsState();
}

class _StoryViewsState extends State<StoryViews> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Views'),
      ),
      body: PagedListView(
        autoNextPage: true,
        itemsPerPage: 25,
        onFinish: 'No more views',
        onNextPage: (startIndex, endIndex) async {
          List<Widget> widgets = [];
          if (widget.story.views.isEmpty) return widgets;
          else if (widget.story.views.length <= startIndex) return widgets;
          else if (widget.story.views.length < endIndex) endIndex = widget.story.views.length;
          Map viewsL = widget.story.views.getRange(startIndex, endIndex);
          viewsL.forEach((uid, timestamp) {
            widgets.add(UserListTile(
              id: uid,
              isCurrentUser: uid == me.uid,
              subtitle: getTimeAgo(DateTime.fromMillisecondsSinceEpoch(timestamp)),
            ));
          });
          return widgets;
        },
      ),
    );
  }
}