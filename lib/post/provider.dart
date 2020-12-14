import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geocoder/model.dart';
import 'package:location/location.dart';
import '../app.dart';
import 'location_search.dart';

class LocationSelector extends StatefulWidget {

  LocationSelector({@required this.onLocationSelect, this.selectedLocation});
  final Function(GeoPoint geoPoint, String feature) onLocationSelect;
  final String selectedLocation;

  @override
  _LocationSelectorState createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> with SingleTickerProviderStateMixin {

  Address address;
  List<String> featureAddress = [];
  GeoPoint geoPoint;

  int index;

  Future<void> getLocation() async {
    // print('Getting Location...');
    Location location = new Location();
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return null;
      }
    }
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return null;
      }
    }
    _locationData = await location.getLocation();
    // print('Got Location');
    Coordinates coordinates = new Coordinates(_locationData.latitude, _locationData.longitude);
    GeoPoint geoPointL = new GeoPoint(_locationData.latitude, _locationData.longitude); // Main var
    // print('Got geoPoint');

    List<Address> addresses = await Geocoder.local.findAddressesFromCoordinates(coordinates);
    // print('Got Address');
    // addresses.forEach((address) {
    //   print("Address Line: ${address.addressLine},\nAdmin Area: ${address.adminArea},\nFeature Name: ${address.featureName},\nLocality: ${address.locality},\nSub Admin Area: ${address.subAdminArea},\nSub Locality: ${address.subLocality},\nSub Thoroughfare: ${address.subThoroughfare},\nThoroughfare: ${address.thoroughfare}\n---------------------\n");
    // });
    address = addresses.first;
    featureAddress.addAll([address.locality, '${address.locality ?? ''}, ${address.adminArea ?? ''}', address.subLocality ?? '', address.adminArea ?? '', address.featureName ?? '']); // Add Admin Area
    featureAddress.removeWhere((element) => element == '');

    if (widget.selectedLocation != null && widget.selectedLocation.trim() != "" && widget.selectedLocation.trim() != "null") {
      if (featureAddress.contains(widget.selectedLocation)) index = featureAddress.indexOf(widget.selectedLocation);
      else {
        featureAddress.insert(0, widget.selectedLocation);
        index = 0;
      }
    }
    setState(() {
      geoPoint = geoPointL;
    });
    //print("Address Line: ${address.addressLine},\nAdmin Area: ${address.adminArea},\nFeature Name: ${address.featureName},\nLocality: ${address.locality},\nSub Admin Area: ${address.subAdminArea},\nSub Locality: ${address.subLocality},\nSub Thoroughfare: ${address.subThoroughfare},\nThoroughfare: ${address.thoroughfare}\n---------------------\n");
  }

  @override
  void initState() {
    getLocation();
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: Duration(milliseconds: 300),
      vsync: this,
      child: (featureAddress.length >= 1)
      ? SizedBox(
        height: 30,
        width: double.infinity,
        child: ListView(
          children: [
            ... List.generate(
              featureAddress.length,
              (i) => Padding(
                padding: const EdgeInsets.only(right: 3),
                child: ChoiceChip(
                  label: Text(featureAddress[i]),
                  selected: i == index,
                  selectedColor: Colors.indigoAccent,
                  onSelected: (isSelected) {
                    if (isSelected) {
                      setState(() {
                        index = i;
                      });
                      widget.onLocationSelect(geoPoint, featureAddress[i]);
                    } else {
                      setState(() {
                        index = null;
                      });
                      widget.onLocationSelect(null, null);
                    }
                  },
                ),
              )
            ),
            Padding(
              padding: const EdgeInsets.only(left: 5),
              child: SizedBox(
                width: 30,
                height: 30,
                child: InkWell(
                  onTap: () async {
                    Map result = await showSearch(context: context, delegate: LocationSearchDelegate());
                    if (result != null) {
                      setState(() {
                        geoPoint = result['geoPoint'];
                        featureAddress.insert(0, result['location']);
                        index = 0;
                      });
                      widget.onLocationSelect(geoPoint, result['location']);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.indigoAccent,
                      borderRadius: BorderRadius.all(Radius.circular(20))
                    ),
                    child: Icon(Icons.search, size: 15, color: Colors.white,),
                  ),
                ),
              ),
            ),
          ],
          physics: BouncingScrollPhysics(),
          scrollDirection: Axis.horizontal,
        ),
      )
      : Container()
    );
  }
}

String subtitleValidator(String subtitle) {
  if (subtitle.length > 50) {
    return 'Subtitle should not exceed 50 characters';
  }
  return null;
}

String descriptionValidator(String description) {
  if (description.length > 1000) {
    return 'Description should not exceed 500 characters';
  }
  return null;
}

class Post {
  Post({@required this.doc, this.ad, this.user, this.sponsor});
  
  DocumentSnapshot doc;

  bool promoted = false;

  bool isLikedByMe = false;

  /// 6-DIGIT Unique ID for Post
  String get id => doc.id;
  /// Return [bool] that checks if post if by current user
  bool get isMyPost => me.uid == userId;
  /// [Map] of data in Post's Document
  Map<String, dynamic> get data => doc.exists ? doc.data() : {};
  /// Description of Post. Can be NULL
  String get description => data['description'].toString();
  /// Subtitle of Post. Use [GeoPoint] if Subtitle is NULL
  String get subtitle => data['subtitle'].toString();
  /// GeoPoint of User at time he/she created Post. Use in place of Subtitle
  GeoPoint get geoPoint => data['geoPoint'];
  /// A Placeholder text for Location of Post
  String get location => data['locationPlaceholder'].toString();
  /// List of [URL] of images contained in Post
  List get images => data['images'];
  Map get comments => data['comments'];
  bool get showLikeCount => data['showLikeCount'] ?? true;
  Map get likes => data['likes'];
  /// [bool] tells whether owner has allowed to comment on this post
  bool get allowComments => data['allowComments'];
  /// [bool] whether this post contains adult rated content. If [True], then hide it from child account
  bool get adultRated => data['adult-rated'] ?? false;
  /// List of [String] of keywords of this post
  List get keywords => data['keywords'];
  /// List of Labels [String] scanned from all Images
  List get labels => data['labels'];
  /// List of [DocumentReference] of People tagged in this Post
  List get people => data['people'];
  /// User ID [String] of the owner
  String get userId => data['creator'];
  /// Map of [String, int] of people who visited your profile by cliking on this post
  Map get profileVisits => data['profile_visits'];
  /// Ratio [Width / Height] of ALL images in post
  double get ratio => data['ratio'];
  Map get reach => data['reach'];
  Map get impressions => data['impressions'];
  Map get shares => data['shares'];
  bool get takenDown => data['takenDown'] ?? false;
  bool get available => doc.exists ? (data['available'] ?? true) : false;
  String get shareableUrl => data['shareableUrl'] ?? '';
  Stream<Post> get stream {
    return reference.snapshots().map((event) {
      return Post(doc: event, ad: ad, user: user, sponsor: sponsor);
    });
  }
  Map get click {
    if (data['clicks'] != null) {
      return data['clicks'];
    } else {
      return null;
    }
  }
  List get tags => data['tags'];
  int get timestamp => data['timestamp'];
  DocumentReference get userRef => data['user'];
  DocumentReference get reference => doc.reference;
  bool get isLiked => data['likes'].containsKey(me.user.uid);
  bool get isProduct => data['isProduct'] ?? false;
  String get productUrl => data['productUrl'];
  String get productTitle => data['productTitle'] ?? 'Open';
  DocumentReference get sponsorRef => data['sponsor'];

  // --------- NEW -------------
  var user;
  var sponsor;

  DocumentSnapshot ad;

  /// [Setter]
  /// Set the [DocumentSnapshot] of the Ad
  set adDoc(DocumentSnapshot adD) {
    ad = adD;
  }
  /// [bool] Get whether the post has beem loaded as (Paid Promotion or Ad) or from (Timeline, Profile, Search, Tags, Trending, Explore, etc)
  bool get isPromoted => ad != null;
  DocumentReference get adRef => ad?.reference;
  /// [DateTime] of day of creation of Ad
  DateTime get adCreated => new DateTime.fromMicrosecondsSinceEpoch(ad.data()['created']);
  /// [DateTime] upto which the Ad is valid
  DateTime get adValidity => new DateTime.fromMicrosecondsSinceEpoch(ad.data()['validity']);
  /// [bool] Get whether Ad is valid until today
  bool get isAdValid => DateTime.now().isBefore(adValidity);
  /// [Map] of Impression recored in Post loaded as Ad
  Map get adImpressions => ad.data()['impressions'];
  /// [Map] of Reach recored in Post loaded as Ad
  Map get adReach => ad.data()['reach'];
  /// [Map] of Profile Visits recored in Post loaded as Ad
  Map get adProfileVisits => ad.data()['profile_visits'];
  /// Report this AD
  Future<void> reportAd() async {
    String reportId = firestore.collection('rival').doc('reports').collection('ads').doc().id;
    DocumentReference reportRef = firestore.collection('rival').doc('reports').collection('ads').doc(reportId);
    await reportRef.set({
      'user': userRef,
      'by': me.reference,
      'post': reference,
      'timestamp': new DateTime.now().millisecondsSinceEpoch,
    });
    await RivalProvider.showToast(text: 'Report Submitted');
  }

  Future<void> refresh() async {
    doc = await reference.get();
  }

  Future<void> report() async {
    String reportId = firestore.collection('rival').doc('reports').collection('posts').doc().id;
    DocumentReference reportRef = firestore.collection('rival').doc('reports').collection('posts').doc(reportId);
    await reportRef.set({
      'user': userRef,
      'by': me.reference,
      'post': reference,
      'timestamp': new DateTime.now().millisecondsSinceEpoch,
    });
    await RivalProvider.showToast(text: 'Report Submitted');
  }

  Future<void> shareAsStory() async {
    int timestamp = new DateTime.now().millisecondsSinceEpoch;
    await me.update({
      'story.$timestamp': {
        'type': 'post',
        'timestamp': timestamp,
        'postRef': reference,
        'postId': id,
        'views': {}
      }
    });
    await me.reload();
    await RivalProvider.showToast(text: 'Added Post to your Story');
  }

  // ---------------------
  /// Get a Post by providing ID [String] or [DocumentSnapshot] or [DocumentReference]
  static Future<Post> fetch({String id, DocumentReference ref, DocumentSnapshot doc, DocumentSnapshot ad, RivalUser user}) async {
    assert(id != null || ref != null || doc != null, "Document Id or Reference or Snapshot should be provided");
    Post post;
    if (doc != null) {
      post = await _getPostByDoc(doc: doc, ad: ad);
    } else if (ref != null) {
      post = await _getPostByDoc(doc: await ref.get(), ad: ad);
    } else if (id != null) {
      post = await getPost(id, ad: ad);
    }
    return post;
  }
  
}

// ------------------------------------------------------------------------------------

/// List of all [Post]s that has been loaded once.
/// Using this list prevents re-reading of docs in firestore and reduces cost
List<Post> allLoadedPosts = [];

Future<Post> getPost(String id, {DocumentSnapshot ad, RivalUser user, RivalUser sponsor}) async {
  if (allLoadedPosts.indexWhere((element) => element.id == id) > 0) return allLoadedPosts[allLoadedPosts.indexWhere((element) => element.id == id)]; // Post is already loaded. Return Post from allLoadedPosts list. This reduces cost
  DocumentSnapshot doc = await firestore.collection('posts').doc(id).get();
  if (doc.exists && doc.data().isNotEmpty) {

    var creator;
    var sponsorL;

    if (doc.data()['creator'] == me.uid) {
      creator = me;
    } else if (user != null) {
      creator = user;
    } else {
      creator = await getUser(doc.data()['creator']);
    }

    if (doc.data()['sponsor'] == me.uid) {
      sponsorL = me;
    } else if (sponsor != null) {
      sponsorL = sponsor;
    } else if (doc.data()['sponsor'] != null) {
      sponsorL =  await getUser(doc.data()['sponsor'].id);
    }

    Post post = Post(doc: doc, user: creator, sponsor: sponsorL, ad: ad);
    allLoadedPosts.add(post);
    return post;
  } else {
    return null;
  }
}

Future<Post> _getPostByDoc({@required DocumentSnapshot doc, DocumentSnapshot ad, RivalUser user, RivalUser sponsor}) async {
  String userId = doc.data()['creator'];
  DocumentReference sP = doc.data()['sponsor'];

  var sponsorL;
  var creator;

  if (userId == me.uid) {
    creator = me;
  } else if (user != null) {
    creator = user;
  } else {
    creator = await getUser(userId);
  }

  if (sP?.id == me.uid) { // I am the sponsor
    sponsorL = me;
  } else if (sponsor != null) {
    sponsorL = sponsor;
  } else if (sP != null) {
    sponsorL = await getUser(sP.id);
  }

  Post post = Post(doc: doc, sponsor: sponsorL, user: creator, ad: ad);
  return post;
}