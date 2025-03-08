import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ViewSchedulesPage extends StatefulWidget {
  const ViewSchedulesPage({super.key});

  @override
  State<ViewSchedulesPage> createState() => _ViewSchedulesPageState();
}

class _ViewSchedulesPageState extends State<ViewSchedulesPage> {
  Map<String, Map<String, List<String>>> _schedules = {};

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  void _loadSchedules() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? schedulesString = prefs.getString('schedules');

    if (schedulesString != null) {
      final Map<String, dynamic> decoded = jsonDecode(schedulesString);

      setState(() {
        _schedules = decoded.map((date, hoursMap) {
          Map<String, List<String>> filteredHours =
              (hoursMap as Map<String, dynamic>).map(
            (hour, notesList) => MapEntry(hour, List<String>.from(notesList)),
          )..removeWhere((key, value) => value.isEmpty);

          return MapEntry(date, filteredHours);
        });

        _schedules.removeWhere((date, hours) => hours.isEmpty);
      });
    }
  }

  void _saveSchedules() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    Map<String, Map<String, List<String>>> serializableSchedules = {};

    _schedules.forEach((date, hourMap) {
      serializableSchedules[date] = {};

      hourMap.forEach((hour, notes) {
        serializableSchedules[date]![hour] = notes;
      });
    });

    String schedulesString = jsonEncode(serializableSchedules);
    prefs.setString('schedules', schedulesString);
  }

  void _editNote(
      BuildContext context, String date, String hour, String oldNote) {
    TextEditingController controller = TextEditingController(text: oldNote);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Note"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Enter new note"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  List<String> notes = _schedules[date]![hour]!;
                  int index = notes.indexOf(oldNote);
                  if (index != -1) {
                    notes[index] = controller.text; // Update note
                  }
                  _saveSchedules();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green[300],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                        child: Text('Schedule Changed!'),
                      ),
                    ],
                  )));
                });
                Navigator.pop(context); // Close dialog
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> sortedDates = _schedules.keys.toList()
      ..sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: sortedDates.isEmpty
            ? const Center(child: Text("No schedules found."))
            : ListView.builder(
                itemCount: sortedDates.length,
                itemBuilder: (context, index) {
                  String date = sortedDates[index];
                  Map<String, List<String>> dailySchedule = _schedules[date]!;

                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.all(8.0),
                    child: ExpansionTile(
                      title: Text(
                        date,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      children: dailySchedule.entries.map((entry) {
                        String hour = entry.key;
                        List<String> notes = entry.value;

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "${hour.toString().padLeft(2, '0')}.00",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: notes.map((note) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(7),
                                                  border: Border.all(
                                                      color: Colors.black)),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text(
                                                  note,
                                                  style: const TextStyle(
                                                      fontSize: 16),
                                                ),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () {
                                              _editNote(
                                                  context, date, hour, note);
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    AlertDialog(
                                                  title: const Text(
                                                      "Delete Schedule"),
                                                  content: const Text(
                                                      "Are you sure you want to delete the schedule?"),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child: const Text("No"),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          notes.remove(note);
                                                          if (notes.isEmpty) {
                                                            dailySchedule
                                                                .remove(hour);
                                                            if (dailySchedule
                                                                .isEmpty) {
                                                              _schedules
                                                                  .remove(date);
                                                            }
                                                          }
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                                  SnackBar(
                                                                      content:
                                                                          Row(
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .check_circle_rounded,
                                                                color: Colors
                                                                    .green[300],
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .fromLTRB(
                                                                        8,
                                                                        0,
                                                                        0,
                                                                        0),
                                                                child: Text(
                                                                    'Schedule Deleted!'),
                                                              ),
                                                            ],
                                                          )));
                                                          _saveSchedules();
                                                        });
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child: const Text("Yes"),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
