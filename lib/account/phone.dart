import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../app.dart';

class LinkPhoneNumber extends StatefulWidget {
  @override
  _LinkPhoneNumberState createState() => _LinkPhoneNumberState();
}

class _LinkPhoneNumberState extends State<LinkPhoneNumber> {

  final _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  var phoneNumberFormatter = MaskTextInputFormatter(mask: '+91 ##### #####', filter: { "#": RegExp(r'[0-9]') });

  TextEditingController _controller = TextEditingController();
  bool isLoading = false;
  bool locked = false;

  String phoneError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Phone Number'),
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
                    labelText: 'Phone Number',
                    hintText: '+91 ##### #####',
                    errorText: phoneError
                  ),
                  readOnly: locked,
                  keyboardType: TextInputType.phone,
                  validator: verifyPhone,
                  inputFormatters: [
                    phoneNumberFormatter
                  ],
                  onChanged: (value) {
                    setState(() {
                      phoneError = null;
                    });
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlineButton(
                    onPressed: isLoading ? null : _sendOTP,
                    child: isLoading ? Container(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black : Colors.white),)
                    ) : Text('Send OTP'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10))
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  String verifyPhone(String value) {
    Pattern pattern = r'\+?\d[\d ]{6}[ \d]{6}\d';
    RegExp regex = new RegExp(pattern);
    if (!regex.hasMatch(value) || value.trim() == "") {
      setState(() {
        phoneError = "Invalid Phone Number";
      });
      return phoneError;
    } else {
      phoneError = null;
      return null;
    }
  }

  _sendOTP() async {
    RivalProvider.vibrate();
    setState(() {
      isLoading = true;
      locked = true;
    });
    if (_formKey.currentState.validate()) {
      String phone = _controller.text;
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await me.user.linkWithCredential(credential);
          setState(() {
            locked = true;
            isLoading = false;
          });
          await RivalProvider.showToast(text: 'Phone Number Verified');
          Navigator.of(context).pushAndRemoveUntil(RivalNavigator(page: Home(),), (route) => false);
        },
        verificationFailed: (FirebaseAuthException e) {
          print(e);
          setState(() {
            isLoading = false;
            locked = false;
          });
          _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text('Failed to verify. Please try again later')));
        },
        codeSent: (String verificationId, int resendToken) {
          _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text('OTP sent to $phone. Trying to Auto-Verify')));
          //Navigator.of(context).push(RivalNavigator(page: EnterOTP(verificationId: verificationId,), ));
        },
        codeAutoRetrievalTimeout: (String verificationId) async {
          await RivalProvider.showToast(text: 'Could not auto-verify');
          Navigator.of(context).push(RivalNavigator(page: EnterOTP(verificationId: verificationId, phoneNumber: phoneNumberFormatter.getUnmaskedText(),), ));
        },
      );
    } else {
      setState(() {
        isLoading = false;
        locked = false;
      });
    }
  }

}

class EnterOTP extends StatefulWidget {

  final String verificationId;
  final int resendToken;
  final String phoneNumber;

  const EnterOTP({Key key, @required this.verificationId, this.resendToken, this.phoneNumber}) : super(key: key);

  @override
  _EnterOTPState createState() => _EnterOTPState();
}

class _EnterOTPState extends State<EnterOTP> {

  final _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  var otpFormatter = MaskTextInputFormatter(mask: '### ###', filter: { "#": RegExp(r'[0-9]') });

  TextEditingController _controller = TextEditingController();
  bool isLoading = false;
  bool locked = false;

  String otpError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Phone Number'),
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
                    labelText: 'OTP',
                    hintText: '### ###',
                    errorText: otpError
                  ),
                  readOnly: locked,
                  keyboardType: TextInputType.phone,
                  validator: verifyOTP,
                  inputFormatters: [
                    otpFormatter
                  ],
                  onChanged: (value) {
                    setState(() {
                      otpError = null;
                    });
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlineButton(
                    onPressed: isLoading ? null : _verifyOTP,
                    child: isLoading ? Container(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black : Colors.white),)
                    ) : Text('Verify OTP'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10))
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  String verifyOTP(String value) {
    Pattern pattern = r'[\d]{3}[ ]{1}[\d]{3}';
    RegExp regex = new RegExp(pattern);
    if (!regex.hasMatch(value) || value.trim() == "") {
      setState(() {
        otpError = "Invalid OTP";
      });
      return otpError;
    } else {
      otpError = null;
      return null;
    }
  }

  _verifyOTP() async {
    setState(() {
      isLoading = false;
      locked = true;
    });
    try {
      AuthCredential credential = PhoneAuthProvider.credential(verificationId: widget.verificationId, smsCode: otpFormatter.getUnmaskedText());
      await me.user.linkWithCredential(credential);
      await me.reference.update({
        'phoneNumber': me.user.phoneNumber
      });
      await me.reload();
      await me.user.reload();
      print(credential);
      await RivalProvider.showToast(text: 'Phone Number Linked');
      Navigator.of(context).pushAndRemoveUntil(RivalNavigator(page: Home(),), (route) => false);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'provider-already-linked':
          setState(() {
            otpError = 'Phone Number is already linked';
          });
          break;
        case 'invalid-credential':
          setState(() {
            otpError = 'Phone Number is already linked';
          });
          break;
        case 'credential-already-in-use':
          setState(() {
            otpError = 'Phone Number in user by another account';
          });
          break;
        case 'operation-not-allowed':
          setState(() {
            otpError = 'Oops! Could not verify. Please try again later';
          });
          break;
        case 'invalid-verification-code':
          setState(() {
            otpError = 'Invalid OTP';
          });
          break;
        case 'invalid-verification-id':
          setState(() {
            otpError = 'Invalid OTP';
          });
          break;
        default:
          setState(() {
            otpError = 'An unknown error occured. Please try again later';
          });
          break;
      }
    }
    setState(() {
      isLoading = false;
      locked = false;
    });
  }

}

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue
  ) {
    final int newTextLength = newValue.text.length;
    int selectionIndex = newValue.selection.end;
    int usedSubstringIndex = 0;
    final StringBuffer newText = StringBuffer();
    if (newTextLength >= 1) {
      newText.write('(');
      if (newValue.selection.end >= 1)
        selectionIndex++;
    }
    if (newTextLength >= 4) {
      newText.write(newValue.text.substring(0, usedSubstringIndex = 3) + ') ');
      if (newValue.selection.end >= 3)
        selectionIndex += 2;
    }
    if (newTextLength >= 7) {
      newText.write(newValue.text.substring(3, usedSubstringIndex = 6) + '-');
      if (newValue.selection.end >= 6)
        selectionIndex++;
    }
    if (newTextLength >= 11) {
      newText.write(newValue.text.substring(6, usedSubstringIndex = 10) + ' ');
      if (newValue.selection.end >= 10)
        selectionIndex++;
    }
    // Dump the rest.
    if (newTextLength >= usedSubstringIndex)
      newText.write(newValue.text.substring(usedSubstringIndex));
    return TextEditingValue(
      text: newText.toString(),
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}