import 'package:flutter/material.dart';
import '../widgets/events_tab.dart';
import '../widgets/my_events_tab.dart';
import '../widgets/event_registered_tab.dart';
import 'profile_screen.dart';
import 'admin_home_screen.dart';
import 'home_screen_na.dart';

class HomeScreen extends StatefulWidget {
  final Function toggleTheme;
  final bool isDarkMode;
  final int initialTabIndex;

  const HomeScreen({
    Key? key,
    required this.toggleTheme,
    required this.isDarkMode,
    this.initialTabIndex = 0,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;

  final List<Widget> _screens = [
    const EventsTab(),
    const MyEventsTab(),
    const RegisteredEventsTab(),
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
              height: 100,
              width: 120,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset('assets/apu_logo.png', fit: BoxFit.contain),
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
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'My Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.how_to_reg),
            label: 'Registered',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue.shade600,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
