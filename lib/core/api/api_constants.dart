abstract class ApiConstants {
  static const baseUrl = 'https://matchiq-service.coderhivex.com';

  // Auth
  static const register = '/api/auth/register';
  static const login = '/api/auth/login';
  static const googleLogin = '/api/auth/google';
  static const verifyEmail = '/api/auth/verify-email';
  static const resendVerification = '/api/auth/resend-verification';
  static const refresh = '/api/auth/refresh';
  static const forgotPassword = '/api/auth/forgot-password';
  static const resetPassword = '/api/auth/reset-password';
  static const changePassword = '/api/auth/change-password';

  static const logout = '/api/auth/logout';

  // Catalog
  static const categories = '/api/catalog/categories';
  static String skillsByCategory(int categoryId) =>
      '/api/catalog/categories/$categoryId/skills';

  // Candidate
  static const candidateProfile = '/api/candidate/profile';

  // Company
  static const companyProfile = '/api/company/profile';
  static const companyDashboard = '/api/company/dashboard';
  static const companyReport = '/api/company/report';

  // Offers
  static const offerTiers = '/api/offers/tiers';
  static const parseDescription = '/api/offers/parse-description';
  static const offers = '/api/offers';
  static String offerById(int id) => '/api/offers/$id';
  static String cancelOffer(int id) => '/api/offers/$id/cancel';
  static String forceCancelOffer(int id) => '/api/offers/$id/force-cancel';

  // Payments
  static const createCheckout = '/api/payments/create-checkout';
  static const verifySession = '/api/payments/verify-session';

  // Matching
  static String matchingByOffer(int offerId) => '/api/matching/$offerId';
  static String runMatching(int offerId) => '/api/matching/$offerId/run';
  static String reevaluateMatching(int offerId) =>
      '/api/matching/$offerId/reevaluate';
  static const sendTest = '/api/matching/send-test';
  static String selectCandidate(int matchId) => '/api/matching/$matchId/select';
  static String rejectCandidate(int matchId) => '/api/matching/$matchId/reject';

  // Tests
  static const candidateTests = '/api/tests/candidate';
  static String generateTest(int offerId) => '/api/tests/$offerId/generate';
  static String regenerateTest(int offerId) =>
      '/api/tests/$offerId/regenerate';
  static String testByOffer(int offerId) => '/api/tests/$offerId';
  static String testForCandidate(int offerId) =>
      '/api/tests/$offerId/candidate';
  static String submitTest(int testId) => '/api/tests/$testId/submit';
  static String testResult(int testId) => '/api/tests/$testId/result';
  static String questionChat(int questionId) =>
      '/api/tests/questions/$questionId/chat';
  static String testSubmissionsByMatch(int matchId) =>
      '/api/tests/submissions/$matchId';
  static String proctoringReportByMatch(int matchId) =>
      '/api/tests/submissions/$matchId/proctoring';

  // Analytics
  static const analyticsMarket = '/api/analytics/market';
  static const analyticsMyInsights = '/api/analytics/market/my-insights';

  // Admin
  static const adminUsers = '/api/admin/users';
  static String adminUserById(int userId) => '/api/admin/users/$userId';
  static String toggleUserStatus(int userId) =>
      '/api/admin/users/$userId/toggle-status';
  static String deleteUser(int userId) => '/api/admin/users/$userId';
  static const adminStats = '/api/admin/stats';
  static const adminReport = '/api/admin/report';
}

abstract class GoogleAuthConstants {
  // Must match the "Google:ClientId" configured on the backend, since it
  // validates the ID token's `aud` claim against this exact value.
  static const clientId =
      '94963457392-rnnlop0pj63cf0330mgbit5lnuo2f5pa.apps.googleusercontent.com';
}
