import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class RosterGenerator {
  final int year;
  final int month;
  final int daysInMonth;
  final List<String> names;
  final int shiftSize;
  final int shiftsPerDay;
  final String selectedShiftType;

  RosterGenerator({
    required this.year,
    required this.month,
    required this.daysInMonth,
    required this.names,
    required this.shiftSize,
    required this.shiftsPerDay,
    required this.selectedShiftType,
  });

  Future<List<Map<String, String>>> generateRoster() async {
    List<Map<String, String>> roster = [];
    Map<String, int> restUntilDay = {for (var name in names) name: 0};
    Map<String, String?> lastShift = {for (var name in names) name: null};
    Map<String, int> consecutiveNightShifts = {for (var name in names) name: 0};

    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, int> shiftHistory = {};
    String? historyJson = prefs.getString('shiftHistory');
    if (historyJson != null) {
      Map<String, dynamic> decoded = jsonDecode(historyJson);
      decoded.forEach((key, value) {
        shiftHistory[key] = value as int;
      });
    } else {
      shiftHistory = {for (var name in names) name: 0};
    }

    int personIndex = 0;
    final random = Random();
    Map<String, int> remainingWorkStreak = {for (var name in names) name: 0};

    for (int day = 1; day <= daysInMonth; day++) {
      DateTime currentDate = DateTime(year, month, day);
      String formattedDate =
          "${currentDate.day}-${currentDate.month}-${currentDate.year} (${["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][currentDate.weekday - 1]})";

      List<String> assignedToday = [];
      List<String> availableToday = names
          .where((name) => restUntilDay[name]! <= day - 1)
          .toList();

      if (availableToday.isNotEmpty) {
        availableToday = [
          ...availableToday.sublist(personIndex % availableToday.length),
          ...availableToday.sublist(0, personIndex % availableToday.length)
        ];
      }

      for (var name in availableToday) {
        shiftHistory[name] ??= 0;
      }

      availableToday.shuffle();

      if (shiftsPerDay == 1) {
        String shift = selectedShiftType;
        List<String> assignedPersons = [];

        for (int i = 0; i < shiftSize && availableToday.isNotEmpty; i++) {
          String person = availableToday.removeAt(0);
          assignedPersons.add(person);
          assignedToday.add(person);

          if (remainingWorkStreak[person]! == 0) {
            remainingWorkStreak[person] = 2 + random.nextInt(2);
          }

          remainingWorkStreak[person] = (remainingWorkStreak[person] ?? 0) - 1;

          if (shift == 'Night') {
            restUntilDay[person] = day + 1; // Mandatory rest after Night
            consecutiveNightShifts[person] = consecutiveNightShifts[person]! + 1;
          } else {
            consecutiveNightShifts[person] = 0;
          }

          if (remainingWorkStreak[person] == 0) {
            int extraRest = (lastShift[person] == 'Night')
                ? max(2, consecutiveNightShifts[person]!)
                : 1;
            restUntilDay[person] = max(restUntilDay[person]!, day + extraRest);
          }

          shiftHistory[person] = shiftHistory[person]! + 1;
          lastShift[person] = shift;
        }

        roster.add({
          'date': formattedDate,
          'shift': shift,
          'assigned': assignedPersons.join(", "),
        });
      } else {
        List<String> shiftNames = shiftsPerDay == 2
            ? ['Morning', 'Night']
            : ['Morning', 'Afternoon', 'Night'];

        for (String shift in shiftNames) {
          List<String> assignedPersons = [];
          List<String> shiftEligiblePersons = availableToday
              .where((person) => !assignedToday.contains(person))
              .toList();

          for (int i = 0; i < shiftSize && shiftEligiblePersons.isNotEmpty; i++) {
            String person = shiftEligiblePersons.removeAt(0);
            availableToday.remove(person);
            assignedPersons.add(person);
            assignedToday.add(person);

            if (remainingWorkStreak[person]! == 0) {
              remainingWorkStreak[person] = 2 + random.nextInt(2);
            }

            remainingWorkStreak[person] =
                (remainingWorkStreak[person] ?? 0) - 1;

            if (shift == 'Night') {
              restUntilDay[person] = day + 1; // Mandatory rest after Night
              consecutiveNightShifts[person] =
                  consecutiveNightShifts[person]! + 1;
            } else {
              consecutiveNightShifts[person] = 0;
            }

            if (remainingWorkStreak[person] == 0) {
              int extraRest = (lastShift[person] == 'Night')
                  ? max(2, consecutiveNightShifts[person]!)
                  : 1;
              restUntilDay[person] =
                  max(restUntilDay[person]!, day + extraRest);
            }

            shiftHistory[person] = shiftHistory[person]! + 1;
            lastShift[person] = shift;
          }

          roster.add({
            'date': formattedDate,
            'shift': shift,
            'assigned': assignedPersons.join(", "),
          });
        }
      }

      personIndex = (personIndex + 1) % names.length;

      List<String> offPersons =
      names.where((name) => !assignedToday.contains(name)).toList();
      if (offPersons.isNotEmpty) {
        roster.add({
          'date': formattedDate,
          'shift': 'OFF',
          'assigned': offPersons.join(", "),
        });

        for (var person in offPersons) {
          lastShift[person] = 'OFF';
        }
      }
    }

    await prefs.setString('shiftHistory', jsonEncode(shiftHistory));
    return roster;
  }
}
