import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../app.dart';

class AddSponsor extends StatefulWidget {
  @override
  _AddSponsorState createState() => _AddSponsorState();
}

class _AddSponsorState extends State<AddSponsor> {

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController usernameCtrl = TextEditingController();

  RivalUser user;

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Add Partner'),
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
      : ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: TextFormField(
              controller: usernameCtrl,
              decoration: InputDecoration(
                filled: true,
                labelText: 'Search by username',
                prefixText: '@',
                isDense: true,
                border: UnderlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  borderSide: BorderSide.none
                ),
              ),
              keyboardType: TextInputType.name,
              onFieldSubmitted: _search,
            ),
          ),
          if (user != null) PartnerWidget(user: user)
        ],
      ),
    );
  }

  Future<void> _search(String username) async {
    username = username
     ..replaceAll(new RegExp(r'\W+'), '')
     ..toLowerCase()
     ..trim();

    if (username != me.username) {
      setState(() {
        isLoading = true;
      });
      QuerySnapshot query = await firestore.collection('users').where('username', isEqualTo: username).get();
      if (query.docs.isNotEmpty) user = RivalUser(doc: query.docs.first);
      else _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text('No user found with username @$username'),));
      setState(() {
        isLoading = false;
      });
    }
  }

}

class PartnerWidget extends StatefulWidget {

  final RivalUser user;

  const PartnerWidget({Key key, @required this.user}) : super(key: key);

  @override
  _PartnerWidgetState createState() => _PartnerWidgetState();
}

class _PartnerWidgetState extends State<PartnerWidget> {

  bool isBtnLoading = false;
  RivalUser user;

  @override
  void initState() {
    user = widget.user;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        UserListTile(
          isCurrentUser: false,
          user: user,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              if (user.isBusinessAccount || me.partners.containsKey(user.uid)) TextButton(
                child: isBtnLoading ? Container(
                  height: 14,
                  width: 14,
                  child: CustomProgressIndicator(
                    valueColor: Colors.white,
                    strokeWidth: 2,
                  )
                ) : Text(_getPartnerBtnText(user), style: TextStyle(color: Colors.white),),
                onPressed: isBtnLoading ? null : () => _partnerBtnTap(user),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.indigoAccent
                ),
              ) else ... [
                Icon(Icons.warning, color: Colors.yellow, size: 15,),
                Container(width: 5),
                Text('@${user.username} does not have a business account', style: Theme.of(context).textTheme.subtitle2)
              ]
            ],
          ),
        ),
        Container(height: 10),
      ],
    );
  }

  String _getPartnerBtnText(RivalUser user) {
    if (me.partners.containsKey(user.uid)) {
      return 'Remove Partner';
    } else if (user.manuallyApprovePartnerRequests && !user.partnerRequests.containsKey(me.uid)) {
      return 'Request Partner';
    } else if (user.manuallyApprovePartnerRequests && user.partnerRequests.containsKey(me.uid)) {
      return 'Requested';
    } else {
      return 'Add as Partner';
    }
  }

  Future<void> _partnerBtnTap(RivalUser user) async {
    setState(() {
      isBtnLoading = true;
    });
    if (user.manuallyApprovePartnerRequests && !user.partnerRequests.containsKey(me.uid)) {
      await user.update({
        'partnerRequests.${me.uid}': DateTime.now().millisecondsSinceEpoch
      }, reload: true);
      RivalProvider.showToast(text: 'Requested @${user.username}');
    } else if (user.manuallyApprovePartnerRequests && user.partnerRequests.containsKey(me.uid)) {
      await user.update({
        'partnerRequests.${me.uid}': FieldValue.delete()
      }, reload: true);
      RivalProvider.showToast(text: 'Request Deleted');
    } else if (me.partners.containsKey(user.uid)) {
      await user.update({
        'partners.${me.uid}': FieldValue.delete()
      }, reload: true);
      await me.update({
        'partners.${user.uid}': FieldValue.delete()
      }, reload: true);
      RivalProvider.showToast(text: 'Remove Partner');
    } else {
      int timestamp = DateTime.now().millisecondsSinceEpoch;
      await user.update({
        'partners.${me.uid}': timestamp
      }, reload: true);
      await me.update({
        'partners.${user.uid}': timestamp
      }, reload: true);
      RivalProvider.showToast(text: 'Added @${user.username} as partner');
    }
    setState(() {
      isBtnLoading = false;
    });
  }

}