import 'package:flutter/material.dart';
import '../app.dart';

class ManageSponsor extends StatefulWidget {
  @override
  _ManageSponsorState createState() => _ManageSponsorState();
}

class _ManageSponsorState extends State<ManageSponsor> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Sponsors'),
      ),
      body: ListView(
        children: [
          ListTile(
              title: Text('Partners'),
              subtitle: Text('Manage your partnership with people'),
              onTap: () => Navigator.of(context)
                  .push(RivalNavigator(page: MyPartners()))),
          if (me.isBusinessAccount)
            ListTile(
              title: Text('Manually Approve Partners'),
              subtitle: Text(
                  'Enabling this will make people send you a request before adding you as a sponsor'),
              trailing: Switch.adaptive(
                  value: me.manuallyApprovePartnerRequests,
                  onChanged: (val) async {
                    await Loader.show(context, function: () async {
                      RivalProvider.vibrate();
                      await me.update({'manuallyApprovePartnerRequests': val},
                          reload: true);
                    }, onComplete: () {
                      setState(() {});
                      RivalProvider.showToast(text: 'Saved Changes');
                    });
                  }),
            ),
          if (me.isBusinessAccount &&
              (me.manuallyApprovePartnerRequests ||
                  me.partnerRequests.isNotEmpty))
            ListTile(
                title: Text('Requests'),
                subtitle: Text('Approve or deny business partner requests'),
                onTap: () => Navigator.of(context)
                    .push(RivalNavigator(page: PartnerRequests()))),
          ListTile(
              title: Text('Add Partner'),
              subtitle: Text(
                  'Add business accounts as your partner for sponsored posts'),
              onTap: () => Navigator.of(context)
                  .push(RivalNavigator(page: AddSponsor()))),
          if (me.isBusinessAccount)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              child: Text(
                  'Approved business partners will be able to add you as a sponsor in their posts.',
                  style: Theme.of(context).textTheme.bodyText2),
            )
        ],
      ),
    );
  }
}
