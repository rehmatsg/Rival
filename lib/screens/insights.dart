import 'package:flutter/material.dart';
import 'package:supercharged/supercharged.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import '../app.dart';

class AccountInsights extends StatefulWidget {
  @override
  _AccountInsightsState createState() => _AccountInsightsState();
}

class _AccountInsightsState extends State<AccountInsights> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Insights'),
      ),
      body: ListView(
        
      ),
    );
  }
}

// class AccountInsights extends StatefulWidget {
//   @override
//   _AccountInsightsState createState() => _AccountInsightsState();
// }

// class _AccountInsightsState extends State<AccountInsights> {

//   List<Post> posts;

//   bool isLoading = true;

//   _init() async {
//     //posts = await getMyPosts();
//     // setState(() {
//     //   isLoading = false;
//     // });
//   }

//   @override
//   void initState() { 
//     super.initState();
//     _init();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Account'),
//       ),
//       body: isLoading
//       ? Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator()
//           ],
//         )
//       )
//       : ListView(
//         children: [
//           Row(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.only(top: 20, left: 15, right: 15, bottom: 5),
//                 child: Text('Insigths', style: TextStyle(fontSize: Theme.of(context).textTheme.headline3.fontSize, fontFamily: RivalFonts.feature),),
//               ),
//             ],
//           ),
//           Container(height: 20,),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//             child: Column(
//               children: [
//                 SizedBox(
//                   width: MediaQuery.of(context).size.width - 20,
//                   height: MediaQuery.of(context).size.width * 2/3,
//                   child: PostImpressionGraph(posts: posts,)
//                 ),
//                 Text('Impressions', style: Theme.of(context).textTheme.caption)
//               ],
//             ),
//           ),
//           Divider(),
//         ],
//       )
//     );
//   }

// }

// class WeekDay {
//   final String day;
//   final int count;

//   WeekDay({@required this.day, @required this.count});
// }

// class PostImpressionGraph extends StatefulWidget {

//   final List<Post> posts;

//   const PostImpressionGraph({Key key, @required this.posts}) : super(key: key);

//   @override
//   _PostImpressionGraphState createState() => _PostImpressionGraphState();
// }

// class _PostImpressionGraphState extends State<PostImpressionGraph> {

//   List<Post> posts;

//   Map<String, int> weekDaysData = {
//     'Sun': 0,
//     'Mon': 0,
//     'Tue': 0,
//     'Wed': 0,
//     'Thur': 0,
//     'Fri': 0,
//     'Sat': 0,
//   };

//   List<WeekDay> data;
//   var series;

//   @override
//   void initState() {
//     posts = widget.posts;
//     super.initState();
//     _init();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return charts.BarChart(
//       series,
//       animate: true,
//     );
//   }

//   _init() async {
//     posts.forEachIndexed((int index, Post post) {
//       post.impressions.values.forEach((timestamp) {
//         DateTime dateTime = new DateTime.fromMillisecondsSinceEpoch(timestamp);
//         int weekDay = dateTime.weekday;
//         if (weekDay == 7) weekDay = 0;
//         String weekDayName = weekDaysData.keys.toList()[weekDay];
//         int previousVal = weekDaysData[weekDayName];
//         weekDaysData[weekDayName] = previousVal + 1;
//       });
//     });
//     print(weekDaysData);
//     data = [];
//     weekDaysData.forEach((day, value) {
//       data.add(WeekDay(day: day, count: value));
//     });
//     series = [
//       new charts.Series(
//         id: 'Impression',
//         data: data,
//         domainFn: (WeekDay impData, index) => impData.day,
//         measureFn: (WeekDay impData, index) => impData.count,
//         colorFn: (WeekDay impData, index) => charts.Color(r: Colors.indigoAccent.red, b: Colors.indigoAccent.blue, g: Colors.indigoAccent.green),
//       )
//     ];
//   }
// }

// class PostTimeGraph extends StatefulWidget {

//   final List<Post> posts;

//   const PostTimeGraph({Key key, @required this.posts}) : super(key: key);

//   @override
//   _PostTimeGraphState createState() => _PostTimeGraphState();
// }

// class _PostTimeGraphState extends State<PostTimeGraph> {

//   List<Post> posts;

//   Map<int, int> hourData = {
//     8: 0,
//     10: 0,
//     12: 0,
//     15: 0,
//     17: 0,
//     19: 0,
//     21: 0,
//   };

//   List<WeekDay> data;
//   var series;

//   @override
//   void initState() {
//     posts = widget.posts;
//     super.initState();
//     _init();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return charts.BarChart(
//       series,
//       animate: true,
//     );
//   }

//   _init() async {
//     posts.forEachIndexed((int index, Post post) {
//       // DateTime dateTime = new DateTime.fromMillisecondsSinceEpoch(post.timestamp);
//       // int weekDay = dateTime.weekday;
//       // if (weekDay == 7) weekDay = 0;
//       // String weekDayName = weekDaysData.keys.toList()[weekDay];
//       // int previousVal = weekDaysData[weekDayName];
//       // weekDaysData[weekDayName] = previousVal + 1;
//     });
//     // print(weekDaysData);
//     data = [];
//     // weekDaysData.forEach((day, value) {
//     //   data.add(WeekDay(day: day, count: value));
//     // });
//     series = [
//       new charts.Series(
//         id: 'Impression',
//         data: data,
//         domainFn: (WeekDay impData, index) => impData.day,
//         measureFn: (WeekDay impData, index) => impData.count,
//         colorFn: (WeekDay impData, index) => charts.Color(r: Colors.indigoAccent.red, b: Colors.indigoAccent.blue, g: Colors.indigoAccent.green),
//       )
//     ];
//   }
// }