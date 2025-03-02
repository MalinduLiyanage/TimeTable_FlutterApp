import 'dart:convert'; // For jsonEncode and jsonDecode
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<DateTime> _dates = [];
  String _selectedDate = DateTime.now().toString().split(" ")[0];
  String _previousselectedDate = DateTime.now().toString().split(" ")[0];

  // Store schedules per date (Each hour has a list of notes)
  Map<String, Map<String, List<String>>> _schedules =
      {}; // Changed Map<int, List<String>> to Map<String, List<String>>

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  // Load schedules from SharedPreferences
  void _loadSchedules() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? schedulesString = prefs.getString('schedules');

    if (schedulesString != null) {
      // Safely decode and cast the loaded JSON string
      final Map<String, dynamic> decoded = jsonDecode(schedulesString);

      // Manually cast the inner structure to the expected type
      setState(() {
        _schedules = decoded.map((date, hoursMap) {
          return MapEntry(
            date,
            (hoursMap as Map<String, dynamic>).map((hour, notesList) {
              return MapEntry(
                hour,
                List<String>.from(notesList),
              );
            }),
          );
        });
      });
    }
  }

  // Save schedules to SharedPreferences
  void _saveSchedules() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Convert the Map to a serializable structure
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      CalendarDatePicker2(
                        key: ValueKey(_dates.hashCode),
                        config: CalendarDatePicker2Config(
                          dayBuilder: (
                              {required DateTime date,
                              BoxDecoration? decoration,
                              bool? isDisabled,
                              bool? isSelected,
                              bool? isToday,
                              TextStyle? textStyle}) {
                            bool hasRecords = _schedules
                                .containsKey(date.toString().split(" ")[0]);
                            bool isCurrentDate =
                                date.toString().split(" ")[0] ==
                                    DateTime.now().toString().split(" ")[0];

                            return Container(
                              decoration: BoxDecoration(
                                color: hasRecords
                                    ? Colors.purple
                                    : Colors
                                        .transparent, // Purple fill for records
                                borderRadius: BorderRadius.circular(8),
                                border: isCurrentDate
                                    ? Border.all(
                                        color: Colors.blue,
                                        width: 2) // Blue border for today
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  "${date.day}",
                                  style: TextStyle(
                                    color: hasRecords
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: hasRecords || isCurrentDate
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        value: _dates,
                        onValueChanged: (dates) {
                          setState(() {
                            _previousselectedDate = _selectedDate;
                            _dates = dates;
                            _selectedDate = _dates.isNotEmpty
                                ? _dates.first
                                    .toString()
                                    .split(" ")[0] // Selected date
                                : DateTime.now()
                                    .toString()
                                    .split(" ")[0]; // Default to current date

                            // Initialize empty schedule if the date is new
                            _schedules.putIfAbsent(_selectedDate, () => {});

                            // Remove the date if it has no scheduled entries (check all hours)
                            if (_schedules[_previousselectedDate] != null) {
                              bool isEmpty = _schedules[_previousselectedDate]!
                                  .values
                                  .every((list) => list.isEmpty);

                              if (isEmpty) {
                                _schedules.remove(_previousselectedDate);
                              }
                            }

                            // Save updated schedules to SharedPreferences
                            _saveSchedules();
                          });
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity,
                                50), // Full width and fixed height
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8), // Rounded corners
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              DateTime today = DateTime.now();
                              String todayString =
                                  today.toString().split(" ")[0];

                              _previousselectedDate = _selectedDate;
                              _selectedDate = todayString;

                              // Update the _dates list with a new instance to trigger UI refresh
                              _dates = [today];

                              // Initialize empty schedule if the date is new
                              _schedules.putIfAbsent(_selectedDate, () => {});

                              // Remove previous date if no records exist
                              if (_schedules[_previousselectedDate] != null) {
                                bool isEmpty =
                                    _schedules[_previousselectedDate]!
                                        .values
                                        .every((list) => list.isEmpty);
                                if (isEmpty) {
                                  _schedules.remove(_previousselectedDate);
                                }
                              }

                              // Save updated schedules to SharedPreferences
                              _saveSchedules();
                            });
                          },
                          child: Text("Jump to Today"),
                        ),
                      ),
                      // Other buttons for importing/exporting data can go here...
                    ],
                  )),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedDate,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: 24,
                          itemBuilder: (context, index) {
                            String timeLabel =
                                "${index.toString().padLeft(2, '0')}.00";

                            // Ensure we have a list for each hour
                            _schedules.putIfAbsent(_selectedDate, () => {});
                            _schedules[_selectedDate]!.putIfAbsent(
                                index.toString(),
                                () => []); // Change index to string

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
                                          timeLabel,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add),
                                          onPressed: () {
                                            setState(() {
                                              _schedules[_selectedDate]![
                                                      index.toString()]!
                                                  .add(""); // Add empty note
                                            });

                                            // Save updated schedules to SharedPreferences
                                            _saveSchedules();
                                          },
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: List.generate(
                                        _schedules[_selectedDate]![
                                                index.toString()]!
                                            .length,
                                        (noteIndex) {
                                          TextEditingController controller =
                                              TextEditingController(
                                            text: _schedules[_selectedDate]![
                                                index.toString()]![noteIndex],
                                          );

                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4.0),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: TextField(
                                                    controller: controller,
                                                    decoration:
                                                        const InputDecoration(
                                                      hintText: "Add note...",
                                                      border:
                                                          OutlineInputBorder(),
                                                    ),
                                                    onChanged: (text) {
                                                      _schedules[_selectedDate]![
                                                              index
                                                                  .toString()]![
                                                          noteIndex] = text;
                                                    },
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete,
                                                      color: Colors.red),
                                                  onPressed: () {
                                                    setState(() {
                                                      _schedules[_selectedDate]![
                                                              index.toString()]!
                                                          .removeAt(noteIndex);
                                                    });

                                                    // Save updated schedules to SharedPreferences
                                                    _saveSchedules();
                                                  },
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
