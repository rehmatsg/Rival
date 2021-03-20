import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../app.dart';

class TagSubscription extends StatefulWidget {
  @override
  _TagSubscriptionState createState() => _TagSubscriptionState();
}

class _TagSubscriptionState extends State<TagSubscription> {

  List<String> tagsSubscribed;

  @override
  void initState() {
    tagsSubscribed = List<String>.from(me.tagsSubscribed);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subscriptions'),
      ),
      body: ListView.builder(
        itemBuilder: (context, index) => ListTile(
          title: Text('#${tagsSubscribed[index]}', style: Theme.of(context).textTheme.headline6.copyWith(fontFamily: RivalFonts.feature)),
          trailing: SubscribedTagBtn(tag: tagsSubscribed[index],),
        ),
        itemCount: tagsSubscribed.length,
      ),
    );
  }
}

class SubscribedTagBtn extends StatefulWidget {

  final String tag;

  const SubscribedTagBtn({Key key, @required this.tag}) : super(key: key);

  @override
  _SubscribedTagBtnState createState() => _SubscribedTagBtnState();
}

class _SubscribedTagBtnState extends State<SubscribedTagBtn> {

  bool isBtnLoading = false;
  bool isSubscribed = true;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: isBtnLoading ? (MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[300] : Colors.white10) : Colors.indigoAccent,
      ),
      onPressed: isBtnLoading
      ? null
      : () async {
        setState(() {
          isBtnLoading = true;
        });
        if (isSubscribed) {
          await me.update({
            'tagsSubscribed': FieldValue.arrayRemove([widget.tag])
          }, reload: true);
          await FirebaseMessaging().unsubscribeFromTopic(widget.tag);
          isSubscribed = false;
        } else {
          await me.update({
            'tagsSubscribed': FieldValue.arrayUnion([widget.tag])
          }, reload: true);
          await FirebaseMessaging().subscribeToTopic(widget.tag);
          isSubscribed = true;
        }
        setState(() {
          isBtnLoading = false;
        });
      },
      child: isBtnLoading
      ? Container(
        width: 14,
        height: 14,
        child: CustomProgressIndicator(
          strokeWidth: 2,
        ),
      )
      : Text(isSubscribed ? 'Unsubscribe' : 'Subscribe', style: TextStyle(color: Colors.white),)
    );
  }
}