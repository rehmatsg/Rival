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
              onSelected: (value) async {
                if (value == 'business' && !me.isBusinessAccount) Navigator.of(context).push(RivalNavigator(page: BusinessIntro()));
                else if (value == 'creator' && !me.isCreatorAccount) Navigator.of(context).push(RivalNavigator(page: CreatorIntro()));
                else if (value == 'personal') {
                  await Loader.show(
                    context,
                    function: () async {
                      await me.update({
                        'type': 'personal'
                      }, reload: true);
                    },
                    onComplete: () => Navigator.of(context).pushAndRemoveUntil(RivalNavigator(page: Home()), (route) => false),
                    disableBackButton: true
                  );
                }
              },
            ),
          ),
          // ListTile(
          //   title: Text('Language'),
          //   subtitle: Text('Browse Rival in you language'),
          // ),
        ],
      ),
    );
  }
}