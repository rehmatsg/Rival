import 'package:flutter/material.dart';
//import '../app.dart';

class AddDOB extends StatefulWidget {
  @override
  _AddDOBState createState() => _AddDOBState();
}

class _AddDOBState extends State<AddDOB> {

  TextEditingController _ageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add DOB'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(),
          ),
          TextFormField(
            controller: _ageController,
            decoration: InputDecoration(
              filled: true,
              labelText: 'Age',
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Text('Your age is kept private. It will not be shown anywhere', style: Theme.of(context).textTheme.caption,),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: () async {
                    
                  },
                  child: Text('Save'),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}