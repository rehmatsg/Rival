import 'package:flutter/material.dart';
import '../app.dart';

class BusinessPage extends StatefulWidget {
  @override
  _BusinessPageState createState() => _BusinessPageState();
}

class _BusinessPageState extends State<BusinessPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Business Tools'),
        actions: [
          IconButton(
            icon: Icon(Icons.help),
            onPressed: () => Navigator.of(context).push(RivalNavigator(page: BusinessIntro()))
          )
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Insights'),
            subtitle: Text('View Insights of your Posts'),
            onTap: () => Navigator.of(context).push(RivalNavigator(page: AccountInsights())),
          ),
          ListTile(
            title: const Text('Sponsors'),
            subtitle: Text('View and manage sponsors'),
            onTap: () => Navigator.of(context).push(RivalNavigator(page: ManageSponsor())),
          ),
          ListTile(
            title: const Text('Contact'),
            subtitle: const Text('Choose contact options for your profile'),
            onTap: () => Navigator.of(context).push(RivalNavigator(page: BusinessContact())),
          ),
          ListTile(
            title: const Text('Setup Shopping'),
            subtitle: Text('Create Posts to sell your product'),
            onTap: () => Navigator.of(context).push(RivalNavigator(page: EmailPage())),
          ),
        ],
      ),
    );
  }
}