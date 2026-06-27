class AdminStats {
  const AdminStats({
    required this.totalCandidates,
    required this.totalCompanies,
    required this.totalOffers,
    required this.totalMatches,
    required this.activeTests,
    required this.pendingSubmissions,
    required this.usersLast30Days,
    required this.offersLast30Days,
  });
  final int totalCandidates;
  final int totalCompanies;
  final int totalOffers;
  final int totalMatches;
  final int activeTests;
  final int pendingSubmissions;
  final int usersLast30Days;
  final int offersLast30Days;
}
