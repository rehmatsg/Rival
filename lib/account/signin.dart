import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:octo_image/octo_image.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.of(context).push(RivalNavigator(page: SignUp(), )),
                              child: Text('Don\'t have an account? Sign Up', style: TextStyle(),),
                            ),
                            OutlineButton(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10))
                              ),
                              onPressed: () async {
                                if (!isLoading && _formKey.currentState.validate()) await next();
                              },
                              child: isLoading ? Container(
                                height: 15,
                                width: 15,
                                child: CircularProgressIndicator(strokeWidth: 1,)
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(RivalNavigator(page: ForgotPassword(), )),
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black : Colors.white),
                      ),
                    ),
                    OutlineButton(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10))
                      ),
                      onPressed: () async {
                        await signIn();
                      },
                      child: isLoading ? Container(
                        height: 15,
                        width: 15,
                        child: CircularProgressIndicator(strokeWidth: 1,)
                      ) : Text('Sign In'),
                    )
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
        _firebaseMessaging.getToken().then((token) async {
          await myDoc.reference.update({
            'token': token,
          });
          setState(() {
            isLoading = false;
          });
        });
        try { // Try to get token from FCM
          await RivalProvider.showToast(
            text: 'Welcome $email',
          );
          if (!result.user.emailVerified) {
            result.user.sendEmailVerification();
            await RivalProvider.showToast(
              text: 'Please verify your email',
            );
          }
          String token = await _firebaseMessaging.getToken();
          await myDoc.reference.update({
            'token': token,
          });
          //await CurrentUser().init();
          me = Me();
          me.firebaseUser = result.user;
          await me.init();
          await analytics.logLogin();
          setState(() {
            isLoading = false;
          });
          Navigator.pushAndRemoveUntil(context, RivalNavigator(page: LandingPage(), ), (route) => false);
        } catch (e) {
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
          case 'wrong-password':
            setState(() {
              passwordError = 'Invalid password';
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
              passwordError = 'Your account has been disabled.';
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

class SignIn2 extends StatefulWidget {
  @override
  _SignIn2State createState() => _SignIn2State();
}

class _SignIn2State extends State<SignIn2> {

  final FirebaseAnalytics analytics = FirebaseAnalytics();

  String emailError;
  String passwordError;

  TextEditingController _euCtrl = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rival', style: TextStyle(fontFamily: RivalFonts.rival, fontSize: 25),),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Visibility(
              visible: isLoading == true ? false : true,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('Sign In', style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.15, fontFamily: RivalFonts.feature),),
                  Container(height: 20,),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          child: TextFormField(
                            controller: _euCtrl,
                            decoration: InputDecoration(
                              filled: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                              labelText: 'Email',
                              errorText: emailError
                            ),
                            onChanged: (value) {
                              setState(() {
                                this.emailError = null;
                              });
                            },
                            validator: validateEmail,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          child: TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              filled: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                              labelText: 'Password',
                              errorText: passwordError
                            ),
                            onChanged: (value) {
                              setState(() {
                                this.passwordError = null;
                              });
                            },
                            obscureText: true,
                          ),
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 15),
                              child: GestureDetector(
                                onTap: () => Navigator.of(context).push(RivalNavigator(page: ForgotPassword(), ),),
                                child: Text('Forgot Password?', style: TextStyle(fontFamily: RivalFonts.feature),),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 15),
                              child: GestureDetector(
                                onTap: () => Navigator.of(context).pushReplacement(RivalNavigator(page: SignUp(), )),
                                child: Text('Don\'t have an account? Sign Up', style: TextStyle(fontFamily: RivalFonts.feature),),
                              ),
                            ),
                          ],
                        ),
                        OutlineButton(
                          child: Text('Sign In'),
                          onPressed: () {
                            if (_formKey.currentState.validate()) {
                              _signIn();
                            }
                          },  
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            Visibility(
              visible: isLoading == true ? true : false,
              child: Container(
                height: 100,
                width: 100,
                child: CircularProgressIndicator(),
              ),
            )
          ],
        )
      ),
    );
  }

  String validateEmail(String value) {
    Pattern pattern = r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex = new RegExp(pattern);
    if (!regex.hasMatch(value)) {
      return 'Invalid Email';
    } else {
      this.emailError = null;
      return null;
    }
  }

  _signIn() async {
    String email = _euCtrl.text.trim();
    String password = _passwordController.text.trim();
    if (_formKey.currentState.validate() && email != null && password != null) {
      try {
        setState(() {
          isLoading = true;
        });
        UserCredential result = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
        DocumentSnapshot myDoc = await firestore.collection('users').doc(result.user.uid).get();
        _firebaseMessaging.getToken().then((token) async {
          await myDoc.reference.update({
            'token': token,
          });
          setState(() {
            isLoading = false;
          });
        });
        try { // Try to get token from FCM
          await RivalProvider.showToast(
            text: 'Welcome $email',
          );
          if (!result.user.emailVerified) {
            result.user.sendEmailVerification();
            await RivalProvider.showToast(
              text: 'Please verify your email'
            );
          }
          String token = await _firebaseMessaging.getToken();
          await myDoc.reference.update({
            'token': token,
          });
          //await CurrentUser().init();
          me = Me();
          me.firebaseUser = result.user;
          await me.init();
          await analytics.logLogin();
          await RivalProvider.getPosts(1); // Initialize Rival Home Page Posts
          setState(() {
            isLoading = false;
          });
          Navigator.pushAndRemoveUntil(context, RivalNavigator(page: Home(), ), (route) => false);
        } catch (e) {
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
          case 'ERROR_WRONG_PASSWORD':
            setState(() {
              passwordError = 'Invalid password';
            });
            break;
          case 'ERROR_INVALID_EMAIL':
            setState(() {
              emailError = 'Invalid email';
            });
            break;
          case 'ERROR_USER_NOT_FOUND':
            setState(() {
              emailError = 'No account exists with this email';
            });
            break;
          case 'ERROR_USER_DISABLED':
            setState(() {
              emailError = 'Your account has been disabled.';
            });
            break;
          case 'ERROR_TOO_MANY_REQUESTS':
            setState(() {
              emailError = 'We have blocked your device for too many attempts';
            });
            break;
          case 'ERROR_OPERATION_NOT_ALLOWED':
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
    } else {
      print('Kuch toh gadbad hai!');
    }
  }

}