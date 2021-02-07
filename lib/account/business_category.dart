import 'package:flutter/material.dart';
import '../app.dart';

class BusinessCategory extends StatefulWidget {
  @override
  _BusinessCategoryState createState() => _BusinessCategoryState();
}

final List<String> businessCategories = [
  'Actor',
  'Architectural Designer',
  'Artist',
  'Author',
  'Band',
  'Blogger',
  'Chef',
  'Coach',
  'Comedian',
  'Concert Tour',
  'Dancer',
  'Designer',
  'DJ',
  'Editor',
  'Engineer',
  'Enterprenuer',
  'Fashion Designer',
  'Fashion Model',
  'Film Character',
  'Film Director',
  'Fitness Model',
  'Fitness Trainer',
  'Gamer',
  'Government Official',
  'Graphic Designer',
  'Interior Design Studio',
  'Journalist',
  'Motivational Speaker',
  'Musician',
  'News Personality',
  'Photographer',
  'Political Candidate',
  'Politician',
  'Producer',
  'Public Figure',
  'Scientist',
  'Software Engineer',
  'Sportsperson',
  'Video Creator',
  'Web Designer',
  'Web Developer',
  'Writer',
];

class _BusinessCategoryState extends State<BusinessCategory> {

  String currentBusinessCategory;

  @override
  void initState() {
    currentBusinessCategory = me.category;
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
        title: Text('Profile Category'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
            child: Row(
              children: [
                ProfilePhoto(width: 50, height: 50,),
                Container(width: 15,),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      me.doc.data()['displayName'] != null ? me.doc.data()['displayName'] : 'Tap to set your name',
                      style: Theme.of(context).textTheme.headline6.copyWith(
                        fontFamily: RivalFonts.feature,
                      )
                    ),
                    Text(
                      me.doc.data()['username'] != null ? me.doc.data()['username'] : 'Tap to set your username',
                      style: Theme.of(context).textTheme.subtitle2
                    ),
                  ],
                )
              ],
            ),
          ),
          ... List.generate(
            businessCategories.length,
            (index) => ListTile(
              title: Text(businessCategories[index]),
              onTap: () async {
                setState(() {
                  currentBusinessCategory = businessCategories[index];
                });
                await me.update({
                  'category': businessCategories[index]
                });
                await me.reload();
              },
              visualDensity: VisualDensity.compact,
              selected: currentBusinessCategory == businessCategories[index],
              subtitle: currentBusinessCategory == businessCategories[index] ? Text('Selected') : null,
            )
          ),
          Divider(),
          ListTile(
            focusColor: Colors.red,
            title: Text('Remove'),
            subtitle: Text('Remove Category from Profile'),
            onTap: () async {
              setState(() {
                currentBusinessCategory = null;
              });
              await me.update({
                'category': null
              });
              await RivalProvider.showToast(text: 'Removed Category');
              await me.reload();
            },
          )
        ],
      ),
    );
  }
}