import 'package:flutter/material.dart';
import '../diagnostics/diagnostics_screen.dart';
import '../inventory/screens/inventory_screen.dart';
import '../pos/screens/pos_screen.dart';
import '../reports/screens/daily_z_report_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final _screens = const [
    PosScreen(),
    InventoryScreen(),
    DailyZReportScreen(),
    DiagnosticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktopOrTablet = constraints.maxWidth >= 700;

        if (isDesktopOrTablet) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            body: Row(
              children: [
                NavigationRail(
                  backgroundColor: const Color(0xFF1E293B),
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: const IconThemeData(color: Color(0xFF60A5FA)),
                  unselectedIconTheme: const IconThemeData(color: Color(0xFF94A3B8)),
                  selectedLabelTextStyle: const TextStyle(
                    color: Color(0xFF60A5FA),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelTextStyle: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.point_of_sale, color: Colors.white, size: 22),
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.point_of_sale_outlined),
                      selectedIcon: Icon(Icons.point_of_sale),
                      label: Text('POS Sales'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.inventory_2_outlined),
                      selectedIcon: Icon(Icons.inventory_2),
                      label: Text('Inventory'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.receipt_long_outlined),
                      selectedIcon: Icon(Icons.receipt_long),
                      label: Text('Z-Report'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.storage_outlined),
                      selectedIcon: Icon(Icons.storage),
                      label: Text('DB & Sync'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1, color: Color(0xFF334155)),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _screens,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            body: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
            bottomNavigationBar: NavigationBar(
              backgroundColor: const Color(0xFF1E293B),
              indicatorColor: const Color(0xFF2563EB).withValues(alpha: 0.3),
              selectedIndex: _currentIndex,
              onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.point_of_sale_outlined, color: Color(0xFF94A3B8)),
                  selectedIcon: Icon(Icons.point_of_sale, color: Color(0xFF60A5FA)),
                  label: 'Register',
                ),
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined, color: Color(0xFF94A3B8)),
                  selectedIcon: Icon(Icons.inventory_2, color: Color(0xFF60A5FA)),
                  label: 'Inventory',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined, color: Color(0xFF94A3B8)),
                  selectedIcon: Icon(Icons.receipt_long, color: Color(0xFF60A5FA)),
                  label: 'Z-Report',
                ),
                NavigationDestination(
                  icon: Icon(Icons.storage_outlined, color: Color(0xFF94A3B8)),
                  selectedIcon: Icon(Icons.storage, color: Color(0xFF60A5FA)),
                  label: 'DB & Sync',
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
