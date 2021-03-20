import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../app.dart';

class PartnerRequests extends StatefulWidget {
  @override
  _PartnerRequestsState createState() => _PartnerRequestsState();
}

class _PartnerRequestsState extends State<PartnerRequests> {

  List<RivalUser> requests;
  bool isLoading = true;

  @override
  void initState() {
    _getPartnerRequests();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reqeusts'),
      ),
      body: isLoading
      ? Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: CustomProgressIndicator(),
          )
        ],
      )
      : ListView.separated(
        itemBuilder: (context, index) => Column(
          children: [
            UserListTile(
              isCurrentUser: false,
              user: requests[index],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              child: Row(
                children: [
                  TextButton(
                    child: Text('Add Partner', style: TextStyle(color: Colors.white),),
                    onPressed: () async {
                      Loader.show(
                        context,
                        function: () async {
                          await me.update({
                            'partnerRequests.${requests[index].uid}': FieldValue.delete()
                          }, reload: true);
                          int timestamp = DateTime.now().millisecondsSinceEpoch;
                          await me.update({
                            'partners.${requests[index].uid}': timestamp
                          }, reload: true);
                          await requests[index].update({
                            'partners.${me.uid}': timestamp
                          }, reload: true);
                        },
                        onComplete: () {
                          RivalProvider.showToast(text: 'Added as partner');
                        }
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.indigoAccent
                    ),
                  ),
                  Container(width: 10),
                  TextButton(
                    child: Text('Remove', style: TextStyle(color: Colors.white),),
                    onPressed: () async {
                      Loader.show(
                        context,
                        function: () async {
                          await me.update({
                            'partnerRequests.${requests[index].uid}': FieldValue.delete()
                          }, reload: true);
                        },
                        onComplete: () {
                          RivalProvider.showToast(text: 'Request Deleted');
                        }
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red[400]
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
        separatorBuilder: (context, index) => Divider(),
        itemCount: requests.length
      ),
    );
  }

  Future<void> _getPartnerRequests() async {
    requests = [];
    for (String uid in me.partnerRequests.keys) {
      RivalUser user = await getUser(uid);
      requests.add(user);
    }
    setState(() {
      isLoading = false;
    });
  }

}