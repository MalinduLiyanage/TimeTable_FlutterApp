import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';

class Schedulepage extends StatefulWidget {
  const Schedulepage({super.key});

  @override
  State<Schedulepage> createState() => _SchedulepageState();
}

class _SchedulepageState extends State<Schedulepage> {
  List<DateTime> _dates = [];
  String _selectedDate = DateTime.now().toString().split(" ")[0];
  String _previousselectedDate = DateTime.now().toString().split(" ")[0];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(color: Colors.white),
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
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: isCurrentDate
                                    ? Border.all(color: Colors.blue, width: 2)
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
                                ? _dates.first.toString().split(" ")[0]
                                : DateTime.now().toString().split(" ")[0];

                            _schedules.putIfAbsent(_selectedDate, () => {});

                            if (_schedules[_previousselectedDate] != null) {
                              bool isEmpty = _schedules[_previousselectedDate]!
                                  .values
                                  .every((list) => list.isEmpty);

                              if (isEmpty) {
                                _schedules.remove(_previousselectedDate);
                              }
                            }

                            _saveSchedules();
                          });
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              DateTime today = DateTime.now();
                              String todayString =
                                  today.toString().split(" ")[0];

                              _previousselectedDate = _selectedDate;
                              _selectedDate = todayString;

                              _dates = [today];

                              _schedules.putIfAbsent(_selectedDate, () => {});

                              if (_schedules[_previousselectedDate] != null) {
                                bool isEmpty =
                                    _schedules[_previousselectedDate]!
                                        .values
                                        .every((list) => list.isEmpty);
                                if (isEmpty) {
                                  _schedules.remove(_previousselectedDate);
                                }
                              }
                              _saveSchedules();
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                      content: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.green[300],
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(8, 0, 0, 0),
                                    child: Text('Today Selected!'),
                                  ),
                                ],
                              )));
                            });
                          },
                          child: Text("Jump to Today"),
                        ),
                      ),
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

                            _schedules.putIfAbsent(_selectedDate, () => {});
                            _schedules[_selectedDate]!
                                .putIfAbsent(index.toString(), () => []);

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
                                                  icon: const Icon(Icons.check,
                                                      color: Colors.green),
                                                  onPressed: () {
                                                    _saveSchedules();
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(SnackBar(
                                                            content: Row(
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .check_circle_rounded,
                                                          color:
                                                              Colors.green[300],
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .fromLTRB(
                                                                  8, 0, 0, 0),
                                                          child: Text(
                                                              'Schedule Saved!'),
                                                        ),
                                                      ],
                                                    )));
                                                  },
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
