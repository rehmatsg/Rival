import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:introduction_screen/introduction_screen.dart';
import '../app.dart';

class BusinessIntro extends StatefulWidget {
  @override
  _BusinessIntroState createState() => _BusinessIntroState();
}

class _BusinessIntroState extends State<BusinessIntro> {
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
            title: 'Business',
            body: 'With Rival for Businesses, grow your business to the next-scale',
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
                  Text('for Business', style: Theme.of(context).textTheme.headline6.copyWith(
                    fontFamily: RivalFonts.feature,
                    color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black : Colors.white
                  ),),
                ],
              ),
            ),
          ),
          PageViewModel(
            title: 'Insights',
            body: 'Get detailed insights of all your posts with a business account. Insights help you know your audience and what they like.',
            decoration: PageDecoration(
              titleTextStyle: Theme.of(context).textTheme.headline4.copyWith(
                fontFamily: RivalFonts.feature,
                color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black : Colors.white
              )
            ),
            image: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
              child: SvgPicture.asset(
                'assets/intro/business/insights.svg',
              ),
            ),
          ),
          PageViewModel(
            title: 'Sponsor',
            body: 'Create a sponsored posts by public figures to reach a wide range of audience.',
            decoration: PageDecoration(
              titleTextStyle: Theme.of(context).textTheme.headline4.copyWith(
                fontFamily: RivalFonts.feature,
                color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black : Colors.white
              )
            ),
            image: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
              child: SvgPicture.asset(
                'assets/intro/business/collaborate.svg',
              ),
            ),
          ),
          PageViewModel(
            title: 'Shopping',
            body: 'Promote your product by setting up shopping in Business section of your profile settings',
            decoration: PageDecoration(
              titleTextStyle: Theme.of(context).textTheme.headline4.copyWith(
                fontFamily: RivalFonts.feature,
                color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black : Colors.white
              )
            ),
            image: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
              child: SvgPicture.asset(
                'assets/intro/business/shopping.svg',
              ),
            ),
          ),
        ],
        onDone: () { },
        done: FlatButton(
          child: me.isBusinessAccount ? Text('Done') : Text('Get Started'),
          onPressed: () async {
            if (!me.isBusinessAccount) {
              Loader.show(
                context,
                function: () async {
                  await me.update({
                    'type': 'business',
                    'manuallyApprovePartnerRequests': true
                  }, reload: true);
                },
                onComplete: () {
                  RivalProvider.showToast(text: 'Switched to Business Account');
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