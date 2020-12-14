import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import '../app.dart';

class ChangePassword extends StatefulWidget {
  @override
  _ChangePasswordState createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {

  final _formKey = GlobalKey<FormState>();
  final FirebaseAnalytics analytics = FirebaseAnalytics();

  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  String oldPasswordError;
  String newPasswordError;
  
  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Rival', style: TextStyle(fontFamily: RivalFonts.rival, fontSize: 60),),
            Container(height: 20,),
            Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: TextFormField(
                        controller: _oldPasswordController,
                        decoration: const InputDecoration(
                          filled: true,
                          labelText: 'Old Password',
                        ),
                        validator: validateOldPassword,
                        obscureText: true,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: TextFormField(
                        controller: _newPasswordController,
                        decoration: const InputDecoration(
                          filled: true,
                          labelText: 'New Password',
                          helperText: 'Min 8 and Max 16 characters'
                        ),
                        validator: validateNewPassword,
                        obscureText: true,
                      ),
                    )
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 10),
              child: Row(
                children: <Widget>[
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        RivalNavigator(page: ForgotPassword()),
                      );
                    },
                    child: const Text('Forgot Password?'),
                  )
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: OutlineButton(
                    onPressed: () {
                      _resetPassword();
                    },
                    child: const Text('Change password'),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  String validateOldPassword(String value) {
    if  (oldPasswordError != null) {
      final oldPasswordErrorL = oldPasswordError;
      oldPasswordError = null;
      return oldPasswordErrorL;
    } else {
      oldPasswordError = null;
      return null;
    }
  }

  String validateNewPassword(String value) {
    if (value.length < 8) {
      return 'Minimum 8 characters';
    } else if (value.length > 16) {
      return 'Maximum 16 characters';
    } else if (newPasswordError != null) {
      final newPasswordErrorL = newPasswordError;
      newPasswordError = null;
      return newPasswordErrorL;
    } else if (value == _oldPasswordController.text) {
      return 'Both passwords are same';
    } else {
      newPasswordError = null;
      return null;
    }
  }

  Future<void> _resetPassword() async {
    final newPassword = _newPasswordController.text;
    final oldPassword = _oldPasswordController.text;

    if (_formKey.currentState.validate() && oldPassword != null && newPassword != null) {
      try {

        await analytics.logEvent(name: 'password_changed');

        await me.user.updatePassword(newPassword);

        await RivalProvider.showToast(
          text: 'Password changed',
        );
        _newPasswordController.clear();
        _oldPasswordController.clear();
      } catch (e) {
        switch (e.code.toString()) {
          case 'weak-password':
            setState(() {
              newPasswordError = 'Weak password';
              _formKey.currentState.validate();
            });
            break;
          case 'requires-recent-login':
            setState(() {
              newPasswordError = 'This action requires recent login';
              _formKey.currentState.validate();
            });
            break;
          default:
            setState(() {
              oldPasswordError = "An error occured. Please try again later";
              _formKey.currentState.validate();
            });
            break;
        }
      }
    }
  }

}