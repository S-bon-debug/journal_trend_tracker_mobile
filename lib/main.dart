import 'package:flutter/material.dart';
import 'features/trends/presentation/screens/trends_dashboard_screen.dart';
import 'features/trends/presentation/screens/export_report_screen.dart';
import 'features/papers/presentation/screens/papers_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Journal Trend Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purpleAccent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    TrendsDashboardScreen(),
    ExportReportScreen(),
    PapersScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Trends Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.file_download),
            label: 'Export Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Papers',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.purpleAccent,
        unselectedItemColor: Colors.white54,
        backgroundColor: const Color(0xFF1E1E1E),
        onTap: _onItemTapped,
      ),
    );
  }
}
