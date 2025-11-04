import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/transaction_provider.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';
import '../models/api_models.dart';
import '../widgets/date_range_selector.dart';
import '../services/report_service.dart';

class SavingsPlannerScreen extends StatefulWidget {
  const SavingsPlannerScreen({super.key});

  @override
  State<SavingsPlannerScreen> createState() => _SavingsPlannerScreenState();
}

class _SavingsPlannerScreenState extends State<SavingsPlannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _goalAmountController = TextEditingController();
  final _timelineController = TextEditingController();
  final _currentBalanceController = TextEditingController();
  DateRangeMonths _analysisRange = DateRangeMonths.three;

  SavingsPlan? _savingsPlan;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _goalAmountController.dispose();
    _timelineController.dispose();
    _currentBalanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Planner'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          if (_savingsPlan != null)
            IconButton(
              onPressed: _isLoading ? null : _exportReport,
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Generate PDF Report',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGoalForm(),
            const SizedBox(height: 24),
            if (_savingsPlan != null) _buildSavingsPlan(),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalForm() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Set Your Savings Goal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _goalAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Goal Amount',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.savings),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter goal amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid amount';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _currentBalanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Current Available Balance (optional)',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance_wallet),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid amount';
                  }
                  if (double.parse(value) < 0) {
                    return 'Balance cannot be negative';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _timelineController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Timeline (Months)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_month),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter timeline';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (int.parse(value) <= 0) {
                    return 'Timeline must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Analysis period:'),
                  DateRangeSelector(
                    value: _analysisRange,
                    onChanged: (v) {
                      setState(() {
                        _analysisRange = v;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _generateSavingsPlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Generate Savings Plan',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavingsPlan() {
    if (_error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(
                Icons.error,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Error: $_error',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _generateSavingsPlan,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildPlanSummary(),
        const SizedBox(height: 24),
        _buildSuggestedCuts(),
      ],
    );
  }

  Widget _buildPlanSummary() {
    final plan = _savingsPlan!;
    final monthlySavings = plan.monthlySavingsAchieved;
    final totalGoal = double.parse(_goalAmountController.text);
    final timeline = int.parse(_timelineController.text);
    final totalSavings = monthlySavings * timeline;

    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: plan.planPossible
                ? [Colors.green, Colors.greenAccent]
                : [Colors.red, Colors.redAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  plan.planPossible ? Icons.check_circle : Icons.cancel,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  plan.planPossible
                      ? 'Plan Achievable!'
                      : 'Plan Not Achievable',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly Savings',
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      '₹${monthlySavings.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Total Savings',
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      '₹${totalSavings.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Goal: ₹${totalGoal.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  'Timeline: $timeline months',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
            if (!plan.planPossible) ...[
              const SizedBox(height: 16),
              const Text(
                'Consider increasing your timeline or reducing your goal amount.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
            if (plan.messages.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...plan.messages.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Colors.white70)),
                        Expanded(
                          child: Text(
                            m,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedCuts() {
    if (_savingsPlan!.suggestedCuts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('No spending cuts suggested'),
              if (_savingsPlan!.messages.isNotEmpty) ...[
                const SizedBox(height: 8),
                ..._savingsPlan!.messages.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• '),
                          Expanded(child: Text(m)),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Suggested Spending Cuts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._savingsPlan!.suggestedCuts.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '₹${entry.value.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'These cuts will help you save ₹${_savingsPlan!.monthlySavingsAchieved.toStringAsFixed(0)} per month.',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateSavingsPlan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);

      // Get average spending by category for selected analysis period
      final averageSpending = await DatabaseService
          .getAverageSpendingByCategory(_analysisRange.months);

      final savingsPlan = await ApiService.getSavingsPlan(
        goalAmount: double.parse(_goalAmountController.text),
        timelineMonths: int.parse(_timelineController.text),
        averageSpending: averageSpending,
        currentBalance: double.tryParse(_currentBalanceController.text),
      );

      setState(() {
        _savingsPlan = savingsPlan;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _exportReport() async {
    if (_savingsPlan == null) return;
    final goal = double.tryParse(_goalAmountController.text) ?? 0;
    final timeline = int.tryParse(_timelineController.text) ?? 0;
    final monthly = _savingsPlan!.monthlySavingsAchieved;
    final total = monthly * timeline;

    // Try to compute simple forecast for the selected analysis window
    ForecastData? forecastData;
    try {
      final days = _analysisRange.months * 30;
      final daily = await DatabaseService.getDailySpendingData(days);
      if (daily.isNotEmpty) {
        final now = DateTime.now();
        final start = now.subtract(Duration(days: days));
        forecastData = await ApiService.getForecast(daily, startDate: start, endDate: now);
      }
    } catch (_) {}

    await ReportService.generateAndShareReport(
      title: 'FinSight Personal Finance Report',
      analysisPeriodLabel: _analysisRange.label,
      keyStats: {
        'Goal Amount': goal,
        'Timeline (months)': timeline.toDouble(),
        'Monthly Savings (plan)': monthly,
        'Total Savings (plan)': total,
      },
      forecast: forecastData,
      savingsPlan: _savingsPlan!,
    );
  }
}
