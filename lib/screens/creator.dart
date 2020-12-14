import 'package:e/app.dart';
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
          )
        ],
      ),
    );
  }
}