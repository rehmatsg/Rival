import 'package:flutter/material.dart';
//import '../app.dart';

List<String> allTopics = [
  'Photography',
  'Videography',
  'Programming',
  'Cooking',
  'Knowledge',
  'Tutorial',
  'Quotes',
  'How-to',
  'Tips',
  'Knowledge',
  'News',
  'Events',
  'Gaming',
  'Poetry',
  'Design',
  'Food',
  'Culture',
  'Pets',
  'Outdoors',
  'Sports',
  'Travel',
  'Health',
  'Business',
  'Marketing',
  'UX',
  'Creativity',
  'Productivity',
  'Science',
  'Space',
  'Astrology',
  'Self',
  'Spirituality',
  'History',
  'Education',
  'World',
  'Social Media',
  'Artificial Intelligence',
  'Gadgets',
  'Technology'
];


/// Return [String] `topic` related to which the user is creating post
class SelectTopic<String> extends StatefulWidget {
  @override
  _SelectTopicState createState() => _SelectTopicState();
}

class _SelectTopicState extends State<SelectTopic> {

  List<String> copy;

  @override
  void initState() {
    copy = allTopics;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Topic'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              child: TextFormField(
                decoration: InputDecoration(
                  filled: true,
                  labelText: 'Search',
                  isDense: true,
                  border: UnderlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    borderSide: BorderSide.none
                  ),
                ),
                keyboardType: TextInputType.name,
                onChanged: _search,
              ),
            ),
            ListView.separated(
              itemBuilder: (context, index) => ListTile(
                title: Text(copy[index]),
                onTap: () => Navigator.of(context).pop(copy[index]),
                visualDensity: VisualDensity.compact
              ),
              separatorBuilder: (context, index) => Divider(),
              itemCount: copy.length,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics()
            ),
          ],
        ),
      ),
    );
  }

  void _search(String query) {
    query = query.toLowerCase().trim();
    if (query != "") {
      search(query: query);
    } else {
      setState(() {
        copy = allTopics;
      });
    }
  }

  void search({@required String query}) {
    copy = allTopics.where((item) {
      if (item.contains(query) || item.toLowerCase().contains(query)) {
        return true;
      } else {
        return false;
      }
    }).toList();
    setState(() { });
  }

}