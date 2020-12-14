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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
            child: Row(
              children: [
                Tooltip(
                  message: 'Profile Photo',
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        RivalNavigator(page: EditName()),
                      );
                    },
                    child: ProfilePhoto(width: 60, height: 60,),
                  ),
                ),
                Container(width: 15,),
                Flexible(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        child: Text(
                          me.displayName != null ? me.displayName : 'Tap to set your name',
                          style: TextStyle(
                            fontFamily: RivalFonts.feature,
                            fontSize: Theme.of(context).textTheme.headline6.fontSize
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.push(context, RivalNavigator(page: EditName()),),
                      ),
                      GestureDetector(
                        child: Text(
                          me.username != null ? me.username : 'Tap to set your username',
                          style: TextStyle(
                            fontSize: Theme.of(context).textTheme.bodyText2.fontSize
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            RivalNavigator(page: Username()),
                          );
                        },
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.account_circle, size: 30, color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.blueGrey : Colors.white),
            title: Text('Account'),
            visualDensity: VisualDensity.compact,
            onTap: () {
              Navigator.push(
                context,
                RivalNavigator(page: Account()),
              );
            },
          ),
          if (me.isBusinessAccount) ListTile(
            leading: Icon(Icons.business, size: 30, color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.blueGrey : Colors.white),
            title: Text('Business Tools'),
            visualDensity: VisualDensity.compact,
            onTap: () => Navigator.of(context).push(RivalNavigator(page: BusinessPage(),)),
          ),
          if (me.isCreatorAccount) ListTile(
            leading: Icon(Icons.brush, size: 30, color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.blueGrey : Colors.white),
            title: Text('Creator'),
            visualDensity: VisualDensity.compact,
            onTap: () => Navigator.of(context).push(RivalNavigator(page: Creator(),)),
          ),
          ListTile(
            leading: Icon(Icons.notifications_none, size: 30, color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.blueGrey : Colors.white),
            title: Text('Notifications'),
            visualDensity: VisualDensity.compact,
            onTap: () => AppSettings.openNotificationSettings(),
          ),
          ListTile(
            leading: Icon(Icons.account_box, size: 30, color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.blueGrey : Colors.white),
            title: Text('Personal Information'),
            visualDensity: VisualDensity.compact,
            onTap: () {
              Navigator.push(
                context,
                RivalNavigator(page: Info()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.security, size: 30, color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.blueGrey : Colors.white),
            title: Text('Security'),
            visualDensity: VisualDensity.compact,
            onTap: () {
              Navigator.push(
                context,
                RivalNavigator(page: Security()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.person_add, size: 30, color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.blueGrey : Colors.white),
            title: Text('Invite People'),
            visualDensity: VisualDensity.compact,
            onTap: () async {
              if (await Vibration.hasVibrator()) {
                Vibration.vibrate(duration: 5);
              }
              Share.share('Hi, I have just started using the new Rival for sharing awesome photos. Follow my account @${me.doc.data()['username']} by installing Rival from Google Play (https://play.google.com/store/apps/details?id=gillco.rival)', subject: 'Get Rival');
            },
          ),
          ListTile(
            leading: Icon(Icons.lock_outline, size: 30, color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.blueGrey : Colors.white),
            title: Text('Privacy'),
            visualDensity: VisualDensity.compact,
            onTap: () {
              Navigator.push(
                context,
                RivalNavigator(page: PrivacyPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.info_outline, size: 30, color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.blueGrey : Colors.white,),
            title: Text('About'),
            visualDensity: VisualDensity.compact,
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
        ],
      )
    );
  }
}