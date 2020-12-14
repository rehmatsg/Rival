import 'package:flutter/material.dart';
import 'package:octo_image/octo_image.dart';
import 'package:shimmer/shimmer.dart';
import '../app.dart';

class Blocked extends StatefulWidget {
  @override
  _BlockedState createState() => _BlockedState();
}

class _BlockedState extends State<Blocked> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blocked People'),
      ),
      body: ListView.builder(
        itemCount: me.doc.data()['blocked'].length,
        itemBuilder: (context, index) => BlockedUserTile(index: index,),
      ),
    );
  }
}

class BlockedUserTile extends StatefulWidget {

  final int index;
  const BlockedUserTile({Key key, this.index}) : super(key: key);

  @override
  _BlockedUserTileState createState() => _BlockedUserTileState();
}

class _BlockedUserTileState extends State<BlockedUserTile> {

  bool unblocked = false;
  bool isUnblocking = false;

  RivalUser user;

  Future<RivalUser> _futureGetUser() async {
    if (user != null) return user;
    user = await getUser(me.doc.data()['blocked'][widget.index].id);
    return user;
  }
  
  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RivalUser>(
      future: _futureGetUser(),
      builder: (context, snapshot) {
        bool loaded = snapshot.connectionState == ConnectionState.done;
        return ListTile(
          title: loaded ? Text(user.displayName) : Shimmer.fromColors(
            child: Container(
              decoration: BoxDecoration(
                color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black87 : Colors.white70,
                borderRadius: BorderRadius.all(Radius.circular(5))
              ),
              height: 8,
            ),
            baseColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.white10, highlightColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black26 : Colors.white24,
          ),
          leading: loaded
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
          subtitle: loaded ? Text(user.username) : null,
          trailing: loaded ? (
            unblocked
            ? Text('Unblocked', style: TextStyle(color: Colors.indigoAccent),)
            : FlatButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10))
              ),
              color: isUnblocking ? (MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[100] : Colors.grey[900]) : Colors.indigoAccent,
              child: isUnblocking ? Container(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(strokeWidth: 2,),
              ) : Text('Unblock'),
              onPressed: () async {
                setState(() {
                  isUnblocking = true;
                });
                await user.blockUnblock(autoUpdateUser: false);
                setState(() {
                  isUnblocking = false;
                  unblocked = true;
                });
                await me.reload();
              },
            )
          ) : null,
        );
      }
    );
  }
}