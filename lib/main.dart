import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme.dart';
import 'data/app_state.dart';

import 'screens/history_screen.dart';
import 'screens/insight_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/budget_detail_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    BudgetDetailScreen(),
    HistoryScreen(),
    InsightScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Budget App',
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: _screens[_currentIndex],

        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.orange,
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddTransactionScreen(),
              ),
            );
          },
        ),

        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet),
              label: 'Budget',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.insights),
              label: 'Insight',
            ),
          ],
        ),
      ),
    );
  }
}