import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app.dart';

class ForgotPassword extends StatefulWidget {
  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {

  final FirebaseAnalytics analytics = FirebaseAnalytics();

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  String emailError;

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
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
                child: TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    filled: true,
                    labelText: 'Email',
                    helperText: 'Enter the email associated with your account'
                  ),
                  validator: validateEmail,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: OutlinedButton(
                    onPressed: () {
                      _resetPassword();
                    },
                    child: const Text('Send Reset Link'),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  String validateEmail(String value) {
    const String pattern = r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    final RegExp regex = RegExp(pattern);
    if (!regex.hasMatch(value)) {
      emailError = 'Invalid Email';
      emailError = null;
      return emailError;
    } else if (emailError != null) {
      final emailErrorL = emailError;
      emailError = null;
      return emailErrorL;
    } else {
      emailError = null;
      return null;
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text;

    if (_formKey.currentState.validate() && email != null) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        await RivalProvider.showToast(
          text: 'Link sent to $email',
        );
        await analytics.logEvent(name: 'password_reset_successful');
      } catch (e) {
        switch (e.code.toString()) {
          case 'ERROR_INVALID_EMAIL':
            setState(() {
              emailError = 'Invalid email';
              _formKey.currentState.validate();
            });
            break;
          default:
            setState(() {
              emailError = 'An error occured';
              _formKey.currentState.validate();
            });
            break;
        }
      }
    }
  }

}