import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/exam_manager_provider.dart';
import 'monitoring_screen.dart';
import 'exam_creation_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const MonitoringScreen(),
    const ExamCreationScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExamManagerProvider>(context, listen: false).loadInitialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 260,
            decoration: const BoxDecoration(
              color: Color(0xFF111111),
              border: Border(right: BorderSide(color: Colors.white12)),
            ),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    "UNIELIVATE",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                _buildSidebarItem(0, Icons.speed, "Live Monitor"),
                _buildSidebarItem(1, Icons.add_circle_outline, "Create Exam"),
                const Spacer(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white38),
                  title: const Text("Logout", style: TextStyle(color: Colors.white38)),
                  onTap: () {
                    Provider.of<AuthProvider>(context, listen: false).logout();
                    // Navigator handled by provider/main state
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          // Main Content
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return ListTile(
      onTap: () => setState(() => _selectedIndex = index),
      leading: Icon(icon, color: isSelected ? Colors.indigoAccent : Colors.white38),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white38,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      tileColor: isSelected ? Colors.white.withValues(alpha: 0.02) : null,
    );
  }
}
