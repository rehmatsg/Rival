import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';

import '../app.dart';

class ManageDevices extends StatefulWidget {
  ManageDevices({Key key}) : super(key: key);

  @override
  _ManageDevicesState createState() => _ManageDevicesState();
}

class _ManageDevicesState extends State<ManageDevices> {

  @override
  void initState() {
    super.initState();    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Devices'),
      ),
      body: ListView.builder(
        itemCount: me.devices.length,
        itemBuilder: (context, index) => ListTile(
          leading: IconButton(
            icon: Icon(
              me.devices.values.toList()[index]['device']['os'] == 'android' ? FontAwesome.android : FontAwesome.apple,
              color: me.devices.values.toList()[index]['device']['os'] == 'android' ? Colors.greenAccent : (MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black : Colors.white),
            ),
            onPressed: null,
          ),
          visualDensity: VisualDensity.compact,
          title: Text('${me.devices.values.toList()[index]['device']['manufacturer']} ${me.devices.values.toList()[index]['device']['model']}'),
          subtitle: Text(
            '${getTimeAgo(new DateTime.fromMillisecondsSinceEpoch((me.devices.values.toList()[index]['timestamp'])))}${(me.devices.values.toList()[index]['timestamp'].toString() == me.loginTimestamp.toString()) ? '\nThis Device' : ''}'
          ),
          trailing: PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Text('Remove Device'),
                value: 'logout',
              )
            ],
            onSelected: (value) async {
              switch (value) {
                case 'logout':
                  await Loader.show(
                    context,
                    function: () async {
                      if (me.devices.values.toList()[index]['timestamp'].toString() == me.loginTimestamp.toString()) {
                        await me.signOut(context);
                        Navigator.of(context).pushAndRemoveUntil(RivalNavigator(page: SignIn()), (route) => false);
                      } else {
                        await me.update({
                          'devices.${me.devices.values.toList()[index]['timestamp'].toString()}': FieldValue.delete()
                        }, reload: true);
                      }
                    },
                    onComplete: () {},
                    disableBackButton: true
                  );
                  setState(() { });
                  break;
                default:
              }
            },
          ),
        ),
      ),
    );
  }
}