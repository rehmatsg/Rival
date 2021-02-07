import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';
import 'package:octo_image/octo_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import '../app.dart';

class SignIn extends StatefulWidget {
  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {

  final _formKey = GlobalKey<FormState>();
  TextEditingController euCtrl = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  bool isLoading = false;

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Sign In'),
        elevation: 0.6,
      ),
      body: WillPopScope(
        onWillPop: () async => showDialog(
          context: context,
          child: AlertDialog(
            title: Text('Exit'),
            content: Text('Are you sure you want quit?'),
            actions: [
              FlatButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              FlatButton(
                onPressed: () => SystemNavigator.pop(animated: true),
                child: Text('Exit'),
              )
            ],
          )
        ),
        child: SafeArea(
          child: Center(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Rival', style: TextStyle(fontSize: Theme.of(context).textTheme.headline2.fontSize, fontFamily: RivalFonts.rival),),
                      //Text('Sign In', style: TextStyle(fontSize: Theme.of(context).textTheme.headline3.fontSize, fontFamily: RivalFonts.feature),),
                      Padding(
                        padding: const EdgeInsets.only(left: 15, right: 15, top: 20, bottom: 10),
                        child: Form(
                          key: _formKey,
                          child: TextFormField(
                            controller: euCtrl,
                            decoration: InputDecoration(
                              labelText: 'Email or Username',
                              filled: true,
                            ),
                            onFieldSubmitted: (value) async {
                              if (!isLoading && _formKey.currentState.validate()) await next();
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: SizedBox(
                          width: double.infinity,
                          child: FlatButton(
                            padding: EdgeInsets.symmetric(vertical: 15),
                            color: isLoading ? Colors.indigoAccent.withOpacity(0.3) : Colors.indigoAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(3))
                            ),
                            onPressed: () async {
                              if (!isLoading && _formKey.currentState.validate()) await next();
                            },
                            child: isLoading ? Container(
                              height: 15,
                              width: 15,
                              child: CircularProgressIndicator(strokeWidth: 1,)
                            ) : Text('Next', style: TextStyle(color: Colors.white),),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.of(context).push(RivalNavigator(page: SignUp(), )),
                              child: Text('Don\'t have an account? Sign Up', style: Theme.of(context).textTheme.caption,),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Rival', style: Theme.of(context).textTheme.headline6.copyWith(fontFamily: RivalFonts.rival),),
                        HDivider(),
                        Text('Gill co', style: Theme.of(context).textTheme.headline6.copyWith(fontFamily: RivalFonts.feature),)
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> next() async {
    setState(() {
      isLoading = true;
    });
    String eu = euCtrl.text; // Email, username or phone
    String feature;
    QuerySnapshot querySnapshot;
    if (RegExp(RivalRegex.email).hasMatch(eu)) { // EUP is Email
      querySnapshot = await firestore.collection('users').where('email', isEqualTo: eu.toLowerCase().trim()).get();
      feature = eu;
    } else { // EUP is Username
      querySnapshot = await firestore.collection('users').where('username', isEqualTo: eu.toLowerCase().trim()).get();
      feature = '@$eu';
    }
    if (querySnapshot.docs.length > 0) {
      // RivalUser found
      setState(() {
        isLoading = false;
      });
      Navigator.of(context).push(RivalNavigator(page: EnterPassword(feature: feature, user: RivalUser(doc: querySnapshot.docs.first),), ));
    } else {
      // No user found with email
      setState(() {
        isLoading = false;
      });
      _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text('Account not found')));
    }
  }

}

class EnterPassword extends StatefulWidget {

  EnterPassword({Key key, @required this.feature, this.user}) : super(key: key);
  /// This feature is either Email, Phone Number or Username
  final String feature;
  final RivalUser user;

  @override
  _EnterPasswordState createState() => _EnterPasswordState();
}

class _EnterPasswordState extends State<EnterPassword> {

  final _formKey = GlobalKey<FormState>();
  TextEditingController passwordController = TextEditingController();

  String emailError;
  String passwordError;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: ClipOval(
                  child: OctoImage(
                    image: widget.user.photo,
                    width: 100,
                    height: 100,
                    placeholderBuilder: (context) => Container(
                      height: 100,
                      width: 100,
                      child: CircularProgressIndicator()
                    ),
                  ),
                ),
              ),
              Text(widget.feature, style: TextStyle(fontSize: Theme.of(context).textTheme.headline6.fontSize, fontFamily: RivalFonts.feature),),
              Padding(
                padding: const EdgeInsets.only(left: 15, right: 15, top: 20, bottom: 10),
                child: Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      filled: true,
                      prefixIcon: Icon(Icons.lock),
                      errorText: passwordError
                    ),
                    obscureText: true,
                    onFieldSubmitted: (value) async {
                      await signIn();
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: SizedBox(
                  width: double.infinity,
                  child: FlatButton(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    color: isLoading ? Colors.indigoAccent.withOpacity(0.3) : Colors.indigoAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(3))
                    ),
                    onPressed: () async {
                      await signIn();
                    },
                    child: isLoading ? Container(
                      height: 15,
                      width: 15,
                      child: CircularProgressIndicator(strokeWidth: 1,)
                    ) : Text('Sign In', style: TextStyle(color: Colors.white),),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(RivalNavigator(page: ForgotPassword(), )),
                      child: Text(
                        'Forgot Password?',
                        style: Theme.of(context).textTheme.caption,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> signIn() async {
    String email = widget.user.email.toLowerCase().trim();
    String password = passwordController.text.trim();
    if (_formKey.currentState.validate() && email != null && password != null) {
      try {
        setState(() {
          isLoading = true;
        });
        UserCredential result = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
        DocumentSnapshot myDoc = await firestore.collection('users').doc(result.user.uid).get();

        LocationData location = await getLocation();
        GeoPoint geoPoint = GeoPoint(location.latitude, location.longitude);
        try { // Try to get token from FCM
          String token = await _firebaseMessaging.getToken();

          await sharedPreferences.setString('token', token);

          DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
          Map<String, dynamic> info = {
            'os': Platform.operatingSystem,
          };
          if (Platform.isAndroid) {
            AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
            info.addAll({
              'version': androidInfo.version.baseOS,
              'model': androidInfo.model,
              'device': androidInfo.device,
              'isEmulator': !androidInfo.isPhysicalDevice,
              'manufacturer': androidInfo.manufacturer,
              'token': token
            });
          } else if (Platform.isIOS) {
            IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
            info.addAll({
              'version': iosInfo.systemVersion,
              'device': iosInfo.utsname.machine,
              'model': iosInfo.localizedModel,
              'isEmulator': !iosInfo.isPhysicalDevice,
              'manufacturer': 'Apple',
              'token': token
            });
          }

          int loginTimestamp = new DateTime.now().millisecondsSinceEpoch;
          
          await myDoc.reference.update({
            'token': token,
            'devices.$loginTimestamp': {
              'location': geoPoint,
              'timestamp': loginTimestamp,
              'device': info,
              'token': token
            },
            'loginHistory.$loginTimestamp': {
              'location': geoPoint,
              'timestamp': loginTimestamp,
              'device': info,
              'token': token
            }
          });
          me = Me();
          me.firebaseUser = result.user;
          await me.init();
          await analytics.logLogin();
          await RivalProvider.showToast(
            text: 'Welcome $email',
          );
          if (!result.user.emailVerified) {
            result.user.sendEmailVerification();
            await RivalProvider.showToast(
              text: 'Please verify your email',
            );
          }
          Navigator.pushAndRemoveUntil(context, RivalNavigator(page: LandingPage(), ), (route) => false);
        } catch (e) {
          //print('Error Logging In: $e');
          await RivalProvider.showToast(
            text: 'Failed to sign in. Please try again later.',
          );
          await FirebaseAuth.instance.signOut();
          SystemNavigator.pop();
        }
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        switch (e.code) {
          case 'wrong-password':
            setState(() {
              passwordError = 'Email and password do not match';
            });
            break;
          case 'invalid-email':
            setState(() {
              emailError = 'Invalid email';
            });
            break;
          case 'user-not-found':
            setState(() {
              emailError = 'No account exists with this email';
            });
            break;
          case 'user-disabled':
            setState(() {
              passwordError = 'Failed to login. Account disabled';
            });
            break;
          default:
            setState(() {
              passwordError = 'Some error occured on our side. Please try again later.';
            });
            break;
        }
      }
    }
  }

}