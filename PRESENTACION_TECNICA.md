# MatchIQ — Presentación Técnica
### Plataforma de Reclutamiento con Inteligencia Artificial
#### Frontend Flutter · Arquitectura Hexagonal · BLoC

---

## 1. ¿Qué es MatchIQ?

MatchIQ es una plataforma web de reclutamiento potenciada por IA que conecta empresas con candidatos técnicos a través de un proceso automatizado de:

1. **Publicación de oferta** por la empresa
2. **Matching algorítmico** candidato ↔ oferta (motor IA en backend)
3. **Prueba técnica** generada por IA y entregada al candidato seleccionado
4. **Proctoring en tiempo real** durante el examen (visión por computadora)
5. **Evaluación automática** y ranking final para la empresa

**Roles de usuario:** Candidato · Empresa · Admin

---

## 2. Stack Tecnológico

| Capa | Tecnología |
|---|---|
| Framework UI | Flutter (web) |
| Gestión de estado | `flutter_bloc` — BLoC + Cubit |
| Routing | `go_router` v14 |
| HTTP client | `dio` v5 |
| Inyección de dependencias | `get_it` |
| Manejo de errores | `dartz` (Either) |
| Tokens seguros | `flutter_secure_storage` |
| Tipografía | `google_fonts` |
| Iconos | `material_symbols_icons` |
| Conectividad | `connectivity_plus` |

**Backend principal:** `https://matchiq-service.coderhivex.com` (.NET)  
**Backend IA / Proctoring:** `https://bank-user.coderhivex.com` (Python)

---

## 3. Arquitectura Hexagonal (Ports & Adapters)

La aplicación implementa **Arquitectura Hexagonal** — el dominio es el núcleo y todo lo externo (HTTP, storage, Firebase) se conecta a través de puertos e implementaciones intercambiables.

```
┌─────────────────────────────────────────────────────┐
│                  PRESENTACIÓN                        │
│   Pages ─── Widgets ─── BLoC / Cubit               │
│                     │                               │
│              AuthBlocAdapter                         │
└─────────────────────┬───────────────────────────────┘
                       │ AuthInputPort (interfaz)
┌─────────────────────▼───────────────────────────────┐
│                    DOMINIO                           │
│   AuthDomainService (lógica pura)                   │
│   Entities: User, JobOffer, TechnicalTest…          │
│   Value Objects: Email                              │
│   UseCase: LoginUseCase                             │
│                     │                               │
│              AuthOutputPort (interfaz)               │
└─────────────────────┬───────────────────────────────┘
                       │ implementación concreta
┌─────────────────────▼───────────────────────────────┐
│                INFRAESTRUCTURA                       │
│   RemoteAuthAdapter ─── ApiClient (Dio)             │
│   RemoteDatasource  ─── TokenStorage                │
│   ProctoringDatasource ─ ProctoringApiClient        │
│   (también existen: MockAuthAdapter, LocalAdapter)  │
└─────────────────────────────────────────────────────┘
```

**Ventaja clave:** el dominio no sabe nada de HTTP ni Flutter — solo trabaja con puertos abstractos.

---

## 4. Estructura de Carpetas

```
lib/
├── config/
│   ├── router/          # GoRouter + rutas tipadas (AppRoutes)
│   └── theme/           # Colores, tipografía, tema Material, responsivo
│
├── core/
│   ├── api/             # ApiClient (Dio + JWT), TokenStorage, constantes
│   ├── errors/          # Failures (ServerFailure, etc.) + Exceptions
│   ├── network/         # NetworkInfo (conectividad)
│   ├── ports/           # UseCase base genérico
│   └── utils/           # Typedefs (Either), extensiones, snackbar helper
│                        # + utilidades web: cámara, fullscreen, descargas
│
├── features/
│   ├── domain/
│   │   ├── entities/    # User, JobOffer, TechnicalTest, Candidate, Company…
│   │   ├── ports/
│   │   │   ├── input/   # AuthInputPort (casos de uso expuestos)
│   │   │   └── output/  # AuthOutputPort (contrato hacia infraestructura)
│   │   ├── services/    # AuthDomainService (orquestación de lógica)
│   │   ├── usecases/    # LoginUseCase
│   │   └── value_objects/ # Email (validación tipada)
│   │
│   ├── infrastructure/
│   │   ├── adapters/    # RemoteAuthAdapter, MockAuthAdapter, LocalAuthAdapter
│   │   ├── datasources/ # AppDatasource (interfaz), RemoteDatasource, ProctorDatasource
│   │   ├── mappers/     # UserMapper (Model → Entity)
│   │   └── models/      # UserModel (JSON ↔ Dart)
│   │
│   └── presentarion/
│       ├── adapters/    # AuthBlocAdapter (bridge Bloc ↔ Domain)
│       ├── bloc/        # AuthBloc + Events/States, 6 Cubits
│       ├── pages/       # 20+ páginas por rol
│       └── widgets/     # Componentes compartidos (AppCard, AppSidebar…)
│
└── injection/
    ├── injection_container.dart   # Wiring de todas las dependencias (GetIt)
    └── modules/auth_module.dart
```

---

## 5. Módulo de Autenticación (AuthBloc)

El único módulo que usa **BLoC completo** (eventos explícitos) porque el ciclo de vida auth es complejo.

### Estados
```
AuthInitial → AuthLoading → AuthAuthenticated (user)
                          → AuthUnauthenticated
                          → AuthPendingVerification (email)
                          → AuthFailureState (message)
                          → AuthPasswordResetSent
                          → AuthPasswordResetSuccess
                          → AuthEmailVerified
```

### Eventos
```
CheckSessionRequested    ← al arrancar la app
LoginRequested           ← formulario de login
RegisterCandidateRequested / RegisterCompanyRequested
ForgotPasswordRequested
ResetPasswordRequested   ← llega vía link en el email (token en URL)
VerifyEmailRequested     ← código OTP
ResendVerificationRequested
LogoutRequested
```

### Flujo de registro + verificación
```
Register → AuthPendingVerification
         → VerifyEmail (OTP)
         → auto-login con credenciales guardadas en memoria
         → AuthAuthenticated
```

### Ports (Hexagonal)
- `AuthInputPort` — interfaz que consume el BLoC (solo llama métodos del dominio)
- `AuthOutputPort` — interfaz que implementa `RemoteAuthAdapter` (HTTP real)
- `AuthDomainService` implementa `AuthInputPort` y delega a `AuthOutputPort`

---

## 6. Módulos de Negocio — Cubits

Cada dominio funcional tiene su **Cubit** (más simple que BLoC, sin eventos explícitos):

| Cubit | Responsabilidad principal |
|---|---|
| `CandidateCubit` | Perfil, skills, tests pendientes, postulaciones |
| `CompanyCubit` | Dashboard, ofertas, matching, pagos (Stripe), tests |
| `AdminCubit` | Estadísticas globales, CRUD de usuarios, reportes |
| `TestCubit` | Sesión de prueba técnica: preguntas, respuestas, timer, submit |
| `ProctorCubit` | Proctoring en tiempo real: frames, alertas, reporte final |
| `AnalyticsCubit` | Analytics de mercado (pública) e insights personales del candidato |

---

## 7. Flujo Empresa — Publicar Oferta

```
CompanyDashboardPage
  │
  ├─ CreateNewOfferPage
  │    ├─ [IA] Parseo de descripción libre → campos sugeridos
  │    │       POST /api/offers/parse-description
  │    ├─ Selección de tier (cantidad de candidatos)
  │    │       GET /api/offers/tiers
  │    └─ Crear oferta → POST /api/offers
  │
  ├─ OfferPendingPage (estado: PendingPayment)
  │    └─ Pago vía Stripe → POST /api/payments/create-checkout
  │         → redirect a Stripe → /payment-result?session_id=...
  │              → POST /api/payments/verify-session
  │
  ├─ [Backend dispara matching automático]
  │    POST /api/matching/{offerId}/run
  │
  └─ OfferMatchesPage
       ├─ Ver ranking de candidatos con match %
       ├─ Enviar tests → POST /api/matching/send-test
       └─ Ver resultados → MatchTestResultsPage
            └─ Reporte de proctoring incluido
```

---

## 8. Flujo Candidato — Prueba Técnica

```
JobOffersListPage (assessments)
  │  GET /api/tests/candidate
  │
  └─ ActiveTechnicalTestPage
       │
       ├─ TestCubit.startTest(offerId)
       │    └─ POST /api/tests/{offerId}/candidate/start
       │         → TestSession (preguntas múltiple opción + código)
       │
       ├─ ProctorCubit.startSession(userId, submissionId)
       │    └─ POST bank-user.coderhivex.com/api/session/start
       │
       ├─ [Loop cada 3s] ProctorCubit.processFrame(base64)
       │    └─ POST /api/session/frame
       │         → { isLooking, hasIntruder, hasDevice }
       │         → Alertas visuales en tiempo real
       │
       ├─ TestCubit.submitTest(answers)
       │    └─ POST /api/tests/{testId}/submit
       │
       └─ ProctorCubit.endSession()
            └─ POST /api/session/end → reporte guardado en backend Python
                 (empresa lo consulta vía .NET: GET /api/tests/submissions/{matchId}/proctoring)
```

---

## 9. Sistema de Proctoring (Detalle)

El proctoring usa una **arquitectura de microservicio separada** (Python + visión por computadora):

```
Flutter Web (cámara via dart:html)
  │  captura frame → base64
  │
  ▼
ProctoringApiClient (Dio)
  → POST https://bank-user.coderhivex.com/api/session/frame
       Response:
         isLooking: bool      ← candidato mira la pantalla
         hasIntruder: bool    ← otra persona en cuadro
         hasDevice: bool      ← dispositivo no permitido
  │
ProctorCubit
  ├─ Acumula contadores: distractionCount, intruderCount, deviceCount
  ├─ Emite estado en tiempo real → UI muestra alertas
  └─ Al terminar: endSession() → reporte final persistido
```

**Estrategia de cámara web**: patrón stub/web para compilación multiplataforma:
- `camera.dart` — exporta condicional
- `camera_web.dart` — implementación real con `dart:html`
- `camera_stub.dart` — implementación vacía para mobile/desktop

---

## 10. Routing y Guards (GoRouter)

El router es **reactivo al AuthBloc** mediante `refreshListenable`:

```dart
// main.dart
BlocListener<AuthBloc, AuthState>(
  listener: (_, __) => _authNotifier.notify(),  // dispara refresh del router
)
```

### Guard de redirección
```
Estado AuthInitial / AuthLoading → no redirige (espera)
Usuario autenticado en ruta pública → redirige según rol:
  candidate → /candidate/assessments
  company   → /company/dashboard
  admin     → /admin/dashboard
Usuario no autenticado en ruta privada → /login
```

### Rutas por rol
| Rol | Rutas |
|---|---|
| Público | `/`, `/login`, `/register/*`, `/forgot-password`, `/auth/*` |
| Candidato | `/candidate/dashboard`, `/candidate/profile`, `/candidate/assessments`, `/candidate/insights`, `/candidate/test/:id` |
| Empresa | `/company/dashboard`, `/company/matches`, `/company/offers/*` |
| Admin | `/admin/dashboard`, `/admin/users` |

---

## 11. Inyección de Dependencias (GetIt)

```dart
// Singleton (una instancia para toda la app)
sl.registerLazySingleton<TokenStorage>(...)
sl.registerLazySingleton<ApiClient>(...)
sl.registerLazySingleton<AppDatasource>(() => RemoteDatasource(...))
sl.registerLazySingleton<AuthOutputPort>(() => RemoteAuthAdapter(...))
sl.registerLazySingleton<AuthInputPort>(() => AuthDomainService(...))

// Factory (nueva instancia por cada uso — importante para Cubits)
sl.registerFactory<AuthBloc>(...)
sl.registerFactory<CandidateCubit>(...)
sl.registerFactory<CompanyCubit>(...)
sl.registerFactory<AdminCubit>(...)
sl.registerFactory<TestCubit>(...)
sl.registerFactory<ProctorCubit>(...)
sl.registerFactory<AnalyticsCubit>(...)
```

Los Cubits de scope de página (TestCubit, ProctorCubit, AnalyticsCubit) se inyectan **directamente en el GoRoute** para que su ciclo de vida esté ligado a la página, no a la app.

---

## 12. Manejo de Errores — Either (Dartz)

Toda llamada a dominio e infraestructura retorna `Either<Failure, T>`:

```dart
// Typedefs en core/utils/typedef.dart
typedef ResultFuture<T> = Future<Either<Failure, T>>;
typedef ResultVoid      = Future<Either<Failure, void>>;

// Uso en BLoC/Cubit
final result = await _authPort.login(email: e.email, password: e.password);
result.fold(
  (failure) => emit(AuthFailureState(failure.message)),
  (user)    => emit(AuthAuthenticated(user)),
);
```

No hay `try/catch` en la capa de presentación — los errores son **valores tipados**, no excepciones.

---

## 13. API Client — Detalles de Implementación

`ApiClient` (sobre Dio) maneja automáticamente:

- **Inyección de JWT** en cada request desde `TokenStorage` (`flutter_secure_storage`)
- **Refresh de token** automático cuando el backend retorna 401
- **Extracción del payload** de la respuesta: `response.data['data']`
- **Mapeo a Failure** con el `statusCode` incluido para diferenciar 404 vs 500
- `skipAuth: true` para endpoints públicos (analytics de mercado)

```
POST /api/auth/login → { data: { user, accessToken, refreshToken } }
                              ↓
                        TokenStorage.save(access, refresh)
                              ↓
                        return Right(User)
```

---

## 14. Módulo de Analytics

Dos endpoints con el mismo parser:

| Endpoint | Auth | Datos |
|---|---|---|
| `GET /api/analytics/market` | Pública | Top habilidades en demanda, oferta y combinaciones |
| `GET /api/analytics/market/my-insights` | Candidato | Igual + campos `candidateHasSkill`, `skillGaps` |

La entidad `MarketAnalytics` unifica ambos casos. La página `CandidateInsightsPage` resalta visualmente si el candidato ya tiene la skill o si es un gap.

---

## 15. Diagrama de Capas — Resumen Visual

```
┌──────────────────────────────────────────────────┐
│  UI / PRESENTACIÓN                               │
│  Pages (20+) · Widgets compartidos · BLoC/Cubit  │
│  GoRouter (guards por rol)                       │
└────────────────────┬─────────────────────────────┘
                     │ Either<Failure, T>
┌────────────────────▼─────────────────────────────┐
│  DOMINIO (puro Dart, sin imports de Flutter)     │
│  Entities · Services · Ports (Input/Output)      │
│  Value Objects · UseCases                        │
└────────────────────┬─────────────────────────────┘
                     │ implementaciones concretas
┌────────────────────▼─────────────────────────────┐
│  INFRAESTRUCTURA                                 │
│  ApiClient (Dio) · TokenStorage (SecureStorage)  │
│  RemoteDatasource · RemoteAuthAdapter            │
│  ProctoringApiClient · ProctoringDatasource      │
└──────────────────────────────────────────────────┘
                     │
┌────────────────────▼─────────────────────────────┐
│  SERVICIOS EXTERNOS                              │
│  matchiq-service.coderhivex.com (.NET REST API)  │
│  bank-user.coderhivex.com (Python CV/AI)         │
│  Stripe (pagos)                                  │
└──────────────────────────────────────────────────┘
```

---

## 16. Puntos Técnicos Destacados

| Decisión | Justificación |
|---|---|
| Arquitectura Hexagonal | Dominio testeable de forma aislada; fácil cambiar RemoteAdapter por MockAdapter |
| BLoC para Auth, Cubit para el resto | Auth tiene eventos complejos (verificación, auto-login post-OTP); cubits son suficientes para CRUD |
| `Either` en lugar de excepciones | Errores como valores tipados, sin propagación de excepciones inesperadas |
| `registerFactory` para Cubits | Cada página obtiene una instancia fresca, evita estado residual entre navegaciones |
| Stub/Web para APIs de browser | Permite compilar en Android/iOS/desktop sin errors de `dart:html` |
| `refreshListenable` en GoRouter | El router reacciona automáticamente a cambios de sesión sin lógica extra |
| Dos backends separados | El microservicio Python de visión por computadora escala independientemente del backend de negocio |

---

## 17. Flujo Admin

```
AdminDashboardPage
  ├─ AdminCubit.loadStats()  → GET /api/admin/stats
  │    Métricas: candidatos, empresas, ofertas por estado,
  │              matches, tests, tasa de completitud, revenue
  │
  ├─ AdminCubit.downloadReport() → GET /api/admin/report (PDF/Excel)
  │
  └─ AdminUsersPage
       ├─ AdminCubit.loadUsers(role?, isActive?) → GET /api/admin/users
       ├─ AdminCubit.createAdmin(...)  → POST /api/admin/users
       ├─ AdminCubit.toggleStatus(id) → PATCH /api/admin/users/:id/toggle-status
       └─ AdminCubit.deleteUser(id)   → DELETE /api/admin/users/:id
```

---

## 18. CI / CD

El proyecto cuenta con un pipeline en `.github/workflows/deploy.yml` para despliegue web automático del build de Flutter.

---

*MatchIQ Frontend · Flutter 3.x · Dart SDK ^3.5.0*
