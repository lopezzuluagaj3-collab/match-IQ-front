class AdminStats {
  const AdminStats({
    // usuarios
    required this.totalCandidates,
    required this.totalCompanies,
    required this.usersRegisteredLast30Days,
    // ofertas
    required this.totalOffers,
    required this.offersCreatedLast30Days,
    required this.offersActive,
    required this.offersCompleted,
    required this.offersCancelled,
    required this.offersExpired,
    required this.offersPendingPayment,
    this.offersByStatus = const {},
    // matching
    required this.totalMatches,
    required this.matchesSelected,
    required this.matchesRejected,
    required this.matchesTestSent,
    required this.matchesTestCompleted,
    // tests
    required this.activeTests,
    required this.pendingSubmissions,
    required this.submissionsEvaluated,
    required this.submissionsExpired,
    required this.averageTestScore,
    // ingresos
    required this.totalRevenueCop,
    required this.paymentsCompleted,
    required this.paymentsPending,
    // tasas
    required this.testCompletionRate,
    required this.selectionRate,
  });

  // Usuarios
  final int totalCandidates;
  final int totalCompanies;
  final int usersRegisteredLast30Days;

  // Ofertas
  final int totalOffers;
  final int offersCreatedLast30Days;
  final int offersActive;
  final int offersCompleted;
  final int offersCancelled;
  final int offersExpired;
  final int offersPendingPayment;
  final Map<String, int> offersByStatus;

  // Matching
  final int totalMatches;
  final int matchesSelected;
  final int matchesRejected;
  final int matchesTestSent;
  final int matchesTestCompleted;

  // Tests
  final int activeTests;
  final int pendingSubmissions;
  final int submissionsEvaluated;
  final int submissionsExpired;
  final double averageTestScore;

  // Ingresos
  final double totalRevenueCop;
  final int paymentsCompleted;
  final int paymentsPending;

  // Tasas
  final double testCompletionRate;
  final double selectionRate;
}
