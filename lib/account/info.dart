import 'package:flutter/material.dart';
import '../app.dart';

class Info extends StatefulWidget {

  const Info({Key key}) : super(key: key);

  @override
  _InfoState createState() => _InfoState();
}

class _InfoState extends State<Info> {

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Personal Information'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              title: Text(me.doc.data()['displayName'].toString() ?? 'Tap to set your name'),
              subtitle: const Text('Display Name'),
              onTap: () => Navigator.of(context).push(RivalNavigator(page: const EditName())),
            ),
            ListTile(
              title: const Text('Gender'),
              subtitle: Text(me.gender ?? 'Tap to set your gender'),
              onTap: (me.gender == null) ? () => Navigator.of(context).push(RivalNavigator(page: SelectGender())) : () {},
            ),
            ListTile(
              title: const Text('Age'),
              subtitle: Text(me.dob != null ? '${me.dob.day} ${months[me.dob.month]} ${me.dob.year}' : 'Tap to add age'),
              onTap: (me.age == null) ? _addDOB : () {},
            ),
            ListTile(
              title: Text('Phone Number'),
              subtitle: Text(me.phoneNumber ?? 'Tap to add your phone number'),
              onTap: me.phoneNumber != null ? null : () => Navigator.of(context).push(RivalNavigator(page: LinkPhoneNumber())),
            ),
            ListTile(
              title: Text('Category'),
              subtitle: Text(me.category ?? 'Tap to add a category'),
              onTap: () async {
                await Navigator.of(context).push(RivalNavigator(page: BusinessCategory()));
                setState(() {});
              }
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addDOB() async {
    DateTime dob = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950, 1, 1),
      lastDate: DateTime.now()
    );
    if (await me.addDateOfBith(date: dob)) {
      await RivalProvider.showToast(text: 'Updated your Age');
    } else {
      _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text('You need to be atleast 12 years old to use Rival')));
    }
  }

}