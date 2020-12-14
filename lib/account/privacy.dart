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
            MyAccountDisplay(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Divider(),
            ),
            ListTile(
              title: const Text('Account Privacy'),
              subtitle: me.doc.data()['private'] == true ? const Text('Private') : const Text('Public'),
              onTap: () => showDialog(
                context: context,
                child: AlertDialog(
                  title: Text('Account Privacy'),
                  content: Text('Making an account private hides your posts from people who don\'t follow you'),
                  actions: [
                    FlatButton(
                      onPressed: () async {
                        await firestore.collection('users').doc(me.uid).update({
                          'private': false
                        });
                        setState(() { });
                        Navigator.of(context).maybePop();
                        Navigator.pushAndRemoveUntil(context, RivalNavigator(page: Home(),), (route) => false);
                        await RivalProvider.showToast(
                          text: 'Switched to Public Account',
                        );
                      },
                      child: Text('Public')
                    ),
                    FlatButton(
                      onPressed: () async {
                        await firestore.collection('users').doc(me.uid).update({
                          'private': true
                        });
                        setState(() { });
                        Navigator.of(context).maybePop();
                        Navigator.pushAndRemoveUntil(context, RivalNavigator(page: Home(),), (route) => false);
                        await RivalProvider.showToast(
                          text: 'Switched to Private Account'
                        );
                      },
                      child: Text('Private')
                    )
                  ],
                )
              ),
            ),
            ListTile(
              title: const Text('Blocked People'),
              subtitle: const Text('Manage people you have blocked'),
              onTap: () => Navigator.of(context).push(RivalNavigator(page: Blocked(),)),
            ),
            ListTile(
              title: const Text('New followers'),
              subtitle: Text(me.doc.data()['allow_new_followers'] == true ? 'Allow everyone' : 'Only which I approve'),
              onTap: () => showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('New Followers'),
                  content: const Text('Do you want to allow people to follow you directly or make a request?'),
                  actions: [
                    FlatButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await me.update({
                          'allow_new_followers': true
                        });
                        await me.reload();
                        setState(() {});
                        RivalProvider.showToast(
                          text: 'Saved Changes'
                        );
                      },
                      child: const Text('Allow All')
                    ),
                    FlatButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await me.update({
                          'allow_new_followers': false
                        });
                        await me.reload();
                        setState(() {});
                        RivalProvider.showToast(
                          text: 'Saved Changes'
                        );
                      },
                      child: const Text('Only Approved')
                    )
                  ],
                ),
              ),
            ),
            ListTile(
              title: const Text('My Liked Posts'),
              subtitle: const Text('Manage posts you have liked'),
              onTap: () => Navigator.of(context).push(RivalNavigator(page: LikedPosts(),)),
            ),
            ListTile(
              title: const Text('My Comments'),
              subtitle: const Text('Manage posts you have commented on'),
              onTap: () => Navigator.of(context).push(RivalNavigator(page: CommentedPosts(),)),
            ),
            const Divider(),
            ListTile(
              title: const Text('Analytics'),
              subtitle: const Text('Tap to know more'),
              onTap: () => showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Enable Analyics'),
                  content: const Text('Enabling analytics will help us make a better user experience for you. The data is stored internally and not linked to your account. Analytics are enabled by default.'),
                  actions: [
                    FlatButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await analytics.setAnalyticsCollectionEnabled(false);
                        _scaffoldKey.currentState.showSnackBar(const SnackBar(
                          content: Text('Analytics Disabled')
                        ));
                      },
                      child: const Text('Disable')
                    ),
                    FlatButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await analytics.setAnalyticsCollectionEnabled(true);
                        _scaffoldKey.currentState.showSnackBar(const SnackBar(
                          content: Text('Thank You. Your data will remain secure.')
                        ));
                      },
                      child: const Text('Enable')
                    )
                  ],
                ),
              ),
            ),
            ListTile(
              title: const Text('Reset Analytics'),
              subtitle: const Text('Clear analytics collected from your device'),
              onTap: () => showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Analytics Data'),
                  content: const Text('Do you want to clear all data collected from your device to help us make a better user experience for you?'),
                  actions: [
                    FlatButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel')
                    ),
                    FlatButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await analytics.resetAnalyticsData();
                        _scaffoldKey.currentState.showSnackBar(const SnackBar(
                          content: Text('Cleared all data from this device')
                        ));
                      },
                      child: const Text('Clear')
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}