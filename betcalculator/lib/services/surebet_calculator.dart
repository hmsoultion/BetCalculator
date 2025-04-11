class SurebetCalculator {
  static double? parseInput(String input) {
    if (input.trim().isEmpty) return null;
    return double.tryParse(input.trim());
  }

  static String? validate(
    List<String> odds,
    List<String> stakes,
    int count,
    bool isTotalFix,
    String totalInput,
  ) {
    for (int i = 0; i < count; i++) {
      //print("count: $count  odds: ${odds[i]}  stakes: ${stakes[i]}");

      if (odds[i].trim().isEmpty || stakes[i].trim().isEmpty) {
        return 'Please fill every field.';
      }

      if (double.tryParse(odds[i]) == null ||
          double.tryParse(stakes[i]) == null) {
        return 'Please enter the correct formula.';
      }
    }

    if (isTotalFix && totalInput.trim().isEmpty) {
      return 'Please fill Total Input field.';
    }

    if (isTotalFix && double.tryParse(totalInput) == null) {
      return 'Please enter the correct formula.';
    }

    if (isTotalFix &&
        (double.tryParse(totalInput) == null || double.parse(totalInput) < 1)) {
      return 'Please enter a odds number greater than 1.';
    }

    return null; // ✅ 모든 입력이 유효한 경우
  }

  static double calculateExampleLogic(List<double> odds, List<double> stakes) {
    // 샘플 계산 로직 - 예시
    return odds
        .asMap()
        .entries
        .map((e) => e.value * stakes[e.key])
        .reduce((a, b) => a + b);
  }

  // 실제 유형별 계산 분기 추가 가능
  static Map<String, dynamic> calculate({
    required List<double> odds,
    required List<double> stakes,
    required int selectionCount,
    required String type,
    required bool isTotalFixed,
    double? totalInput,
    int? fixIndex,
  }) {
    List<double> resultStakes = List.from(stakes);

    bool hasFix =
        fixIndex != null && fixIndex >= 0 && fixIndex < selectionCount;
    double mainResult = 0;
    double total = 0;

    // ✅ 타입 분기 계산 (selectionCount == 3 && !totalFixed)
    if (selectionCount == 3 && !isTotalFixed && hasFix) {
      _calculateByType(resultStakes, odds, type, fixIndex!);
      mainResult = odds[fixIndex!] * resultStakes[fixIndex!];
      total = resultStakes.take(selectionCount).reduce((a, b) => a + b);
    }
    // ✅ Total 금액 고정 계산 (모든 selectionCount에서 가능)
    else if (isTotalFixed && totalInput != null) {
      final inverseSum = odds
          .take(selectionCount)
          .fold(0.0, (sum, o) => sum + 1 / o);
      for (int i = 0; i < selectionCount; i++) {
        resultStakes[i] = (totalInput / odds[i]) / inverseSum;
      }
      mainResult = resultStakes[0] * odds[0];
      total = resultStakes.take(selectionCount).reduce((a, b) => a + b);
    }
    // ✅ 일반 고정 베팅 계산 (selectionCount != 3 && fix 있음 && total 고정 아님)
    else if (!isTotalFixed && selectionCount != 3 && hasFix) {
      mainResult = odds[fixIndex!] * resultStakes[fixIndex!];
      total = resultStakes[fixIndex!];
      for (int i = 0; i < selectionCount; i++) {
        if (i != fixIndex) {
          final stake = mainResult / odds[i];
          resultStakes[i] = double.parse(stake.toStringAsFixed(2));
          total += stake;
        }
      }
    }
    // ✅ 기본 total 계산만 하는 경우 (예외 방지)
    else {
      total = resultStakes.take(selectionCount).reduce((a, b) => a + b);
      mainResult = resultStakes[0] * odds[0];
    }

    final profit = mainResult - total;
    final yield = (profit / total) * 100;

    return {
      'stakes':
          resultStakes.map((s) => double.parse(s.toStringAsFixed(2))).toList(),
      'profit': double.parse(profit.toStringAsFixed(2)),
      'yield': double.parse(yield.toStringAsFixed(2)),
      'total': double.parse(total.toStringAsFixed(2)),
    };
  }

  static void _calculateByType(
    List<double> resultStakes,
    List<double> odds,
    String type,
    int fixIndex,
  ) {
    if (type == '1-X-2') {
      switch (fixIndex) {
        case 0: // '1' 고정
          resultStakes[1] = (odds[0] * resultStakes[0]) / odds[1];
          resultStakes[2] = (odds[0] * resultStakes[0]) / odds[2];
          break;

        case 1: // 'X' 고정
          resultStakes[0] = (odds[1] * resultStakes[1]) / odds[0];
          resultStakes[2] = (odds[1] * resultStakes[1]) / odds[2];
          break;

        case 2: // '2' 고정
          resultStakes[0] = (odds[2] * resultStakes[2]) / odds[0];
          resultStakes[1] = (odds[2] * resultStakes[2]) / odds[1];
          break;
      }
    } else if (type == '1-X-2/DNB') {
      switch (fixIndex) {
        case 0: // 1 고정
          final h1Result = odds[0] * resultStakes[0];
          resultStakes[2] = h1Result / odds[2]; // 2
          resultStakes[1] = (h1Result - resultStakes[2]) / odds[1]; // X
          break;

        case 1: // X 고정
          final xResult = odds[1] * resultStakes[1];
          resultStakes[2] = xResult / (odds[2] - 1); // 2
          final twoResult = odds[2] * resultStakes[2];
          resultStakes[0] = twoResult / odds[0]; // 1
          break;

        case 2: // 2 고정
          final twoResult = odds[2] * resultStakes[2];
          resultStakes[0] = twoResult / odds[0]; // 1
          resultStakes[1] =
              (odds[0] * resultStakes[0] - resultStakes[2]) / odds[1]; // X
          break;
      }
    } else if (type == '1-1X-2/DNB') {
      switch (fixIndex) {
        case 0: // "1" 고정
          final h1Result = odds[0] * resultStakes[0];
          resultStakes[1] = ((odds[0] - 1) * resultStakes[0]) / odds[1]; // 1X
          resultStakes[2] = h1Result / odds[2]; // 2
          break;

        case 1: // "1X" 고정
          final stake1X = resultStakes[1];
          final result1X = odds[1] * stake1X;
          resultStakes[0] = result1X / (odds[0] - 1); // 1
          resultStakes[2] = (odds[0] * resultStakes[0]) / odds[2]; // 2
          break;

        case 2: // "2/DNB" 고정
          final stake2 = resultStakes[2];
          final result2 = odds[2] * stake2;
          resultStakes[0] = result2 / odds[0]; // 1
          resultStakes[1] = ((odds[0] - 1) * resultStakes[0]) / odds[1]; // 1X
          break;
      }
    } else if (type == 'H1(0)-X-2') {
      switch (fixIndex) {
        case 0: // H1(0) 고정
          final h1Result = odds[0] * resultStakes[0];
          resultStakes[1] = ((odds[0] - 1) * resultStakes[0]) / odds[1]; // X
          resultStakes[2] = h1Result / odds[2]; // 2
          break;

        case 1: // X 고정
          final xStake = resultStakes[1];
          final xResult = odds[1] * xStake;
          resultStakes[0] = xResult / (odds[0] - 1); // H1(0)
          resultStakes[2] = (odds[0] * resultStakes[0]) / odds[2]; // 2
          break;

        case 2: // 2 고정
          final twoStake = resultStakes[2];
          final twoResult = odds[2] * twoStake;
          resultStakes[0] = twoResult / odds[0]; // H1(0)
          resultStakes[1] = ((odds[0] - 1) * resultStakes[0]) / odds[1]; // X
          break;
      }
    } else if (type == 'H1(0)-2-X2') {
      switch (fixIndex) {
        case 0: // H1(0) 고정
          final h1Result = odds[0] * resultStakes[0];
          resultStakes[1] = h1Result / odds[1]; // 2
          resultStakes[2] = ((odds[0] - 1) * resultStakes[0]) / odds[2]; // X2
          break;

        case 1: // 2 고정
          final stake2 = resultStakes[1];
          final result2 = odds[1] * stake2;
          resultStakes[0] = result2 / odds[0]; // H1(0)
          resultStakes[2] = ((odds[0] - 1) * resultStakes[0]) / odds[2]; // X2
          break;

        case 2: // X2 고정
          final x2Stake = resultStakes[2];
          resultStakes[0] = (odds[2] * x2Stake) / (odds[0] - 1); // H1(0)
          resultStakes[1] = (odds[0] * resultStakes[0]) / odds[1]; // 2
          break;
      }
    } else if (type == 'H1(-0.25)-X-H2(-0.25)') {
      switch (fixIndex) {
        case 0: // H1(-0.25) 고정
          final winAmount = odds[0] * resultStakes[0];
          resultStakes[1] = winAmount / odds[1]; // X
          resultStakes[2] = winAmount / odds[2]; // H2(-0.25)
          break;

        case 1: // X 고정
          final winAmount = odds[1] * resultStakes[1];
          resultStakes[0] = winAmount / odds[0]; // H1(-0.25)
          resultStakes[2] = winAmount / odds[2]; // H2(-0.25)
          break;

        case 2: // H2(-0.25) 고정
          final winAmount = odds[2] * resultStakes[2];
          resultStakes[0] = winAmount / odds[0]; // H1(-0.25)
          resultStakes[1] = winAmount / odds[1]; // X
          break;
      }
    } else if (type == 'H1(-0.25)-X-2') {
      switch (fixIndex) {
        case 0: // H1(-0.25) 고정
          final winAmount = odds[0] * resultStakes[0];
          resultStakes[1] = ((odds[0] - 1) * resultStakes[0]) / odds[1]; // X
          resultStakes[2] = winAmount / odds[2]; // 2
          break;

        case 1: // X 고정
          final xStake = resultStakes[1];
          final xResult = odds[1] * xStake;

          resultStakes[0] = xResult / (odds[0] - 1); // H1(-0.25)
          resultStakes[2] = (odds[0] * resultStakes[0]) / odds[2]; // 2
          break;

        case 2: // 2 고정
          final twoStake = resultStakes[2];
          final twoResult = odds[2] * twoStake;

          resultStakes[0] = twoResult / odds[0]; // H1(-0.25)
          resultStakes[1] = ((odds[0] - 1) * resultStakes[0]) / odds[1]; // X
          break;
      }
    } else if (type == 'H1(-0.25)-X-H2(0)') {
      switch (fixIndex) {
        case 0: // H1(-0.25) 고정
          final winAmount = odds[0] * resultStakes[0];
          resultStakes[1] = ((odds[0] - 1) * resultStakes[0]) / odds[1]; // X
          resultStakes[2] = winAmount / odds[2]; // H2(0)
          break;

        case 1: // X 고정
          final xStake = resultStakes[1];
          final xResult = odds[1] * xStake;

          resultStakes[0] = xResult / (odds[0] - 1); // H1(-0.25)
          resultStakes[2] = (odds[0] * resultStakes[0]) / odds[2]; // H2(0)
          break;

        case 2: // H2(0) 고정
          final h2Stake = resultStakes[2];
          final h2Result = odds[2] * h2Stake;

          resultStakes[0] = h2Result / odds[0]; // H1(-0.25)
          resultStakes[1] = ((odds[0] - 1) * resultStakes[0]) / odds[1]; // X
          break;
      }
    } else if (type == 'H1(-0.25)-H2(+0.5)-2') {
      switch (fixIndex) {
        case 0: // H1(-0.25) 고정
          final winAmount = odds[0] * resultStakes[0];
          resultStakes[1] =
              ((odds[0] - 1) * resultStakes[0]) / odds[1]; // H2(+0.5)
          resultStakes[2] = winAmount / odds[2]; // 2
          break;

        case 1: // H2(+0.5) 고정
          final stakeH2 = resultStakes[1];
          final resultH2 = odds[1] * stakeH2;

          resultStakes[0] = resultH2 / (odds[0] - 1); // H1(-0.25)
          resultStakes[2] = (odds[0] * resultStakes[0]) / odds[2]; // 2
          break;

        case 2: // 2 고정
          final stake2 = resultStakes[2];
          final result2 = odds[2] * stake2;

          resultStakes[0] = result2 / odds[0]; // H1(-0.25)
          resultStakes[1] =
              ((odds[0] - 1) * resultStakes[0]) / odds[1]; // H2(+0.5)
          break;
      }
    } else if (type == 'H1(+0.25)-X-2') {
      switch (fixIndex) {
        case 0: // H1(+0.25) 고정
          final h1Stake = resultStakes[0];
          final h1Result = odds[0] * h1Stake;

          resultStakes[1] = ((odds[0] - 1) * h1Stake) / odds[1]; // X
          resultStakes[2] = h1Result / odds[2]; // 2
          break;

        case 1: // X 고정
          final xStake = resultStakes[1];
          final xResult = odds[1] * xStake;

          resultStakes[0] = xResult / (odds[0] - 1); // H1(+0.25)
          resultStakes[2] = (odds[0] * resultStakes[0]) / odds[2]; // 2
          break;

        case 2: // 2 고정
          final stake2 = resultStakes[2];
          final result2 = odds[2] * stake2;

          resultStakes[0] = result2 / odds[0]; // H1(+0.25)
          resultStakes[1] = ((odds[0] - 1) * resultStakes[0]) / odds[1]; // X
          break;
      }
    } else if (type == 'H1(+0.25)-H1(0)-2') {
      switch (fixIndex) {
        case 0: // H1(+0.25) 고정
          final h1Stake = resultStakes[0];
          final h1Result = odds[0] * h1Stake;

          resultStakes[1] = ((odds[0] - 1) * h1Stake) / odds[1]; // H1(0)
          resultStakes[2] = h1Result / odds[2]; // 2
          break;

        case 1: // H1(0) 고정
          final h1ZeroStake = resultStakes[1];
          final h1ZeroResult = odds[1] * h1ZeroStake;

          resultStakes[0] = h1ZeroResult / (odds[0] - 1); // H1(+0.25)
          resultStakes[2] = (odds[0] * resultStakes[0]) / odds[2]; // 2
          break;

        case 2: // 2 고정
          final stake2 = resultStakes[2];
          final result2 = odds[2] * stake2;

          resultStakes[0] = result2 / odds[0]; // H1(+0.25)
          resultStakes[1] =
              ((odds[0] - 1) * resultStakes[0]) / odds[1]; // H1(0)
          break;
      }
    }
  }

  void calculate1X2DNB({
    required List<double> odds,
    required List<double> resultStakes,
    required int fixIndex,
  }) {
    // alias
    final h1 = 0;
    final x = 1;
    final two = 2;

    if (fixIndex == h1) {
      // 1 고정
      final h1Odd = odds[h1];
      final h1Stake = resultStakes[h1];
      final h1Result = h1Odd * h1Stake;

      final twoOdd = odds[two];
      final twoStake = h1Result / twoOdd;

      final xOdd = odds[x];
      final xStake = (h1Result - twoStake) / xOdd;

      resultStakes[x] = xStake;
      resultStakes[two] = twoStake;
    } else if (fixIndex == x) {
      // X 고정
      final xOdd = odds[x];
      final xStake = resultStakes[x];
      final xResult = xOdd * xStake;

      final twoOdd = odds[two];
      final twoStake = xResult / (twoOdd - 1);
      final twoResult = twoOdd * twoStake;

      final h1Odd = odds[h1];
      final h1Stake = twoResult / h1Odd;

      resultStakes[h1] = h1Stake;
      resultStakes[two] = twoStake;
    } else if (fixIndex == two) {
      // 2 고정
      final twoOdd = odds[two];
      final twoStake = resultStakes[two];
      final twoResult = twoOdd * twoStake;

      final h1Odd = odds[h1];
      final h1Stake = twoResult / h1Odd;
      final h1Result = h1Odd * h1Stake;

      final xOdd = odds[x];
      final xStake = (h1Result - twoStake) / xOdd;

      resultStakes[h1] = h1Stake;
      resultStakes[x] = xStake;
    }
  }
}
