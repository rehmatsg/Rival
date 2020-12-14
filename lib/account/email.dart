import 'package:flutter/material.dart';
import '../app.dart';

class EmailPage extends StatefulWidget {

  const EmailPage({Key key}) : super(key: key);

  @override
  _EmailPageState createState() => _EmailPageState();
}

class _EmailPageState extends State<EmailPage> {

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
        title: const Text('Email Address'),
        actions: [
          IconButton(
            tooltip: 'Recheck verification',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ProfilePhoto(width: 100, height: 100,),
            Container(height: 15,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: TextFormField(
                decoration: InputDecoration(
                  filled: true,
                  labelText: 'Email',
                  errorText: !me.user.emailVerified ? 'Unverified Email. Tap to send verification email' : null
                ),
                readOnly: true,
                onTap: () async {
                  if (!me.user.emailVerified) {
                    try {
                      me.user.sendEmailVerification();
                      await RivalProvider.showToast(
                        text: 'Verification email sent'
                      );
                    } catch (e) {
                      await RivalProvider.showToast(
                        text: 'An error occured',
                      );
                    }
                  } else {
                    await RivalProvider.showToast(
                      text: 'You cannot change your email address'
                    );
                  }
                },
                initialValue: me.doc.data()['email'].toString(),
              ),
            )
          ],
        )
      ),
    );
  }

  Future<void> _refresh() async {
    final bool isEmailVerified = me.user.emailVerified;
    if (isEmailVerified == false) {
      await me.user.reload();
      if (me.user.emailVerified == true && !isEmailVerified) {
        await RivalProvider.showToast(
          text: 'Email verified',
        );
        setState(() {});
        Navigator.pushAndRemoveUntil(context, RivalNavigator(page: Home(),), (route) => false);
      }
    } else {
      await RivalProvider.showToast(
        text: 'Email already verified'
      );
    }
  }

}