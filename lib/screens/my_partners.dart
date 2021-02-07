import 'package:flutter/material.dart';
import '../app.dart';

class MyPartners extends StatefulWidget {
  @override
  _MyPartnersState createState() => _MyPartnersState();
}

class _MyPartnersState extends State<MyPartners> {

  List<RivalUser> partners;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getPartner();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Partners'),
      ),
      body: isLoading
      ? Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: CircularProgressIndicator(),
          )
        ],
      )
      : ListView.separated(
        itemBuilder: (context, index) => PartnerWidget(user: partners[index]),
        separatorBuilder: (context, index) => Divider(),
        itemCount: partners.length
      ),
    );
  }

  Future<void> _getPartner() async {
    partners = [];
    for (String uid in me.partners.keys) {
      RivalUser user = await getUser(uid);
      partners.add(user);
    }
    setState(() {
      isLoading = false;
    });
  }

}