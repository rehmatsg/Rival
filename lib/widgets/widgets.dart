import 'dart:ui';
import 'package:animations/animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:octo_image/octo_image.dart';
import 'package:url_launcher/url_launcher.dart';
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
  TextParser({@required this.text, this.ifUsername, this.ifTag, this.ifEmail, this.ifUrl, @required this.textStyle, @required this.matchedWordStyle});
  final String text;
  final Function(String) ifUsername;
  final Function(String) ifTag;
  final Function(String) ifEmail;
  final Function(String) ifUrl;
  final TextStyle textStyle;
  final TextStyle matchedWordStyle;
  @override
  Widget build(BuildContext context) {
    return ParsedText(
      text: text,
      style: textStyle,
      parse: [
        MatchText(
          type: ParsedType.CUSTOM,
          pattern: "${RivalRegex.username}|${RivalRegex.tag}|${RivalRegex.email}|${RivalRegex.url}",
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
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
    await function();
    onComplete();
  }
}