import 'package:flutter/material.dart';
import '../app.dart';

class PostInsights extends StatelessWidget {
  PostInsights({@required this.post});
  final Post post;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20, left: 15, right: 15, bottom: 5),
                  child: Text('Insigths', style: TextStyle(fontSize: Theme.of(context).textTheme.headline3.fontSize, fontFamily: RivalFonts.feature),),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
              child: Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10))
                ),
                color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.white : Colors.white10,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Icon(Icons.remove_red_eye),
                              ),
                              Text('Impressions', style: TextStyle(fontFamily: RivalFonts.feature, fontSize: Theme.of(context).textTheme.headline6.fontSize),),
                            ],
                          ),
                          Text(post.impressions.length.toString(), style: TextStyle(fontSize: Theme.of(context).textTheme.bodyText1.fontSize),)
                        ],
                      ),
                      Divider(),
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
                            Text(post.profileVisits.length.toString(), style: TextStyle(fontSize: Theme.of(context).textTheme.bodyText1.fontSize),)
                          ],
                        ),
                      ),
                      Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(right: 10),
                                child: Icon(Icons.favorite),
                              ),
                              Text('Likes', style: TextStyle(fontFamily: RivalFonts.feature, fontSize: Theme.of(context).textTheme.headline6.fontSize),),
                            ],
                          ),
                          Text(post.likes.length.toString(), style: TextStyle(fontSize: Theme.of(context).textTheme.bodyText1.fontSize),)
                        ],
                      ),
                      if (post.allowComments) ... [
                        Divider(),
                        Tooltip(
                          message: 'Number of people who commented on your post',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(right: 10),
                                    child: Icon(Icons.mode_comment),
                                  ),
                                  Text('Comments', style: TextStyle(fontFamily: RivalFonts.feature, fontSize: Theme.of(context).textTheme.headline6.fontSize),),
                                ],
                              ),
                              Text(post.comments.length.toString(), style: TextStyle(fontSize: Theme.of(context).textTheme.bodyText1.fontSize),)
                            ],
                          ),
                        ),
                      ],
                      Divider(),
                      Tooltip(
                        message: 'Number of people who shared your post',
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(right: 10),
                                  child: Icon(Icons.share),
                                ),
                                Text('Shares', style: TextStyle(fontFamily: RivalFonts.feature, fontSize: Theme.of(context).textTheme.headline6.fontSize),),
                              ],
                            ),
                            Text(post.shares.length.toString(), style: TextStyle(fontSize: Theme.of(context).textTheme.bodyText1.fontSize),)
                          ],
                        ),
                      ),
                      if (post.isProduct) ... [
                        Divider(),
                        Tooltip(
                          message: 'Number of people who interacted with your product post',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(right: 10),
                                    child: Icon(Icons.touch_app),
                                  ),
                                  Text('Interactions', style: TextStyle(fontFamily: RivalFonts.feature, fontSize: Theme.of(context).textTheme.headline6.fontSize),),
                                ],
                              ),
                              Text(post.click != null ? post.click.length.toString() : '0', style: TextStyle(fontSize: Theme.of(context).textTheme.bodyText1.fontSize),)
                            ],
                          ),
                        )
                      ]
                    ],
                  ),
                ),
              ),
            ),
            ViewPost(
              post: post,
            ),
            Divider()
          ],
        ),
      ),
    );
  }
}