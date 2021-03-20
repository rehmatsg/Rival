import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../app.dart';


class PrivacyPage extends StatefulWidget {

  const PrivacyPage({Key key}) : super(key: key);

  @override
  _PrivacyPageState createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {

  final FirebaseAnalytics analytics = FirebaseAnalytics();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Privacy'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              title: Text('Private Account'),
              trailing: Switch.adaptive(
                onChanged: (bool value) => showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Switch to ${me.private ? 'public' : 'private'} account'),
                    content: Text('Are you sure you want to switch to ${me.private ? 'public' : 'private'} account?'),
                    actions: [
                      TextButton(
                        onPressed: Navigator.of(context).pop,
                        child: Text('Cancel')
                      ),
                      TextButton(
                        onPressed: () async {
                          await me.update({
                            'private': value
                          }, reload: true);
                          setState(() { });
                          Navigator.of(context).maybePop();
                          Navigator.pushAndRemoveUntil(context, RivalNavigator(page: Home(),), (route) => false);
                          await RivalProvider.showToast(
                            text: 'Switched to ${me.private ? 'public' : 'private'} Account'
                          );
                        },
                        child: Text('Switch')
                      )
                    ],
                  )
                ),
                value: me.private,
              ),
            ),
            ListTile(
              title: const Text('Blocked People'),
              subtitle: const Text('Manage people you have blocked'),
              onTap: () => Navigator.of(context).push(RivalNavigator(page: Blocked(),)),
            ),
            ListTile(
              title: const Text('Devices'),
              subtitle: const Text('Manage devices with access to your account'),
              onTap: () => Navigator.of(context).push(RivalNavigator(page: ManageDevices(),)),
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
            ListTile(
              title: const Text('New followers'),
              subtitle: Text('Manually approve new followers'),
              trailing: Switch.adaptive(
                value: !me.doc.data()['allow_new_followers'],
                onChanged: (value) async {
                  await me.update({
                    'allow_new_followers': !value
                  }, reload: true);
                  setState(() {});
                  RivalProvider.showToast(
                    text: 'Saved Changes'
                  );
                }
              ),
            ),
            ListTile(
              title: const Text('My Liked Posts'),
              subtitle: const Text('See posts you have liked'),
              onTap: () => Navigator.of(context).push(RivalNavigator(page: LikedPosts(),)),
            ),
            ListTile(
              title: const Text('My Comments'),
              subtitle: const Text('See posts you have commented on'),
              onTap: () => Navigator.of(context).push(RivalNavigator(page: CommentedPosts(),)),
            ),
            // const Divider(),
            // ListTile(
            //   title: const Text('Analytics'),
            //   subtitle: const Text('Tap to know more'),
            //   onTap: () => showDialog(
            //     context: context,
            //     builder: (context) => AlertDialog(
            //       title: const Text('Analyics'),
            //       content: const Text('Enabling analytics will help us make a better user experience for you. The data is stored internally and not linked to your account. Analytics are enabled by default.'),
            //       actions: [
            //         TextButton(
            //           onPressed: () async {
            //             Navigator.of(context).pop();
            //             await analytics.setAnalyticsCollectionEnabled(false);
            //             _scaffoldKey.currentState.showSnackBar(const SnackBar(
            //               content: Text('Analytics Disabled')
            //             ));
            //           },
            //           child: const Text('Disable')
            //         ),
            //         TextButton(
            //           onPressed: () async {
            //             Navigator.of(context).pop();
            //             await analytics.setAnalyticsCollectionEnabled(true);
            //             _scaffoldKey.currentState.showSnackBar(const SnackBar(
            //               content: Text('Thank You. Your data will remain secure.')
            //             ));
            //           },
            //           child: const Text('Enable')
            //         )
            //       ],
            //     ),
            //   ),
            // ),
            // ListTile(
            //   title: const Text('Reset Analytics'),
            //   subtitle: const Text('Clear analytics collected from your device'),
            //   onTap: () => showDialog(
            //     context: context,
            //     builder: (context) => AlertDialog(
            //       title: const Text('Clear Analytics Data'),
            //       content: const Text('Do you want to clear all data collected from your device?'),
            //       actions: [
            //         TextButton(
            //           onPressed: () {
            //             Navigator.of(context).pop();
            //           },
            //           child: const Text('Cancel')
            //         ),
            //         TextButton(
            //           onPressed: () async {
            //             Navigator.of(context).pop();
            //             await analytics.resetAnalyticsData();
            //             _scaffoldKey.currentState.showSnackBar(const SnackBar(
            //               content: Text('Cleared all data from this device')
            //             ));
            //           },
            //           child: const Text('Clear')
            //         )
            //       ],
            //     ),
            //   ),
            // )
          ],
        ),
      ),
    );
  }
}