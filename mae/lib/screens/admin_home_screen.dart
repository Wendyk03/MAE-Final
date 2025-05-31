import 'package:flutter/material.dart';
import '../widgets/admin_events_tab.dart';
import '../widgets/admin_notification_tab.dart';
import '../widgets/admin_event_in_progress_tab.dart';
import '../widgets/admin_events_finished_tab.dart';
import 'profile_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  final Function toggleTheme;
  final bool isDarkMode;
  final int initialTabIndex;

  const AdminHomeScreen({
    Key? key,
    required this.toggleTheme,
    required this.isDarkMode,
    this.initialTabIndex = 0,
  }) : super(key: key);

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late int _selectedIndex;

  final List<Widget> _screens = [
    const EventsTab(),
    const AdminEventInProgressTab(),
    const AdminEventsFinishedTab(),
    const AdminNotificationTab(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              color: Colors.red.shade200,
              child: Center(
                child: Text(
                  'ADMIN',
                  style: TextStyle(
                    color: Colors.red.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Admin Panel',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Colors.black,
            ),
            onPressed: () {
              widget.toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Pending Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timelapse),
            label: 'Event In Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timelapse),
            label: 'Event Completed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notification',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.red.shade600,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
