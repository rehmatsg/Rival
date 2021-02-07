import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../app.dart';

class EditName extends StatefulWidget {

  const EditName({Key key}) : super(key: key);

  @override
  _EditNameState createState() => _EditNameState();
}

class _EditNameState extends State<EditName> {

  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    if (me.displayName != null) {
      _controller.text = me.displayName.toString();
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
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: _updatePhoto,
              child: Tooltip(
                message: 'Change Profile Photo',
                child: ProfilePhoto(width: 100, height: 100,),
              ),
            ),
            Container(height: 15,),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              child: TextFormField(
                controller: _controller,
                decoration: const InputDecoration(
                  filled: true,
                  labelText: 'Name'
                ),
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
    final String name = _controller.text.trim();
    if (name != null && name != "" && RivalRemoteConfig.allowNameChange) {
      Loader.show(
        context,
        function: () async {
          await me.user.updateProfile(
            displayName: name
          );
          await me.update({
            'displayName': name
          }, reload: true);
          await me.user.reload();
        },
        onComplete: () {
          RivalProvider.showToast(
            text: 'Updated Name',
          );
          Navigator.pushAndRemoveUntil(context, RivalNavigator(page: Home(),), (route) => false);
        }
      );
    } else if (!RivalRemoteConfig.allowNameChange) {
      showDialog(
        context: context,
        child: AlertDialog(
          title: Text('Error'),
          content: Text('Editing display name has been disabled for a limited time. Please try again later'),
          actions: [
            FlatButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK')
            )
          ],
        )
      );
    }
  }

  Future<void> _updatePhoto() async {
    final _image = await ImagePicker().getImage(source: ImageSource.gallery);
    if (_image != null && _image.path != null) {
      final File croppedFile = await cropProfilePicture(path: _image.path);
      if (croppedFile != null) {
        Loader.show(
          context,
          function: () async {
            await me.updateProfilePhoto(photo: croppedFile);
          },
          onComplete: () {
            Navigator.of(context).pushAndRemoveUntil(RivalNavigator(page: Home()), (route) => false);
          }
        );
      }
    }
  }

}