import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../app.dart';

class Followers extends StatefulWidget {
  Followers({Key key, @required this.user}) : super(key: key);
  final user;
  @override
  _FollowersState createState() => _FollowersState();
}

class _FollowersState extends State<Followers> {

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
    return Scaffold(
      appBar: AppBar(
        title: Text('@${widget.user.username}'),
      ),
      body: StreamProvider<RivalRootUser>.value(
        value: widget.user.stream,
        lazy: false,
        initialData: widget.user,
        updateShouldNotify: (previous, current) {
          if (previous.followers.length < current.followers.length) {
            return true;
          } else {
            return false;
          }
        },
        builder: (context, child) {
          RivalRootUser user = Provider.of<RivalRootUser>(context);
          return SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 20, left: 15, right: 15, bottom: 5),
                      child: Text('Followers', style: TextStyle(fontSize: Theme.of(context).textTheme.headline3.fontSize, fontFamily: RivalFonts.feature),),
                    ),
                  ],
                ),
                if (widget.user.uid == me.uid && (me.data['allow_new_followers'] == false || me.data['follow_requests'].isNotEmpty)) ListTile(
                  title: Text('Approve follow requests'),
                  trailing: Chip(
                    label: Text(me.doc.data()['follow_requests'].length > 0 ? '+${me.doc.data()['follow_requests'].length}' : 'No Requests', style: TextStyle(color: Colors.white),),
                    backgroundColor: Colors.indigoAccent,
                  ),
                  onTap: () => Navigator.of(context).push(RivalNavigator(page: FollowRequests(),)),
                ),
                ... List.generate(user.followers.length, (index) => UserListTile(ref: user.followers[index],))
              ],
            ),
          );
        },
      ),
    );
  }
}