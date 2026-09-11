import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/providers/auth_provider.dart';
import '../auth/widgets/admin_override_dialog.dart';
import '../auth/widgets/pin_login_dialog.dart';
import '../customers/screens/customers_screen.dart';
import '../settings/screens/settings_screen.dart';
import '../inventory/screens/inventory_screen.dart';
import '../pos/screens/pos_screen.dart';
import '../reports/screens/daily_z_report_screen.dart';
import '../../core/localization/app_locale.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;

  final _screens = const [
    PosScreen(),
    InventoryScreen(),
    CustomersScreen(),
    DailyZReportScreen(),
    SettingsScreen(),
  ];

  void _onDestinationSelected(int idx) async {
    final activeUser = ref.read(currentUserProvider);

    // If cashier attempts to access Z-Report (3) or Settings (4)
    if (activeUser?.role == 'cashier' && (idx == 3 || idx == 4)) {
      final approved = await AdminOverrideDialog.requestApproval(
        context,
        actionTitle: idx == 3 ? 'View Daily Z-Report' : 'Access Settings & Management',
      );
      if (!approved) return;
    }

    setState(() => _currentIndex = idx);
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(isTerminalLockedProvider);
    final lang = ref.watch(appLanguageProvider);

    Widget content = LayoutBuilder(
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
                  onDestinationSelected: _onDestinationSelected,
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
                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(Icons.point_of_sale_outlined),
                      selectedIcon: const Icon(Icons.point_of_sale),
                      label: Text(AppTranslations.tr('nav_register', lang)),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.inventory_2_outlined),
                      selectedIcon: const Icon(Icons.inventory_2),
                      label: Text(AppTranslations.tr('nav_inventory', lang)),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.people_outline),
                      selectedIcon: const Icon(Icons.people),
                      label: Text(AppTranslations.tr('nav_customers', lang)),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.receipt_long_outlined),
                      selectedIcon: const Icon(Icons.receipt_long),
                      label: Text(AppTranslations.tr('nav_zreport', lang)),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.settings_outlined),
                      selectedIcon: const Icon(Icons.settings),
                      label: Text(AppTranslations.tr('nav_settings', lang)),
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
              onDestinationSelected: _onDestinationSelected,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.point_of_sale_outlined, color: Color(0xFF94A3B8)),
                  selectedIcon: const Icon(Icons.point_of_sale, color: Color(0xFF60A5FA)),
                  label: AppTranslations.tr('nav_register', lang),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.inventory_2_outlined, color: Color(0xFF94A3B8)),
                  selectedIcon: const Icon(Icons.inventory_2, color: Color(0xFF60A5FA)),
                  label: AppTranslations.tr('nav_inventory', lang),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.people_outline, color: Color(0xFF94A3B8)),
                  selectedIcon: const Icon(Icons.people, color: Color(0xFF60A5FA)),
                  label: AppTranslations.tr('nav_customers', lang),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.receipt_long_outlined, color: Color(0xFF94A3B8)),
                  selectedIcon: const Icon(Icons.receipt_long, color: Color(0xFF60A5FA)),
                  label: AppTranslations.tr('nav_zreport', lang),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.settings_outlined, color: Color(0xFF94A3B8)),
                  selectedIcon: const Icon(Icons.settings, color: Color(0xFF60A5FA)),
                  label: AppTranslations.tr('nav_settings', lang),
                ),
              ],
            ),
          );
        }
      },
    );

    if (isLocked) {
      return Stack(
        children: [
          content,
          Positioned.fill(
            child: Container(
              color: const Color(0xFF0F172A).withValues(alpha: 0.96),
              alignment: Alignment.center,
              child: const PinLoginDialog(isLockScreen: true),
            ),
          ),
        ],
      );
    }

    return content;
  }
}
