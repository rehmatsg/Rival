import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import '../providers.dart';

class Following extends StatefulWidget {
  Following({Key key, @required this.user}) : super(key: key);
  final user;
  @override
  _FollowingState createState() => _FollowingState();
}

class _FollowingState extends State<Following> {

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
          if (previous.following.length < current.following.length) {
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
                      child: Text('Following', style: TextStyle(fontSize: Theme.of(context).textTheme.headline3.fontSize, fontFamily: RivalFonts.feature),),
                    ),
                  ],
                ),
              ] + List.generate(user.following.length, (index) => UserListTile(ref: user.following[index],)),
            ),
          );
        },
      ),
    );
  }
}