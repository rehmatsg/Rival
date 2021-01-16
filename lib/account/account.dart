import 'package:flutter/material.dart';

import '../app.dart';

class Account extends StatefulWidget {
  const Account({Key key}) : super(key: key);

  @override
  _AccountState createState() => _AccountState();
}

class _AccountState extends State<Account> {

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
        title: const Text('Account'),
      ),
      body: ListView(
        children: [
          MyAccountDisplay(),
          Container(height: 10,),
          Divider(),
          Container(height: 10,),
          ListTile(
            title: Text(me.displayName != null ? me.displayName : 'Tap to set your name', overflow: TextOverflow.ellipsis,),
            subtitle: const Text('Display Name'),
            onTap: () => Navigator.of(context).push(RivalNavigator(page: const EditName())),
          ),
          ListTile(
            title: const Text('Username'),
            subtitle: Text(me.doc.data()['username'] != null ? '@${me.doc.data()['username']}' : 'Tap to set your username'),
            onTap: () => Navigator.of(context).push(RivalNavigator(page: Username())),
          ),
          ListTile(
            subtitle: Text(me.doc.data()['email'].toString()),
            title: const Text('Email'),
            onTap: () => Navigator.of(context).push(RivalNavigator(page: const EmailPage())),
          ),
          ListTile(
            title: const Text('Bio'),
            subtitle: Text(me.doc.data()['bio'] != null
              ? (me.doc.data()['bio'].toString().length > 50 ? '${me.doc.data()['bio'].toString().substring(0, 50).replaceAll('\n', ' ')}...' : me.doc.data()['bio'].toString().replaceAll('\n', ' '))
              : 'Tap to add bio'
            ),
            onTap: () => Navigator.of(context).push(RivalNavigator(page: const EditBio())),
          ),
          if (!me.isVerified) ListTile(
            title: const Text('Apply for Verification'),
            subtitle: Text('Get verified on Rival'),
            onTap: () => Navigator.of(context).push(RivalNavigator(page: ApplyForVerification())),
          ),
          ListTile(
            title: Text('Account Type'),
            subtitle: Text('${me.data['type'][0].toUpperCase()}${me.data['type'].substring(1)}'),
            trailing: PopupMenuButton(
              itemBuilder: (context) => <PopupMenuEntry>[
                PopupMenuItem(
                  child: Text('Personal'),
                  value: 'personal',
                ),
                PopupMenuItem(
                  child: Text('Business'),
                  value: 'business',
                ),
                PopupMenuItem(
                  child: Text('Creator'),
                  value: 'creator',
                )
              ],
              child: Text('${me.data['type'][0].toUpperCase()}${me.data['type'].substring(1)}'),
              onSelected: (value) {
                if (value == 'business' && !me.isBusinessAccount) Navigator.of(context).push(RivalNavigator(page: BusinessIntro()));
                else if (value == 'creator' && !me.isCreatorAccount) Navigator.of(context).push(RivalNavigator(page: CreatorIntro()));
              },
            ),
          ),
          // ListTile(
          //   title: Text('Language'),
          //   subtitle: Text('Browse Rival in you language'),
          // ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                OutlineButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (_) => AlertDialog(
                        title: Text('Sign Out', style: TextStyle(fontFamily: RivalFonts.feature),),
                        content: const Text('Do you want to sign out of your account?'),
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
                  child: Text('Sign Out'),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MyAccountDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 30, bottom: 10),
          child: Center(
            child: Tooltip(
              message: 'Profile Photo',
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(RivalNavigator(page: const EditName(),)),
                child: ProfilePhoto(height: 100, width: 100),
              ),
            ),
          ),
        ),
        Center(child: Text(me.displayName != null ? me.displayName : 'Tap to set your name', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: Theme.of(context).textTheme.headline5.fontSize, fontFamily: RivalFonts.feature),)),
      ],
    );
  }
}