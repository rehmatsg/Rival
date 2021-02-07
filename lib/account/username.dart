import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app.dart';

class Username extends StatefulWidget {

  Username({
    Key key
  }) : super(key: key);

  @override
  _UsernameState createState() => _UsernameState();
}

class _UsernameState extends State<Username> {

  TextEditingController _controller = TextEditingController();
  String usernameError;

  bool usernameEditable = true;
  bool isLoading = false;

  List usernames;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    if (me.username != null) {
      usernameEditable = false;
      _controller.text = me.username;
    }
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
        title: Text('Username'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ProfilePhoto(width: 100, height: 100,),
            Container(height: 15,),
            Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                child: TextFormField(
                  controller: _controller,
                  decoration: InputDecoration(
                    filled: true,
                    labelText: 'Userame',
                    helperText: usernameEditable ? 'Choose a unique username' : 'You cannot change your username',
                    errorText: usernameError
                  ),
                  onChanged: (value) {
                    setState(() {
                      usernameError = null;
                    });
                  },
                  validator: validateUsername,
                  readOnly: !usernameEditable,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (usernameEditable) OutlineButton(
                    child: isLoading
                    ? Container(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 1,),)
                    : Text('Save'),
                    onPressed: _save,
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  String validateUsername(value) {
    Pattern pattern = r"^(?=[a-zA-Z0-9._]{6,16}$)(?!.*[_.]{2})[^_.].*[^_.]$";
    RegExp regex = new RegExp(pattern);
    if (!regex.hasMatch(value)) {
      return 'Invalid username';
    } else {
      return null;
    }
  }

  _save() async {
    String username = _controller.text.trim().toLowerCase();
    if (username != null && username != "" && usernameEditable && _formKey.currentState.validate()) {
      setState(() {
        isLoading = true;
      });
      if (usernames == null) {
        await _loadUsernames();
      }
      if (usernames.contains(username)) {
        await RivalProvider.showToast(
          text: 'Username already taken',
        );
        setState(() {
          isLoading = false;
          usernameError = "This username is already taken";
        });
      } else {
        Loader.show(
          context,
          function: () async {
            await me.update({
              'username': username
            }, reload: true);
            await firestore.collection('rival').doc('general').update({
              'usernames': FieldValue.arrayUnion([username])
            });
          },
          onComplete: () {
            RivalProvider.showToast(
              text: 'Updated Username',
            );
            setState(() {
              usernameEditable = false;
              isLoading = false;
            });
            Navigator.pushAndRemoveUntil(context, RivalNavigator(page: Home(),), (route) => false);
          }
        );
      }
    } else if (!usernameEditable) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _loadUsernames() async {
    DocumentReference rivalUsernamesRef = firestore.collection('rival').doc('general');
    usernames = (await rivalUsernamesRef.get()).data()['usernames'];
    rivalUsernamesRef.snapshots().listen((updatedDoc) {
      usernames = updatedDoc.data()['usernames'];
    });
  }

}