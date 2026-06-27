abstract class ApiConstants {
  static const baseUrl = 'http://localhost:5000';

  // Auth
  static const register = '/api/auth/register';
  static const login = '/api/auth/login';
  static const verifyEmail = '/api/auth/verify-email';
  static const resendVerification = '/api/auth/resend-verification';
  static const refresh = '/api/auth/refresh';
  static const forgotPassword = '/api/auth/forgot-password';
  static const resetPassword = '/api/auth/reset-password';
  static const logout = '/api/auth/logout';

  // Catalog
  static const categories = '/api/catalog/categories';
  static String skillsByCategory(int categoryId) =>
      '/api/catalog/categories/$categoryId/skills';

  // Candidate
  static const candidateProfile = '/api/candidate/profile';

  // Company
  static const companyProfile = '/api/company/profile';

  // Offers
  static const offerTiers = '/api/offers/tiers';
  static const parseDescription = '/api/offers/parse-description';
  static const offers = '/api/offers';
  static String offerById(int id) => '/api/offers/$id';
  static String cancelOffer(int id) => '/api/offers/$id/cancel';
  static String forceCancelOffer(int id) => '/api/offers/$id/force-cancel';

  // Payments
  static const createCheckout = '/api/payments/create-checkout';

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

  // Admin
  static const adminUsers = '/api/admin/users';
  static String adminUserById(int userId) => '/api/admin/users/$userId';
  static String toggleUserStatus(int userId) =>
      '/api/admin/users/$userId/toggle-status';
  static String deleteUser(int userId) => '/api/admin/users/$userId';
  static const adminStats = '/api/admin/stats';
}
