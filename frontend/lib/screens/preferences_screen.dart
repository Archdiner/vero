import 'package:flutter/material.dart';

class PreferencesScreen extends StatefulWidget {
  @override
  _PreferencesScreenState createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final List<String> cuisines = ['Italian', 'Japanese', 'Mexican', 'Indian'];
  List<String> selectedCuisines = [];
  double distance = 10; // Default: 10km

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Choose Preferences')),
      body: Column(
        children: [
          Text('Select Cuisines'),
          Wrap(
            children: cuisines.map((cuisine) {
              return ChoiceChip(
                label: Text(cuisine),
                selected: selectedCuisines.contains(cuisine),
                onSelected: (bool selected) {
                  setState(() {
                    selected
                        ? selectedCuisines.add(cuisine)
                        : selectedCuisines.remove(cuisine);
                  });
                },
              );
            }).toList(),
          ),
          Text('Select Distance'),
          Slider(
            value: distance,
            min: 1,
            max: 50,
            divisions: 10,
            label: '$distance km',
            onChanged: (value) {
              setState(() {
                distance = value;
              });
            },
          ),
          ElevatedButton(
            onPressed: () {
              // Save preferences (to be implemented)
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: Text('Continue'),
          ),
        ],
      ),
    );
  }
}
