import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bitmap/bitmap.dart';
import 'package:bitmap/transformations.dart' as btmp;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:octo_image/octo_image.dart';
//import 'app.dart';
import 'package:image/image.dart' as IMG;

import 'providers.dart';

class Test extends StatefulWidget {
  @override
  _TestState createState() => _TestState();
}

class _TestState extends State<Test> {

  List<DocumentSnapshot> allUsers;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Change USERS'),
      ),
      body: ListView(
        children: [
          if  (isLoading) Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator()
            ),
          ),
          if (allUsers == null && !isLoading) FlatButton(
            onPressed: () async {
              setState(() {
                isLoading = true;
              });
              allUsers = (await firestore.collection('users').get()).docs;
              print('Loaded ${allUsers.length} users');
              setState(() {
                isLoading = false;
              });
            },
            child: Text('Load Users')
          ),
          if (allUsers != null) FlatButton(
            onPressed: () async {
              setState(() {
                isLoading = true;
              });
              for (DocumentSnapshot doc in allUsers) {
                bool isBusinessAccount = doc.data()['isBusinessAccount'];
                await doc.reference.update({
                  'type': isBusinessAccount ? 'business' : 'personal'
                });
              }
              print('Commited all users');
              setState(() {
                isLoading = false;
              });
            },
            child: Text('Commit')
          )
        ],
      ),
    );
  }
}

class Test2 extends StatefulWidget {
  @override
  _Test2State createState() => _Test2State();
}

class _Test2State extends State<Test2> {

  File image;
  Uint8List u8l;
  Bitmap bg;
  Bitmap img;
  ui.Image imgImg;

  @override
  void initState() { 
    super.initState();
    bg = Bitmap.blank(800, 800);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TEST'),
      ),
      body: ListView(
        children: [
          FlatButton(
            onPressed: () async {
              PickedFile pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);
              image = File(pickedFile.path);
              img = await Bitmap.fromProvider(FileImage(image));
              imgImg = await getUiImage(img.buildHeaded(), 100, 100);

              setState(() {
                u8l = image.readAsBytesSync();
              });
            },
            child: Text('Pick Image')
          ),
          if (image != null) OctoImage(
            image: FileImage(image),
          ),
          if (u8l != null) OctoImage(
            image: MemoryImage(u8l),
          ),
          if (bg != null) OctoImage(
            image: MemoryImage(bg.buildHeaded()),
          ),
          if (bg != null && image != null) FutureBuilder<ui.Image>(
            future: bg.buildImage(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) return CustomPaint(
                size: Size(800, 800),
                painter: MyPainter(background: snapshot.data, image: imgImg),
              );
              return Container();
            },
          ),
          FlatButton(
            onPressed: () {
              setState(() {
                bg = btmp.brightness(bg, 1);
              });
              print('Done');
            },
            child: Text('Change BG to White'),
          )
        ],
      ),
    );
  }

  Future<ui.Image> getUiImage(Uint8List uint8list, int height, int width) async {
    IMG.Image baseSizeImage = IMG.decodeImage(uint8list);
    IMG.Image resizeImage = IMG.copyResize(baseSizeImage, height: height, width: width);
    ui.Codec codec = await ui.instantiateImageCodec(IMG.encodePng(resizeImage));
    ui.FrameInfo frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }

}

class MyPainter extends CustomPainter {

  final ui.Image background;
  final ui.Image image;

  MyPainter({@required this.image, @required this.background});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, 800, 800), Paint()..color = Colors.white);
    canvas.drawImage(image, Offset(0, 0), Paint());
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}