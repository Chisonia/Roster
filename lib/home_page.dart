import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:roster/roster_logic.dart';
import 'package:roster/widgets/month_picker.dart';
import 'package:roster/widgets/shift_dropdown.dart';
import 'widgets/input_field.dart';

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
    final result = await showMonthYearPicker(context, _selectedYear, _selectedMonth);
    if (result != null) {
      setState(() {
        _selectedYear = result['year'];
        _selectedMonth = result['month'];
        _daysInMonth = DateTime(_selectedYear!, _selectedMonth! + 1, 0).day;
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

    List<String> inputNames = _namesController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    var validated = NameValidator.validateAndFilterNames(inputNames);
    List<String> names = validated['filtered']!;
    List<String> rejected = validated['rejected']!;

    if (names.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No valid unique names found.")),
      );
      return;
    }

    if (rejected.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Duplicate name(s)/initial(s) removed: ${rejected.join(', ')}"),
          duration: const Duration(seconds: 5),
        ),
      );
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

    String abbreviateName(String name) =>
        name.split(' ').map((e) => e[0].toUpperCase()).join();

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
          if (entry['date']!.startsWith('${i + 1}-$_selectedMonth') &&
              entry['assigned']!.contains(name)) {
            assignment += "${abbreviateShift(entry['shift']!)} ";
          }
        }
        row.add(assignment.trim().isEmpty ? 'off' : assignment.trim());
      }
      return row;
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (_) => [
          pw.Text(
            'Roster for $_selectedMonth/$_selectedYear',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: ["Names"] + dates,
            data: tableData,
            cellAlignment: pw.Alignment.center,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 8,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final shiftNumber = int.tryParse(_shiftNumberController.text) ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text("Roster Generator")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints:
            BoxConstraints(maxWidth: isSmallScreen ? double.infinity : 600),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _pickMonthYear,
                  child: Text((_selectedMonth == null || _selectedYear == null)
                      ? "Pick Month & Year"
                      : "Selected: $_selectedMonth/$_selectedYear ($_daysInMonth days)"),
                ),
                const SizedBox(height: 16),
                InputField(
                  controller: _namesController,
                  label: "Names or Initials (comma-separated)",
                ),
                InputField(
                  controller: _shiftSizeController,
                  label: "Number of Persons per Shift",
                  isNumber: true,
                ),
                InputField(
                  controller: _shiftNumberController,
                  label: "Number of Shifts Per Day",
                  isNumber: true,
                  onChanged: () => setState(() {}),
                ),
                if (shiftNumber == 1)
                  ShiftDropdown(
                    selectedValue: selectedShiftType,
                    onChanged: (value) => setState(() {
                      selectedShiftType = value;
                    }),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _generateRoster,
                  child: const Text("Generate Roster"),
                ),
                const SizedBox(height: 20),
                if (_generatedRoster.isNotEmpty) ...[
                  const Text("Generated Roster:",
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _generatedRoster.length,
                    itemBuilder: (_, index) {
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
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
