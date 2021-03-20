import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../app.dart';

class Followers extends StatefulWidget {
  Followers({Key key, @required this.user}) : super(key: key);
  final user;
  @override
  _FollowersState createState() => _FollowersState();
}

class _FollowersState extends State<Followers> {

  RivalRootUser user;

  Map<String, Future<RivalUser>> followers = {};

  @override
  void initState() {
    user = widget.user;
    user.followers.forEach((f) {
      DocumentReference ref = f;
      String uid = ref.id;
      followers[uid] = getUser(uid);
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
      body: SingleChildScrollView(
        physics: ScrollPhysics(),
        child: Column(
          children: [
            if (!me.data['allow_new_followers'] || me.data['follow_requests'].length > 0) ListTile(
              title: Text('Approve follow requests'),
              trailing: Chip(
                label: Text(me.data['follow_requests'].length > 0 ? '${me.data['follow_requests'].length}' : 'No Requests', style: TextStyle(color: Colors.white),),
                backgroundColor: Colors.indigoAccent,
              ),
              onTap: () async {
                await Navigator.of(context).push(RivalNavigator(page: FollowRequests(),));
                setState(() {});
              }
            ),
            PagedListView(
              autoNextPage: false,
              itemsPerPage: 30,
              useSeparator: false,
              onNextPage: (startIndex, endIndex) async {
                Map<String, Future<RivalUser>> followersL = followers.getRange(startIndex, endIndex);
                List<Widget> widgets = [];
                followersL.forEach((uid, future) {
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
            )
          ],
        ),
      ),
    );
  }
}