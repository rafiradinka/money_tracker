import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../screens/home_screen.dart';
import '../screens/history_screen.dart';
import '../screens/insight_screen.dart';
import '../screens/add_transaction_sheet.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  void switchTab(int index) => setState(() => _currentIndex = index);

  static AppShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<AppShellState>();

  final List<Widget> _screens = const [
    HomeScreen(),
    HistoryScreen(),
    SizedBox(), // placeholder for FAB center
    InsightScreen(),
    _MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.bottomBar,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(
          index: _currentIndex == 2 ? 0 : _currentIndex > 2 ? _currentIndex - 1 : _currentIndex,
          children: [
            const HomeScreen(),
            const HistoryScreen(),
            const InsightScreen(),
            const _MoreScreen(),
          ],
        ),
        floatingActionButton: _FABButton(
          onTap: () => AddTransactionSheet.show(context),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _BottomBar(
          currentIndex: _currentIndex,
          onTap: (i) {
            if (i == 2) return; // FAB slot — handled by FAB
            setState(() => _currentIndex = i);
          },
        ),
      ),
    );
  }
}

// ── FAB ───────────────────────────────────────────────────────────────────────

class _FABButton extends StatelessWidget {
  final VoidCallback onTap;
  const _FABButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: AppColors.orange,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withOpacity(0.4),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}

// ── Bottom Navigation Bar ─────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: AppColors.bottomBar,
        border: Border(
          top: BorderSide(
            color: AppColors.greyDark.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            iconFilled: Icons.home_rounded,
            label: 'Home',
            selected: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.receipt_long_outlined,
            iconFilled: Icons.receipt_long_rounded,
            label: 'History',
            selected: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          // FAB center placeholder
          const Expanded(child: SizedBox()),
          _NavItem(
            icon: Icons.bar_chart_outlined,
            iconFilled: Icons.bar_chart_rounded,
            label: 'Insight',
            selected: currentIndex == 3,
            onTap: () => onTap(3),
          ),
          _NavItem(
            icon: Icons.more_horiz_rounded,
            iconFilled: Icons.more_horiz_rounded,
            label: 'More',
            selected: currentIndex == 4,
            onTap: () => onTap(4),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData iconFilled;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.iconFilled,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? iconFilled : icon,
              color: selected ? AppColors.orange : AppColors.grey,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.orange : AppColors.grey,
                fontSize: 11,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── More Screen (placeholder) ─────────────────────────────────────────────────

class _MoreScreen extends StatelessWidget {
  const _MoreScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'More',
          style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text(
          'Coming soon',
          style: TextStyle(color: AppColors.grey, fontSize: 16),
        ),
      ),
    );
  }
}
