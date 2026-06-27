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

  static const companyDashboard = '/company/dashboard';
  static const companySettings = '/company/settings';
  static const companyMatches = '/company/matches';
  static const createOffer = '/company/offers/new';

  static const adminDashboard = '/admin/dashboard';
}
