# MatchIQ — Contexto del Proyecto

## Qué es esto

**MatchIQ** es una plataforma de reclutamiento con IA. Conecta candidatos con empresas usando matching inteligente, pruebas técnicas automáticas y rankings generados por IA.

Tres roles de usuario: **Candidate**, **Company**, **Admin**.

---

## Stack Tecnológico

| Capa | Tecnología |
|------|-----------|
| Framework | Flutter (Dart SDK ^3.12.1) |
| State Management | BLoC (`flutter_bloc`) |
| Dependency Injection | GetIt (`get_it`) |
| Auth | Firebase Auth |
| Router | GoRouter (planificado, archivos listos) |

> **Estado actual (v0.2)**: Todas las vistas implementadas con mock data. 0 errores de compilación. Para conectar al backend real: reemplazar `MockDatasource` + `MockAuthAdapter` con implementaciones HTTP manteniendo los mismos puertos.

---

## Arquitectura: Hexagonal (Ports & Adapters) + Clean Architecture

La separación es estricta: **Domain no depende de nada**, Infrastructure implementa los puertos, Presentation consume los casos de uso vía BLoC.

```
lib/
├── config/
│   ├── router/          # app_router.dart, app_routes.dart
│   └── theme/           # app_colors.dart, app_text_styles.dart, app_theme.dart
├── core/
│   ├── errors/          # exeption.dart, failures.dart (Either pattern)
│   ├── network/         # network_info.dart / network_info_impl.dart
│   ├── ports/           # use_case.dart (interfaz base para todos los UseCases)
│   └── utils/
│       ├── extensions/  # datetime_ext.dart, string_ext.dart
│       └── typedef.dart # tipos globales (ej. ResultFuture<T>)
├── features/
│   ├── domain/          # Núcleo — cero dependencias externas
│   │   ├── entities/    # Modelos puros de negocio (User, etc.)
│   │   ├── ports/
│   │   │   ├── input/   # Interfaces que la UI llama (AuthInputPort)
│   │   │   └── output/  # Interfaces que Infrastructure implementa (AuthOutputPort)
│   │   ├── services/    # Lógica de dominio (AuthDomainService)
│   │   ├── usecases/    # Un caso de uso por archivo (LoginUseCase)
│   │   └── value_objects/ # Email, etc. (validación en el dominio)
│   ├── infrastructure/  # Implementaciones concretas
│   │   ├── adapters/    # FirebaseAuthAdapter, LocalAuthAdapter
│   │   ├── datasources/ # AuthRemoteDatasource
│   │   ├── mappers/     # UserMapper (UserModel ↔ User entity)
│   │   └── models/      # UserModel (DTOs con serialización)
│   └── presentarion/    # ⚠️ Typo intencional en el nombre de la carpeta — no renombrar
│       ├── adapters/    # AuthBlocAdapter (conecta BLoC con el puerto de entrada)
│       ├── bloc/        # auth_bloc.dart, auth_event.dart, auth_state.dart
│       ├── pages/       # login_page.dart (una página por archivo)
│       └── widgets/     # login_form.dart (widgets reutilizables)
└── injection/
    ├── injection_container.dart  # Setup global de GetIt
    └── modules/
        └── auth_module.dart      # Registro de dependencias por feature
```

### Flujo de datos (ejemplo: Login)

```
UI (LoginForm)
  → AuthBlocAdapter.login(email, password)
  → AuthBloc dispatches LoginEvent
  → LoginUseCase.call(params)
  → AuthDomainService (via AuthInputPort)
  → FirebaseAuthAdapter (implementa AuthOutputPort)
  → Firebase Auth SDK
  ← UserModel → UserMapper → User entity
  ← AuthBloc emits AuthAuthenticated(user)
  ← UI reacciona y navega
```

---

## Pantallas Planificadas (del ZIP de diseños Stitch)

El ZIP `lib/stitch_matchiq_recruitment_platform.zip` contiene pantallas con `code.html` y `screen.png` para cada una:

| Pantalla | Ruta esperada | Rol |
|----------|--------------|-----|
| `landing_page` | `/` | Público |
| `login_page` | `/login` | Público |
| `forgot_password` | `/forgot-password` | Público |
| `auth_utility_screens` | `/verify-email`, etc. | Público |
| `candidate_registration` | `/register/candidate` | Público |
| `company_registration` | `/register/company` | Público |
| `candidate_dashboard` | `/candidate/dashboard` | Candidate |
| `candidate_profile` | `/candidate/profile` | Candidate |
| `job_offers_list` | `/candidate/offers` | Candidate |
| `active_technical_test` | `/candidate/test/:id` | Candidate |
| `company_dashboard` | `/company/dashboard` | Company |
| `company_profile_settings` | `/company/settings` | Company |
| `company_matches_ai_ranking` | `/company/matches` | Company |
| `create_new_offer` | `/company/offers/new` | Company |
| `admin_dashboard` | `/admin/dashboard` | Admin |

---

## Design System (del DESIGN.md en el ZIP)

**Fuente**: Inter (único typeface)

**Paleta principal**:
```
Primary (Deep Navy):  #000F1D / #0F2537
Secondary (Blue):     #3B618A
AI Accent (Emerald):  solo para matches IA y estados de éxito — nunca decorativo
Error:                #BA1A1A
Background:           #F7F9FB
Surface:              #FFFFFF (cards)
```

**Bordes redondeados**:
- Botones e inputs: `8px`
- Cards y contenedores: `20px–26px`
- Badges/pills: `full` (9999px)

**Sombras (elevación)**:
- Cards (Level 1): `0px 4px 20px rgba(15,37,55,0.08)`
- Modals (Level 2): `0px 12px 32px rgba(15,37,55,0.12)`
- Navbar: glassmorphism `backdrop-filter: blur(12px)`, `bg-white/80`

**Espaciado** (base 8px):
- xs: 8px | sm: 16px | md: 24px | lg: 40px | xl: 64px

**Tipografía**:
- Display: Inter 48px / 800
- Headline LG: Inter 32px / 700
- Headline MD: Inter 24px / 600
- Body LG: Inter 18px / 400 / lh 1.6
- Body MD: Inter 16px / 400 / lh 1.5
- Label Bold: Inter 14px / 600

---

## Convenciones del Proyecto

- **Un feature = un módulo de inyección** en `injection/modules/`
- **Mappers** siempre convierten bidireccional: `Model → Entity` y `Entity → Model`
- **Value Objects** llevan validación embebida (ej. `Email` valida formato en constructor)
- **Either pattern** para manejo de errores: `ResultFuture<T> = Future<Either<Failure, T>>`
- Los **BLoC adapters** en `presentarion/adapters/` son la única capa que conoce tanto el BLoC como el InputPort
- **No mezclar lógica de negocio en widgets** — toda lógica va al BLoC/UseCase

## Notas Importantes

- El nombre de carpeta `presentarion` (sin segunda 'e') es un typo existente — **no renombrar** para no romper imports
- El `main.dart` tiene el contador default de Flutter — necesita ser reemplazado con el setup real (MaterialApp + GoRouter + GetIt init + BlocProviders)
- Las dependencias de `pubspec.yaml` están vacías — faltan `flutter_bloc`, `get_it`, `firebase_auth`, `go_router`, `dartz` (o `fpdart`), `connectivity_plus`


flutter run -d web-server --web-port 3000