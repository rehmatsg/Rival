import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../app.dart';

class ApplyForVerification extends StatefulWidget {
  @override
  _ApplyForVerificationState createState() => _ApplyForVerificationState();
}

class _ApplyForVerificationState extends State<ApplyForVerification> {

  String category;

  TextEditingController _nameCtrl = TextEditingController();
  TextEditingController _knownAsCtrl = TextEditingController();

  /// Image of Govt. issued ID
  File id;

  @override
  void initState() {
    if (me.category != null) category = me.category;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify Account'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Text('Get you account verified by filling the form below. Note that verification is generally meant for public figures or global brands. Applying for verification does not guarentee that your account will be verified'),
          ),
          ListTile(
            leading: ProfilePhoto(
              width: 40,
              height: 40,
              hero: false,
            ),
            title: Text(me.displayName),
            subtitle: Text(me.username),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Full Name*',
                helperText: 'Your full name as on your govt issued id',
                filled: true,
              ),
              keyboardType: TextInputType.name,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: TextFormField(
              controller: _knownAsCtrl,
              decoration: InputDecoration(
                labelText: 'Publicly Knows As*',
                helperText: 'Your name as known publicy',
                filled: true,
              ),
              keyboardType: TextInputType.name,
            ),
          ),
          ListTile(
            title: Text('ID*'),
            subtitle: Text('Please attach a Government issued ID (e.g. Driver\'s License, Passport or Aadhar Card)'),
            trailing: TextButton(
              child: Text(id == null ? 'Select' : 'Selected'),
              onPressed: () async {
                if (id != null) {} // File already selected
                else {
                  PickedFile pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() {
                      id = File(pickedFile.path);
                    });
                  }
                }
              },
            ),
          ),
          if (me.category == null) ListTile(
            title: Text('Category'),
            subtitle: Text('Please select a category for your account'),
            trailing: PopupMenuButton(
              child: Text(category ?? 'Select'),
              itemBuilder: (context) => List.generate(
                businessCategories.length,
                (index) => PopupMenuItem(
                  child: Text(businessCategories[index]),
                  value: businessCategories[index],
                )
              ),
              onSelected: (value) {
                setState(() {
                  category = value;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Text('We may contact you later on your email ${me.email} for verification'),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _submit,
                  child: Text('Submit'),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> _submit() async {
    String fullName = _nameCtrl.text.toLowerCase().trim();
    String publicName = _knownAsCtrl.text.toLowerCase().trim();
    if (fullName != null && fullName != "" && publicName != null && publicName != "" && id != null && category != null) await submit(fullName: fullName, publicName: publicName);
  }

  Future<void> submit({@required String fullName, @required String publicName}) async {
    int timestamp = new DateTime.now().millisecondsSinceEpoch;
    
    Loader.show(
      context,
      function: () async {
        String imageUrl = await (await FirebaseStorage.instance.ref().child('verification').child(timestamp.toString()).putFile(id).onComplete).ref.getDownloadURL();
        String applicationId = firestore.collection('rival').doc('applications').collection('verification').doc().id;
        DocumentReference applicationRef = firestore.collection('rival').doc('applications').collection('verification').doc(applicationId);

        await applicationRef.set({
          'timestamp': timestamp,
          'username': me.username,
          'uid': me.uid,
          'ref': me.reference,
          'govtId': imageUrl,
          'applicationId': applicationId,
          'category': category,
          'fullName': fullName,
          'publicName': publicName
        });
      },
      onComplete: () {
        RivalProvider.showToast(text: 'Application Submited');
        Navigator.of(context).pushAndRemoveUntil(RivalNavigator(page: Home()), (route) => false);
      }
    );
  }
  
}