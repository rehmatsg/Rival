import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../app.dart';

class Following extends StatefulWidget {
  Following({Key key, @required this.user}) : super(key: key);
  final user;
  @override
  _FollowingState createState() => _FollowingState();
}

class _FollowingState extends State<Following> {

  RivalRootUser user;

  Map<String, Future<RivalUser>> following = {};

  @override
  void initState() {
    user = widget.user;
    user.following.forEach((f) {
      DocumentReference ref = f;
      String uid = ref.id;
      following[uid] = getUser(uid);
    });
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('@${widget.user.username}'),
      ),
      body: PagedListView(
        autoNextPage: false,
        itemsPerPage: 30,
        useSeparator: false,
        onNextPage: (startIndex, endIndex) async {
          Map<String, Future<RivalUser>> followingL = following.getRange(startIndex, endIndex);
          List<Widget> widgets = [];
          followingL.forEach((uid, future) {
            if (uid != me.uid) widgets.add(UserListTile(
              future: future,
              isCurrentUser: false,
            ));
            else widgets.add(UserListTile(
              isCurrentUser: true,
            ));
          });
          return widgets;
        },
      ),
    );
  }
}