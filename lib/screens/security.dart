import 'package:flutter/material.dart';
import '../app.dart';

class Security extends StatefulWidget {

  Security({
    Key key,
  }) : super(key: key);

  @override
  _SecurityState createState() => _SecurityState();
}

class _SecurityState extends State<Security> {

  Widget profilePhoto;

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    profilePhoto = Hero(
      tag: 'profile_photo',
      child: ClipOval(
        child: Image(image: me.photo, width: 100, height: 100,),
      )
    );
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Security'),
      ),
      body: ListView(
        children: [
          MyAccountDisplay(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Text('Account', style: TextStyle(color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black87 : Colors.white70, fontFamily: RivalFonts.feature),),
            ),
          ),
          ListTile(
            title: Text('Change Password'),
            subtitle: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning, size: 15,), Container(width: 5,),
                Text('Requires recent login'),
              ],
            ),
            onTap: () => Navigator.of(context).push(RivalNavigator(page: ChangePassword(),)),
          ),
        ],
      ),
    );
  }
}