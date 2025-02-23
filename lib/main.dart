import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roster Generator',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: RosterPage(),
    );
  }
}

class RosterPage extends StatefulWidget {
  @override
  _RosterPageState createState() => _RosterPageState();
}

class _RosterPageState extends State<RosterPage> {
  final TextEditingController _daysController = TextEditingController();
  final TextEditingController _peopleController = TextEditingController();
  final TextEditingController _workDaysController = TextEditingController();
  final TextEditingController _offDaysController = TextEditingController();
  final TextEditingController _shiftSizeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Roster Generator")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _daysController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Number of Days in Month"),
            ),
            TextField(
              controller: _peopleController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Number of Persons"),
            ),
            TextField(
              controller: _workDaysController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Workdays per Person"),
            ),
            TextField(
              controller: _offDaysController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Off Duty Days"),
            ),
            TextField(
              controller: _shiftSizeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Number of Persons per Shift"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {}, // Logic will be added here
              child: Text("Generate Roster"),
            ),
          ],
        ),
      ),
    );
  }
}
