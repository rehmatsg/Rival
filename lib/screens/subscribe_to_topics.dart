import 'package:cloud_firestore/cloud_firestore.dart';
import '../post/select_topic.dart';
import 'package:flutter/material.dart';

import '../app.dart';

class SubscribeToTopics extends StatefulWidget {
  @override
  _SubscribeToTopicsState createState() => _SubscribeToTopicsState();
}

class _SubscribeToTopicsState extends State<SubscribeToTopics> {
  List<String> copy;

  @override
  void initState() {
    copy = allTopics;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Topics'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              child: TextFormField(
                decoration: InputDecoration(
                  filled: true,
                  labelText: 'Search',
                  isDense: true,
                  border: UnderlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      borderSide: BorderSide.none),
                ),
                keyboardType: TextInputType.name,
                onChanged: _search,
              ),
            ),
            ListView.separated(
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) => ListTile(
                title: Text(copy[index]),
                onTap: () => Navigator.of(context).push(RivalNavigator(
                    page: PostsByTopic(
                  topic: copy[index],
                ))),
                trailing: SubscribedTopicsBtn(
                  topic: copy[index],
                ),
                visualDensity: VisualDensity.compact,
              ),
              separatorBuilder: (context, index) => Divider(),
              itemCount: copy.length,
              shrinkWrap: true,
            ),
          ],
        ),
      ),
    );
  }

  void _search(String query) {
    query = query.toLowerCase().trim();
    if (query != "") {
      search(query: query);
    } else {
      setState(() {
        copy = allTopics;
      });
    }
  }

  void search({@required String query}) {
    copy = allTopics.where((item) {
      if (item.contains(query) || item.toLowerCase().contains(query)) {
        return true;
      } else {
        return false;
      }
    }).toList();
    setState(() {});
  }
}

class SubscribedTopicsBtn extends StatefulWidget {
  final String topic;

  const SubscribedTopicsBtn({Key key, @required this.topic}) : super(key: key);

  @override
  _SubscribedTopicsBtnState createState() => _SubscribedTopicsBtnState();
}

class _SubscribedTopicsBtnState extends State<SubscribedTopicsBtn> {
  bool isBtnLoading = false;
  bool isSubscribed = false;

  @override
  void initState() {
    if (me.subscriptions.contains(widget.topic)) isSubscribed = true;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FlatButton(
        color: isBtnLoading
            ? (MediaQuery.of(context).platformBrightness == Brightness.light
                ? Colors.grey[300]
                : Colors.white10)
            : Colors.indigoAccent,
        onPressed: isBtnLoading
            ? null
            : () async {
                setState(() {
                  isBtnLoading = true;
                });
                if (isSubscribed) {
                  await me.update({
                    'subscriptions': FieldValue.arrayRemove([widget.topic])
                  }, reload: true);
                  isSubscribed = false;
                } else {
                  await me.update({
                    'subscriptions': FieldValue.arrayUnion([widget.topic])
                  }, reload: true);
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
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : Text(
                isSubscribed ? 'Unsubscribe' : 'Subscribe',
                style: TextStyle(color: Colors.white),
              ));
  }
}
