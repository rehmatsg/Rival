import 'dart:async';
import 'dart:io';

import 'package:animations/animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  /// Return [True] if account is a Business Account
  bool get isBusinessAccount => data['type'] == 'business';
  /// Return [True] if account is a Creator Account
  bool get isCreatorAccount => data['type'] == 'creator';
  /// Return [True] if account is a Personal Account
  bool get isPersonalAccount => data['type'] == 'personal';
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
    if (reload) await me.reload();
  }

  /// Manually update user's [DocumentSnapshot] if it changes
  Future<void> reload() async {
    doc = await reference.get();
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
  List get activity => [];
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
  /// [Map<String, int>] Map of all profile visits
  Map get visits => data['visits'] ?? {};

  /// [Stream<Me>] of the user
  Stream<Me> get streamX {
    return doc.reference.snapshots().map((event) {
      doc = event;
      return me;
    });
  }

  Future<void> signOut(BuildContext context) async {
    await reference.update({
      'token': null
    });
    me = myPosts = timeline = storyItems = homeScreenPosts = homeScreenStories = topPosts = null;
    await FirebaseAuth.instance.signOut();
    RivalProvider.showToast(
      text: 'Signed Out'
    );
    Navigator.of(context).pushReplacement(RivalNavigator(page: SignIn(), transitionType: SharedAxisTransitionType.scaled));
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

  Future<bool> addDateOfBith({@required DateTime date}) async {
    int age = DateTime.now().year - date.year;
    if (age >= 12) {
      await me.update({
        'dob': Timestamp.fromDate(date)
      }, reload: true);
      return false;
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