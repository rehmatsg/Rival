import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:octo_image/octo_image.dart';
import 'package:shimmer/shimmer.dart';
import '../app.dart';

class FollowRequests extends StatefulWidget {
  @override
  _FollowRequestsState createState() => _FollowRequestsState();
}

class _FollowRequestsState extends State<FollowRequests> {

  Map followRequests = me.doc.data()['follow_requests'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Follow Requests'),
      ),
      body: ListView.builder(
        itemCount: followRequests.length,
        itemBuilder: (context, index) {
          return FollowRequestUser(followRequests: followRequests, index: index,);
        },
      ),
    );
  }
}

class FollowRequestUser extends StatefulWidget {

  FollowRequestUser({
    Key key,
    @required this.followRequests,
    @required this.index
  }) : super(key: key);
  final Map followRequests;
  final int index;

  @override
  _FollowRequestUserState createState() => _FollowRequestUserState();
}

class _FollowRequestUserState extends State<FollowRequestUser> {

  bool isApproved = false;
  bool isCancelled = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RivalUser>(
      future: getUser(widget.followRequests.values.toList()[widget.index].id),
      builder: (context, snapshot) {
        RivalUser user;
        if (snapshot.connectionState == ConnectionState.done) user = snapshot.data;
        return ListTile(
          title: snapshot.connectionState == ConnectionState.done ? Text(user.displayName) : Shimmer.fromColors(
            child: Container(
              decoration: BoxDecoration(
                color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black87 : Colors.white70,
                borderRadius: BorderRadius.all(Radius.circular(5))
              ),
              height: 9,
            ),
            baseColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.white10, highlightColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black26 : Colors.white12
          ),
          leading: snapshot.connectionState == ConnectionState.done
          ? ClipOval(
            child: OctoImage(
              image: user.photo,
              width: 40,
              height: 40,
              placeholderBuilder: (context) => Shimmer.fromColors(
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
            ),
          ) : Shimmer.fromColors(
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
          subtitle: Text(getTimeAgo(new DateTime.fromMillisecondsSinceEpoch(int.parse(widget.followRequests.keys.toList()[widget.index])), includeHour: false)),
          trailing: isCancelled ? Chip(label: Text('Removed'), backgroundColor: Colors.red,) : (isApproved
          ? Chip(label: Text('Approved'), backgroundColor: Colors.blueAccent,)
          : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: Icon(Icons.close), tooltip: 'Delete Request', onPressed: () async {
                await me.update({
                  'follow_requests.${widget.followRequests.keys.toList()[widget.index]}': FieldValue.delete()
                });
                await me.reload();
                setState(() {
                  isCancelled = true;
                });
                await RivalProvider.showToast(text: 'Request Deleted');
              }),
              IconButton(icon: Icon(Icons.done), tooltip: 'Approve Request', onPressed: () async {
                await me.update({
                  'follow_requests.${widget.followRequests.keys.toList()[widget.index]}': FieldValue.delete()
                });
                await me.update({
                  'followers': FieldValue.arrayUnion([widget.followRequests.values.toList()[widget.index]])
                });
                await widget.followRequests.values.toList()[widget.index] .update({
                  'following': FieldValue.arrayUnion([me.reference])
                });
                await me.reload();
                setState(() {
                  isApproved = true;
                });
                await RivalProvider.showToast(text: 'Request Approved');
              })
            ],
          )),
        );
      }
    );
  }
}