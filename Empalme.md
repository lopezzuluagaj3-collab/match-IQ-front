# Empalme — Estado del Proyecto MatchIQ

> Documento de traspaso. Registra qué llegó en el repositorio, qué se modificó en sesión de trabajo, y un comparativo honesto contra lo planificado en `CLAUDE.md`.
>
> Fecha: 2026-06-27 (actualizado) | Rama: `main` | Autor modificaciones: Steven.Patino

---

## 1. Historial de Commits

| SHA | Autor | Fecha | Descripción |
|-----|-------|-------|-------------|
| `69985a4` | GitHub | — | Initial commit (README.md vacío generado por GitHub) |
| `f810eb1` | SantiagoBoteroDiaz | — | first commit, creation of the front infrastructure |
| `bccee92` | SantiagoBoteroDiaz | 2026-06-27 | add proyect — entrega del proyecto completo (68 archivos, +14.260 líneas) |

El repositorio llegó con **todo el código ya entregado en un solo commit grande** (`bccee92`). No hubo construcción incremental visible en git.

---

## 2. Cambios Realizados Post-Clone

Solo **2 archivos** han sido modificados desde que se descargó el repositorio. Ambios son cambios menores y puntuales.

### 2.1 `lib/features/presentarion/bloc/company_cubit.dart` — Bug fix

**Problema:** Error de compilación que impedía correr la app.

```diff
- CompanyProfile? profile = profileRes.getOrElse(() => null);
+ CompanyProfile? profile = profileRes.fold((l) => null, (r) => r);
```

**Por qué fallaba:** `dartz` en modo null-safe requiere que `getOrElse` devuelva el mismo tipo no-nulable que `Right<T>`. `() => null` devuelve `Null`, que no es asignable a `CompanyProfile`. La corrección usa `fold` que sí permite devolver `null` mediante el tipo de retorno implícito `CompanyProfile?`.

**Línea:** 98 de `company_cubit.dart`.

---

### 2.2 `lib/injection/injection_container.dart` — Modo mock activable

**Motivo:** Poder desarrollar y probar las pantallas sin necesidad del backend corriendo en `localhost:5000`.

```diff
+ import '../features/infrastructure/adapters/mock_auth_adapter.dart';
+ import '../features/infrastructure/datasources/mock_datasource.dart';

+ // Cambiar a false cuando el backend esté disponible en localhost:5000
+ const bool kUseMock = true;

  sl.registerLazySingleton<AppDatasource>(
-   () => RemoteDatasource(sl<ApiClient>(), sl<TokenStorage>()),
+   () => kUseMock
+       ? MockDatasource()
+       : RemoteDatasource(sl<ApiClient>(), sl<TokenStorage>()),
  );

  sl.registerLazySingleton<AuthOutputPort>(
-   () => RemoteAuthAdapter(sl<ApiClient>(), sl<TokenStorage>()),
+   () => kUseMock
+       ? MockAuthAdapter(sl<AppDatasource>())
+       : RemoteAuthAdapter(sl<ApiClient>(), sl<TokenStorage>()),
  );
```

**Para activar el backend real:** cambiar `kUseMock = false`.

**Archivo afectado:** `lib/injection/injection_container.dart`

**Credenciales de prueba (modo mock):**

| Email | Password | Rol |
|-------|----------|-----|
| `company@test.com` | `123456` | Company |
| `candidate@test.com` | `123456` | Candidate |
| `admin@test.com` | `123456` | Admin |

---

### 2.3 Mejoras visuales — Modo día/noche, animaciones y logo

**Archivos nuevos:**

| Archivo | Descripción |
|---------|-------------|
| `lib/features/presentarion/bloc/theme_cubit.dart` | Cubit para toggle dark/light mode. Estado persiste durante la sesión vía `lazySingleton` en GetIt. |
| `lib/assets/logo_dark.jpeg` | Logo MatchIQ versión oscura (texto blanco sobre fondo transparente) — para sidebar y splash |
| `lib/assets/logo_light.jpeg` | Logo MatchIQ versión clara (texto navy sobre fondo blanco) — para login en modo día |

**Archivos modificados:**

| Archivo | Cambio |
|---------|--------|
| `pubspec.yaml` | Añadida carpeta `lib/assets/` a la sección de assets |
| `lib/config/theme/app_theme.dart` | Añadido `AppTheme.dark` completo con ColorScheme navy oscuro |
| `lib/config/router/app_router.dart` | Todas las rutas migradas de `builder:` a `pageBuilder:` con `CustomTransitionPage`. Fade (320ms) para páginas públicas, fade+slide (280ms) para dashboards. |
| `lib/main.dart` | ThemeCubit añadido al MultiBlocProvider. Splash screen convertida a StatefulWidget con animación escala+fade. Logo `logo_dark.jpeg` en splash. |
| `lib/features/presentarion/widgets/shared/app_card.dart` | AppCard ahora usa `Theme.of(context).colorScheme.surface` (theme-aware). Nuevos widgets: `FadeSlideCard` (animación de entrada por delay), `AIPulseBadge` (badge esmeralda que pulsa), `StatusBadge`, `EmeraldBadge`. |
| `lib/features/presentarion/widgets/shared/app_sidebar.dart` | Logo en header y AppBar móvil. "MatchIQ" en RichText (blanco + esmeralda). Hover animation en nav items (MouseRegion + ScaleTransition). Theme toggle en footer con AnimatedSwitcher + RotationTransition. |
| `lib/features/presentarion/pages/login_page.dart` | Animaciones de entrada escalonadas (logo easeOutBack, form fade+slide desde abajo). Logo tema-aware: `logo_dark.jpeg` en modo noche, `logo_light.jpeg` en modo día. Theme toggle esquina superior derecha. Hover animation en links de registro. |
| `lib/injection/injection_container.dart` | ThemeCubit registrado como `lazySingleton`. |

---

### 2.4 Nota sobre `lib/stitch_designs/`

La carpeta `lib/stitch_designs/` contiene diseños de referencia generados por Stitch (herramienta de diseño AI):
- `code.html` — código HTML/CSS, **no importado por Flutter en ningún momento**
- `screen.png` — capturas de pantalla usadas como guía visual para construir las páginas Flutter

**El compilador de Flutter ignora completamente esta carpeta.** Las pantallas Flutter se construyeron desde cero en Dart. Se puede eliminar la carpeta sin afectar la compilación ni el runtime.

---

## 3. Comparativo con CLAUDE.md

### 3.1 Pantallas Planificadas

CLAUDE.md lista 15 pantallas. **Las 15 están implementadas.**

| Pantalla | Ruta | Rol | Archivo | Estado |
|----------|------|-----|---------|--------|
| Landing Page | `/` | Público | `landing_page.dart` | ✅ Implementada |
| Login | `/login` | Público | `login_page.dart` | ✅ Implementada |
| Forgot Password | `/forgot-password` | Público | `forgot_password_page.dart` | ✅ Implementada |
| Auth Utility (verify email) | `/verify-email` | Público | `auth_utility_page.dart` | ✅ Implementada |
| Candidate Registration | `/register/candidate` | Público | `candidate_registration_page.dart` | ✅ Implementada |
| Company Registration | `/register/company` | Público | `company_registration_page.dart` | ✅ Implementada |
| Candidate Dashboard | `/candidate/dashboard` | Candidate | `candidate_dashboard_page.dart` | ✅ Implementada |
| Candidate Profile | `/candidate/profile` | Candidate | `candidate_profile_page.dart` | ✅ Implementada |
| Job Offers List | `/candidate/offers` | Candidate | `job_offers_list_page.dart` | ✅ Implementada |
| Active Technical Test | `/candidate/test/:id` | Candidate | `active_technical_test_page.dart` | ✅ Implementada |
| Company Dashboard | `/company/dashboard` | Company | `company_dashboard_page.dart` | ✅ Implementada |
| Company Profile Settings | `/company/settings` | Company | `company_profile_settings_page.dart` | ✅ Implementada |
| Company Matches AI Ranking | `/company/matches` | Company | `company_matches_ranking_page.dart` | ✅ Implementada |
| Create New Offer | `/company/offers/new` | Company | `create_new_offer_page.dart` | ✅ Implementada |
| Admin Dashboard | `/admin/dashboard` | Admin | `admin_dashboard_page.dart` | ✅ Implementada |

---

### 3.2 Stack Tecnológico

| Capa | Planificado en CLAUDE.md | Estado real |
|------|--------------------------|-------------|
| Framework | Flutter (Dart SDK ^3.12.1) | ✅ Flutter — pubspec usa `^3.5.0` (diferencia menor) |
| State Management | `flutter_bloc` | ✅ `flutter_bloc ^8.1.6` |
| Dependency Injection | `get_it` | ✅ `get_it ^8.0.2` |
| Auth | Firebase Auth | ⚠️ **Cambiado** — JWT propio via `RemoteAuthAdapter` + `dio`. Firebase no se usa. |
| Router | GoRouter (planificado) | ✅ `go_router ^14.3.0` — ya en producción, no solo planificado |
| Either / FP | `dartz` o `fpdart` | ✅ `dartz ^0.10.1` |
| HTTP Client | _(no mencionado)_ | ✅ `dio ^5.8.0` — agregado |
| Token Storage | _(no mencionado)_ | ✅ `flutter_secure_storage ^9.2.4` — agregado |
| Iconos | _(no mencionado)_ | ✅ `material_symbols_icons` — agregado |
| Fuente | Inter | ✅ `google_fonts` — Inter cargada |

**Nota crítica sobre Auth:** CLAUDE.md dice Firebase Auth pero el backend usa JWT propio (`accessToken` 60 min + `refreshToken` 7 días según `ApiRefetrence.md`). La implementación real usa `RemoteAuthAdapter` con `dio` y `flutter_secure_storage`. Firebase no está en el `pubspec.yaml`.

---

### 3.3 Arquitectura — Planificado vs Implementado

#### Lo que se implementó tal como se planificó

| Elemento | Ruta en CLAUDE.md | Estado |
|----------|-------------------|--------|
| Domain entities | `domain/entities/` | ✅ 8 entidades: User, CandidateProfile, CompanyProfile, CandidateMatch, JobOffer, TechnicalTest, Catalog, AdminStats |
| Auth ports | `domain/ports/input/` y `output/` | ✅ AuthInputPort, AuthOutputPort |
| Domain service | `domain/services/` | ✅ AuthDomainService |
| Infrastructure adapters | `infrastructure/adapters/` | ✅ RemoteAuthAdapter, MockAuthAdapter |
| Datasources | `infrastructure/datasources/` | ✅ AppDatasource (abstract), RemoteDatasource, MockDatasource |
| BLoC / Cubits | `presentarion/bloc/` | ✅ AuthBloc, CompanyCubit, CandidateCubit, AdminCubit, TestCubit |
| Pages | `presentarion/pages/` | ✅ 15 páginas |
| Shared widgets | `presentarion/widgets/` | ✅ AppCard, AppSidebar, AppTextField |
| Injection container | `injection/injection_container.dart` | ✅ GetIt configurado con factory/singleton |
| Router | `config/router/` | ✅ app_router.dart, app_routes.dart |
| Theme | `config/theme/` | ✅ app_colors.dart, app_text_styles.dart, app_theme.dart |
| Either pattern | `core/utils/typedef.dart` | ✅ `ResultFuture<T>`, `ResultVoid` |
| Error types | `core/errors/` | ✅ failures.dart, exeption.dart |
| API layer | `core/api/` | ✅ ApiClient (Dio), ApiConstants, TokenStorage |
| main.dart | Setup completo | ✅ MaterialApp.router + GoRouter + GetIt + BlocProviders |

#### Lo que CLAUDE.md planificó pero NO se implementó

| Elemento | Ruta esperada | Motivo / Adaptación |
|----------|---------------|---------------------|
| UseCases | `domain/usecases/LoginUseCase` | La lógica está en `AuthDomainService` directamente. Los Cubits consumen el datasource sin pasar por UseCases intermedios. |
| Value Objects | `domain/value_objects/Email` | La validación de formularios se hace en los widgets con `validator:`. No hay Value Objects en el dominio. |
| Mappers | `infrastructure/mappers/UserMapper` | El parseo JSON→Entity se hace inline dentro de los métodos de `RemoteDatasource`. No hay clases Mapper separadas. |
| Models / DTOs | `infrastructure/models/UserModel` | No existen DTOs. Se deserializa directo a entidades del dominio. |
| BLoC Adapters | `presentarion/adapters/AuthBlocAdapter` | Los Cubits consumen `AppDatasource` directamente, sin adaptadores intermedios. |
| `core/network/` | `core/network/network_info.dart` | Existe `core/api/` en su lugar (Dio + interceptors). |
| `core/utils/extensions/` | `datetime_ext.dart`, `string_ext.dart` | No existen. Las extensiones no se crearon. |

#### Simplificaciones adoptadas (diferencias arquitecturales conscientes)

El proyecto tomó un camino más directo que el descrito en CLAUDE.md:

```
CLAUDE.md planificaba:
  UI → BlocAdapter → BLoC → UseCase → DomainService → OutputPort → Adapter → API

Lo implementado:
  UI → Cubit → AppDatasource (port) → RemoteDatasource → ApiClient → API
```

Esto simplifica el grafo de dependencias pero significa que los Cubits tienen más responsabilidad que en la arquitectura original.

---

### 3.4 Notas Importantes de CLAUDE.md — Estado Actual

| Nota original | Estado |
|---------------|--------|
| `presentarion` (typo) — no renombrar | ✅ Respetado. La carpeta mantiene el typo en todos los imports. |
| `main.dart` tenía contador default de Flutter | ✅ Resuelto. main.dart ya tiene el setup completo. |
| `pubspec.yaml` vacío, faltan dependencias | ✅ Resuelto. pubspec.yaml tiene todas las dependencias necesarias. |

---

## 4. Árbol de Archivos — Estado Real

```
lib/
├── assets/                          ✅ Logos tema-aware
│   ├── logo_dark.jpeg               ✅ Logo modo noche (sidebar, splash)
│   └── logo_light.jpeg              ✅ Logo modo día (login en light mode)
├── config/
│   ├── router/
│   │   ├── app_router.dart          ✅ GoRouter con guards por rol + CustomTransitionPage
│   │   └── app_routes.dart          ✅ Constantes de rutas
│   └── theme/
│       ├── app_colors.dart          ✅ Paleta completa + gradientes
│       ├── app_text_styles.dart     ✅ Tipografía Inter
│       └── app_theme.dart           ✅ ThemeData light + dark (Material 3)
├── core/
│   ├── api/
│   │   ├── api_client.dart          ✅ Dio + interceptor JWT refresh
│   │   ├── api_constants.dart       ✅ Todos los endpoints
│   │   └── token_storage.dart       ✅ flutter_secure_storage
│   ├── errors/
│   │   ├── exeption.dart            ✅
│   │   └── failures.dart            ✅ ServerFailure, AuthFailure, etc.
│   ├── ports/
│   │   └── use_case.dart            ✅ Interfaz base UseCase
│   └── utils/
│       ├── snackbar_helper.dart     ✅
│       └── typedef.dart             ✅ ResultFuture<T>, ResultVoid
├── features/
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── activity.dart        ✅
│   │   │   ├── admin_stats.dart     ✅
│   │   │   ├── candidate.dart       ✅ CandidateProfile, ExperienceItem, EducationItem
│   │   │   ├── catalog.dart         ✅ Category, CatalogSkill, OfferTier, AiParseResult
│   │   │   ├── company.dart         ✅ CompanyProfile, CandidateMatch, MatchStatus enum
│   │   │   ├── job_offer.dart       ✅ JobOffer, CreateOfferInput, OfferMode, OfferType
│   │   │   ├── technical_test.dart  ✅ TechnicalTest, TestSession, TestQuestion, TestResult
│   │   │   └── user.dart            ✅ User, UserRole enum
│   │   ├── ports/
│   │   │   ├── input/
│   │   │   │   └── auth_input_port.dart   ✅
│   │   │   └── output/
│   │   │       └── auth_output_port.dart  ✅
│   │   └── services/
│   │       └── auth_domain_service.dart   ✅
│   ├── infrastructure/
│   │   ├── adapters/
│   │   │   ├── mock_auth_adapter.dart     ✅ Usuarios de prueba hardcodeados
│   │   │   └── remote_auth_adapter.dart   ✅ JWT login/register/refresh/logout
│   │   └── datasources/
│   │       ├── app_datasource.dart        ✅ Interfaz abstracta (puerto de salida)
│   │       ├── mock_datasource.dart       ✅ Datos mock realistas para todas las entidades
│   │       └── remote_datasource.dart     ✅ Todos los endpoints del backend implementados
│   └── presentarion/                      ⚠️ Typo intencional — no renombrar
│       ├── bloc/
│       │   ├── admin_cubit.dart           ✅
│       │   ├── auth_bloc.dart             ✅ + auth_event.dart + auth_state.dart
│       │   ├── candidate_cubit.dart       ✅
│       │   ├── company_cubit.dart         ✅ (bug fix aplicado)
│       │   ├── test_cubit.dart            ✅
│       │   └── theme_cubit.dart           ✅ Toggle day/night, lazySingleton
│       ├── pages/
│       │   ├── active_technical_test_page.dart    ✅
│       │   ├── admin_dashboard_page.dart           ✅
│       │   ├── auth_utility_page.dart              ✅
│       │   ├── candidate_dashboard_page.dart       ✅
│       │   ├── candidate_profile_page.dart         ✅
│       │   ├── candidate_registration_page.dart    ✅
│       │   ├── company_dashboard_page.dart         ✅
│       │   ├── company_matches_ranking_page.dart   ✅
│       │   ├── company_profile_settings_page.dart  ✅
│       │   ├── company_registration_page.dart      ✅
│       │   ├── create_new_offer_page.dart          ✅
│       │   ├── forgot_password_page.dart           ✅
│       │   ├── job_offers_list_page.dart           ✅
│       │   ├── landing_page.dart                   ✅
│       │   └── login_page.dart                     ✅
│       └── widgets/
│           └── shared/
│               ├── app_card.dart          ✅ AppCard, FadeSlideCard, AIPulseBadge, EmeraldBadge, StatusBadge
│               ├── app_sidebar.dart       ✅ ScaffoldWithSidebar + logo + hover anim + theme toggle
│               └── app_text_field.dart    ✅ AppTextField + AppButton
├── injection/
│   ├── injection_container.dart     ✅ (kUseMock flag agregado)
│   └── modules/
│       └── auth_module.dart         — Placeholder vacío
└── main.dart                        ✅ Setup completo
```

---

## 5. Pendientes Identificados

### Bloqueantes para producción

| # | Pendiente | Archivo / Área |
|---|-----------|----------------|
| 1 | Cambiar `kUseMock = false` cuando el backend esté en `localhost:5000` | `injection/injection_container.dart` |
| 2 | Activar Developer Mode en Windows para poder compilar desktop (symlinks) | Configuración del sistema |

### Deuda técnica vs arquitectura planificada

| # | Pendiente | Contexto |
|---|-----------|---------|
| 3 | Implementar UseCases (`domain/usecases/`) si se quiere respetar el flujo completo de CLAUDE.md | Hoy la lógica está en los Cubits |
| 4 | Implementar Mappers (`infrastructure/mappers/`) separados del datasource | Hoy el parseo JSON está inline en `RemoteDatasource` |
| 5 | Implementar Value Objects con validación en dominio (`domain/value_objects/`) | Hoy la validación está en los widgets |
| 6 | Implementar BLoC Adapters (`presentarion/adapters/`) como capa de mediación | Hoy los Cubits consumen `AppDatasource` directamente |

### Funcionalidad no verificada

| # | Pendiente | Notas |
|---|-----------|-------|
| 7 | Probar flujo completo de empresa contra backend real | Requiere backend corriendo |
| 8 | Verificar manejo de expiración de `accessToken` y refresh automático | Lógica existe en `ApiClient` pero no se ha probado end-to-end |
| 9 | Flujo de pago con Wompi (`createCheckout`) | `create_new_offer_page.dart` lanza la URL, no verificado con Wompi real |
| 10 | Tests unitarios | No existe ningún test en el proyecto |

---

## 6. Cómo Conectar al Backend Real

Cuando el backend esté disponible en `http://localhost:5000`:

```dart
// lib/injection/injection_container.dart — línea 19
const bool kUseMock = false;  // ← solo cambiar esto
```

No se necesita tocar ninguna otra cosa. `RemoteDatasource` y `RemoteAuthAdapter` ya tienen todos los endpoints mapeados según `ApiRefetrence.md`.
