import 'package:flutter/material.dart';
import 'package:timetable/pages/schedulepage.dart';
import 'package:timetable/pages/settingspage.dart';
import 'package:timetable/pages/viewschedulespage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Widget> _pages = [
    Schedulepage(),
    ViewSchedulesPage(),
    SettingsPage()
  ];

  final List<String> _pagetitle = [
    "Time Table",
    "Assigned Schedules",
    "Settings",
  ];

  int _selectedIndex = 0;

  void _onSelectPage(int index) {
    setState(() {
      _selectedIndex = index;
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          _pagetitle[_selectedIndex],
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Text(
                'Main Menu',
                style: TextStyle(fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.calendar_month),
              title: Text('Set Schedules'),
              onTap: () => _onSelectPage(0),
            ),
            ListTile(
              leading: Icon(Icons.check_circle),
              title: Text('View Schedules'),
              onTap: () => _onSelectPage(1),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () => _onSelectPage(2),
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
}
