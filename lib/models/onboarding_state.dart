import 'package:flutter/material.dart';

/// OnyxFi — Onboarding State Model (ChangeNotifier)
///
/// Holds the user's financial profile collected during the
/// onboarding flow (goals, income, expenses).
/// Exposed as a Provider so GenUI widgets can persist user choices.

enum FinancialGoal { home, car, retirement, education, travel, emergency }

class OnboardingStateNotifier extends ChangeNotifier {
  List<String> _selectedGoalIds = [];
  double? _monthlySalary;
  double? _monthlyExpenses;
  double? _currentSavings;
  int _currentStep = 0;

  // ── Getters ───────────────────────────────────────────
  List<String> get selectedGoalIds => _selectedGoalIds;
  double? get monthlySalary => _monthlySalary;
  double? get monthlyExpenses => _monthlyExpenses;
  double? get currentSavings => _currentSavings;
  int get currentStep => _currentStep;

  /// Whether the onboarding is complete with minimum required data.
  bool get isComplete =>
      _selectedGoalIds.isNotEmpty &&
      _monthlySalary != null &&
      _monthlyExpenses != null;

  /// Net monthly savings potential.
  double get monthlySavingsPotential =>
      (_monthlySalary ?? 0) - (_monthlyExpenses ?? 0);

  // ── Setters ───────────────────────────────────────────

  void setGoals(List<String> goalIds) {
    _selectedGoalIds = goalIds;
    notifyListeners();
    debugPrint('[OnboardingState] Goals set: $goalIds');
  }

  void setMonthlySalary(double salary) {
    _monthlySalary = salary;
    notifyListeners();
    debugPrint('[OnboardingState] Salary set: $salary');
  }

  void setMonthlyExpenses(double expenses) {
    _monthlyExpenses = expenses;
    notifyListeners();
    debugPrint('[OnboardingState] Expenses set: $expenses');
  }

  void setCurrentSavings(double savings) {
    _currentSavings = savings;
    notifyListeners();
    debugPrint('[OnboardingState] Savings set: $savings');
  }

  void advanceStep() {
    _currentStep++;
    notifyListeners();
  }

  void reset() {
    _selectedGoalIds = [];
    _monthlySalary = null;
    _monthlyExpenses = null;
    _currentSavings = null;
    _currentStep = 0;
    notifyListeners();
  }
}
