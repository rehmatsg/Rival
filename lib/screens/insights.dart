import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import '../app.dart';

Future<QuerySnapshot> timeInsights;

class AccountInsights extends StatefulWidget {
  @override
  _AccountInsightsState createState() => _AccountInsightsState();
}

class _AccountInsightsState extends State<AccountInsights> {

  @override
  void initState() {
    _init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Insights'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10))
              ),
              color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.white : Colors.white10,
              margin: EdgeInsets.only(left: 5, right: 5, top: 5,),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: 'People who visited your profile from this post',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(right: 10),
                                child: Icon(Icons.people),
                              ),
                              Text('Profile Visits', style: TextStyle(fontFamily: RivalFonts.feature, fontSize: Theme.of(context).textTheme.headline6.fontSize),),
                            ],
                          ),
                          Text('${_getProfileVisitsPercentage() > 0 ? '+' : ''}${_getProfileVisitsPercentage()}%', style: _getProfileVisitsPercentage() > 0 ? Theme.of(context).textTheme.bodyText1.copyWith(color: Colors.green) : Theme.of(context).textTheme.bodyText1)
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              child: Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10))
                ),
                color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.white : Colors.white10,
                margin: EdgeInsets.only(left: 5, right: 5, top: 5,),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Audience Active Time', style: TextStyle(fontFamily: RivalFonts.feature, fontSize: Theme.of(context).textTheme.headline6.fontSize),),
                      Container(height: 10),
                      if (timeInsights != null) FutureBuilder<QuerySnapshot>(
                        future: timeInsights,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                            List<TimeGroupInsight> data = _calculateTimeInsights(snapshot.data.docs);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: SizedBox(
                                    height: MediaQuery.of(context).size.width * 2/3,
                                    width: MediaQuery.of(context).size.width,
                                    child: charts.BarChart([
                                      charts.Series(
                                        data: data,
                                        domainFn: (timeGroup, index) => timeGroup.group,
                                        measureFn: (timeGroup, index) => timeGroup.value,
                                        id: 'Time'
                                      )
                                      ],
                                      animate: true,  
                                    ),
                                  ),
                                ),
                                Container(height: 5),
                                Text('* based on your 10 latest posts', style: Theme.of(context).textTheme.caption)
                              ],
                            );
                          }
                          else if (snapshot.connectionState == ConnectionState.done && (!snapshot.hasData || snapshot.hasError)) return Text('Error calculating this insight');
                          else return Container(
                            width: double.infinity,
                            height: MediaQuery.of(context).size.width / 2,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Center(
                                  child: CircularProgressIndicator(),
                                )
                              ],
                            ),
                          );
                        },
                      ) else Text('Not enough data to calculate this insight')
                    ],
                  )
                ),
              ),
            ),
            Container(
              width: double.infinity,
              child: Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10))
                ),
                color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.white : Colors.white10,
                margin: EdgeInsets.only(left: 5, right: 5, top: 5,),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Audience Active Days', style: TextStyle(fontFamily: RivalFonts.feature, fontSize: Theme.of(context).textTheme.headline6.fontSize),),
                      Container(height: 10),
                      if (timeInsights != null) FutureBuilder<QuerySnapshot>(
                        future: timeInsights,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                            List<WeekdayInsight> data = _calculateWeekdayInsight(snapshot.data.docs);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: SizedBox(
                                    height: MediaQuery.of(context).size.width * 2/3,
                                    width: MediaQuery.of(context).size.width,
                                    child: charts.BarChart([
                                      charts.Series(
                                        data: data,
                                        domainFn: (timeGroup, index) => timeGroup.group,
                                        measureFn: (timeGroup, index) => timeGroup.value,
                                        id: 'Weekdays'
                                      )
                                      ],
                                      animate: true,  
                                    ),
                                  ),
                                ),
                                Container(height: 5),
                                Text('* based on your 10 latest posts', style: Theme.of(context).textTheme.caption)
                              ],
                            );
                          }
                          else if (snapshot.connectionState == ConnectionState.done && (!snapshot.hasData || snapshot.hasError)) return Text('Error calculating this insight');
                          else return Container(
                            width: double.infinity,
                            height: MediaQuery.of(context).size.width / 2,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Center(
                                  child: CircularProgressIndicator(),
                                )
                              ],
                            ),
                          );
                        },
                      ) else Text('Not enough data to calculate this insight')
                    ],
                  )
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _init() {
    if (me.posts.length > 10 && timeInsights == null) {
      timeInsights = firestore.collection('posts').where('creator', isEqualTo: me.uid).orderBy('timestamp', descending: true).limit(10).get();
    }
  }

  double _getProfileVisitsPercentage() {
    List visits = me.visits;
    List thisWeek = [];
    List lastWeek = [];
    DateTime thisMonday = _getThisMonday();
    DateTime lastMonday = _getLastMonday();
    for (int timestamp in visits) {
      DateTime dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (dt.isAfter(thisMonday)) { // This Week
        thisWeek.add(timestamp);
      } else if (dt.isAfter(lastMonday) && dt.isBefore(thisMonday)) { // Last week
        lastWeek.add(timestamp);
      }
    }
    int visitsThisWeek = thisWeek.length;
    int visitsLastWeek = lastWeek.length;
    if (visitsThisWeek == 0) return 0;
    if (visitsLastWeek == 0) return 100;
    double percentageIncrease = (visitsThisWeek - visitsLastWeek) / (visitsLastWeek) * 100;
    return percentageIncrease;
  }

  _getThisMonday() {
    DateTime date = DateTime.now();
    while (date.weekday != 1) {
      date = date.subtract(Duration(days: 1));
    }
    return date;
  }

  _getLastMonday() {
    DateTime date = DateTime.now().subtract(Duration(days: 7));
    while (date.weekday != 1) {
      date = date.subtract(Duration(days: 1));
    }
    return date;
  }

  List<TimeGroupInsight> _calculateTimeInsights(List<DocumentSnapshot> posts) {
    List<DateTime> datetimes = [];
    List<TimeGroupInsight> data = [];
    Map<String, List<DateTime>> groups = {
      'Midnight': [],
      '6AM': [],
      '9AM': [],
      '12PM': [],
      '4PM': [],
      '7PM': [],
      '10PM': []
    };
    for (DocumentSnapshot doc in posts) {
      int timestamp = doc.data()['timestamp'];
      DateTime dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (dt.minute >= 30) {
        dt.add(Duration(minutes: (60 - dt.minute)));
      } else if (dt.minute < 30) {
        dt.subtract(Duration(minutes: dt.minute));
      }
      datetimes.add(dt);
    }
    for (DateTime dt in datetimes) {
      int hour = dt.hour;
      String group;
      if (hour <= 4) {
        group = 'Midnight';
      } else if (hour > 4 && hour <= 8) {
        group = '6AM';
      } else if (hour > 8 && hour <= 19) {
        group = '9AM';
      } else if (hour > 10 && hour <= 14) {
        group = '12PM';
      } else if (hour > 14 && hour <= 18) {
        group = '4PM';
      } else if (hour > 18 && hour <= 21) {
        group = '7PM';
      } else if (hour > 21) {
        group = '10PM';
      } else {
        group = 'Midnight';
      }
      groups[group].add(dt);
    }
    groups.forEach((group, allTime) {
      data.add(TimeGroupInsight(value: allTime.length, group: group));
    });
    return data;
  }

  List<WeekdayInsight> _calculateWeekdayInsight(List<DocumentSnapshot> posts) {
    List<DateTime> datetimes = [];
    List<WeekdayInsight> data = [];
    Map<String, List<DateTime>> groups = {
      'Mon': [],
      'Tue': [],
      'Wed': [],
      'Thu': [],
      'Fri': [],
      'Sat': [],
      'Sun': [],
    };
    for (DocumentSnapshot doc in posts) {
      int timestamp = doc.data()['timestamp'];
      DateTime dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      datetimes.add(dt);
    }
    for (DateTime dt in datetimes) {
      int weekday = dt.weekday;
      String group;
      if (weekday == 1) {
        group = 'Mon';
      } else if (weekday == 2) {
        group = 'Tue';
      } else if (weekday == 3) {
        group = 'Wed';
      } else if (weekday == 4) {
        group = 'Thu';
      } else if (weekday == 5) {
        group = 'Fri';
      } else if (weekday == 6) {
        group = 'Sat';
      } else {
        group = 'Sun';
      }
      groups[group].add(dt);
    }
    groups.forEach((group, allTime) {
      data.add(WeekdayInsight(value: allTime.length, group: group));
    });
    return data;
  }

}

class TimeGroupInsight {
  final int value;
  final String group;

  TimeGroupInsight({@required this.value, @required this.group});
}

class WeekdayInsight {
  final int value;
  /// Weekday i.e. Sunday, Monday, etc.
  final String group;

  WeekdayInsight({@required this.value, @required this.group});
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