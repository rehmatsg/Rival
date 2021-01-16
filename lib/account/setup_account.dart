import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../app.dart';

class SetupAccount extends StatefulWidget {
  @override
  _SetupAccountState createState() => _SetupAccountState();
}

class _SetupAccountState extends State<SetupAccount> {

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  TextEditingController _displayNameCtrl = TextEditingController();
  TextEditingController _bioCtrl = TextEditingController();

  String gender;

  @override
  void initState() {
    super.initState();
    if (me.data['displayName'] != null) { // me.displayName is null safe
      _displayNameCtrl.text = me.displayName;
    } else if (me.bio != null) {
      _bioCtrl.text = me.bio;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Setup Account'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 15),
              child: Center(
                child: GestureDetector(
                  onTap: _updatePhoto,
                  child: ProfilePhoto(hero: false,),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
              child: TextFormField(
                controller: _displayNameCtrl,
                decoration: InputDecoration(
                  filled: true,
                  labelText: 'Name',
                  helperText: 'This will be visible to people on Rival',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
              child: TextFormField(
                controller: _bioCtrl,
                decoration: InputDecoration(
                  filled: true,
                  labelText: 'Bio',
                  floatingLabelBehavior: FloatingLabelBehavior.always
                ),
                minLines: 3,
                maxLines: 7,
                maxLength: 500,
              ),
            ),
            ListTile(
              title: Text('Add DOB'),
              subtitle: Text('This information is kept private'),
              trailing: IconButton(
                icon: Icon(Icons.date_range),
                onPressed: (me.dob == null) ? _addDOB : null
              ),
            ),
            if (me.gender == null) ListTile(
              title: Text('Select Gender'),
              subtitle: Text('This information is kept private'),
              trailing: IconButton(
                icon: Icon(Icons.keyboard_arrow_right),
                onPressed: () async{
                  gender = await _addGender();
                  setState(() { });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlineButton(
                    onPressed: _save,
                    child: Text('Save')
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _updatePhoto() async {
    final _image = await ImagePicker().getImage(source: ImageSource.gallery);
    if (_image != null && _image.path != null) {
      final File croppedFile = await cropProfilePicture(path: _image.path);
      if (croppedFile != null) await me.updateProfilePhoto(photo: croppedFile);
    }
  }

  Future<void> _addDOB() async {
    DateTime dob = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950, 1, 1),
      lastDate: DateTime.now()
    );
    if (dob != null) {
      if (await me.addDateOfBith(date: dob)) {
        await RivalProvider.showToast(text: 'Updated your Age');
      } else {
        _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text('You need to be atleast 12 years old to use Rival')));
      }
    }
  }

  Future<String> _addGender() async {
    Gender gender = await Navigator.of(context).push(RivalNavigator(page: SelectGender()));
    if (gender == Gender.male) return 'Male';
    else if (gender == Gender.female) return 'Female';
    else if (gender == Gender.custom) return 'Prefer Not to Say';
    else return null;
  }

  Future<void> _save() async {
    String displayName = _displayNameCtrl.text.trim();
    String bio = _bioCtrl.text.trim();

    Loader.show(
      context,
      function: () async {
        await me.update({
          'displayName': displayName,
          'bio': bio,
        }, reload: true);
      },
      onComplete: () {
        RivalProvider.showToast(text: 'Setup Complete');
        if (me.username != null) {
          Navigator.of(context).pushAndRemoveUntil(RivalNavigator(page: Home()), (route) => false);
        } else {
          Navigator.of(context).pushAndRemoveUntil(RivalNavigator(page: Username()), (route) => false);
        }
      }
    );
  }
  
}