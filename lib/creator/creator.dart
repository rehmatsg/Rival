import 'package:flutter/material.dart';

import '../app.dart';
import 'classes.dart';
//import 'package:supercharged/supercharged.dart';

class StoryCreator extends StatefulWidget {
  @override
  _StoryCreatorState createState() => _StoryCreatorState();
}

class _StoryCreatorState extends State<StoryCreator> with TickerProviderStateMixin {

  GlobalKey globalKey = new GlobalKey();

  bool isLoading = true;

  PageSize pageType = PageSize.story;

  CreatorPage page;

  CreatorWidget selection;

  TabController tabController;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, _createPage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[100] : Colors.black,
      // appBar: AppBar(
      //   title: Text('Creator'),
      // ),
      body: isLoading
      ? Column(
        children: [

        ],
      )
      : SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            page.changeSelection(selection: page.properties);
          },
          child: Column(
            children: [
              if (page != null) Transform.scale(
                scale: 1,
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.only(top: 5, bottom: 5),
                  child: AspectRatio(
                    aspectRatio: _getAspectRatio(),
                    child: page.build(
                      key: globalKey,
                      context: context,
                      boxShadow: [
                        BoxShadow(
                          color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.grey[900],
                          blurRadius: 10,
                          spreadRadius: 1,
                        )
                      ]
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.white : Colors.grey[900],
                    boxShadow: [
                    ]
                  ),
                ),
              ),
              // ignore: dead_code
              if (false) Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.white : Colors.grey[900],
                  boxShadow: [
                    BoxShadow(
                      color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.grey[900],
                      blurRadius: 5,
                      spreadRadius: 1,
                    )
                  ]
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TabBar(
                      controller: tabController,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: TextStyle(
                        fontFamily: RivalFonts.feature,
                        fontSize: Theme.of(context).textTheme.subtitle1.fontSize
                      ),
                      indicator: UnderlineTabIndicator(),
                      labelColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black : Colors.white,
                      unselectedLabelColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[700] : Colors.grey[300],
                      tabs: List.generate(
                        selection.options.length,
                        (index) => Tab(
                          text: selection.options.keys.toList()[index],
                        )
                      )
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 5, right: 5, top: 20, bottom: 20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 80, // calculated
                        child: TabBarView(
                          controller: tabController,
                          physics: NeverScrollableScrollPhysics(),
                          children: List.generate(
                            selection.options.length,
                            (index) {
                              List<Option> options = selection.options.values.toList()[index];
                              return Container(
                                // color: Colors.yellow,
                                child: ListView.builder(
                                  itemCount: options.length,
                                  itemBuilder: (context, index) => Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 5),
                                    child: options[index].build(context),
                                  ),
                                  physics: BouncingScrollPhysics(),
                                  scrollDirection: Axis.horizontal,
                                ),
                              );
                            }
                          )
                        ),
                      ),
                    ),
                  ],
                )
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createPage() {
    page = CreatorPage(
      onSave: (image) {
        Navigator.of(context).pop(image);
      },
    );
    selection = page.selection;
    tabController = TabController(length: selection.options.keys.toList().length, vsync: this);
    page.addListener(onSelectionChange);
    isLoading = false;
    setState(() { });
  }

  void onSelectionChange() {
    selection = page.selection;
    tabController = TabController(length: selection.options.keys.toList().length, vsync: this);
    setState(() { });
  }

  double _getAspectRatio() {
    switch (pageType) {
      case PageSize.square:
        return 1;
        break;
      case PageSize.landscape:
        return 1.91/1;
        break;
      case PageSize.portrait:
        return 4/5;
        break;
      case PageSize.story:
        return 9/16;
        break;
      default:
        return 1;
        break;
    }
  }

}

class PostCreator extends StatefulWidget {
  @override
  _PostCreatorState createState() => _PostCreatorState();
}

class _PostCreatorState extends State<PostCreator> with TickerProviderStateMixin {

  GlobalKey globalKey = new GlobalKey();

  bool isLoading = true;

  PageSize pageType = PageSize.square;

  CreatorPage page;

  CreatorWidget selection;

  TabController tabController;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, _createPage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[100] : Colors.black,
      appBar: AppBar(
        title: Text('Creator'),
      ),
      body: isLoading
      ? Column(
        children: [

        ],
      )
      : GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          page.changeSelection(selection: page.properties);
        },
        child: Column(
          children: [
            Spacer(),
            if (page != null) Transform.scale(
              scale: 1,
              alignment: Alignment.center,
              child: AspectRatio(
                aspectRatio: _getAspectRatio(),
                child: page.build(
                  key: globalKey,
                  context: context,
                  boxShadow: [
                    BoxShadow(
                      color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.grey[900],
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ]
                ),
              ),
            ),
            Spacer(),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.white : Colors.grey[900],
                boxShadow: [
                  BoxShadow(
                    color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.grey[900],
                    blurRadius: 5,
                    spreadRadius: 1,
                  )
                ]
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TabBar(
                    controller: tabController,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: TextStyle(
                      fontFamily: RivalFonts.feature,
                      fontSize: Theme.of(context).textTheme.subtitle1.fontSize
                    ),
                    indicator: UnderlineTabIndicator(),
                    labelColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black : Colors.white,
                    unselectedLabelColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[700] : Colors.grey[300],
                    tabs: List.generate(
                      selection.options.length,
                      (index) => Tab(
                        text: selection.options.keys.toList()[index],
                      )
                    )
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 5, right: 5, top: 20, bottom: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 80, // calculated
                      child: TabBarView(
                        controller: tabController,
                        physics: NeverScrollableScrollPhysics(),
                        children: List.generate(
                          selection.options.length,
                          (index) {
                            List<Option> options = selection.options.values.toList()[index];
                            return Container(
                              // color: Colors.yellow,
                              child: ListView.builder(
                                itemCount: options.length,
                                itemBuilder: (context, index) => Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 5),
                                  child: options[index].build(context),
                                ),
                                physics: BouncingScrollPhysics(),
                                scrollDirection: Axis.horizontal,
                              ),
                            );
                          }
                        )
                      ),
                    ),
                  ),
                ],
              )
            ),
          ],
        ),
      ),
    );
  }

  void _createPage() {
    page = CreatorPage(onSave: (image) {
      Navigator.of(context).pop(image);
    },);
    selection = page.selection;
    tabController = TabController(length: selection.options.keys.toList().length, vsync: this);
    page.addListener(onSelectionChange);
    isLoading = false;
    setState(() { });
  }

  void onSelectionChange() {
    selection = page.selection;
    tabController = TabController(length: selection.options.keys.toList().length, vsync: this);
    setState(() { });
  }

  double _getAspectRatio() {
    switch (pageType) {
      case PageSize.square:
        return 1;
        break;
      case PageSize.landscape:
        return 1.91/1;
        break;
      case PageSize.square:
        return 4/5;
        break;
      default:
        return 1;
        break;
    }
  }

}