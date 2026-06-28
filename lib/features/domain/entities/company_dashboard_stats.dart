import 'package:equatable/equatable.dart';

class CompanyDashboardOffers extends Equatable {
  const CompanyDashboardOffers({
    required this.total,
    required this.open,
    required this.testSent,
    required this.completed,
    required this.cancelled,
    required this.expired,
    required this.pendingPayment,
  });

  final int total;
  final int open;
  final int testSent;
  final int completed;
  final int cancelled;
  final int expired;
  final int pendingPayment;

  @override
  List<Object?> get props =>
      [total, open, testSent, completed, cancelled, expired, pendingPayment];
}

class CompanyDashboardMatches extends Equatable {
  const CompanyDashboardMatches({
    required this.total,
    required this.testSent,
    required this.testCompleted,
    required this.selected,
    required this.rejected,
    required this.selectionRate,
  });

  final int total;
  final int testSent;
  final int testCompleted;
  final int selected;
  final int rejected;
  final double selectionRate;

  @override
  List<Object?> get props =>
      [total, testSent, testCompleted, selected, rejected, selectionRate];
}

class CompanyDashboardTests extends Equatable {
  const CompanyDashboardTests({
    required this.sent,
    required this.completed,
    required this.evaluated,
    required this.expired,
    required this.completionRate,
    this.averageScore,
  });

  final int sent;
  final int completed;
  final int evaluated;
  final int expired;
  final double completionRate;
  final double? averageScore;

  @override
  List<Object?> get props =>
      [sent, completed, evaluated, expired, completionRate, averageScore];
}

class CompanyDashboardStats extends Equatable {
  const CompanyDashboardStats({
    required this.offers,
    required this.matches,
    required this.tests,
  });

  final CompanyDashboardOffers offers;
  final CompanyDashboardMatches matches;
  final CompanyDashboardTests tests;

  @override
  List<Object?> get props => [offers, matches, tests];
}
