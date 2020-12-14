import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../app.dart';

class SearchPage extends StatefulWidget {

  SearchPage({Key key, this.searchQuery}) : super(key: key);
  final String searchQuery;

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {

  TextEditingController _controller = TextEditingController();

  Widget _home = Container();
  
  @override
  void initState() {
    super.initState();
    if (widget.searchQuery != null) {
      _controller.text = widget.searchQuery;
      _search();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: 'Search...',
            hintStyle: TextStyle(fontFamily: RivalFonts.feature, fontSize: 20),
            border: InputBorder.none
          ),
          onFieldSubmitted: (value) {
            _search();
          },
          textInputAction: TextInputAction.search,
        ),
        actions: [
          IconButton(icon: Icon(Icons.search), onPressed: () {
            _search();
          })
        ],
      ),
      body: _home,
    );
  }

  _search() async {
    List<String> queryList = _controller.text.split(' ');
    String query = queryList.first.toLowerCase().trim();
    print('Searching for $query');
    if (query.startsWith('#')) {
      // Search for tags in post
      QuerySnapshot querySnapshot = await firestore.collection('posts').where('keywords', arrayContains: query).get();
      if (querySnapshot.docs.length == 0) {
        setState(() {
          _home = Center(
            child: Column(
              children: [
                Container(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Chip(label: Text('No result found')),
                  ),
                ),
              ],
            ),
          );
        });
      }
      return Container();
    } else {
      // Search for people
      QuerySnapshot querySnapshot = await firestore.collection('users').where('username', isGreaterThanOrEqualTo: query).get();
      if (querySnapshot.docs.length == 0) {
        setState(() {
          _home = Center(
            child: Column(
              children: [
                Container(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Chip(label: Text('No result found')),
                  ),
                ),
              ],
            ),
          );
        });
      }
      setState(() {
        _home = ListView(
          children: List.generate(
            querySnapshot.docs.length,
            (index) => ListTile(
              leading: ClipOval(
                child: (querySnapshot.docs[index].data()['photoUrl'] != null)
                ? Image.network(querySnapshot.docs[index].data()['photoUrl'], width: 40, height: 40,)
                : Image.asset('assets/images/avatar.png', width: 40, height: 40,)
              ),
              title: Text(querySnapshot.docs[index].data()['displayName']),
              subtitle: Text(querySnapshot.docs[index].data()['username']),
              onTap: () async {
                User me = FirebaseAuth.instance.currentUser;
                if (me.uid == querySnapshot.docs[index].data()['uid']) {
                  Navigator.of(context).push(
                    RivalNavigator(page: ProfilePage(isCurrentUser: true)),
                  );
                } else {
                  Navigator.of(context).push(
                    RivalNavigator(page: ProfilePage(user: RivalUser(doc: querySnapshot.docs[index])),)
                  );
                }
              },
            )
          ),
        );
      });
    }
  }

}