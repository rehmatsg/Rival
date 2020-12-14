import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import '../app.dart';

class SignUp extends StatefulWidget {
  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {

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
      body: SafeArea(
        child: Center(
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Row(
                  children: [
                    IconButton(icon: Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop())
                  ],
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Sign Up', style: TextStyle(fontSize: Theme.of(context).textTheme.headline2.fontSize, fontFamily: RivalFonts.feature),),
                    Padding(
                      padding: const EdgeInsets.only(left: 15, right: 15, top: 30, bottom: 10),
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
                            child: Text('Already have an account? Sign In', style: TextStyle(fontFamily: RivalFonts.feature),),
                          ),
                          OutlineButton(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10))
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
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Sign Up', style: TextStyle(fontSize: Theme.of(context).textTheme.headline2.fontSize, fontFamily: RivalFonts.feature),),
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
- must contain at least 1 uppercase letter, 1 lowercase letter, and 1 number
- Can contain special characters''',
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
                              labelText: 'Re Enter Password',
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
                        OutlineButton(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10))
                          ),
                          onPressed: () {
                            if (_formKey.currentState.validate()) {
                              _signUp();
                            }
                          },
                          child: isLoading ? Container(
                            height: 15,
                            width: 15,
                            child: CircularProgressIndicator(strokeWidth: 1,)
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
          await myDoc.reference.set({
            'uid': result.user.uid,
            'displayName': result.user.displayName,
            'photoURL': result.user.photoURL,
            'phoneNumber': result.user.phoneNumber,
            'email': result.user.email,
            'token': token,
            'followers': [],
            'following': [],
            'bookmarks': [],
            'activity': [
              {
                'type': 'welcome',
                'timestamp': result.user.metadata.creationTime.millisecondsSinceEpoch,
              }
            ],
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
            'visits': {},
            'showContactCall': false,
            'showContactEmail': false,
            'tagsSubscribed': [],
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