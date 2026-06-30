<div align="center">
  <img src="assets/images/logo.jpeg" alt="MatchIQ Logo" width="260" />

  <h3>AI-Powered Recruitment Platform</h3>
  <p>Match candidates with companies using intelligent scoring, automated technical assessments, and real-time AI proctoring.</p>

  <p>
    <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" />
    <img src="https://img.shields.io/badge/Dart-SDK%20%5E3.5-0175C2?logo=dart&logoColor=white" />
    <img src="https://img.shields.io/badge/Architecture-Hexagonal%20%2B%20Clean-blueviolet" />
    <img src="https://img.shields.io/badge/State-BLoC%20%2F%20Cubit-orange" />
    <img src="https://img.shields.io/badge/Platform-Web%20%7C%20Android%20%7C%20iOS-green" />
  </p>
</div>

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Modules](#modules)
  - [Domain Layer](#domain-layer)
  - [Infrastructure Layer](#infrastructure-layer)
  - [Presentation Layer](#presentation-layer)
  - [State Management](#state-management)
- [Routing](#routing)
- [API Reference](#api-reference)
  - [Authentication](#authentication)
  - [Catalog](#catalog)
  - [Candidate](#candidate)
  - [Company](#company)
  - [Job Offers](#job-offers)
  - [Payments](#payments)
  - [Matching & Tests](#matching--tests)
  - [Analytics](#analytics)
  - [Admin](#admin)
- [Getting Started](#getting-started)
- [Environment Variables](#environment-variables)
- [Scripts](#scripts)
- [Design System](#design-system)

---

## Overview

**MatchIQ** is a full-featured recruitment web application built with Flutter. It connects job candidates with companies through an AI-driven matching engine that considers skills, experience, and real-time assessment results to generate compatibility scores.

The platform serves **three distinct user roles**:

| Role | Description |
|---|---|
| **Candidate** | Browses job offers, completes AI-generated technical assessments, tracks match scores |
| **Company** | Posts job offers, manages candidate pipelines, reviews AI-ranked match results |
| **Admin** | Manages users, monitors platform stats, generates reports |

---

## Features

### For Candidates
- AI compatibility score per job offer
- AI-generated technical assessments (multiple choice + coding challenges)
- Camera-based AI proctoring during test sessions
- Real-time profile strength tracking
- Test result history with per-question feedback
- **Market insights dashboard** — see which skills the market demands, identify personal gaps vs. top-demand skills, and track skill level alignment (1–5 scale) against live offer data

### For Companies
- AI-ranked candidate pipeline per offer
- Job description AI parser — auto-extracts required skills
- Stripe-powered offer activation
- Manual candidate selection / rejection with pipeline tracking
- Proctoring violation reports per candidate submission
- Analytics dashboard and downloadable reports

### For Admins
- Platform-wide KPI statistics
- User management — toggle status, delete accounts
- Exportable platform activity reports

### Platform-wide
- Role-based access control with JWT authentication
- Email verification on registration (6-digit code)
- Forgot / reset password via email link
- Change password from any profile page
- Responsive design (web-first, mobile-ready)
- PWA-compatible — installable, manifest configured

---

## Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| Framework | Flutter 3.x (Dart ^3.5) | Cross-platform UI |
| State Management | `flutter_bloc` ^8.1.6 | BLoC / Cubit pattern |
| Navigation | `go_router` ^14.3.0 | Declarative routing + deep links |
| HTTP Client | `dio` ^5.8.0 | REST API calls with interceptors |
| Dependency Injection | `get_it` ^8.0.2 | Service locator |
| Secure Storage | `flutter_secure_storage` ^9.2.2 | JWT token persistence |
| Functional Programming | `dartz` ^0.10.1 | `Either<Failure, T>` error handling |
| Typography | `google_fonts` ^6.2.1 | Inter typeface |
| Icons | `material_symbols_icons` ^4.2738.0 | Material Symbols library |
| Network Detection | `connectivity_plus` ^6.0.5 | Online / offline awareness |
| Permissions | `permission_handler` ^11.3.0 | Camera access (native platforms) |
| Window Security | `flutter_windowmanager` ^0.2.0 | Screenshot blocking (Android) |

---

## Architecture

MatchIQ follows **Hexagonal (Ports & Adapters) + Clean Architecture**. The domain has zero external dependencies — all I/O flows through typed ports that are implemented by the infrastructure layer.

```
┌──────────────────────────────────────────────────────────────────┐
│                        PRESENTATION                              │
│   Pages  ──►  BLoC / Cubit  ──►  InputPort  (interface)         │
└───────────────────────────┬──────────────────────────────────────┘
                            │
┌───────────────────────────▼──────────────────────────────────────┐
│                          DOMAIN                                  │
│   Entities · Value Objects · Services · Use Cases · Ports        │
│   (zero Flutter / zero Dio / zero Firebase dependencies)         │
└───────────────────────────┬──────────────────────────────────────┘
                            │
┌───────────────────────────▼──────────────────────────────────────┐
│                      INFRASTRUCTURE                              │
│   RemoteAuthAdapter  ──►  ApiClient (Dio)  ──►  REST API         │
│   MockAuthAdapter    ──►  Mock data (local, for dev)             │
│   FirebaseAuthAdapter ──► Firebase Auth SDK                      │
└──────────────────────────────────────────────────────────────────┘
```

### Data Flow — Login Example

```
LoginPage
  └─► AuthBloc.add(LoginRequested)
        └─► LoginUseCase.call(email, password)
              └─► AuthDomainService.login()           [InputPort]
                    └─► RemoteAuthAdapter.login()     [OutputPort impl]
                          └─► POST /api/auth/login    (Dio)
                                └─► UserModel
                                      └─► UserMapper.toEntity()
                                            └─► AuthBloc emits AuthAuthenticated(user)
                                                  └─► GoRouter redirects by role
```

### Error Handling

All repository methods return `ResultFuture<T>` — a type alias for `Future<Either<Failure, T>>`. The BLoC unwraps `Left(failure)` into `AuthFailureState` and surfaces a `SnackBar`. Uncaught exceptions never reach the UI.

```dart
typedef ResultFuture<T> = Future<Either<Failure, T>>;
typedef ResultVoid      = Future<Either<Failure, void>>;
```

---

## Project Structure

```
lib/
├── config/
│   ├── router/
│   │   ├── app_router.dart          # GoRouter config, redirect guard, 404 page
│   │   └── app_routes.dart          # All route path constants (static strings)
│   └── theme/
│       ├── app_colors.dart          # Color palette (Deep Navy, Emerald, Blue)
│       ├── app_text_styles.dart     # Inter-based type scale
│       ├── app_theme.dart           # MaterialTheme configuration
│       └── responsive.dart          # Breakpoint helpers
│
├── core/
│   ├── api/
│   │   ├── api_client.dart          # Dio client + JWT interceptor + auto-refresh
│   │   ├── api_constants.dart       # All endpoint strings + base URLs
│   │   ├── proctoring_api_client.dart # Proctoring-specific HTTP client
│   │   └── token_storage.dart       # SecureStorage read/write helpers
│   ├── errors/
│   │   ├── exeption.dart            # ServerException, CacheException, etc.
│   │   └── failures.dart            # Failure hierarchy (ServerFailure, etc.)
│   ├── ports/
│   │   └── use_case.dart            # UseCase<T, Params> base interface
│   └── utils/
│       ├── extensions/              # DateTimeExt, StringExt helpers
│       ├── web/                     # Conditional imports — web vs native
│       │   ├── camera.dart          # CameraCapture (routes to camera_web.dart on web)
│       │   ├── download_helper.dart # File download (routes to download_web.dart on web)
│       │   └── fullscreen.dart      # Fullscreen API (routes to fullscreen_web.dart on web)
│       ├── snackbar_helper.dart     # showSuccessSnackBar / showErrorSnackBar / showInfoSnackBar
│       └── typedef.dart             # ResultFuture<T>, ResultVoid
│
├── features/
│   ├── domain/                      # Pure business logic — zero external dependencies
│   │   ├── entities/                # 11 immutable business models
│   │   ├── ports/
│   │   │   ├── input/               # Interfaces the UI layer calls (AuthInputPort)
│   │   │   └── output/              # Interfaces Infrastructure implements (AuthOutputPort)
│   │   ├── services/                # AuthDomainService — orchestrates use cases
│   │   ├── usecases/                # One file per use case (LoginUseCase, etc.)
│   │   └── value_objects/           # Email — validates format in constructor
│   │
│   ├── infrastructure/              # Concrete implementations of domain ports
│   │   ├── adapters/
│   │   │   ├── remote_auth_adapter.dart   # Production: REST API via Dio
│   │   │   ├── mock_auth_adapter.dart     # Development: returns hardcoded data
│   │   │   ├── firebase_auth_adapter.dart # Alternative: Firebase Auth SDK
│   │   │   └── local_auth_adapter.dart    # Fallback: local secure storage
│   │   ├── datasources/
│   │   │   ├── app_datasource.dart        # Interface for all non-auth API calls
│   │   │   ├── remote_datasource.dart     # Production implementation
│   │   │   ├── mock_datasource.dart       # Development implementation
│   │   │   └── proctor_datasource.dart    # Proctoring API calls
│   │   ├── mappers/
│   │   │   └── user_mapper.dart           # UserModel ↔ User entity (bidirectional)
│   │   └── models/
│   │       └── user_model.dart            # UserModel — JSON-serializable DTO
│   │
│   └── presentarion/                # ⚠️ Intentional typo — do not rename (breaks imports)
│       ├── adapters/
│       │   └── auth_bloc_adapter.dart     # Bridges AuthBloc ↔ AuthInputPort
│       ├── bloc/                    # All BLoC / Cubit state management files
│       ├── pages/                   # 22 full-screen route pages
│       └── widgets/
│           └── shared/              # AppCard, AppTextField, AppSidebar, ChangePasswordCard
│
└── injection/
    ├── injection_container.dart     # GetIt setup — sl<T>() accessor
    └── modules/
        └── auth_module.dart         # Auth adapter/service registrations
```

---

## Modules

### Domain Layer

#### Entities (`lib/features/domain/entities/`)

| Entity | Key Fields |
|---|---|
| `User` | id, name, email, role (`candidate` / `company` / `admin`) |
| `CandidateProfile` | userId, bio, skills, experience, photoUrl, location |
| `CompanyProfile` | userId, name, industry, description, logoUrl, website |
| `JobOffer` | id, title, description, requiredSkills, tier, status, companyId |
| `CandidateMatch` | matchId, candidateId, offerId, score, status |
| `OfferTier` | id, name, price, maxCandidates, features |
| `TechnicalTest` | testId, offerId, questions, timeLimitMinutes |
| `TestSession` | sessionId, testId, submissionId, questions, timeLimitMinutes |
| `TestQuestion` | id, type (mc / code), text, options, language, functionSignature |
| `TestResult` | score, feedback, answers, proctoring summary |
| `ProctoringReport` | sessionId, distractionCount, intruderCount, deviceCount, incidents |
| `CompanyDashboardStats` | totalOffers, activeOffers, totalMatches, avgMatchScore, conversionRate |
| `AdminStats` | totalUsers, totalCandidates, totalCompanies, totalOffers, revenue |
| `Payment` | id, offerId, status, amount, stripeSessionId |

#### Value Objects

- **`Email`** — Validates format on construction. Throws `ValueFailure` on invalid input. Ensures malformed emails never reach the domain service.

#### Auth Ports

```dart
// What the UI calls
abstract class AuthInputPort {
  ResultFuture<User>  login(String email, String password);
  ResultVoid          registerCandidate(String name, String email, String password);
  ResultVoid          registerCompany(String name, String email, String password);
  ResultVoid          verifyEmail(String email, String code);
  ResultVoid          forgotPassword(String email);
  ResultVoid          resetPassword(String token, String newPassword, String confirmPassword);
  ResultVoid          changePassword(String current, String newPassword, String confirm);
  ResultVoid          logout();
  ResultFuture<User?> checkSession();
}
```

---

### Infrastructure Layer

#### Adapters

| Adapter | When Used | Description |
|---|---|---|
| `RemoteAuthAdapter` | Production | Calls REST API via `ApiClient` (Dio) |
| `MockAuthAdapter` | Development | Returns `Right(...)` after simulated delay — no backend needed |
| `FirebaseAuthAdapter` | Optional | Uses Firebase Auth SDK |
| `LocalAuthAdapter` | Fallback | Reads from secure local storage |

Swapping adapters only requires changing one binding in `injection/modules/auth_module.dart`. The rest of the app is completely unaffected.

#### API Client (`core/api/api_client.dart`)

- Built on **Dio** with a custom `InterceptorsWrapper`
- Attaches `Authorization: Bearer <token>` to every request automatically
- On `401 Unauthorized`: silently refreshes the token via `POST /api/auth/refresh` and retries the original request once
- On repeated `401` (refresh also expired): calls `logout()` and redirects to `/login`

#### Proctoring API Client

Separate Dio instance pointing to the proctoring microservice. Handles frame uploads and session lifecycle independently, so proctoring failures never affect the main test submission flow.

---

### Presentation Layer

#### Pages (22 total)

| Page | Route | Role | Description |
|---|---|---|---|
| `LandingPage` | `/` | Public | Marketing page: hero, stats, features, how-it-works, roles CTA |
| `LoginPage` | `/login` | Public | Email + password login with remember-me and forgot-password link |
| `ForgotPasswordPage` | `/forgot-password` | Public | Sends reset link to user's email |
| `ResetPasswordPage` | `/auth/reset-password?token=` | Public | New password form; validates token from email link |
| `AuthUtilityPage` | `/auth/verify` | Public | Email verification (6-digit code) + post-reset confirmation screen |
| `CandidateRegistrationPage` | `/register/candidate` | Public | Candidate signup: account info + skills & bio |
| `CompanyRegistrationPage` | `/register/company` | Public | Company signup: name, industry, description |
| `CandidateDashboardPage` | `/candidate/dashboard` | Candidate | Overview stats, recent activity, quick actions |
| `CandidateProfilePage` | `/candidate/profile` | Candidate | Edit bio / skills / photo URL; change password inline |
| `JobOffersListPage` | `/candidate/assessments` | Candidate | Browse open offers with AI match scores; category filter |
| `ActiveTechnicalTestPage` | `/candidate/test/:id` | Candidate | Live test: timer, question navigation, AI proctoring active |
| `CandidateTestResultPage` | `/candidate/test/:id/result` | Candidate | Score, AI feedback, per-question breakdown |
| `CompanyDashboardPage` | `/company/dashboard` | Company | Revenue, active offers, match KPIs, activity feed |
| `CompanyProfileSettingsPage` | `/company/settings` | Company | Edit company profile; change password inline |
| `CompanyMatchesRankingPage` | `/company/matches` | Company | AI-ranked candidate list across all offers |
| `CreateNewOfferPage` | `/company/offers/new` | Company | Create offer: AI description parser, tier selection, validation |
| `OfferPendingPage` | `/company/offers/:id/pending` | Company | Activate offer via Stripe payment |
| `OfferMatchesPage` | `/company/offers/:id/matches` | Company | Candidate pipeline for one offer — select / reject / send test |
| `MatchTestResultsPage` | `/company/matches/:matchId/results` | Company | Full test submission + proctoring report per candidate |
| `PaymentResultPage` | `/payment-result` | Company | Stripe redirect handler (success / cancel) |
| `AdminDashboardPage` | `/admin/dashboard` | Admin | Platform KPIs, user growth, revenue; change password inline |
| `AdminUsersPage` | `/admin/users` | Admin | User table: role/status filters, toggle active, delete |

#### Shared Widgets

| Widget | Description |
|---|---|
| `AppTextField` | Unified text input — label, prefix icon, password toggle, inline validator |
| `AppButton` | Primary action button with built-in loading spinner |
| `AppCard` | Elevated white container with standard border-radius and shadow |
| `AppSidebar` | Role-aware navigation sidebar (different links per role) |
| `ChangePasswordCard` | Self-contained change-password form; calls `AuthInputPort` directly (bypasses `AuthBloc`) to avoid triggering the router's auth redirect guard |

---

### State Management

One **`AuthBloc`** (event-driven) handles the authentication lifecycle. Every other feature uses a **Cubit** to keep concerns separated and avoid polluting global auth state.

#### AuthBloc

```
Event                        →  State
───────────────────────────────────────────────────────
LoginRequested               →  AuthLoading → AuthAuthenticated(User)
RegisterCandidateRequested   →  AuthLoading → AuthPendingVerification
RegisterCompanyRequested     →  AuthLoading → AuthPendingVerification
VerifyEmailRequested         →  AuthLoading → AuthEmailVerified
ForgotPasswordRequested      →  AuthLoading → AuthPasswordResetSent
ResetPasswordRequested       →  AuthLoading → AuthPasswordResetSuccess
LogoutRequested              →  AuthUnauthenticated
CheckSessionRequested        →  AuthAuthenticated(User) | AuthUnauthenticated
(any on error)               →  AuthFailureState(message)
```

> **Note:** Actions performed by an already-authenticated user (change password, update profile) must not emit non-`AuthAuthenticated` states — the GoRouter redirect guard would kick them to `/login`. For those cases, widgets call `sl<AuthInputPort>()` directly, bypassing `AuthBloc` entirely.

#### CandidateCubit

Manages the full candidate post-login experience:

```
loadDashboard()       → profile + activity + match stats
loadOffers()          → available offers with per-offer AI match score
loadAssessments()     → pending and completed assessments
loadProfile()         → full candidate profile
updateProfile()       → save bio, skills, photo URL
loadCategories()      → skill catalog categories
loadCatalogSkills()   → skills within a selected category
```

#### CompanyCubit

Manages the company workflow end-to-end:

```
loadDashboard()          → KPIs + recent activity
loadProfile()            → company profile
loadOffers()             → all company offers + status
loadMatches()            → ranked candidates across all offers
createOffer()            → POST new job offer
parseOfferDescription()  → AI-parse text → auto-fill required skills
loadTiers()              → available pricing tiers
createCheckout()         → Stripe checkout session URL
verifyPayment()          → confirm Stripe payment, activate offer
selectCandidate()        → advance match to "selected"
rejectCandidate()        → mark match as "rejected"
sendTest()               → dispatch test to a specific candidate
loadProctoringReport()   → AI proctoring report for a submission
downloadReport()         → export company report (CSV/PDF)
```

#### TestCubit

Controls the end-to-end test experience for candidates:

```
previewTest(offerId)                     → TestPreview (title, question count, time limit)
startTest(offerId)                       → TestSession (questions, submissionId, timer)
submitTest(testId, mcAnswers, codeAns)   → TestResult (score, feedback)
fetchResult(testId)                      → TestResult (for history / result page)
sendChatMessage(questionId, message)     → AI hint response for a specific question
```

#### AdminCubit

```
loadStats()                  → AdminStats (platform-wide KPIs)
loadUsers(role?, isActive?)  → filtered and paginated user list
toggleUserStatus(userId)     → activate / deactivate user account
deleteUser(userId)           → permanent account deletion
downloadReport()             → platform-wide exportable report
```

#### ProctorCubit

Manages real-time AI monitoring during a live test session:

```
startSession(userId, submissionId)   → registers session with proctoring service
processFrame(imageBytes)             → sends camera frame for AI analysis
endSession()                         → finalises session, retrieves report
```

**Status lifecycle:** `idle → starting → monitoring → ended | error`

**Detection categories:**

| Category | Trigger |
|---|---|
| Distraction | Candidate looks away from screen for too long |
| Intruder | Another person appears in the camera frame |
| Device | Phone or other electronic device detected in frame |

---

## Routing

GoRouter is configured in `lib/config/router/app_router.dart` with a **global redirect guard** that runs before every navigation:

```
Incoming route
      │
      ▼
  AuthInitial / AuthLoading?      → return null (wait for session check)
      │
      ▼
  path is /auth/reset-password
  or /reset-password?             → return null (always allow — user may be
      │                             logged in on another tab when clicking
      ▼                             the email reset link)
  isAuthenticated + publicRoute?  → redirect to role dashboard
      │
      ▼
  !isAuthenticated + privateRoute? → redirect to /login
      │
      ▼
  Allow navigation
```

**Public routes** (no auth required):
`/` · `/login` · `/forgot-password` · `/auth/verify` · `/register/candidate` · `/register/company`

**Route alias:**
`/reset-password?token=X` → redirects internally to `/auth/reset-password?token=X`
(The backend generates short-form links; Flutter handles the alias transparently.)

---

## API Reference

**Main API:** `https://bank-n8n.coderhivex.com`  
**Proctoring API:** `https://bank-user.coderhivex.com`  
**Auth scheme:** `Authorization: Bearer <accessToken>` (auto-attached by `ApiClient`)

### Authentication

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `POST` | `/api/auth/register` | — | Register new user |
| `POST` | `/api/auth/login` | — | Login; returns `accessToken` + `refreshToken` |
| `POST` | `/api/auth/refresh` | — | Refresh access token silently |
| `POST` | `/api/auth/verify-email` | — | Verify email with 6-digit code |
| `POST` | `/api/auth/resend-verification` | — | Resend verification code |
| `POST` | `/api/auth/forgot-password` | — | Send password reset email |
| `POST` | `/api/auth/reset-password` | — | Reset password using email token |
| `POST` | `/api/auth/change-password` | ✓ | Change password (authenticated) |
| `POST` | `/api/auth/logout` | ✓ | Invalidate refresh token |

### Catalog

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/catalog/categories` | All skill categories |
| `GET` | `/api/catalog/categories/:categoryId/skills` | Skills within a category |

### Candidate

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/candidate/profile` | Get authenticated candidate profile |
| `PATCH` | `/api/candidate/profile` | Update profile fields |

### Company

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/company/profile` | Get authenticated company profile |
| `GET` | `/api/company/dashboard` | Dashboard KPIs |
| `GET` | `/api/company/report` | Downloadable company report |

### Job Offers

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/offers` | List offers (filtered by role automatically) |
| `POST` | `/api/offers` | Create new job offer |
| `GET` | `/api/offers/:id` | Get offer detail |
| `GET` | `/api/offers/tiers` | Available pricing tiers |
| `POST` | `/api/offers/parse-description` | AI-parse a description into required skills |
| `POST` | `/api/offers/:id/cancel` | Cancel an offer |
| `POST` | `/api/offers/:id/force-cancel` | Force-cancel regardless of state |

### Payments

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/payments/create-checkout` | Create Stripe checkout session |
| `POST` | `/api/payments/verify-session` | Confirm payment and activate offer |

### Matching & Tests

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/matching/:offerId` | AI-ranked candidates for an offer |
| `POST` | `/api/matching/:offerId/run` | Trigger AI matching algorithm |
| `POST` | `/api/matching/:offerId/reevaluate` | Re-run matching scores |
| `POST` | `/api/matching/send-test` | Dispatch test to a candidate |
| `POST` | `/api/matching/:matchId/select` | Mark candidate as selected |
| `POST` | `/api/matching/:matchId/reject` | Mark candidate as rejected |
| `GET` | `/api/tests/candidate` | All tests for the logged-in candidate |
| `GET` | `/api/tests/:offerId` | Get test associated with an offer |
| `POST` | `/api/tests/:offerId/generate` | Generate test via AI |
| `POST` | `/api/tests/:offerId/regenerate` | Regenerate existing test |
| `GET` | `/api/tests/:offerId/candidate` | Candidate-facing test view |
| `POST` | `/api/tests/:testId/submit` | Submit test answers |
| `GET` | `/api/tests/:testId/result` | Get scored result with feedback |
| `POST` | `/api/tests/questions/:id/chat` | Request AI hint for a question |
| `GET` | `/api/tests/submissions/:matchId` | All submissions for a match |
| `GET` | `/api/tests/submissions/:matchId/proctoring` | Proctoring report for a submission |

### Analytics

Two endpoints that expose demand/supply intelligence derived from real platform data.

#### Market Overview (public)

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `GET` | `/api/analytics/market` | — | Top skills in demand, top candidate skills, top skill pairs |

**Response shape:**

| Field | Type | Description |
|---|---|---|
| `topDemand[]` | array | Top skills required by offers: `skillName`, `categoryName`, `offerCount` |
| `topSupply[]` | array | Top skills declared by candidates: `skillName`, `categoryName`, `candidateCount` |
| `topCombinations[]` | array | Most-requested skill pairs: `skillA`, `skillB`, `offerCount` |

No token required. Safe to call on mount from any public or pre-login screen (landing, onboarding, admin dashboard).

#### Candidate Insights (authenticated)

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `GET` | `/api/analytics/market/my-insights` | ✓ Candidate | Same market data, cross-referenced against the candidate's own profile |

**Additional fields returned:**

`topDemand` items gain:

| Field | Type | Description |
|---|---|---|
| `candidateHasSkill` | `bool` | Candidate has this skill in their profile |
| `candidateLevel` | `int?` | Proficiency level 1–5 (`null` if skill absent) |

`topCombinations` items gain:

| Field | Type | Description |
|---|---|---|
| `candidateHasA` | `bool` | Candidate has `skillA` |
| `candidateHasB` | `bool` | Candidate has `skillB` |
| `candidateHasBoth` | `bool` | Candidate satisfies the full pair |

Two summary arrays:

| Field | Type | Description |
|---|---|---|
| `skillsInDemand` | `string[]` | Skills the candidate **has** that appear in `topDemand` — their strengths |
| `skillGaps` | `string[]` | `topDemand` skills the candidate **lacks** — ordered most-urgent first |

**Proficiency scale:**

| Value | Meaning |
|---|---|
| 1 | Básico / learning |
| 2 | Limited practice |
| 3 | Works independently |
| 4 | Solid, real projects |
| 5 | Expert / reference |

**Errors:**

| HTTP | Cause |
|---|---|
| `401` | Missing / expired token, or not a Candidate role |
| `404` `"Perfil de candidato no encontrado."` | Candidate has never set up any profile data |

**UI pattern for `topCombinations`:**
- `candidateHasBoth: true` → ✅ "You have this full combination"
- Only one of the two → ⚠️ "You have X, still need Y"
- Neither → ❌

---

### Admin

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/admin/users` | All users — filterable by role and status |
| `GET` | `/api/admin/users/:userId` | Single user detail |
| `POST` | `/api/admin/users/:userId/toggle-status` | Activate or deactivate account |
| `DELETE` | `/api/admin/users/:userId` | Permanently delete user |
| `GET` | `/api/admin/stats` | Platform-wide statistics |
| `GET` | `/api/admin/report` | Full admin report export |

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.5.0
- Dart SDK ≥ 3.5.0 (included with Flutter)
- Google Chrome (for web development)
- A running instance of the MatchIQ backend

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/your-org/match-IQ-front.git
cd match-IQ-front

# 2. Install dependencies
flutter pub get

# 3. Start the development server
flutter run -d web-server --web-port 3000
```

Open `http://localhost:3000` in your browser.

### Production Build

```bash
flutter build web --release
```

Output lands in `build/web/`. Deploy that folder to any static host — Vercel, Firebase Hosting, Nginx, Cloudflare Pages, etc.

---

## Environment Variables

API base URLs live in `lib/core/api/api_constants.dart`:

```dart
static const baseUrl           = 'https://bank-n8n.coderhivex.com';
static const proctoringBaseUrl = 'https://bank-user.coderhivex.com';
```

For local development, change `baseUrl` to your local backend address (e.g. `http://localhost:8080`).

> **Backend requirement:** The backend must set `FRONTEND_URL=http://localhost:3000` (or your deployed domain) so that password-reset email links point back to the Flutter SPA instead of the backend's own domain.

---

## Scripts

| Command | Description |
|---|---|
| `flutter pub get` | Install all dependencies |
| `flutter run -d web-server --web-port 3000` | Dev server on port 3000 |
| `flutter run -d chrome` | Open directly in Chrome |
| `flutter build web --release` | Production web build |
| `flutter analyze` | Static analysis (lint + type check) |
| `flutter test` | Run unit and widget tests |

---

## Design System

MatchIQ uses a **two-zone color palette** — dark navy for immersive sections (hero, navbar, stats, roles, footer) and a soft blue-grey for content sections (features, how it works).

| Token | Hex | Usage |
|---|---|---|
| Dark Background | `#000F1D` | Navbar, hero top, footer |
| Dark Mid | `#0D1F35` | Stats bar, roles section, CTA card background |
| Light Background | `#F4F7FA` | Features section, body background |
| White Surface | `#FFFFFF` | Card surfaces, how-it-works section |
| Emerald Accent | `#34D399` | AI match scores, CTAs, success states — never decorative |
| Secondary Blue | `#3B618A` | Links, secondary actions, info states |
| Error | `#BA1A1A` | Validation errors, violation alerts |

**Typography:** Inter (via Google Fonts)

| Scale | Size | Weight |
|---|---|---|
| Display | 48px | 800 |
| Headline LG | 32px | 700 |
| Headline MD | 24px | 600 |
| Body LG | 18px | 400 |
| Body MD | 16px | 400 |
| Label Bold | 14px | 600 |
| Label SM | 12px | 500 |

**Border radius:** Buttons / inputs `8–10px` · Cards `18–20px` · Badges `999px` (pill)

**Shadows:**
- Cards: `0px 6px 20px rgba(15, 37, 55, 0.06)`
- Modals: `0px 12px 32px rgba(15, 37, 55, 0.12)`

---

<div align="center">
  <sub>Built with Flutter · Powered by AI · MatchIQ 2025</sub>
</div>
