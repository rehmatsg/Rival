import 'package:flutter/material.dart';
import '../app.dart';

class SelectGender extends StatefulWidget {

  final bool isSettingUp;

  const SelectGender({Key key, this.isSettingUp = false}) : super(key: key);

  @override
  _SelectGenderState createState() => _SelectGenderState();
}

List<Gender> genders = [Gender.male, Gender.female, Gender.custom, Gender.other];

class _SelectGenderState extends State<SelectGender> {

  Gender gender;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Gender'),
      ),
      body: ListView(
        children: [
          ... List.generate(
            genders.length,
            (index) => ListTile(
              leading: Radio(
                visualDensity: VisualDensity.compact,
                groupValue: gender,
                value: genders[index],
                onChanged: (value) {
                  setState(() {
                    gender = value;
                  });
                },
              ),
              title: Text(_getGender(genders[index])),
              visualDensity: VisualDensity.compact,
            )
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Text('Your gender is kept private. It will not be shown anywhere', style: Theme.of(context).textTheme.caption,),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                OutlineButton(
                  onPressed: () async {
                    Loader.show(
                      context,
                      function: () async {
                        await me.update({
                          'gender': _getGenderForDB(gender)
                        }, reload: true);
                      },
                      onComplete: () {
                        RivalProvider.showToast(text: 'Updated Gender');
                        if (widget.isSettingUp) {
                          Navigator.of(context).pop(true);
                        } else Navigator.of(context).pushAndRemoveUntil(RivalNavigator(page: Home()), (route) => false);
                      }
                    );
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

  String _getGender(Gender gender) {
    if (gender == Gender.male) return 'Male';
    else if (gender == Gender.female) return 'Female';
    else if (gender == Gender.custom) return 'Prefer Not to Say';
    else return 'Other';
  }
  String _getGenderForDB(Gender gender) {
    if (gender == Gender.male) return 'male';
    else if (gender == Gender.female) return 'female';
    else if (gender == Gender.custom) return null;
    else return 'other';
  }

}

enum Gender {
  male,
  female,
  other,
  custom
}