import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'package:vibration/vibration.dart';
import '../app.dart';

class SettingsPage extends StatefulWidget {

  SettingsPage({Key key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

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
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ProfilePhoto(height: 100, width: 100,),
                Container(height: 15,),
                Text(
                  me.displayName,
                  style: Theme.of(context).textTheme.headline5.copyWith(
                    fontFamily: RivalFonts.feature
                  )
                ),
              ],
            ),
          ),
          ListTile(
            leading: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.indigoAccent.withOpacity(0.3),
                borderRadius: BorderRadius.all(Radius.circular(30))
              ),
              child: Center(
                child: Icon(
                  Icons.account_circle,
                  size: 25,
                  color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[900] : Colors.white
                ),
              ),
            ),
            title: Text('Account'),
            onTap: () {
              Navigator.push(
                context,
                RivalNavigator(page: Account()),
              );
            },
          ),
          if (me.isBusinessAccount) ListTile(
            leading: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.indigoAccent.withOpacity(0.3),
                borderRadius: BorderRadius.all(Radius.circular(30))
              ),
              child: Center(
                child: Icon(
                  Icons.business,
                  size: 25,
                  color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[900] : Colors.white
                ),
              ),
            ),
            title: Text('Business'),
            onTap: () => Navigator.of(context).push(RivalNavigator(page: BusinessPage(),)),
          ),
          if (me.isCreatorAccount) ListTile(
            leading: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.indigoAccent.withOpacity(0.3),
                borderRadius: BorderRadius.all(Radius.circular(30))
              ),
              child: Center(
                child: Icon(
                  Icons.brush,
                  size: 25,
                  color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[900] : Colors.white
                ),
              ),
            ),
            title: Text('Creator'),
            onTap: () => Navigator.of(context).push(RivalNavigator(page: Creator(),)),
          ),
          ListTile(
            leading: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.indigoAccent.withOpacity(0.3),
                borderRadius: BorderRadius.all(Radius.circular(30))
              ),
              child: Center(
                child: Icon(
                  Icons.notifications_none,
                  size: 25,
                  color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[900] : Colors.white
                ),
              ),
            ),
            title: Text('Notifications'),
            onTap: () => AppSettings.openNotificationSettings(),
          ),
          ListTile(
            leading: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.indigoAccent.withOpacity(0.3),
                borderRadius: BorderRadius.all(Radius.circular(30))
              ),
              child: Center(
                child: Icon(
                  Icons.account_box,
                  size: 25,
                  color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[900] : Colors.white
                ),
              ),
            ),
            title: Text('Personal Information'),
            onTap: () => Navigator.of(context).push(RivalNavigator(page: Info())),
          ),
          ListTile(
            leading: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.indigoAccent.withOpacity(0.3),
                borderRadius: BorderRadius.all(Radius.circular(30))
              ),
              child: Center(
                child: Icon(
                  Icons.lock_outline,
                  size: 25,
                  color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[900] : Colors.white
                ),
              ),
            ),
            title: Text('Privacy and Security'),
            onTap: () {
              Navigator.push(
                context,
                RivalNavigator(page: PrivacyPage()),
              );
            },
          ),
          ListTile(
            leading: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.indigoAccent.withOpacity(0.3),
                borderRadius: BorderRadius.all(Radius.circular(30))
              ),
              child: Center(
                child: Icon(
                  Icons.person_add,
                  size: 25,
                  color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[900] : Colors.white
                ),
              ),
            ),
            title: Text('Invite People'),
            onTap: () async {
              if (await Vibration.hasVibrator()) {
                Vibration.vibrate(duration: 5);
              }
              Share.share('Hi, I have just started using the new Rival for sharing awesome photos. Follow my account @${me.doc.data()['username']} by installing Rival from Google Play (https://play.google.com/store/apps/details?id=gillco.rival)', subject: 'Get Rival');
            },
          ),
          ListTile(
            leading: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.indigoAccent.withOpacity(0.3),
                borderRadius: BorderRadius.all(Radius.circular(30))
              ),
              child: Center(
                child: Icon(
                  Icons.info,
                  size: 25,
                  color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[900] : Colors.white
                ),
              ),
            ),
            title: Text('About'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Rival',
                applicationIcon: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  child: Image.asset('assets/icon.png', width: 50, height: 50,),
                ),
                applicationVersion: '1.0.0',
                children: [
                  Row(
                    children: [
                      Text('Rival', style: TextStyle(fontFamily: RivalFonts.rival, fontSize: Theme.of(context).textTheme.headline6.fontSize),)
                    ],
                  ),
                  Text(
                    '''Thank your for choosing Rival. Please rate if you loved using it.'''
                  ),
                ]
              );
            },
          ),
          Divider(),
          ListTile(
            leading: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.5),
                borderRadius: BorderRadius.all(Radius.circular(30))
              ),
              child: Center(
                child: Icon(
                  Icons.logout,
                  size: 25,
                  color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[900] : Colors.white
                ),
              ),
            ),
            title: Text('Logout of @${me.username}'),
            onTap: () {
              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (_) => AlertDialog(
                  title: Text('Log Out', style: TextStyle(fontFamily: RivalFonts.feature),),
                  content: const Text('Do you want to log out of your account?'),
                  actions: [
                    FlatButton(
                      onPressed: () async {
                        Navigator.of(_).pop();
                        await me.signOut(context);
                        // await CurrentUser().logout(context);
                      },
                      child: const Text('Sign Out'),
                    ),
                    FlatButton(
                      onPressed: () {
                        Navigator.of(_).pop(true);
                      },
                      child: const Text('Cancel'),
                    )
                  ],
                )
              );
            },
          ),
        ],
      )
    );
  }
}