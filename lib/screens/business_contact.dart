import 'package:flutter/material.dart';
import '../app.dart';

class BusinessContact extends StatefulWidget {
  @override
  _BusinessContactState createState() => _BusinessContactState();
}

class _BusinessContactState extends State<BusinessContact> {

  bool showCallOption = false;
  bool showEmailOption = false;

  @override
  void initState() {
    showCallOption = me.showContactCall;
    showEmailOption = me.showContactEmail;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contact'),
      ),
      body: ListView(
        children: [
          MyAccountDisplay(),
          ListTile(
            leading: Icon(Icons.call),
            title: Text('Call'),
            subtitle:  Text('Show a call option in your profile'),
            trailing: Tooltip(
              message: me.phoneNumber != null ? 'Add call button to your profile' : 'Please add phone number to your account',
              child: Switch.adaptive(
                value: showCallOption,
                onChanged: me.phoneNumber != null ? (bool show) async {
                  setState(() {
                    showCallOption = show;
                  });
                  await me.update({
                    'showContactCall': show
                  }, reload: true);
                } : null,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.email),
            title: Text('Email'),
            subtitle:  Text('Show an email contact button in your profile'),
            trailing: Switch.adaptive(
              value: showEmailOption,
              onChanged:(bool show) async {
                setState(() {
                  showEmailOption = show;
                });
                await me.update({
                  'showContactEmail': show
                }, reload: true);
              },
            ),
          )
        ],
      ),
    );
  }
}