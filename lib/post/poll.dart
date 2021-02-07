import 'package:flutter/material.dart';
import '../app.dart';

class CreatePoll extends StatefulWidget {

  final Map data;

  CreatePoll({Key key, this.data}) : super(key: key);

  @override
  _CreatePollState createState() => _CreatePollState();
}

class _CreatePollState extends State<CreatePoll> {

  Map poll = {
    'question': 'Your question here',
    'options': [
      {
        'title': 'Option',
        'votes': {},
        'controller': TextEditingController(text: 'Option')
      },
      {
        'title': 'Option',
        'votes': {},
        'controller': TextEditingController(text: 'Option')
      }
    ]
  };

  String error;
  String warning;

  @override
  void initState() {
    if (widget.data != null) {
      poll = widget.data;
      for (int i = 0; i < poll['options'].length; i++) {
        poll['options'][i]['controller'] = TextEditingController(text: poll['options'][i]['title']);
      }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Poll'),
        actions: [
          IconButton(
            icon: Icon(Icons.check_circle),
            tooltip: 'Done',
            onPressed: () {
              if (poll['options'].length < 2) {
                setState(() {
                  error = 'Poll must have atleast 2 options';
                });
              } else {
                for (int i = 0; i < poll['options'].length; i++) {
                  //print(poll['options'][i]);
                  (poll['options'][i] as Map).remove('controller');
                  print(poll['options'][i]);
                }
                Navigator.of(context).pop(poll);
              }
            },
          )
        ],
      ),
      body: ListView(
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.white : Colors.grey[900],
              boxShadow: [
                BoxShadow(
                  color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.grey[900],
                  blurRadius: 1,
                  spreadRadius: 0
                )
              ]
            ),
            child: ListTile(
              title: TextFormField(
                initialValue: poll['question'],
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none
                ),
                onChanged: (val) {
                  poll['question'] = val;
                  setState(() { });
                },
              ),
              leading: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.indigoAccent.withOpacity(0.3),
                  borderRadius: BorderRadius.all(Radius.circular(40))
                ),
                child: Center(
                  child: Text('Q', style: TextStyle(
                    fontFamily: RivalFonts.feature,
                  ),),
                ),
              ),
            ),
          ),
          Divider(),
          ListTile(
            title: Text(
              'Options',
              style: TextStyle(fontFamily: RivalFonts.feature),
            ),
            subtitle: (warning != null || error != null) ? Text(
              warning ?? error,
              style: TextStyle(
                color: warning != null ? Colors.yellow : Colors.red
              ),
            ) : null,
          ),
          ... List.generate(
            poll['options'].length,
            (index) => Container(
              margin: EdgeInsets.only(left: 10, right: 10, top: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.white : Colors.grey[900],
                boxShadow: [
                  BoxShadow(
                    color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black12 : Colors.grey[900],
                    blurRadius: 1,
                    spreadRadius: 0
                  )
                ]
              ),
              child: ListTile(
                title: TextFormField(
                  controller: poll['options'][index]['controller'],
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none
                  ),
                  onChanged: (val) {
                    poll['options'][index]['title'] = val;
                    setState(() { });
                  },
                ),
                //subtitle: Text(poll['options'][index]['title']),
                leading: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.indigoAccent.withOpacity(0.3),
                    borderRadius: BorderRadius.all(Radius.circular(40))
                  ),
                  child: Center(
                    child: Text('${index + 1}', style: TextStyle(
                      fontFamily: RivalFonts.feature,
                    ),),
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  tooltip: 'Delete option',
                  onPressed: () {
                    print('Option to be removed: ${poll['options'][index]} at index $index');
                    (poll['options'] as List).removeAt(index);
                    print('After Removing: ${poll['options']}');
                    setState(() { });
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlineButton(
                  child: Text('Add Option'),
                  onPressed: poll['options'].length < 5 ? () {
                    int noOfOptions = poll['options'].length;
                    if (noOfOptions < 5) {
                      poll['options'].add({
                        'title': 'Option',
                        'votes': {},
                        'controller': TextEditingController(text: 'Option')
                      });
                      warning = error = null;
                      setState(() { });
                    } else RivalProvider.showToast(text: 'You can add upto 5 options only');
                  } : null,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}