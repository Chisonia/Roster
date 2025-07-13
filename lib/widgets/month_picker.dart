import 'package:flutter/material.dart';

Future<Map<String, int>?> showMonthYearPicker(
    BuildContext context, int? selectedYear, int? selectedMonth) async {
  int tempYear = selectedYear ?? DateTime.now().year;
  int? tempMonth;

  return showDialog<Map<String, int>>(
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
                      onPressed: () => setState(() => tempYear--),
                    ),
                    Text('$tempYear'),
                    IconButton(
                      icon: const Icon(Icons.arrow_right),
                      onPressed: () => setState(() => tempYear++),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 200,
                  width: 250,
                  child: GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.5,
                    children: List.generate(12, (index) {
                      return ElevatedButton(
                        onPressed: () {
                          tempMonth = index + 1;
                          Navigator.pop(context, {'month': tempMonth!, 'year': tempYear});
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
}
