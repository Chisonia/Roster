import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:roster/roster_logic.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roster Generator',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const RosterPage(),
    );
  }
}

class RosterPage extends StatefulWidget {
  const RosterPage({super.key});

  @override
  RosterPageState createState() => RosterPageState();
}

class RosterPageState extends State<RosterPage> {
  final TextEditingController _namesController = TextEditingController();
  final TextEditingController _shiftSizeController = TextEditingController();
  final TextEditingController _shiftNumberController = TextEditingController();

  int? _selectedYear;
  int? _selectedMonth;
  int? _daysInMonth;
  String selectedShiftType = 'Morning';

  List<Map<String, String>> _generatedRoster = [];

  void _pickMonthYear() async {
    int tempYear = DateTime.now().year;
    int? tempMonth;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Month & Year'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_left),
                        onPressed: () {
                          setState(() {
                            tempYear--;
                          });
                        },
                      ),
                      Text('$tempYear'),
                      IconButton(
                        icon: const Icon(Icons.arrow_right),
                        onPressed: () {
                          setState(() {
                            tempYear++;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 300,
                    width: 300,
                    child: GridView.count(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.5,
                      shrinkWrap: true,
                      children: List.generate(12, (index) {
                        return ElevatedButton(
                          onPressed: () {
                            tempMonth = index + 1;
                            Navigator.pop(context);
                          },
                          child: Text([
                            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                          ][index]),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (tempMonth != null) {
      setState(() {
        _selectedYear = tempYear;
        _selectedMonth = tempMonth;
        _daysInMonth =
            DateTime(_selectedYear!, _selectedMonth! + 1, 0).day;
      });
    }
  }

  Future<void> _generateRoster() async {
    if (_selectedMonth == null || _selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select month and year")),
      );
      return;
    }

    List<String> names = _namesController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (names.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter valid names or initials")),
      );
      return;
    }

    int shiftSize = int.parse(_shiftSizeController.text);
    int shiftsPerDay = int.parse(_shiftNumberController.text);

    var generator = RosterGenerator(
      year: _selectedYear!,
      month: _selectedMonth!,
      daysInMonth: _daysInMonth!,
      names: names,
      shiftSize: shiftSize,
      shiftsPerDay: shiftsPerDay,
      selectedShiftType: selectedShiftType,
    );

    List<Map<String, String>> roster = await generator.generateRoster();

    setState(() {
      _generatedRoster = roster;
    });
  }

  Future<void> _exportToPdf() async {
    final pdf = pw.Document();

    String abbreviateName(String name) {
      return name.split(' ').map((part) => part[0].toUpperCase()).join('');
    }

    String abbreviateShift(String shift) {
      switch (shift) {
        case 'Morning':
          return 'M';
        case 'Afternoon':
          return 'A';
        case 'Night':
          return 'N';
        case 'OFF':
          return 'O';
        default:
          return shift;
      }
    }

    List<String> dates = List.generate(_daysInMonth!, (i) {
      DateTime date = DateTime(_selectedYear!, _selectedMonth!, i + 1);
      return "${i + 1}/$_selectedMonth/${_selectedYear! % 100}\n${["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][date.weekday - 1]}";
    });

    List<List<String>> tableData = _namesController.text
        .split(',')
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .map((name) {
      final initials = abbreviateName(name);
      List<String> row = [initials];
      for (int i = 0; i < _daysInMonth!; i++) {
        String assignment = "";
        for (var entry in _generatedRoster) {
          if (entry['date']!.startsWith('${i + 1}-${_selectedMonth}')) {
            if (entry['assigned']!.contains(name)) {
              assignment += "${abbreviateShift(entry['shift']!)} ";
            }
          }
        }
        row.add(assignment.trim().isEmpty ? 'off' : assignment.trim());
      }
      return row;
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [
          pw.Text(
            'Roster for $_selectedMonth/$_selectedYear',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: ["Names"] + dates,
            data: tableData,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 8,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
            cellAlignment: pw.Alignment.center,
            oddRowDecoration:
            const pw.BoxDecoration(color: PdfColors.grey200),
            cellStyle: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shiftNumber = int.tryParse(_shiftNumberController.text) ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text("Roster Generator")),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Column(
                children: <Widget>[
                  ElevatedButton(
                    onPressed: _pickMonthYear,
                    child: Text((_selectedMonth == null ||
                        _selectedYear == null)
                        ? "Pick Month & Year"
                        : "Selected: $_selectedMonth/$_selectedYear ($_daysInMonth days)"),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _namesController,
                    decoration: const InputDecoration(
                      labelText: "Names or Initials (comma-separated)",
                    ),
                  ),
                  TextField(
                    controller: _shiftSizeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Number of Persons per Shift",
                    ),
                  ),
                  TextField(
                    controller: _shiftNumberController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Number of Shifts Per Day",
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  if (shiftNumber == 1)
                    DropdownButton<String>(
                      value: selectedShiftType,
                      items: ['Morning', 'Night']
                          .map((shift) => DropdownMenuItem(
                        value: shift,
                        child: Text(shift),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedShiftType = value!;
                        });
                      },
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _generateRoster,
                    child: const Text("Generate Roster"),
                  ),
                  const SizedBox(height: 20),
                  if (_generatedRoster.isNotEmpty) ...[
                    const Text(
                      "Generated Roster:",
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _generatedRoster.length,
                      itemBuilder: (context, index) {
                        var entry = _generatedRoster[index];
                        return ListTile(
                          title: Text(entry['date']!),
                          subtitle:
                          Text('${entry['shift']}: ${entry['assigned']}'),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _exportToPdf,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text("Export to PDF"),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
