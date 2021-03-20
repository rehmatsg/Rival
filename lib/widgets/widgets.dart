import 'dart:ui';
import 'package:animations/animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:octo_image/octo_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:supercharged/supercharged.dart';
import '../app.dart';

/// Create a Horizontal Divider between two elements
/// Used in a horizontal row of widgets
class HDivider extends StatelessWidget {
  final double height;
  final double width;
  final Color lightColor;
  final Color darkColor;
  const HDivider({Key key, this.height = 25, this.width = 1, this.lightColor = Colors.black12, this.darkColor = Colors.white10}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: SizedBox(
        height: height,
        width: width,
        child: Container(
          color: MediaQuery.of(context).platformBrightness == Brightness.light ? lightColor: darkColor
        ),
      ),
    );
  }
}

class ProfilePhoto extends StatelessWidget {
  final double height;
  final double width;
  final bool hero;
  ProfilePhoto({this.height = 100, this.width = 100, this.hero});
  @override
  Widget build(BuildContext context) {
    Widget mainWidget = ClipOval(
      child: OctoImage(
        image: (me != null && me.user.photoURL != null) ? CachedNetworkImageProvider(me.user.photoURL) : AssetImage('assets/images/avatar.png'),
        width: width,
        height: height,
        placeholderBuilder: (context) => Image.asset('assets/images/avatar.png'),
      ),
    );
    if (hero == false) {
      return mainWidget;
    } else {
      return Hero(
        tag: 'profile_photo',
        child: mainWidget,
      );
    }
  }
}

class TextParser extends StatelessWidget {
  TextParser({
    @required this.text,
    this.ifUsername,
    this.ifTag,
    this.ifEmail,
    this.ifUrl,
    @required this.textStyle,
    @required this.matchedWordStyle,
    this.textAlign = TextAlign.left,
    this.regexes
  });
  final String text;
  final Function(String) ifUsername;
  final Function(String) ifTag;
  final Function(String) ifEmail;
  final Function(String) ifUrl;
  final TextStyle textStyle;
  final TextStyle matchedWordStyle;
  final TextAlign textAlign;
  final List<String> regexes;

  @override
  Widget build(BuildContext context) {
    return ParsedText(
      text: text,
      style: textStyle,
      alignment: textAlign,
      parse: [
        MatchText(
          type: ParsedType.CUSTOM,
          pattern: _getPattern(),
          regexOptions: RegexOptions(
            caseSensitive: false,
            multiLine: true,
          ),
          style: matchedWordStyle,
          onTap: (word) async {
            RegExp username = RegExp(RivalRegex.username);
            RegExp tag = RegExp(RivalRegex.tag);
            RegExp email = RegExp(RivalRegex.email);
            RegExp url = RegExp(RivalRegex.url);
            if (email.hasMatch(word)) {
              RivalProvider.vibrate();
              if (ifEmail != null) {
                ifEmail(word);
              } else {
                if (await canLaunch(word)) {
                  launch('mailto:$word');
                }
              }
            } else if (tag.hasMatch(word)) {
              RivalProvider.vibrate();
              if (ifTag != null) {
                ifTag(word);
              } else {
                Navigator.of(context).push(RivalNavigator(page: PostsByTag(tag: word,),));
              }
            } else if (url.hasMatch(word)) {
              RivalProvider.vibrate();
              if (ifUrl != null) {
                ifUrl(word);
              } else {
                if (await canLaunch(word)) {
                  launch(word);
                }
              }
            } else if (username.hasMatch(word)) {
              RivalProvider.vibrate();
              if (ifUsername != null) {
                ifUsername(word);
              } else {
                Navigator.of(context).push(RivalNavigator(page: ProfilePage(username: word,)));
              }
            } else {
              print('No match');
            }
          }
        ),
      ],
    );
  }

  String _getPattern() {
    String pattern;
    if (regexes == null || regexes.isEmpty) {
      pattern = "${RivalRegex.username}|${RivalRegex.tag}|${RivalRegex.email}|${RivalRegex.url}";
    } else {
      pattern = '';
      regexes.forEachIndexed((index, r) {
        pattern = pattern + r;
        if (index.isOdd) pattern = pattern + '|';
      });
    }
    return pattern;
  }

}

class CustomProgressIndicator extends StatefulWidget {

  final Color valueColor;
  final Color backgroundColor;
  final double strokeWidth;
  final double value;

  /// Set CPI color to black or white according to theme
  /// Black for light theme
  /// And White for dark theme
  final bool blackAndWhite;

  CustomProgressIndicator({Key key, this.valueColor, this.backgroundColor, this.strokeWidth = 4.0, this.value, this.blackAndWhite = true}) : super(key: key);

  @override
  _CustomProgressIndicatorState createState() => _CustomProgressIndicatorState();
}

class _CustomProgressIndicatorState extends State<CustomProgressIndicator> {
  @override
  Widget build(BuildContext context) {
    Color color;
    if (widget.blackAndWhite == true) {
      if (MediaQuery.of(context).platformBrightness == Brightness.light) color = Colors.black;
      else color = Colors.white;
    } else color = widget.valueColor ?? Colors.indigoAccent;
    return CircularProgressIndicator(
      backgroundColor: widget.backgroundColor,
      strokeWidth: widget.strokeWidth,
      value: widget.value,
      valueColor: AlwaysStoppedAnimation(color),
    );
  }
}

class RivalNavigator<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SharedAxisTransitionType transitionType;
  RivalNavigator({this.transitionType = SharedAxisTransitionType.horizontal, @required this.page}) : super(
    pageBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
    ) => page,
    transitionsBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) => SharedAxisTransition(
      secondaryAnimation: secondaryAnimation,
      transitionType: transitionType,
      animation: animation,
      child: child,
    ),
  );
}

class VerifiedBadge extends StatelessWidget {
  final double height;
  final double width;
  final Color color;
  const VerifiedBadge({Key key, this.height = 15, this.width = 15, this.color}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/verified.svg',
      color: color ?? (MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.indigoAccent : Colors.white),
      height: height,
      width: width,
    );
  }
}

class PageNotifier extends AnimatedWidget {
  final PreloadPageController controller;
  final int pages;
  const PageNotifier({Key key, @required this.pages, @required this.controller}) : super(key: key, listenable: controller);
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('${controller.page != null ? ((controller.page.round() + 1).toString()) : ((controller.initialPage.round() + 1).toString())}/$pages'),
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.white70 : Colors.black45,
        borderRadius: BorderRadius.all(Radius.circular(10))
      ),
    );
  }
}

/// Create a Material Styled Banner to display useful information
class InfoBanner extends StatelessWidget {
  final List<Widget> actions;
  final Widget content;
  final Color backgroundColor;
  final IconData leadingIcon;
  const InfoBanner({Key key, @required this.actions, @required this.content, this.backgroundColor, this.leadingIcon}) : assert(content != null, "Content of a banner should not be null"), super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      leading: leadingIcon != null ? Icon(leadingIcon, color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black87 : Colors.white,) : null,
      backgroundColor: backgroundColor ?? (MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.yellow[300] : Colors.indigoAccent),
      content: content,
      forceActionsBelow: true,
      actions: actions
    );
  }
}

class Loader {
  static Future<void> show(
    BuildContext context, {
      bool disableBackButton = true,
      /// Provide a function that will be executed
      @required Future<void> Function() function,
      @required Function onComplete
    }
  ) async {
    showModal(
      context: context,
      builder: (context) => WillPopScope(
        onWillPop: () async {
          if (disableBackButton) return false;
          else return true;
        },
        child: Container(
          height: double.infinity,
          width: double.infinity,
          color: Colors.black38,
          child: Center(
            child: CustomProgressIndicator(
              valueColor: Colors.white,
            ),
          ),
        ),
      ),
    );
    await function();
    Navigator.of(context).pop();
    onComplete();
  }
}

class PagedListView extends StatefulWidget {

  /// Return List of [Widget] to display
  /// Start Index [int] and End Index [int] is provided
  /// End Index is generally excluded in `range()` function so be careful while using
  final Future<List<Widget>> Function(int startIndex, int endIndex) onNextPage;
  /// Provide `itemsPerPage` [int] to tell how much items should be stored on a single page
  final int itemsPerPage;
  /// This [String] is used when no more data is available
  /// We consider that no more data is available when you provide less items than `itemsPerPage`
  final String onFinish;

  /// Tell whether the next page should automatically load when user reaches the end of the list
  /// Defaults to `true`
  final bool autoNextPage;

  /// Setting this to `true` will automatically add a `Divider()` between all data items
  final bool useSeparator;

  /// Provide a widget to override the default loading widget
  final Widget loadingWidget;

  /// This function is called when `onNextPage()` functions begins
  final Function(bool isFirstPage) onLoadingStart;

  /// This function is called when `onNextPage()` functions finishes
  final Function(bool isFirstPage) onLoadingEnd;

  PagedListView({
    Key key,
    this.onNextPage,
    this.itemsPerPage = 30,
    this.onFinish = "No more data",
    this.useSeparator = false,
    this.autoNextPage = true,
    this.loadingWidget,
    this.onLoadingStart,
    this.onLoadingEnd
  }) : super(key: key);

  @override
  _PagedListViewState createState() => _PagedListViewState();
}

class _PagedListViewState extends State<PagedListView> {

  bool isLoading = true;
  bool isNextPageLoading = false;
  bool moreDataAvailable = true;

  Future<List<Widget>> Function(int startIndex, int endIndex) onNextPage;
  int itemsPerPage;

  List<Widget> widgets;

  int page = 1;

  @override
  void initState() {
    onNextPage = widget.onNextPage;
    itemsPerPage = widget.itemsPerPage;
    _getFirstPage();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      if (widget.loadingWidget == null) return Center(
        child: CustomProgressIndicator(),
      );
      return widget.loadingWidget;
    } else return SingleChildScrollView(
      physics: ScrollPhysics(),
      child: Column(
        children: [
          ListView.separated(
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) => widgets[index],
            itemCount: widgets.length,
            cacheExtent: MediaQuery.of(context).size.height * 2,
            shrinkWrap: true,
            separatorBuilder: (context, index) => widget.useSeparator ? Divider() : Container(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isNextPageLoading) CustomProgressIndicator(
                  strokeWidth: 2,
                ) else if (!moreDataAvailable) Text(
                  widget.onFinish,
                  style: Theme.of(context).textTheme.caption
                ) else VisibilityDetector(
                  key: UniqueKey(),
                  onVisibilityChanged: (info) {
                    if (info.visibleFraction == 1 && widget.autoNextPage) _getNextPage();
                  },
                  child: IconButton(
                    icon: Icon(Icons.add_circle),
                    onPressed: _getNextPage
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> _getFirstPage() async {
    if (widget.onLoadingStart != null) widget.onLoadingStart(true);
    widgets = await onNextPage(_getStartEndIndex(1)[0], _getStartEndIndex(1)[1]);
    setState(() {
      isLoading = false;
      if (widgets.length < itemsPerPage) moreDataAvailable = false;
    });
    if (widget.onLoadingEnd != null) widget.onLoadingEnd(true);
  }

  List _getStartEndIndex(int page) {
    int startIndex = ((page - 1) * itemsPerPage);
    int endIndex = startIndex + itemsPerPage;
    return [startIndex, endIndex];
  }

  Future<void> _getNextPage() async {
    if (widget.onLoadingStart != null) widget.onLoadingStart(false);
    setState(() {
      isNextPageLoading = true;
    });
    page += 1;
    List<Widget> nextPageWidgets = await onNextPage(_getStartEndIndex(page)[0], _getStartEndIndex(page)[1]);
    widgets.addAll(nextPageWidgets);
    setState(() {
      isNextPageLoading = false;
      if (nextPageWidgets.length < itemsPerPage) moreDataAvailable = false;
    });
    if (widget.onLoadingEnd != null) widget.onLoadingEnd(false);
  }

}