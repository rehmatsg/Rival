import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';

import 'app.dart';

class RivalSearchDelegate extends SearchDelegate {
  final FirebaseAnalytics analytics = FirebaseAnalytics();

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  ThemeData appBarTheme(BuildContext context) {
    assert(context != null);
    final ThemeData theme = Theme.of(context);
    assert(theme != null);
    return theme.copyWith(
      primaryColor: MediaQuery.of(context).platformBrightness == Brightness.dark
          ? Colors.white10
          : Colors.white,
      primaryIconTheme: theme.primaryIconTheme.copyWith(
          color: MediaQuery.of(context).platformBrightness == Brightness.light
              ? Colors.black
              : Colors.white),
      primaryColorBrightness: MediaQuery.of(context).platformBrightness,
      primaryTextTheme: theme.textTheme,
    );
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    analytics.logSearch(searchTerm: query);
    List<String> queryList = query.split(' ');
    String queryLocal = queryList.first.toLowerCase().trim();
    if (queryLocal == null || queryLocal == "") {
      return Container();
    } else if (queryLocal.startsWith('#')) {
      // Search for tags in post
      return FutureBuilder(
        future: firestore
            .collection('posts')
            .where('keywords',
                arrayContains: queryLocal.substring(1, queryLocal.length))
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            QuerySnapshot querySnapshot = snapshot.data;
            if (querySnapshot.docs.length == 0) {
              return Center(
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
            } else {
              return ListView(
                children: List.generate(
                    querySnapshot.docs.length,
                    (index) => FutureBuilder(
                          future: Post.fetch(doc: querySnapshot.docs[index]),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.done) {
                              return ViewPost(post: snapshot.data);
                            }
                            return Container();
                          },
                        )),
              );
            }
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomProgressIndicator()
              ],
            ),
          );
        },
      );
    } else {
      // Search for people
      String query = queryLocal.startsWith('@')
          ? queryLocal.substring(1, queryLocal.length)
          : queryLocal;
      return FutureBuilder(
        future: firestore
            .collection('users')
            .where('username', isEqualTo: query)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            QuerySnapshot querySnapshot = snapshot.data;
            if (querySnapshot.docs.length == 0) {
              return Center(
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
            }
            return ListView.builder(
              itemCount: querySnapshot.docs.length,
              itemBuilder: (context, index) => UserListTile(
                doc: querySnapshot.docs[index],
              ),
            );
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomProgressIndicator()
              ],
            ),
          );
        },
      );
    }
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // This method is called everytime the search term changes.
    // If you want to add search suggestions as the user enters their search term, this is the place to do that.
    return Column();
  }
}
