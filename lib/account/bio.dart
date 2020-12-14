import 'package:flutter/material.dart';
import '../app.dart';

class EditBio extends StatefulWidget {

  const EditBio({
    Key key,
  }) : super(key: key);

  @override
  _EditBioState createState() => _EditBioState();
}

class _EditBioState extends State<EditBio> {

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    if (me.doc.data()['bio'] != null) {
      _controller.text = me.doc.data()['bio'].toString();
    }
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
        title: const Text('Bio'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ProfilePhoto(height: 100, width: 100),
            Container(height: 15,),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              child: TextFormField(
                controller: _controller,
                decoration: const InputDecoration(
                  filled: true,
                  labelText: 'Bio',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
                minLines: 3,
                maxLines: 7,
                maxLength: 500,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlineButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final String bio = _controller.text.trim();
    await me.reference.update({
      'bio': bio
    });
    await me.reload();
    _scaffoldKey.currentState.showSnackBar(const SnackBar(content: Text('Updated your bio')));
    //Navigator.pushAndRemoveUntil(context, RivalNavigator(page: Home(),), (route) => false);
  }

}