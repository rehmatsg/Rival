import 'dart:async';
import 'dart:io';

import 'package:animations/animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:octo_image/octo_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';
import 'app.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RivalRootUser {

  RivalRootUser({this.doc});
  DocumentSnapshot doc;

  /// Get Unique UID for User
  String get uid => doc.id;
  /// [Map] for data stored in Firestore
  Map<String, dynamic> get data => doc?.data() ?? {};
  /// Email of the user
  String get email => data['email'];
  /// Username of the user
  String get username => data['username'] ?? 'rivaluser';
  /// Display Name for user
  String get displayName => data['displayName'] ?? 'A Rival User';
  /// Phone Number of the user. Maybe NULL
  String get phoneNumber => data['phoneNumber'] == null || data['phoneNumber'].toString().trim() == "" ? null : data['phoneNumber'];
  /// Bio of the user
  String get bio => data['bio'];
  /// Gender of [RivalRootUser]
  String get gender {
    if (data['gender'] == 'male') return 'Male';
    else if (data['gender'] == 'female') return 'Female';
    else if (data['gender'] == 'other') return 'Other';
    else return null;
  }
  /// [DateTime] of user's birth
  DateTime get dob => data['dob']?.toDate();
  /// Age of [RivalRootUser]
  int get age {
    if (dob != null) {
      return DateTime.now().year - dob.year;
    } else {
      return null;
    }
  }
  /// Whether user has been verified by Rival
  bool get isVerified => data['verified'] ?? false;
  /// Does the user have a private account
  bool get private => data['private'] ?? false;
  /// [DocumentSnapshot] of the user stored in Firestore
  DocumentSnapshot get snapshot => doc;
  /// [Stream<RivalUser>] of the user
  Stream<RivalUser> get stream {
    return doc.reference.snapshots().map((event) {
      return RivalUser(doc: event);
    });
  }
  /// Reference to Document of user
  DocumentReference get reference => doc.reference;
  /// Return [True] if account is a Creator Account
  bool get isCreatorAccount => data['type'] == 'creator';
  /// Return [True] if account is a Personal Account
  bool get isPersonalAccount => data['type'] == 'personal';
  /// Return [True] if account is a Business Account
  bool get isBusinessAccount => data['type'] == 'business';
  /// Returns [Map<String, int>] map which contains all requests made to user for sponsor
  /// Here the [String] is the uid of requester
  /// And [int] is the timestamp of when request was sent
  Map get partnerRequests => data['partnerRequests'];
  /// If [true] means that we have to request partner approval
  /// else it can be directly added
  /// Return [bool]
  bool get manuallyApprovePartnerRequests => data['manuallyApprovePartnerRequests'];
  /// Returns [Map<String, int>] map which contains all users who are approved as partner
  /// Here the [String] is the uid of requester
  /// And [int] is the timestamp of when request was sent
  Map get partners => data['partners'];
  /// Category of the Business user has
  String get category => data['category'];
  /// [ImageProvider] for user's profile photo. Does not return null in any case
  ImageProvider get photo {
    if (data['photoUrl'] != null) {
      return CachedNetworkImageProvider(data['photoUrl']);
    } else {
      return AssetImage('assets/images/avatar.png');
    }
  }
  /// List of [DocumentReference] with reference to each post created by the user
  List get posts => data['posts'] ?? [];
  /// Map of stories user has currently
  Map get stories => data['story'] ?? {};
  /// List of [DocumentReference] user is currently following
  List get following => data['following'] ?? [];
  /// List of [DocumentReference] user if being followed by
  List get followers => data['followers'] ?? [];
  /// [Map<String, int>]
  /// Key [String] of a single field gives us the name of Interest
  /// Whereas the Value [int] gives us the number of times this Interest was recorded
  Map get interests => data['interests'] ?? {};

  /// Show call option in Profile Page for Business Account ONLY
  bool get showContactCall => isBusinessAccount ? (data['showContactCall'] ?? false) : false;
  /// Show email option in Profile Page for Business Account ONLY
  bool get showContactEmail => isBusinessAccount ? (data['showContactEmail'] ?? false) : false;

  /// Update user's [DocumentSnapshot] with [Map<String, dynamaic>] data
  Future<void> update(Map<String, dynamic> data, {bool reload = false}) async {
    await reference.update(data);
    if (reload) await this.reload();
  }

  /// Manually update user's [DocumentSnapshot] if it changes
  Future<void> reload({DocumentSnapshot update}) async {
    doc = await reference.get();
    if (allLoadedUsers.indexWhere((element) => element.uid == uid) >= 0 && !allLoadedUsers.contains(this)) {
      await allLoadedUsers[allLoadedUsers.indexWhere((element) => element.uid == uid)].reload(update: doc);
    }
  }

}

class Me extends RivalRootUser {
  
  User firebaseUser;
  DocumentSnapshot doc;

  set user(User u) => firebaseUser = u;
  /// Setter for Current User's [DocumentSnapshot]
  set document(DocumentSnapshot d) => doc = d;
  /// Either use the setter [document] or automate using [init()]
  init() async {
    doc = await firestore.collection('users').doc(firebaseUser.uid).get();
  }

  @override
  ImageProvider get photo {
    if (firebaseUser.photoURL != null) return CachedNetworkImageProvider(firebaseUser.photoURL);
    return AssetImage('assets/images/avatar.png');
  }
  @override
  String get uid => firebaseUser.uid ?? '';
  User get user => firebaseUser;
  @override
  String get username => data['username'];
  /// Phone Number of the user. Maybe NULL
  @override
  String get phoneNumber => (firebaseUser.phoneNumber == null || firebaseUser.phoneNumber.trim() == "") ? null : firebaseUser.phoneNumber;
  /// List of [String] all tags I am subscribed to
  List get tagsSubscribed => data['tagsSubscribed'] ?? [];
  /// List of [DocumentReference] of Bookmarked Posts
  List get bookmarks => data['bookmarks'];
  /// List of [String] of Bookmarked Posts
  List<String> get bookmarksById {
    List<String> bookmarksById = [];
    bookmarks.forEach((element) {
      DocumentReference ref = element;
      bookmarksById.add(ref.id);
    });
    return bookmarksById;
  }
  /// [List<int>] Map of all profile visits
  List get visits => data['visits'] ?? [];

  /// List of [String] that contains all topics that current user is subscribed to
  List get subscriptions => data['subscriptions'] ?? [];

  /// [Stream<Me>] of the user
  Stream<Me> get streamX {
    return doc.reference.snapshots().map((event) {
      doc = event;
      return me;
    });
  }

  Future<void> signOut(BuildContext context) async {
    await Loader.show(
      context,
      function: () async {
        await reference.update({
          'token': null
        });
        me = myPosts = timeline = storyItems = homeScreenPosts = homeScreenStories = topPosts = null;
        await FirebaseAuth.instance.signOut();
      },
      onComplete: () {
        RivalProvider.showToast(
          text: 'Signed Out'
        );
        Navigator.of(context).pushReplacement(RivalNavigator(page: SignIn(), transitionType: SharedAxisTransitionType.scaled));
      }
    );
  }

  void navigateToProfile(BuildContext context) {
    Navigator.of(context).push(RivalNavigator(page: ProfilePage(isCurrentUser: true),));
  }

  List get followingWithUids {
    List followingWithUids = [];
    following.forEach((u) {
      DocumentReference ur = u;
      followingWithUids.add(ur.id);
    });
    return followingWithUids;
  }

  Future<void> switchToBusinessOrPersonalAccount() async {
    Map<String, dynamic> data = {};
    if (isBusinessAccount) {
      // Account is business, switch to personal
      data['isBusinessAccount'] = false;
    } else {
      // Account is personal, switch to business
      data['isBusinessAccount'] = true;
    }
    await reference.update(data);
  }

  Future<void> updateProfilePhoto({@required File photo}) async {
    await RivalProvider.showToast(
      text: 'Updating your photo...',
    );
    final StorageUploadTask uploadTask = FirebaseStorage.instance.ref().child('profile_photo').child('${me.uid}-${new DateTime.now().millisecondsSinceEpoch}').putFile(photo);
    StorageTaskSnapshot meta = await uploadTask.onComplete;
    final String url = (await meta.ref.getDownloadURL()).toString();
    me.user.updateProfile(photoURL: url);
    await me.reference.update({
      'photoUrl': url
    });
    await me.user.reload();
    await me.reload();
    await RivalProvider.showToast(
      text: 'Profile photo updated',
    );
  }

  /// Returns `bool` whether the user is eligible for using Rival
  Future<bool> addDateOfBith({@required DateTime date}) async {
    int age = DateTime.now().year - date.year;
    if (age >= 12) {
      await me.update({
        'dob': Timestamp.fromDate(date)
      }, reload: true);
      return true;
    } else {
      // Age not suitable
      return false;
    }
  }

}

class RivalUser extends RivalRootUser {

  DocumentSnapshot doc;
  RivalUser({this.doc});

  @override
  String get username => data['username'] ?? 'rivaluser';

  bool get storyViewed {
    if (data['story'] != null) {
      List storiesOrd = stories.values.toList();
      storiesOrd.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
      Map lastStoryViews = storiesOrd.last['views'];
      if (lastStoryViews.containsKey(me.uid)) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }
  bool get amIBlocked {
    List blocked = data['blocked'];
    List<String> block = [];
    blocked.forEach((dumU) {
      block.add(dumU.path);
    });
    if (block.contains(me.reference.path)) {
      return true;
    } else {
      return false;
    }
  }
  bool get isBlocked {
    List blocked = me.data['blocked'];
    List<String> block = [];
    blocked.forEach((dumU) {
      block.add(dumU.path);
    });
    if (block.contains(doc.reference.path)) {
      return true;
    } else {
      return false;
    }
  }
  bool get isFollowing {
    List followers = [];
    data['followers'].forEach((dummyUserRef) {
      followers.add(dummyUserRef.path);
    });
    if (followers.contains(me.reference?.path)) {
      return true;
    } else {
      return false;
    }
  }
  bool get isInWaitList {
    List waitList = [];
    Map waitListM = data['follow_requests'];
    if (waitListM.length > 0) waitListM.values.toList().forEach((dummyUserRef) {
      waitList.add(dummyUserRef.path);
    });
    if (waitList.contains(me.reference.path)) {
      return true;
    } else {
      return false;
    }
  }
  String get followUnfollow {
    if (isFollowing) {
      // Unfollow
      return 'Following';
    } else if (!isFollowing && !isInWaitList && data['allow_new_followers']) {
      // Follow
      print(me.reference.path);
      print("isFollowing $isFollowing");
      return 'Follow';
    } else if (!isFollowing && !isInWaitList && !data['allow_new_followers']) {
      // Add to wait list
      return 'Request';
    } else if (!isFollowing && isInWaitList) {
      // Remove from wait list
      return 'Requested';
    } else {
      print('Unknown condition');
      return 'Loading';
    }
  }

  Future<void> followUnfollowRequest() async {
    if (isBlocked || amIBlocked) {
      RivalProvider.showToast(text: 'Failed. Please try again later');
    } else if (isFollowing) {
      // Unfollow
      await reference.update({
        'followers': FieldValue.arrayRemove([me.reference])
      });
      await me.reference.update({
        'following': FieldValue.arrayRemove([reference])
      });
      me.reload();
      await RivalProvider.showToast(
        text: 'Unfollowed @$username'
      );
      doc = await reference.get();
    } else if (!isFollowing && !isInWaitList && data['allow_new_followers']) {
      // Follow
      await reference.update({
        'followers': FieldValue.arrayUnion([me.reference])
      });
      await me.reference.update({
        'following': FieldValue.arrayUnion([reference])
      });
      me.reload();
      await RivalProvider.showToast(
        text: 'Started following @$username'
      );
      doc = await reference.get();
    } else if (!isFollowing && !isInWaitList && !data['allow_new_followers']) {
      // Add to wait list
      await reference.update({
        'follow_requests.${new DateTime.now().millisecondsSinceEpoch}': me.reference
      });
      await RivalProvider.showToast(
        text: 'Waiting for @$username to accept request',
      );
      doc = await reference.get();
    } else if (!isFollowing && isInWaitList) {
      // Remove from wait list
      List requests = data['follow_requests'].values.toList();
      List<String> req = [];
      for (DocumentReference ref in requests) {
        req.add(ref.path);
      }
      int myIndex = req.indexOf(me.reference.path);
      var timestamp = data['follow_requests'].keys.toList()[myIndex];
      await reference.update({
        'follow_requests.$timestamp': FieldValue.delete()
      });
      await RivalProvider.showToast(
        text: 'Removed from request list'
      );
      doc = await reference.get();
    } else {
      print('Unknown condition');
    }
  }

  Future<void> blockUnblock({bool autoUpdateUser = true}) async {
    if (isBlocked) {
      await me.reference.update({
        'blocked': FieldValue.arrayRemove([doc.reference])
      });
      await RivalProvider.showToast(text: 'Unblocked $username');
    } else {
      await me.reference.update({
        'blocked': FieldValue.arrayUnion([doc.reference])
      });
      await RivalProvider.showToast(text: 'Blocked $username');
      if (isFollowing && isInWaitList) followUnfollowRequest();
      await me.reference.update({
        'followers': FieldValue.arrayRemove([reference])
      });
      await me.reference.update({
        'following': FieldValue.arrayRemove([reference])
      });
      await reference.update({
        'followers': FieldValue.arrayRemove([me.reference])
      });
      await reference.update({
        'following': FieldValue.arrayRemove([me.reference])
      });
    }
    if (autoUpdateUser) await me.reload();
    await reload();
  }

  Future<void> report() async {
    String reportId = firestore.collection('rival').doc('reports').collection('users').doc().id;
    DocumentReference reportRef = firestore.collection('rival').doc('reports').collection('users').doc(reportId);
    await reportRef.set({
      'user': reference,
      'by': me.reference,
      'timestamp': new DateTime.now().millisecondsSinceEpoch,
    });
    if (!isBlocked) await blockUnblock();
  }

  void navigateToProfile(BuildContext context) {
    Navigator.of(context).push(RivalNavigator(page: ProfilePage(isCurrentUser: uid == me.uid, user: RivalUser(doc: doc),), ));
  }

}


// -----------------------------------------------------------------------------------------------

List<RivalUser> allLoadedUsers = [];
Future<RivalUser> getUser(String uid) async {
  if (allLoadedUsers.where((user) => user.uid == uid).toList().isNotEmpty) {
    return allLoadedUsers.firstWhere((user) => user.uid == uid);
  }
  DocumentSnapshot d = await firestore.collection('users').doc(uid).get();
  RivalUser rivalUser = RivalUser(doc: d);
  allLoadedUsers.add(rivalUser);
  return rivalUser;
}

class UserListTile extends StatefulWidget {

  UserListTile({Key key, this.user, this.doc, this.id, this.ref, this.isCurrentUser, this.subtitle, this.future}) : super(key: key);
  final RivalUser user;
  /// UID of [RivalUser]. Initializing this class using UID automatically gets user by UID.
  final String id;
  final DocumentSnapshot doc;
  final DocumentReference ref;
  final bool isCurrentUser;
  final String subtitle;
  final Future<RivalUser> future;

  @override
  _UserListTileState createState() => _UserListTileState();
}

class _UserListTileState extends State<UserListTile> {

  RivalUser user;
  String id;
  DocumentSnapshot doc;
  
  bool isCurrentUser = false;
  bool isLoading = true;

  _init() async {
    if (widget.user != null) {
      user = widget.user;
      id = user.uid;
      doc = user.doc;
      isLoading = false;
    } else if (widget.id != null) {
      user = await getUser(widget.id);
      id = widget.id;
      doc = user.doc;
      isLoading = false;
    } else if (widget.doc != null) {
      doc = widget.doc;
      user = RivalUser(doc: doc);
      id = doc.id;
      isLoading = false;
    } else if (widget.ref != null) {
      await _getUserFromRef();
    } else if (widget.future != null) {
      user = await widget.future;
      doc = user.doc;
      id = doc.id;
      isLoading = false;
    }

    if (widget.isCurrentUser != null) {
      isCurrentUser = widget.isCurrentUser;
    } else if (user.uid == me.uid) {
      isCurrentUser = true;
    } else {
      isCurrentUser = false;
    }
    setState(() {});
  }

  @override
  void initState() {
    _init();
    super.initState();
  }

  Future<void> _getUserFromRef() async {
    doc = await widget.ref.get();
    id = doc.id;
    user = RivalUser(doc: doc);
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: (isLoading || isCurrentUser) ? true : (user.amIBlocked ? false : true),
      child: ListTile(
        visualDensity: VisualDensity.compact,
        leading: isCurrentUser
        ? ((me.stories != null && me.stories.length > 0)
          ? GestureDetector(
            onTap: () async {
              await RivalProvider.vibrate();
              Navigator.of(context).push(RivalNavigator(page: ViewStory(launchedFromHomeScreen: false, users: [me])));
            },
            child: CircularStepProgressIndicator(
              totalSteps: me.stories.length,
              unselectedColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black38 : Colors.white38,
              width: 40,
              height: 40,
              padding: me.stories.length > 1 ? (22/7) / 15 : 0,
              customStepSize: (intn, boo) => 2,
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: ClipOval(
                  child: ProfilePhoto(width: 30, height: 30,),
                ),
              ),
            ),
          )
          : ClipOval(
            child: ProfilePhoto(width: 40, height: 40,),
          )
        )
        : (
          isLoading
          ? Shimmer.fromColors(
            child: Container(
              decoration: BoxDecoration(
                color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[200] : Colors.grey[900],
                borderRadius: BorderRadius.all(Radius.circular(100))
              ),
              height: 40,
              width: 40
            ),
            baseColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[200] : Colors.grey[900],
            highlightColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[200] : Colors.grey[900]
          )
          : ((user.stories != null && user.stories.length > 0)
            ? GestureDetector(
              onTap: () async {
                await RivalProvider.vibrate();
                Navigator.of(context).push(RivalNavigator(page: ViewStory(launchedFromHomeScreen: false, users: [user],)));
              },
              child: CircularStepProgressIndicator(
                totalSteps: user.stories.length,
                unselectedColor: (user.storyViewed || user.uid == me.user.uid) ? (MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black38 : Colors.white38) : Colors.indigoAccent,
                width: 40,
                height: 40,
                padding: user.stories.length > 1 ? (22/7) / 15 : 0,
                customStepSize: (intn, boo) => 2,
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: ClipOval(
                    child: OctoImage(
                      image: user.photo,
                      placeholderBuilder: (context) => CircularProgressIndicator()
                    ),
                  ),
                ),
              ),
            )
            : ClipOval(
              child: OctoImage(
                image: user.photo,
                placeholderBuilder: (context) => CircularProgressIndicator(),
                width: 40,
                height: 40,
              ),
            )
          )),
        title: isCurrentUser
          ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.subtitle != null) Text(me.username)
              else Flexible(
                flex: 1,
                child: Text(me.displayName, overflow: TextOverflow.ellipsis,)
              ),
              if (me.isVerified) ... [
                Container(width: 5,),
                VerifiedBadge()
              ]
            ],
          )
          : (isLoading
          ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 14,
                width: MediaQuery.of(context).size.width / 2,
                child: Shimmer.fromColors(
                  child: Container(
                    decoration: BoxDecoration(
                      color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[200] : Colors.grey[900],
                      borderRadius: BorderRadius.all(Radius.circular(2))
                    ),
                    width: MediaQuery.of(context).size.width * 0.8,
                  ),
                  baseColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[200] : Colors.grey[900],
                  highlightColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[200] : Colors.grey[900]
                ),
              ),
            ],
          )
          : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                flex: 1,
                child: Text(widget.subtitle != null ? user.username : user.displayName),
              ),
              if (user.isVerified) ... [
                Container(width: 5,),
                VerifiedBadge()
              ],
            ],
          )),
        subtitle: isCurrentUser ? Text(widget.subtitle != null ? widget.subtitle : me.username) : (isLoading ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 11,
              width: MediaQuery.of(context).size.width / 3,
              child: Shimmer.fromColors(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(2))
                  ),
                  width: MediaQuery.of(context).size.width * 0.8,
                ),
                baseColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.white10,
                highlightColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black26 : Colors.white10
              ),
            ),
          ],
        ) : Text(widget.subtitle != null ? widget.subtitle : user.username)),
        trailing: (isLoading || isCurrentUser) ? null : FlatButton(
          onPressed: () async {
            await RivalProvider.vibrate();
            user.followUnfollowRequest();
          },
          child: StreamBuilder<DocumentSnapshot>(
            stream: user.reference.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active) {
                user = RivalUser(doc: snapshot.data);
                return Text(user.followUnfollow, style: TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold),);
              }
              return Text(user.followUnfollow, style: TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold),);
            },
          ),
          splashColor: Colors.indigoAccent.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10))
          ),
        ),
        onTap: () {
          if (!isLoading) {
            user.navigateToProfile(context);
          }
        },
      ),
    );
  }
}