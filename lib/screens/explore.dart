import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../app.dart';
import 'subscribe_to_topics.dart';

class ExplorePage extends StatefulWidget {

  ExplorePage({Key key, this.initialTab = 0}) : super(key: key);
  final int initialTab; 
  
  @override
  _ExplorePageState createState() => _ExplorePageState();
}

List<Post> posts;

class _ExplorePageState extends State<ExplorePage> {

  int page = 1;
  
  bool isLoading = true;
  bool isNextPageLoading = false;
  bool morePostsAvailable = true;

  @override
  void initState() {
    _init();
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Future<void> _init() async {
    if (posts != null) {
      setState(() {
        isLoading = false;
      });
    } else {
      posts = [];
      await getPaginatedPosts(1);
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> getPaginatedPosts(int page) async {
    setState(() {
      isNextPageLoading = true;
    });

    QuerySnapshot querySnapshot;
    if (page > 1) {
      querySnapshot = await firestore.collection('posts').limit(90).orderBy('timestamp', descending: true).startAfterDocument(posts.last.doc).get();
    } else {
      querySnapshot = await firestore.collection('posts').limit(90).orderBy('timestamp', descending: true).get();
    }

    if (querySnapshot.docs.length >= 1) {
      for (DocumentSnapshot doc in querySnapshot.docs) {
        Post newPost = await Post.fetch(doc: doc);
        posts.add(newPost);
      }
    } else {
      morePostsAvailable = false;
    }

    setState(() {
      isNextPageLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: widget.initialTab,
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Explore', style: TextStyle(color: Colors.white),),
          actionsIconTheme: IconThemeData(
            color: Colors.white
          ),
          iconTheme: IconThemeData(
            color: Colors.white
          ),
          brightness: Brightness.dark,
          actions: [
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () => showSearch(context: context, delegate: RivalSearchDelegate())
            ),
          ],
          backgroundColor: Colors.indigo,
          bottom: TabBar(
            physics: BouncingScrollPhysics(),
            labelColor: Colors.white,
            indicatorColor: Colors.yellow,
            indicator: MaterialIndicator(
              color: Colors.white
            ),
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(child: Text('Top Posts'),),
              Tab(child: Text('Trending Tags'),)
            ],
          ),
        ),
        body: TabBarView(
          physics: BouncingScrollPhysics(),
          children: [
            NewPosts(),
            TopTags()
          ],
        )
      ),
    );
  }
}

class NewPosts extends StatefulWidget {
  @override
  _NewPostsState createState() => _NewPostsState();
}

class _NewPostsState extends State<NewPosts> {

  bool isLoading = true;
  bool isNextPageLoading = false;
  bool postsAvailable = true;

  int page = 1;

  List<Post> discoverPosts;

  Future<void> _getTopPosts() async {
    discoverPosts = await getTopPosts(returnNextPageOnly: false);
    setState(() {
      isLoading = false;
      if (discoverPosts.length < 21) {
        postsAvailable = false;
      }
    });
  }

  @override
  void initState() {
    _getTopPosts();
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
        title: Text('Explore'),
      ),
      body: isLoading
      ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomProgressIndicator()
          ],
        ),
      )
      : RefreshIndicator(
        onRefresh: () async {
          topPosts = null;
          await _getTopPosts();
        },
        child: CustomScrollView(
          cacheExtent: MediaQuery.of(context).size.height * 2,
          slivers: [
            SliverStaggeredGrid.countBuilder(
              crossAxisCount: 3,
              staggeredTileBuilder: (int index) => new StaggeredTile.count(discoverPosts[index].isPromoted ? 2 : 1, discoverPosts[index].isPromoted ? 2 : 1),
              itemBuilder: (context, index) => PostGridView(post: discoverPosts[index],),
              itemCount: discoverPosts.length
            ),
            SliverToBoxAdapter(
              child: Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (postsAvailable) ... [
                      if (isNextPageLoading) Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CustomProgressIndicator(strokeWidth: 2,),
                        )
                      ) else VisibilityDetector(
                        key: UniqueKey(),
                        onVisibilityChanged: (info) {
                          if (info.visibleFraction == 1) _nextPage();
                        },
                        child: IconButton(
                          tooltip: 'Load More Posts',
                          onPressed: () async {
                            _nextPage();
                          },
                          icon: Icon(Icons.add),
                        ),
                      ),
                    ] else ... [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: Text(
                          'No more Posts available',
                          style: Theme.of(context).textTheme.caption
                        ),
                      ),
                    ]
                  ]
                ),
              ),
            ),
          ],
        ),
      )
    );
  }
  
  Future<void> _nextPage() async {
    setState(() {
      isNextPageLoading = true;
    });
    page += 1;
    List<Post> nextPagePosts = await getTopPosts(page: page, returnNextPageOnly: true);
    if (nextPagePosts.isNotEmpty) {
      discoverPosts.addAll(nextPagePosts);
    } else {
      postsAvailable = false;
    }
    if (nextPagePosts.length < 21) {
      postsAvailable = false;
    }
    setState(() {
      isNextPageLoading = false;
    });
  }

}

class TopTags extends StatefulWidget {
  @override
  _TopTagsState createState() => _TopTagsState();
}

class _TopTagsState extends State<TopTags> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, int>>(
        future: getTopTags(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.data.isNotEmpty) {
              return ListView.builder(
                itemCount: snapshot.data.length,
                itemBuilder: (context, index) => ListTile(
                  visualDensity: VisualDensity.compact,
                  leading: CircleAvatar(
                    backgroundColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.indigo[100] : Colors.indigo[900],
                    child: Text('#${index + 1}'),
                  ),
                  title: Text(snapshot.data.keys.toList()[index]),
                  subtitle: Text('${(snapshot.data.values.toList()[index] - snapshot.data.values.toList()[index] % 10 > 0) ? snapshot.data.values.toList()[index] - snapshot.data.values.toList()[index] % 10 : snapshot.data.values.toList()[index] }+ posts this week'),
                  onTap: () => Navigator.of(context).push(RivalNavigator(page: PostsByTag(tag: snapshot.data.keys.toList()[index],),)),
                  trailing: Icon(Icons.keyboard_arrow_right),
                ),
              );
            } else {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('No Top Tags this Week', style: Theme.of(context).textTheme.caption,)
                  ],
                ),
              );
            }
          } else {
            return Center(
              child: Container(
                height: 100,
                width: 100,
                child: CustomProgressIndicator(),
              ),
            );
          }
        },
      ),
    );
  }

}



/// Material Indicator used as [indicator] in TabBar
class MaterialIndicator extends Decoration {
  /// Height of the indicator. Defaults to 4
  final double height;

  /// Determines to location of the tab, [TabPosition.bottom] set to default.
  final TabPosition tabPosition;

  /// topRight radius of the indicator, default to 5.
  final double topRightRadius;

  /// topLeft radius of the indicator, default to 5.
  final double topLeftRadius;

  /// bottomRight radius of the indicator, default to 0.
  final double bottomRightRadius;

  /// bottomLeft radius of the indicator, default to 0
  final double bottomLeftRadius;

  /// Color of the indicator, default set to [Colors.black]
  final Color color;

  /// Horizontal padding of the indicator, default set 0
  final double horizontalPadding;

  /// [PagingStyle] determines if the indicator should be fill or stroke, default to fill
  final PaintingStyle paintingStyle;

  /// StrokeWidth, used for [PaintingStyle.stroke], default set to 2
  final double strokeWidth;

  MaterialIndicator({
    this.height = 4,
    this.tabPosition = TabPosition.bottom,
    this.topRightRadius = 5,
    this.topLeftRadius = 5,
    this.bottomRightRadius = 0,
    this.bottomLeftRadius = 0,
    this.color = Colors.black,
    this.horizontalPadding = 0,
    this.paintingStyle = PaintingStyle.fill,
    this.strokeWidth = 2,
  });
  @override
  _CustomPainter createBoxPainter([VoidCallback onChanged]) {
    return new _CustomPainter(
      this,
      onChanged,
      bottomLeftRadius: bottomLeftRadius,
      bottomRightRadius: bottomRightRadius,
      color: color,
      height: height,
      horizontalPadding: horizontalPadding,
      tabPosition: tabPosition,
      topLeftRadius: topLeftRadius,
      topRightRadius: topRightRadius,
      paintingStyle: paintingStyle,
      strokeWidth: strokeWidth,
    );
  }
}

class _CustomPainter extends BoxPainter {
  final MaterialIndicator decoration;
  final double height;
  final TabPosition tabPosition;
  final double topRightRadius;
  final double topLeftRadius;
  final double bottomRightRadius;
  final double bottomLeftRadius;
  final Color color;
  final double horizontalPadding;
  final double strokeWidth;
  final PaintingStyle paintingStyle;

  _CustomPainter(
    this.decoration,
    VoidCallback onChanged, {
    this.height,
    this.tabPosition,
    this.topRightRadius,
    this.topLeftRadius,
    this.bottomRightRadius,
    this.bottomLeftRadius,
    this.color,
    this.horizontalPadding,
    this.paintingStyle,
    this.strokeWidth,
  })  : assert(decoration != null),
        super(onChanged);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    assert(configuration != null);
    assert(configuration.size != null);
    assert(horizontalPadding != null && horizontalPadding >= 0);
    assert(horizontalPadding < configuration.size.width / 2,
        "Padding must be less than half of the size of the tab");
    assert(color != null);
    assert(height != null && height > 0);
    assert(tabPosition != null);
    assert(topRightRadius != null);
    assert(topLeftRadius != null);
    assert(bottomRightRadius != null);
    assert(bottomLeftRadius != null);
    assert(strokeWidth >= 0 &&
        strokeWidth < configuration.size.width / 2 &&
        strokeWidth < configuration.size.height / 2);

    //offset is the position from where the decoration should be drawn.
    //configuration.size tells us about the height and width of the tab.
    Size mysize =
        Size(configuration.size.width - (horizontalPadding * 2), height);

    Offset myoffset = Offset(
      offset.dx + (horizontalPadding),
      offset.dy +
          (tabPosition == TabPosition.bottom
              ? configuration.size.height - height
              : 0),
    );

    final Rect rect = myoffset & mysize;
    final Paint paint = Paint();
    paint.color = color;
    paint.style = paintingStyle;
    paint.strokeWidth = strokeWidth;
    canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          bottomRight: Radius.circular(bottomRightRadius),
          bottomLeft: Radius.circular(bottomLeftRadius),
          topLeft: Radius.circular(topLeftRadius),
          topRight: Radius.circular(topRightRadius),
        ),
        paint);
  }
}

enum TabPosition { top, bottom }

// ##################################################################### NEW ###################################################################

List<Post> subscribedTopicsPosts = [];

class Explore extends StatefulWidget {
  @override
  _ExploreState createState() => _ExploreState();
}

class _ExploreState extends State<Explore> {

  int postsPerPage = 25;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Explore'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle),
            tooltip: 'View Topics',
            onPressed: () {
              Navigator.of(context).push(RivalNavigator(page: SubscribeToTopics()));
            }
          )
        ],
      ),
      body: me.subscriptions.isNotEmpty
      ? RefreshIndicator(
        onRefresh: () async {
          setState(() {
            subscribedTopicsPosts.clear();
            isLoading = true;
          });
        },
        child: SingleChildScrollView(
          primary: true,
          child: Column(
            children: [
              PagedListView(
                autoNextPage: true,
                itemsPerPage: postsPerPage,
                onFinish: 'That\'s it',
                onNextPage: (startIndex, endIndex) async {
                  return await _getPage(startIndex, endIndex);
                },
                loadingWidget: Center(
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 20),
                    child: CustomProgressIndicator(
                      valueColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black : Colors.white,
                    ),
                  ),
                ),
                onLoadingEnd: (isFirstPage) {
                  try {
                    if (isFirstPage) setState(() {
                      isLoading = false;
                    });
                  } catch (e) {
                    isLoading = false;
                  }
                },
              )
            ],
          ),
        ),
      )
      : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('No Subscriptions', style: Theme.of(context).textTheme.headline5,),
            Container(height: 10),
            Text('You haven\'t subscribed to any topics. Subscribe to topics to find related posts.', style: Theme.of(context).textTheme.bodyText1),
            Container(height: 15),
            TextButton(
              child: Text('Find Topics'),
              onPressed: () async {
                await Navigator.of(context).push(RivalNavigator(page: SubscribeToTopics()));
                setState(() { });
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.indigoAccent.withOpacity(0.2),
              ),
            )
          ],
        ),
      )
    );
  }

  Future<List<Widget>> _getPage(int startIndex, int endIndex) async {
    List<Widget> widgets = [];
    if (subscribedTopicsPosts.length > 0 && subscribedTopicsPosts.length < postsPerPage) {
      // If there are less than noOfPostsOfATopic loaded for first page
      // that means we don't have sufficient number of posts
      // So we'll return only loaded posts
      // for first page
      subscribedTopicsPosts.forEach((p) {
        widgets.add(ViewPost(
          post: p,
          whyThisPost: 'You are viewing this post because you have subscribed to ${p.topic} topic.',
        ));
      });
    } else if (subscribedTopicsPosts.length >= startIndex && subscribedTopicsPosts.length >= endIndex) {
      // Our list already contains this page
      // So return it
      List<Post> subscribedTopicsPostsL = subscribedTopicsPosts.getRange(startIndex, endIndex);
      subscribedTopicsPostsL.forEach((p) {
        widgets.add(ViewPost(
          post: p,
          whyThisPost: 'You are viewing this post because you have subscribed to ${p.topic} topic.',
        ));
      });
    } else {
      // if (allPostsFromAllTopics == null) allPostsFromAllTopics = await firestore.collection('rival').doc('topics').get();
      List<Post> local = [];
      int noOfTopics = me.subscriptions.length;
      int noOfPostsOfATopic = (me.subscriptions.length / noOfTopics).floor();
      for (String topic in me.subscriptions) {
        // Get `noOfPostsOfATopic` no of posts related to this topic
        local.addAll(await _getPostsForTopic(topic, noOfPostsOfATopic));
      }
      if (local.length > 0) while (local.length < noOfPostsOfATopic) {
        int missingPosts = local.length - noOfPostsOfATopic;
        // For ex there are 3 posts less than noOfPostsOfATopic per page
        // So, we'll get 3 posts for any random topic to complete the page
        String topic = me.subscriptions.getRandom();
        local.addAll(await _getPostsForTopic(topic, missingPosts));
        // Now all posts are completed for a page
      }
      local.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      subscribedTopicsPosts.addAll(local);
      local.forEach((post) {
        if ((post.isMyPost || (post.user.private && post.user.isFollowing) || !post.user.private) && !post.takenDown && post.available && ((kDebugMode && post.beta) || !post.beta)) widgets.add(ViewPost(
          post: post,
          whyThisPost: 'You are viewing this post because you have subscribed to ${post.topic} topic.',
        ));
      });
    }
    return widgets;
  }

  Future<List<Post>> _getPostsForTopic(String topic, int no) async {
    List<Post> local = [];
    Query query = firestore.collection('posts').where('topic', isEqualTo: topic).orderBy('timestamp', descending: true).limit(no);
    int lastIndexOfPostOfTopic = subscribedTopicsPosts.lastIndexWhere((element) => element.topic == topic);
    if (lastIndexOfPostOfTopic >= 0) {
      query = query.startAfterDocument(subscribedTopicsPosts[lastIndexOfPostOfTopic].doc);
    }
    QuerySnapshot querySnapshot = await query.get();
    for (DocumentSnapshot doc in querySnapshot.docs) {
      Post post = await Post.fetch(doc: doc);
      if (post.isMyPost || (post.user.private && post.user.isFollowing) || !post.user.private) local.add(post);
    }
    return local;
  }

  // This method is used to get posts by tag
  // It is not yet used
  // ignore: unused_element
  Future<List<Post>> _getPostsForTag(String tag, int no) async {
    tag = tag.replaceAll('#', '').replaceAll(RegExp(RivalRegex.specialChars), '');
    List<Post> local = [];
    Query query = firestore.collection('posts').where('tags', arrayContains: tag).orderBy('timestamp', descending: true).limit(no);
    int lastIndexOfPostOfTopic = subscribedTopicsPosts.lastIndexWhere((element) => element.tags.contains('#$tag'));
    if (lastIndexOfPostOfTopic >= 0) {
      query = query.startAfterDocument(subscribedTopicsPosts[lastIndexOfPostOfTopic].doc);
    }
    QuerySnapshot querySnapshot = await query.get();
    for (DocumentSnapshot doc in querySnapshot.docs) {
      Post post = await Post.fetch(doc: doc);
      if (post.isMyPost || (post.user.private && post.user.isFollowing) || !post.user.private) local.add(post);
    }
    return local;
  }

}