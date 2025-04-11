import 'package:flutter/material.dart';
import 'screens/surebet_screen.dart';
import 'screens/oddsconverter_screen.dart';

void main() {
  runApp(const MyApp());
}

// 메인 앱
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SurebetUniversalCal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const MainCalculatorScreen(),
    );
  }
}

// 메인 계산기 화면
class MainCalculatorScreen extends StatefulWidget {
  const MainCalculatorScreen({super.key});

  @override
  State<MainCalculatorScreen> createState() => _MainCalculatorScreenState();
}

class _MainCalculatorScreenState extends State<MainCalculatorScreen> {
  int _selectedIndex = 0;

  final List<String> _calculatorTitles = [
    'SureBet Calculator',
    'Odds Converter',
  ];
  final List<Widget> _calculatorPages = [
    const CalculatorSureBet(),
    const OddsConverter(),
  ];

  void _onMenuSelected(int index) {
    setState(() {
      _selectedIndex = index;
      Navigator.pop(context); // Drawer 닫기
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_calculatorTitles[_selectedIndex])),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            ListTile(
              title: const Text('SureBet Calculator'),
              leading: const Icon(Icons.calculate),
              selected: _selectedIndex == 0,
              onTap: () => _onMenuSelected(0),
            ),
            ListTile(
              title: const Text('Odds Converter'),
              leading: const Icon(Icons.percent),
              selected: _selectedIndex == 1,
              onTap: () => _onMenuSelected(1),
            ),
          ],
        ),
      ),
      body: _calculatorPages[_selectedIndex],
    );
  }
}
