class BudgetSuggestion {
  final Map<String, double> suggestedBudget;

  BudgetSuggestion({required this.suggestedBudget});

  factory BudgetSuggestion.fromJson(Map<String, dynamic> json) {
    Map<String, double> budget = {};
    json['suggested_budget'].forEach((key, value) {
      budget[key] = value.toDouble();
    });
    return BudgetSuggestion(suggestedBudget: budget);
  }
}

class ForecastData {
  final List<ForecastItem> forecastedSpends;

  ForecastData({required this.forecastedSpends});

  factory ForecastData.fromJson(Map<String, dynamic> json) {
    List<ForecastItem> forecasts = [];
    for (var item in json['forecasted_spends']) {
      forecasts.add(ForecastItem.fromJson(item));
    }
    return ForecastData(forecastedSpends: forecasts);
  }
}

class ForecastItem {
  final DateTime date;
  final double amount;

  ForecastItem({required this.date, required this.amount});

  factory ForecastItem.fromJson(Map<String, dynamic> json) {
    return ForecastItem(
      date: DateTime.parse(json['date']),
      amount: json['amount'].toDouble(),
    );
  }
}

class SavingsPlan {
  final bool planPossible;
  final Map<String, double> suggestedCuts;
  final double monthlySavingsAchieved;
  final List<String> messages;

  SavingsPlan({
    required this.planPossible,
    required this.suggestedCuts,
    required this.monthlySavingsAchieved,
    required this.messages,
  });

  factory SavingsPlan.fromJson(Map<String, dynamic> json) {
    Map<String, double> cuts = {};
    json['suggested_cuts'].forEach((key, value) {
      cuts[key] = value.toDouble();
    });
    final msgs = (json['messages'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
    
    return SavingsPlan(
      planPossible: json['plan_possible'],
      suggestedCuts: cuts,
      monthlySavingsAchieved: json['monthly_savings_achieved'].toDouble(),
      messages: msgs,
    );
  }
}
