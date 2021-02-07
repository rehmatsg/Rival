import 'package:flutter/material.dart';
import '../app.dart';

class SelectSponsor<RivalUser> extends StatefulWidget {
  @override
  _SelectSponsorState createState() => _SelectSponsorState();
}

class _SelectSponsorState extends State<SelectSponsor> {

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
        itemBuilder: (context, index) => SelectSponsorWidget(
          user: partners[index],
          onSelect: (sponsor) => Navigator.of(context).pop(sponsor),
        ),
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

class SelectSponsorWidget extends StatefulWidget {

  final RivalUser user;
  final Function(RivalUser sponsor) onSelect;

  const SelectSponsorWidget({Key key, @required this.user, this.onSelect}) : super(key: key);

  @override
  _SelectSponsorWidgetState createState() => _SelectSponsorWidgetState();
}

class _SelectSponsorWidgetState extends State<SelectSponsorWidget> {

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
              FlatButton(
                child: Text('Select', style: TextStyle(color: Colors.white),),
                onPressed: isBtnLoading ? null : () => _partnerBtnTap(user),
                color: Colors.indigoAccent
              )
            ],
          ),
        ),
        Container(height: 10),
      ],
    );
  }

  Future<void> _partnerBtnTap(RivalUser user) async {
    widget.onSelect(user);
  }

}