import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import '../app.dart';

Future<DocumentSnapshot> getUsernames;

class SignUp extends StatefulWidget {
  SignUp({Key key}) : super(key: key);

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  PageController pageCtrl = PageController();

  TextEditingController usernameCtrl = TextEditingController();
  TextEditingController emailCtrl = TextEditingController();
  TextEditingController passwordCtrl = TextEditingController();
  TextEditingController password2Ctrl = TextEditingController();

  final usernameForm = GlobalKey<FormState>();
  final step2Form = GlobalKey<FormState>();

  String emailError;
  String passwordError;
  String password2Error;
  String usernameError;

  bool isStep2Loading = false;
  bool isUsernameLoading = false;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(),
      body: PageView(
        controller: pageCtrl,
        physics: NeverScrollableScrollPhysics(),
        children: [
          Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Create Account', style: TextStyle(fontSize: Theme.of(context).textTheme.headline4.fontSize, fontFamily: RivalFonts.feature),),
                Padding(
                  padding: const EdgeInsets.only(left: 15, right: 15, top: 20, bottom: 10),
                  child: Form(
                    key: usernameForm,
                    child: TextFormField(
                      controller: usernameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        filled: true,
                        errorText: usernameError,
                      ),
                      validator: validateUsername,
                      onChanged: (value) {
                        if (value.trim() != "" && usernameError != null) {
                          setState(() {
                            usernameError = null;
                          });
                        }
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: SizedBox(
                    width: double.maxFinite,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: 15
                        ),
                        backgroundColor: isUsernameLoading ? Colors.indigoAccent.withOpacity(0.3) : Colors.indigoAccent,
                      ),
                      onPressed: () async {
                        if (!isUsernameLoading && usernameForm.currentState.validate()) {
                          setState(() {
                            isUsernameLoading = true;
                          });
                          if (getUsernames == null) {
                            DocumentReference rivalUsernamesRef = firestore.collection('rival').doc('general');
                            getUsernames = rivalUsernamesRef.get();
                          }
                          List usernames = (await getUsernames).data()['usernames'];
                          if (!usernames.contains(usernameCtrl.text.toLowerCase().trim())) {
                            setState(() {
                              isUsernameLoading = false;
                            });
                            pageCtrl.animateToPage(1, curve: Curves.easeInOut, duration: Duration(milliseconds: 300));
                          } else {
                            isUsernameLoading = false;
                            usernameError = 'This username is already taken';
                            setState(() { });
                          }
                        }
                      },
                      child: isUsernameLoading ? Container(
                        height: 15,
                        width: 15,
                        child: CustomProgressIndicator(strokeWidth: 1,)
                      ) : Text('Next', style: TextStyle(color: Colors.white),),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: Navigator.of(context).pop,
                        child: Text('Already have an account? Sign In', style: Theme.of(context).textTheme.caption,)
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            child: Form(
              key: step2Form,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Create Account', style: TextStyle(fontSize: Theme.of(context).textTheme.headline4.fontSize, fontFamily: RivalFonts.feature),),
                  Padding(
                    padding: const EdgeInsets.only(left: 15, right: 15, top: 20, bottom: 10),
                    child: TextFormField(
                      controller: emailCtrl,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        filled: true,
                        errorText: emailError,
                      ),
                      validator: validateEmail,
                      onChanged: (value) {
                        if (value.trim() != "" && emailError != null) {
                          setState(() {
                            emailError = null;
                          });
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 15, right: 15, top: 5, bottom: 10),
                    child: TextFormField(
                      controller: passwordCtrl,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        filled: true,
                        errorText: passwordError
                      ),
                      validator: validatePassword,
                      obscureText: true,
                      onChanged: (value) {
                        if (value.trim() != "" && passwordError != null) {
                          setState(() {
                            passwordError = null;
                          });
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 15, right: 15, top: 5, bottom: 10),
                    child: TextFormField(
                      controller: password2Ctrl,
                      decoration: InputDecoration(
                        labelText: 'Repeat Password',
                        filled: true,
                        errorText: password2Error
                      ),
                      obscureText: true,
                      onChanged: (value) {
                        if (value.trim() != "" && password2Error != null) {
                          setState(() {
                            password2Error = null;
                          });
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    child: Wrap(
                      children: [
                        Text(
                          'By signing up you confirm that you have read and accepted our Terms and Conditions',
                          style: Theme.of(context).textTheme.caption,
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: SizedBox(
                      width: double.maxFinite,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: 15
                          ),
                          backgroundColor: isUsernameLoading ? Colors.indigoAccent.withOpacity(0.3) : Colors.indigoAccent,
                        ),
                        onPressed: isStep2Loading ? null : _signUp,
                        child: isStep2Loading ? Container(
                          height: 15,
                          width: 15,
                          child: CustomProgressIndicator(strokeWidth: 1,)
                        ) : Text('Sign Up', style: TextStyle(color: Colors.white),),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String validateEmail(String value) {
    Pattern pattern = RivalRegex.email;
    RegExp regex = new RegExp(pattern);
    if (!regex.hasMatch(value)) {
      return 'Invalid Email';
    } else {
      emailError = null;
      return null;
    }
  }

  String validateUsername(value) {
    Pattern pattern = r"^(?=[a-zA-Z0-9._]{4,16}$)(?!.*[_.]{2})[^_.].*[^_.]$";
    RegExp regex = new RegExp(pattern);
    RegExp p1 = new RegExp(r'([a-zA-Z0-9._])');
    RegExp p2 = new RegExp(r'([a-zA-Z0-9._]{4,16})');
    if (!regex.hasMatch(value)) {
      if (!p1.hasMatch(value)) {
        return 'Use only alphanumerics, underscore and dots';
      } else if (!p2.hasMatch(value)) {
        return 'Minimum 4 and max 16 characters';
      } else return 'Invalid username';
    } else {
      return null;
    }
  }

  String validatePassword(String value) {
    Pattern pattern = r"^(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[a-zA-Z]).{8,}$";
    RegExp regex = new RegExp(pattern);
    if (!regex.hasMatch(value)) {
      RegExp regex2 = new RegExp(r'^(?=.*[a-zA-Z]).{8,}$');
      if (!regex2.hasMatch(value)) {
        passwordError = 'Password must be atleast 8 characters long';
      } else {
        passwordError = 'Password should be a mix of alphabets and numbers';
      }
      setState(() { });
      return passwordError;
    } else {
      passwordError = null;
      return null;
    }
  }

  Future<void> _signUp() async {

    setState(() {
      isStep2Loading = true;
    });

    String username = usernameCtrl.text.toLowerCase().trim();
    String email = emailCtrl.text.toLowerCase().trim();
    String password = passwordCtrl.text;
    String password2 = password2Ctrl.text;

    if (!step2Form.currentState.validate()) {
      setState(() {
        isStep2Loading = false;
      });
      return;
    }

    // Check Username
    getUsernames = firestore.collection('rival').doc('general').get();
    List usernames = (await getUsernames).data()['usernames'];
    if (usernames.contains(username)) {
      isStep2Loading = false;
      usernameError = 'This username is already taken';
      pageCtrl.animateToPage(0, curve: Curves.easeInOut, duration: Duration(milliseconds: 300));
      setState(() { });
      return;
    }

    // Check Email
    QuerySnapshot querySnapshot = await firestore.collection('users').where('email', isEqualTo: email).get();
    if (querySnapshot.docs.isNotEmpty) {
      emailError = 'This email is already taken';
      isStep2Loading = false;
      setState(() { });
      return;
    }

    // Check Password
    if (password != password2) {
      password2Error = 'Passwords do not match';
      isStep2Loading = false;
      setState(() { });
      return;
    }

    // All good
    String result = await signUp(email: email, password: password, username: username);
    switch (result) {
      case 'email-already-in-use':
        emailError = 'Email already taken';
        isStep2Loading = false;
        setState(() { });
        break;
      case 'invalid-email':
        emailError = 'Invalid Email';
        isStep2Loading = false;
        setState(() { });
        break;
      case 'operation-not-allowed':
        emailError = 'Operation not allowed';
        isStep2Loading = false;
        setState(() { });
        break;
      case 'weak-password':
        passwordError = 'Weak password';
        isStep2Loading = false;
        setState(() { });
        break;
      case 'permission-not-allowed':
        emailError = 'Location permission denied';
        isStep2Loading = false;
        setState(() { });
        break;
      case 'success':
        setState(() {
          isStep2Loading = false;
        });
        Navigator.pushAndRemoveUntil(context, RivalNavigator(page: SetupAccount(), ), (route) => false);
        break;
      default:
        isStep2Loading = false;
        setState(() {});
        RivalProvider.showToast(text: 'Failed to login');
        SystemNavigator.pop(animated: true);
    }
  }

  Future<String> signUp({
    @required String username,
    @required String email,
    @required String password,
  }) async {
    // try {
      LocationData location = await getLocation();
      GeoPoint geoPoint = GeoPoint(location.latitude, location.longitude);

      if (location == null) {
        print('Location denied');
        RivalProvider.showToast(text: 'Location permission is required');
        return 'permission-not-allowed';
      }

      try {
        UserCredential result = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
        await result.user.sendEmailVerification();

        DocumentSnapshot myDoc = await firestore.collection('users').doc(result.user.uid).get();
        String token = await _firebaseMessaging.getToken();

        await sharedPreferences.setString('token', token);

        await result.user.updateProfile(displayName: username);

        DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        Map<String, dynamic> info = {
          'os': Platform.operatingSystem,
          'version': Platform.operatingSystemVersion,
        };
        if (Platform.isAndroid) {
          AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
          info.addAll({
            'model': androidInfo.model,
            'device': androidInfo.device,
            'isEmulator': !androidInfo.isPhysicalDevice,
            'manufacturer': androidInfo.manufacturer,
            'token': token
          });
        } else if (Platform.isIOS) {
          IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
          info.addAll({
            'device': iosInfo.utsname.machine,
            'model': iosInfo.localizedModel,
            'isEmulator': !iosInfo.isPhysicalDevice,
            'manufacturer': 'Apple',
            'token': token
          });
        }

        await myDoc.reference.set({
          'uid': result.user.uid,
          'displayName': username,
          'photoUrl': result.user.photoURL,
          'phoneNumber': result.user.phoneNumber,
          'email': result.user.email,
          'token': token,
          'followers': [],
          'following': [],
          'bookmarks': [],
          'blocked': [],
          'posts': [],
          'username': username,
          'verified': false,
          'account_created': result.user.metadata.creationTime.millisecondsSinceEpoch,
          'bio': null,
          'interests': {},
          'private': false,
          //'liked': [],
          'category': null,
          'gender': null,
          'dob': null,
          'allow_new_followers': true,
          'follow_requests': {},
          'story': {},
          'type': 'personal',
          'visits': [],
          'showContactCall': false,
          'showContactEmail': false,
          'tagsSubscribed': [],
          'subscriptions': [],
          'devices': {
            result.user.metadata.creationTime.millisecondsSinceEpoch.toString(): {
              'location': geoPoint,
              'timestamp': result.user.metadata.creationTime.millisecondsSinceEpoch,
              'device': info,
              'token': token
            }
          },
          'loginHistory': {
            result.user.metadata.creationTime.millisecondsSinceEpoch.toString(): {
              'location': geoPoint,
              'timestamp': result.user.metadata.creationTime.millisecondsSinceEpoch,
              'device': info,
              'token': token
            }
          }
        });

        await firestore.collection('rival').doc('general').set({
          'usernames': FieldValue.arrayUnion([username.toLowerCase().trim()])
        });

        me = Me();
        me.firebaseUser = result.user;
        await me.init();

        isStep2Loading = false;
        await RivalProvider.showToast(
          text: 'Welcome $email',
        );
        await RivalProvider.showToast(
          text: 'Verification email sent.',
        );

        return 'success';
      } on FirebaseAuthException catch (e) {
        return e.code;
      }
    // } catch (e) {
    //   print(e);
    //   return 'unknown';
    // }
  }

}

class SignUp2 extends StatefulWidget {
  @override
  _SignUp2State createState() => _SignUp2State();
}

class _SignUp2State extends State<SignUp2> {

  final _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  bool isLoading = false;

  String emailError;
  String passwordError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Create Account'),
        elevation: 0.6,
      ),
      body: SafeArea(
        child: Center(
          child: Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Rival', style: TextStyle(fontSize: Theme.of(context).textTheme.headline2.fontSize, fontFamily: RivalFonts.rival),),
                    Padding(
                      padding: const EdgeInsets.only(left: 15, right: 15, top: 20, bottom: 10),
                      child: Form(
                        key: _formKey,
                        child: TextFormField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            filled: true,
                            prefixIcon: Icon(Icons.email),
                            errorText: emailError
                          ),
                          validator: validateEmail,
                          onChanged: (value) {
                            if (value.trim() != "" && emailError != null) {
                              setState(() {
                                emailError = null;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Text('Already have an account? Sign In',),
                          ),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10))
                              ),
                            ),
                            onPressed: () async {
                              if (!isLoading && _formKey.currentState.validate()) {
                                setState(() {
                                  isLoading = true;
                                });
                                QuerySnapshot querySnapshot = await firestore.collection('users').where('email', isEqualTo: emailController.text.toLowerCase().trim()).get();
                                if (querySnapshot.docs.isEmpty) {
                                  // Email available
                                  setState(() {
                                    isLoading = false;
                                  });
                                  Navigator.of(context).push(RivalNavigator(page: CreatePassword(email: emailController.text), ));
                                } else {
                                  // No user found with email
                                  setState(() {
                                    emailError = 'This email is already taken';
                                    isLoading = false;
                                  });
                                }
                              }
                            },
                            child: isLoading ? Container(
                              height: 15,
                              width: 15,
                              child: CustomProgressIndicator(strokeWidth: 1,)
                            ) : Text('Next'),
                          )
                        ],
                      ),
                    )
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
    );
  }

  String validateEmail(String value) {
    Pattern pattern = r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex = new RegExp(pattern);
    if (!regex.hasMatch(value)) {
      return 'Invalid Email';
    } else {
      emailError = null;
      return null;
    }
  }

}

class CreatePassword extends StatefulWidget {

  final String email;
  const CreatePassword({Key key, this.email}) : super(key: key);

  @override
  _CreatePasswordState createState() => _CreatePasswordState();
}

class _CreatePasswordState extends State<CreatePassword> {

  final _formKey = GlobalKey<FormState>();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController repasswordController = TextEditingController();
  
  String email;

  String emailError;
  String passwordError;
  String repasswordError;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  bool isLoading = false;

  @override
  void initState() {
    email = widget.email;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Account'),
        elevation: 0.6,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Rival', style: TextStyle(fontSize: Theme.of(context).textTheme.headline2.fontSize, fontFamily: RivalFonts.rival),),
                  Padding(
                    padding: const EdgeInsets.only(left: 15, right: 15, top: 20, bottom: 10),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              filled: true,
                              errorText: passwordError,
                              // ignore: missing_required_param
                              suffixIcon: IconButton(
                                icon: Icon(Icons.help_outline),
                                tooltip: 
'''- at least 8 characters
- must contain at least 1 uppercase letter, 1 lowercase letter, and 1 number''',
                              )
                            ),
                            obscureText: true,
                            validator: validatePassword,
                            onChanged: (String value) {
                              if (value.trim() != "" && passwordError != null) {
                                setState(() {
                                  passwordError = null;
                                });
                              }
                            },
                          ),
                          Container(height: 10,),
                          TextFormField(
                            controller: repasswordController,
                            decoration: InputDecoration(
                              labelText: 'Reenter Password',
                              filled: true,
                              errorText: repasswordError
                            ),
                            obscureText: true,
                            validator: validateRePassword,
                            onChanged: (value) {
                              if (value.trim() != "" && repasswordError != null) {
                                setState(() {
                                  repasswordError = null;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () async => await launch('https://rival.photography/policy'),
                          child: Text(
                            'Terms and Conditions',
                            style: TextStyle(color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black : Colors.white),
                          ),
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10))
                            ),
                          ),
                          onPressed: () {
                            if (_formKey.currentState.validate()) {
                              _signUp();
                            }
                          },
                          child: isLoading ? Container(
                            height: 15,
                            width: 15,
                            child: CustomProgressIndicator(strokeWidth: 1,)
                          ) : Text('Agree & Sign Up'),
                        )
                      ],
                    ),
                  )
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
    );
  }

  String validatePassword(String value) {
    Pattern pattern = r"^(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[a-zA-Z]).{8,}$";
    RegExp regex = new RegExp(pattern);
    if (!regex.hasMatch(value)) {
      setState(() {
        passwordError = "Weak Password";
      });
      return passwordError;
    } else {
      passwordError = null;
      return null;
    }
  }

  String validateRePassword(String value) {
    if (value == passwordController.text) {
      return null;
    } else {
      return 'Passwords do not match';
    }
  }
  
  _signUp() async {
    String password = passwordController.text.trim();
    if (_formKey.currentState.validate() && email != null && password != null) {
      try {
        setState(() {
          isLoading = true;
        });
        UserCredential result = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
        result.user.sendEmailVerification();
        DocumentSnapshot myDoc = await firestore.collection('users').doc(result.user.uid).get();
        try {
          String token = await _firebaseMessaging.getToken();

          await sharedPreferences.setString('token', token);

          LocationData location = await getLocation();
          GeoPoint geoPoint = GeoPoint(location.latitude, location.longitude);
          DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
          Map<String, dynamic> info = {
            'os': Platform.operatingSystem,
            'version': Platform.operatingSystemVersion,
          };
          if (Platform.isAndroid) {
            AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
            info.addAll({
              'model': androidInfo.model,
              'device': androidInfo.device,
              'isEmulator': !androidInfo.isPhysicalDevice,
              'manufacturer': androidInfo.manufacturer,
              'token': token
            });
          } else if (Platform.isIOS) {
            IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
            info.addAll({
              'model': iosInfo.utsname.machine,
              'device': iosInfo.localizedModel,
              'isEmulator': !iosInfo.isPhysicalDevice,
              'manufacturer': 'Apple',
              'token': token
            });
          }

          await myDoc.reference.set({
            'uid': result.user.uid,
            'displayName': result.user.displayName,
            'photoUrl': result.user.photoURL,
            'phoneNumber': result.user.phoneNumber,
            'email': result.user.email,
            'token': token,
            'followers': [],
            'following': [],
            'bookmarks': [],
            'blocked': [],
            'posts': [],
            'username': null,
            'verified': false,
            'account_created': result.user.metadata.creationTime.millisecondsSinceEpoch,
            'bio': null,
            'interests': {},
            'private': false,
            //'liked': [],
            'category': null,
            'gender': null,
            'dob': null,
            'allow_new_followers': true,
            'follow_requests': {},
            'story': {},
            'type': 'personal',
            'visits': [],
            'showContactCall': false,
            'showContactEmail': false,
            'tagsSubscribed': [],
            'subscriptions': [],
            'devices': {
              result.user.metadata.creationTime.millisecondsSinceEpoch.toString(): {
                'location': geoPoint,
                'timestamp': result.user.metadata.creationTime.millisecondsSinceEpoch,
                'device': info,
                'token': token
              }
            }
          });
          await analytics.logSignUp(signUpMethod: 'email');
          //await CurrentUser().init();
          me = Me();
          me.firebaseUser = result.user;
          await me.init();
          setState(() {
            isLoading = false;
          });
          await RivalProvider.showToast(
            text: 'Welcome $email',
          );
          await RivalProvider.showToast(
            text: 'Verification email sent.',
          );
          Navigator.pushAndRemoveUntil(context, RivalNavigator(page: SetupAccount(), ), (route) => false);
        } catch (e) {
          print("Error signing in $e");
          await RivalProvider.showToast(
            text: 'Failed to sign in. Please try again later.',
          );
          await FirebaseAuth.instance.signOut();
          SystemNavigator.pop();
        }
      } catch (e) {
        print(e);
        setState(() {
          isLoading = false;
        });
        switch (e.code) {
          case 'weak-password':
            setState(() {
              passwordError = 'Given password is too weak';
            });
            break;
          case 'invalid-email':
            setState(() {
              emailError = 'Invalid email';
            });
            break;
          case 'email-already-in-use':
            setState(() {
              emailError = 'Given email is already in use';
            });
            break;
          case 'operation-not-allowed':
            setState(() {
              emailError = 'Some error occured on our side. Please try again later.';
            });
            break;
          default:
            setState(() {
              emailError = 'Some error occured on our side. Please try again later.';
            });
            break;
        }
      }
    }
  }

}