import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:introduction_screen/introduction_screen.dart';
import '../app.dart';

class CreatorIntro extends StatefulWidget {
  @override
  _CreatorIntroState createState() => _CreatorIntroState();
}

class _CreatorIntroState extends State<CreatorIntro> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rival', style: TextStyle(
          fontFamily: RivalFonts.rival
        ),),
      ),
      body: IntroductionScreen(
        pages: <PageViewModel>[
          PageViewModel(
            title: 'Creator',
            body: 'Become a content creator and create awesome content and reach a wide range of audience',
            decoration: PageDecoration(
              titleTextStyle: Theme.of(context).textTheme.headline4.copyWith(
                fontFamily: RivalFonts.feature,
                color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black : Colors.white
              )
            ),
            image: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Rival', style: Theme.of(context).textTheme.headline2.copyWith(
                    fontFamily: RivalFonts.rival,
                    color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black : Colors.white
                  ),),
                  Text('for Creators', style: Theme.of(context).textTheme.headline6.copyWith(
                    fontFamily: RivalFonts.feature,
                    color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black : Colors.white
                  ),),
                ],
              ),
            ),
          ),
          PageViewModel(
            title: 'Insights',
            body: 'Get detailed insights of all your posts with a creator account. Insights help you know your audience and what they like.',
            decoration: PageDecoration(
              titleTextStyle: Theme.of(context).textTheme.headline4.copyWith(
                fontFamily: RivalFonts.feature,
                color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black : Colors.white
              )
            ),
            image: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
              child: SvgPicture.asset(
                'assets/intro/creator/insights.svg',
              ),
            ),
          ),
          PageViewModel(
            title: 'Create',
            body: 'With creator account, you get to add up to 15 images in a post.',
            decoration: PageDecoration(
              titleTextStyle: Theme.of(context).textTheme.headline4.copyWith(
                fontFamily: RivalFonts.feature,
                color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black : Colors.white
              )
            ),
            image: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
              child: SvgPicture.asset(
                'assets/intro/creator/content.svg',
              ),
            ),
          ),
          PageViewModel(
            title: 'Topics',
            body: 'Reach more people by adding a Topic to your post making it more discoverable.',
            decoration: PageDecoration(
              titleTextStyle: Theme.of(context).textTheme.headline4.copyWith(
                fontFamily: RivalFonts.feature,
                color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black : Colors.white
              )
            ),
            image: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
              child: SvgPicture.asset(
                'assets/intro/creator/discoverable.svg',
              ),
            ),
          ),
          PageViewModel(
            title: 'Spread Knowledge',
            body: 'Create informational posts and spread knowledge not hate',
            decoration: PageDecoration(
              titleTextStyle: Theme.of(context).textTheme.headline4.copyWith(
                fontFamily: RivalFonts.feature,
                color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black : Colors.white
              )
            ),
            image: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
              child: SvgPicture.asset(
                'assets/intro/creator/spread_love.svg',
              ),
            ),
          ),
        ],
        onDone: () { },
        done: TextButton(
          child: me.isBusinessAccount ? Text('Done') : Text('Get Started'),
          onPressed: () async {
            if (!me.isCreatorAccount) {
              Loader.show(
                context,
                function: () async {
                  await me.update({
                    'type': 'creator'
                  }, reload: true);
                },
                onComplete: () {
                  RivalProvider.showToast(text: 'Switched to Creator Account');
                  Navigator.of(context).pushAndRemoveUntil(RivalNavigator(page: Home()), (route) => false);
                }
              );
            } else {
              Navigator.of(context).pop();
            }
          },
        )
      ),
    );
  }
}