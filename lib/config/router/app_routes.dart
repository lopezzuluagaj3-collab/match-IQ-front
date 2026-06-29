abstract class AppRoutes {
  static const landing = '/';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const authUtility = '/auth/verify';
  static const registerCandidate = '/register/candidate';
  static const registerCompany = '/register/company';

  static const candidateDashboard = '/candidate/dashboard';
  static const candidateProfile = '/candidate/profile';
  static const candidateAssessments = '/candidate/assessments';
  static const technicalTest = '/candidate/test/:id';
  static const candidateTestResult = '/candidate/test/:id/result';
  static String candidateTestResultPath(int testId) => '/candidate/test/$testId/result';

  static const companyDashboard = '/company/dashboard';
  static const companySettings = '/company/settings';
  static const companyMatches = '/company/matches';
  static const createOffer = '/company/offers/new';
  static const offerPending = '/company/offers/:id/pending';
  static String offerPendingPath(int id) => '/company/offers/$id/pending';

  static const offerMatches = '/company/offers/:id/matches';
  static String offerMatchesPath(int id) => '/company/offers/$id/matches';

  static const matchTestResults = '/company/matches/:matchId/results';
  static String matchTestResultsPath(int matchId) =>
      '/company/matches/$matchId/results';

  static const adminDashboard = '/admin/dashboard';
  static const adminUsers = '/admin/users';

  static const paymentResult = '/payment-result';
}
