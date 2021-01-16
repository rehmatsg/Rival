import 'package:e/app.dart';
import 'package:e/screens/sponsor.dart';
import 'package:flutter/material.dart';

class Creator extends StatefulWidget {
  @override
  _CreatorState createState() => _CreatorState();
}

class _CreatorState extends State<Creator> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Creator'),
        actions: [
          IconButton(
            icon: Icon(Icons.help),
            onPressed: () => Navigator.of(context).push(RivalNavigator(page: CreatorIntro()))
          )
        ],
      ),
      body: ListView(
        children: [
          MyAccountDisplay(),
          Container(height: 10,),
          Divider(),
          Container(height: 10,),
          ListTile(
            title: Text('Insights'),
            subtitle: Text('View detailed insights of your account'),
            onTap: () => Navigator.of(context).push(RivalNavigator(page: AccountInsights())),
          ),
          ListTile(
            title: Text('Sponsors'),
            subtitle: Text('View and manage sponsors'),
            onTap: () => Navigator.of(context).push(RivalNavigator(page: ManageSponsor())),
          ),
        ],
      ),
    );
  }
}