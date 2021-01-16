import 'package:flutter/material.dart';

import '../app.dart';
import 'classes.dart';
//import 'package:supercharged/supercharged.dart';

class PostCreator extends StatefulWidget {
  @override
  _PostCreatorState createState() => _PostCreatorState();
}

class _PostCreatorState extends State<PostCreator> {

  GlobalKey globalKey = new GlobalKey();

  bool isLoading = true;

  PageType pageType = PageType.square;

  CreatorPage page;

  CreatorWidget selection;

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
              child: DefaultTabController(
                length: selection.options.length,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TabBar(
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: TextStyle(
                        fontFamily: RivalFonts.feature,
                        fontSize: Theme.of(context).textTheme.subtitle1.fontSize
                      ),
                      indicator: MaterialIndicator(
                        color: Colors.indigoAccent
                      ),
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
            )
          ],
        ),
      ),
    );
  }

  void _createPage() {
    page = CreatorPage();
    selection = page.selection;
    page.addListener(onSelectionChange);
    isLoading = false;
    setState(() { });
  }

  void onSelectionChange() {
    selection = page.selection;
    setState(() { });
  }

  double _getAspectRatio() {
    switch (pageType) {
      case PageType.square:
        return 1;
        break;
      case PageType.landscape:
        return 1.91/1;
        break;
      case PageType.square:
        return 4/5;
        break;
      default:
        return 1;
        break;
    }
  }

}