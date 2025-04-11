import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../services/surebet_calculator.dart';
import 'package:flutter/material.dart';

class CalculatorSureBet extends StatefulWidget {
  const CalculatorSureBet({super.key});

  @override
  State<CalculatorSureBet> createState() => _CalculatorSureBetState();
}

class _CalculatorSureBetState extends State<CalculatorSureBet> {
  String selectedSelection = '2';
  int selectedFixIndex = 0;
  String selectedType = '1-X-2';

  final selections = ['2', '3', '4', '5', '6', '7', '8'];
  final types = [
    '1-X-2',
    '1-X-2/DNB',
    '1-1X-2/DNB',
    'H1(0)-X-2',
    'H1(0)-2-X2',
    'H1(-0.25)-X-H2(-0.25)',
    'H1(-0.25)-X-2',
    'H1(-0.25)-X-H2(0)',
    'H1(-0.25)-H2(+0.5)-2',
    'H1(+0.25)-X-2',
    'H1(+0.25)-H1(0)-2',
  ];

  Map<String, List<String>> typeLabels = {
    '1-X-2': ['1', 'X', '2'],
    '1-X-2/DNB': ['1', 'X', '2'],
    '1-1X-2/DNB': ['1', '1X', '2'],
    'H1(0)-X-2': ['H1', 'X', '2'],
    'H1(0)-2-X2': ['H1', '2', 'X2'],
    'H1(-0.25)-X-H2(-0.25)': ['H1', 'X', 'H2'],
    'H1(-0.25)-X-2': ['H1', 'X', '2'],
    'H1(-0.25)-X-H2(0)': ['H1', 'X', 'H2'],
    'H1(-0.25)-H2(+0.5)-2': ['H1', 'H2', '2'],
    'H1(+0.25)-X-2': ['H1', 'X', '2'],
    'H1(+0.25)-H1(0)-2': ['H1', 'H1', '2'],
  };

  List<bool> fixSelected = List.generate(8, (_) => false);
  List<TextEditingController> oddsControllers = List.generate(
    8,
    (_) => TextEditingController(),
  );
  List<TextEditingController> stakeControllers = List.generate(
    8,
    (_) => TextEditingController(),
  );

  final totalInputController = TextEditingController(text: '100');
  final netProfitController = TextEditingController();
  final yieldController = TextEditingController();

  bool get isTotalFix => selectedFixIndex == int.parse(selectedSelection);

  double profit = 0;
  double yield = 0;
  bool isProfitPositive = true;
  bool isYieldPositive = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    selectedFixIndex = int.parse(selectedSelection); // Total을 기본 선택으로
    totalInputController.text = '100'; // 기본값 100
  }

  void reset() {
    setState(() {
      selectedSelection = selections.first;
      selectedType = types.first;
      fixSelected = List.generate(8, (_) => false);
      for (final c in oddsControllers) c.clear();
      for (final c in stakeControllers) c.clear();
      totalInputController.clear();
      netProfitController.clear();
      yieldController.clear();
      selectedFixIndex = int.parse(selectedSelection);
      totalInputController.text = '100';
    });
  }

  // void _showMessage(BuildContext context, String message) {
  //   showDialog(
  //     context: context,
  //     builder:
  //         (_) => AlertDialog(
  //           title: const Text('알림'),
  //           content: Text(message),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.pop(context),
  //               child: const Text('확인'),
  //             ),
  //           ],
  //         ),
  //   );
  // }

  void calculate() {
    final count = int.tryParse(selectedSelection) ?? 0;
    // 값 추출
    final odds = oddsControllers.take(count).map((c) => c.text).toList();
    final stakes = stakeControllers.take(count).map((c) => c.text).toList();
    final isFixed = selectedFixIndex == count;
    final totalInputText = totalInputController.text;

    // 유효성 검사
    final error = SurebetCalculator.validate(
      oddsControllers.map((e) => e.text).toList(),
      stakeControllers.map((e) => e.text).toList(),
      count,
      isTotalFix,
      totalInputController.text,
    );

    if (error != null) {
      Fluttertoast.showToast(
        msg: error,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    // TODO: 유효할 경우 계산 실행

    final oddsParsed =
        odds.map((e) => SurebetCalculator.parseInput(e)!).toList();
    final stakesParsed =
        stakes.map((e) => SurebetCalculator.parseInput(e)!).toList();
    final total = SurebetCalculator.parseInput(totalInputText);

    // 실제 계산
    final result = SurebetCalculator.calculate(
      odds: oddsParsed,
      stakes: stakesParsed,
      selectionCount: count,
      type: selectedType,
      isTotalFixed: isFixed,
      totalInput: total,
      fixIndex: selectedFixIndex,
    );

    // 결과 출력 or 상태에 반영
    setState(() {
      for (int i = 0; i < count; i++) {
        stakeControllers[i].text = result['stakes'][i].toStringAsFixed(2);
      }

      profit = result['profit'];
      yield = result['yield'];
      isProfitPositive = profit >= 0;
      isYieldPositive = yield >= 0;

      netProfitController.text = result['profit'].toStringAsFixed(2);
      yieldController.text = result['yield'].toStringAsFixed(2);
      totalInputController.text = result['total'].toStringAsFixed(2);
    });
  }

  Widget _buildHeaderCell(String title, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Center(
        child: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildInputRow(int index) {
    return Row(
      children: [
        // No (고정 텍스트)
        Expanded(
          flex: 1,
          child: Center(
            child: Text(
              selectedSelection == '3'
                  ? (typeLabels[selectedType]?[index] ?? '${index + 1}')
                  : '${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),

        // Odds 입력창
        Expanded(
          flex: 3,
          child: SizedBox(
            width: 150,
            height: 36,
            child: TextField(
              controller: oddsControllers[index],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 4,
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                LengthLimitingTextInputFormatter(5),
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Stake 입력창
        Expanded(
          flex: 4,
          child: SizedBox(
            width: 150, // 너비 지정
            height: 36, // 높이 지정
            child: TextField(
              controller: stakeControllers[index],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 8,
                ),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                LengthLimitingTextInputFormatter(8),
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
            ),
          ),
        ),

        // Fix 라디오 버튼
        Expanded(
          flex: 2,
          child: Radio<int>(
            value: index,
            groupValue: selectedFixIndex,
            onChanged: (val) {
              setState(() {
                selectedFixIndex = val!;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTotalInputRow() {
    return Row(
      children: [
        // No + Odds 자리에 'Total Input' 텍스트 (flex: 4)
        const Expanded(
          flex: 4,
          child: Padding(
            padding: EdgeInsets.only(left: 24),
            child: Text(
              'Total Input',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Stake 입력창 (flex: 3)
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.only(left: 0), // 👉 왼쪽 여백 추가
            child: SizedBox(
              width: 150,
              height: 36,
              child: TextField(
                controller: totalInputController,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(8),
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
              ),
            ),
          ),
        ),

        // Fix 라디오 버튼 (flex: 2)
        Expanded(
          flex: 2,
          child: Radio<int>(
            value: int.parse(selectedSelection), // Total row의 고정 인덱스
            groupValue: selectedFixIndex,
            onChanged: (val) {
              setState(() {
                selectedFixIndex = val!;
              });
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 콤보박스 2개
          Row(
            children: [
              const Text(
                'SureBet Selection',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 70, // 원하는 넓이로 조정
                child: DropdownButtonFormField<String>(
                  value: selectedSelection,
                  isExpanded: true,
                  isDense: true,
                  decoration: InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                  ),
                  items:
                      selections
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (val) => setState(() => selectedSelection = val!),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          if (selectedSelection == '3')
            Row(
              children: [
                const Text('Type'),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    isDense: true,
                    isExpanded: true,
                    value: selectedType,
                    items:
                        types
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged: (val) => setState(() => selectedType = val!),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 16),

          // 헤더
          Row(
            children: [
              _buildHeaderCell('No', flex: 1),
              _buildHeaderCell('Odds', flex: 3),
              _buildHeaderCell('Stake', flex: 4),
              _buildHeaderCell('Fix', flex: 2),
            ],
          ),
          const Divider(),

          // 입력창
          Column(
            children: [
              // 선택한 수 만큼 행 생성
              ...List.generate(
                int.parse(selectedSelection),
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  child: _buildInputRow(index),
                ),
              ),

              const SizedBox(height: 12), // 간격을 약간 줘도 좋아요
              // 마지막 Total Input 행 추가
              _buildTotalInputRow(),
            ],
          ),

          const SizedBox(height: 10),

          // 총 입력 및 결과
          Row(
            children: [
              Container(
                width: 120,
                padding: EdgeInsets.only(left: 25),
                child: Text(
                  'Net Profit',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 130,
                child: Container(
                  color: Colors.grey.shade200, // 💡 배경색 지정
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    netProfitController.text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isProfitPositive ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 120,
                padding: EdgeInsets.only(left: 25),
                child: Text(
                  'Yield (%)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 130,
                child: Container(
                  color: Colors.grey.shade200,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    yieldController.text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isProfitPositive ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 버튼들
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12), // 좌우 패딩 16px
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 60,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A3150),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: reset,
                      label: const Text('Reset'),
                      icon: const Icon(Icons.refresh),
                    ),
                  ),
                ),
                const SizedBox(width: 16), // 버튼 사이 간격
                Expanded(
                  child: SizedBox(
                    height: 60,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A3150),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: calculate,
                      label: const Text('Calculate'),
                      icon: const Icon(Icons.calculate),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
