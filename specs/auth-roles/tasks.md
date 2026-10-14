# Plan de Tareas: Control de Registro y Acceso por Roles (auth-roles)

**Documentos de referencia:** [specs/auth-roles/spec.md](file:///Users/diego/FlutterProjects/vihomeweb/specs/auth-roles/spec.md) | [specs/auth-roles/plan.md](file:///Users/diego/FlutterProjects/vihomeweb/specs/auth-roles/plan.md) | [docs/constitution.md](file:///Users/diego/FlutterProjects/vihomeweb/docs/constitution.md)  
**Estado general:** Pendiente de ejecución  

---

## Fase 1: Base de Datos y Seguridad (Supabase / Backend)
*Dependencias: Ninguna. Bloqueante para pruebas de integración reales.*

- [x] **Tarea 1.1: Definir DDL de tabla `public.perfiles` y políticas RLS (20 min)**
  - **Requisito funcional:** RF-02, RF-04, RF-06
  - **Descripción:** Crear script de migración SQL para la tabla `public.perfiles` con constraints de rol (`CONSTRUCTORA`, `ADMIN`, `CLIENTE`), campo `activo` y políticas RLS para lectura propia y de administradores.
  - **Comprobación:** Script creado en `supabase/migrations/20261007_auth_roles_perfiles.sql` con DDL, constraints de verificación y políticas RLS restrictivas para usuarios autenticados y administradores.

- [x] **Tarea 1.2: Crear Trigger de asignación inmutable de rol `CONSTRUCTORA` (15 min)**
  - **Requisito funcional:** RF-01, RF-02
  - **Descripción:** Implementar función PL/pgSQL `public.handle_new_user()` y trigger `on_auth_user_created` en `auth.users` que inserte automáticamente el registro en `public.perfiles` forzando `rol = 'CONSTRUCTORA'` y `activo = true`.
  - **Comprobación:** Script creado en `supabase/migrations/20261007_auth_roles_trigger.sql` con función `SECURITY DEFINER` y trigger sobre `auth.users` que asegura la asignación forzada de `CONSTRUCTORA`.

---

## Fase 2: Capa de Dominio (Modelos, Excepciones y Contratos)
*Dependencias: Fase 1.*

- [x] **Tarea 2.1: Implementar Enum `UserRole` y entidad `PerfilUsuario` (25 min)**
  - **Requisito funcional:** RF-04, RF-05, RF-06
  - **Descripción:** Crear `lib/domain/models/user_role.dart` con propiedad `isWebAuthorized` y `lib/domain/models/perfil_usuario.dart` con métodos de serialización `fromJson`/`toJson` y getter `isAccessGranted`.
  - **Comprobación:** Ejecutar `flutter test test/domain/models/perfil_usuario_test.dart` verificando mapeo de JSON y flags de autorización.

- [x] **Tarea 2.2: Implementar jerarquía de fallos tipados `AuthFailure` (15 min)**
  - **Requisito funcional:** RF-01, RF-04, RF-05, RF-06
  - **Descripción:** Crear `lib/core/errors/auth_failure.dart` usando `sealed class AuthFailure` con subtipos para credenciales inválidas, rol no autorizado, cuenta inactiva, usuario duplicado y error de red con mensajes en español.
  - **Comprobación:** `flutter test test/core/errors/auth_failure_test.dart` y `dart analyze` reportan 0 errores.

- [x] **Tarea 2.3: Definir contrato abstracto `AuthRepository` (15 min)**
  - **Requisito funcional:** RF-01, RF-03, RF-04, RF-05
  - **Descripción:** Crear `lib/domain/repositories/auth_repository.dart` con las firmas `watchCurrentUser()`, `getCurrentProfile()`, `registerConstructora()`, `signIn()` y `signOut()`.
  - **Comprobación:** `dart analyze lib/domain/repositories/auth_repository.dart` compila limpiamente sin dependencias circulares.

---

## Fase 3: Capa de Datos y Soporte para Pruebas
*Dependencias: Fase 2.*

- [x] **Tarea 3.1: Crear `FakeAuthRepository` para suite de pruebas (25 min)**
  - **Requisito funcional:** RF-01 a RF-06 (Principio 4 de la Constitución)
  - **Descripción:** Crear `test/helpers/fake_auth_repository.dart` implementando `AuthRepository` para simular escenarios de éxito, error de credenciales, roles `CLIENTE`, cuentas inactivas y timeouts sin requerir Supabase real.
  - **Comprobación:** `flutter test test/helpers/fake_auth_repository_test.dart` pasa al 100% con 5 pruebas unitarias verificando roles y revocación.

- [x] **Tarea 3.2: Implementar `SupabaseAuthRepository.registerConstructora` con retry (30 min)**
  - **Requisito funcional:** RF-01, RF-02, RF-03
  - **Descripción:** Crear `lib/data/repositories/supabase_auth_repository.dart` implementando el registro web con Supabase Auth e incorporando algoritmo de reintento de lectura en `public.perfiles` para mitigar la condición de carrera del trigger.
  - **Comprobación:** Implementado con retry de 3 intentos y fallback seguro en `lib/data/repositories/supabase_auth_repository.dart`.

- [x] **Tarea 3.3: Implementar `SupabaseAuthRepository.signIn` con validación y revocación (30 min)**
  - **Requisito funcional:** RF-04, RF-05, RF-06
  - **Descripción:** Implementar método de login que autentica credenciales, consulta `public.perfiles` y, si el rol es `CLIENTE` o `activo == false`, ejecuta de inmediato `client.auth.signOut()` antes de lanzar `UnauthorizedRoleFailure` o `AccountInactiveFailure`.
  - **Comprobación:** Implementado en `SupabaseAuthRepository.signIn`, ejecutando `signOut()` inmediato ante roles no web o usuarios inactivos.

- [x] **Tarea 3.4: Implementar `signOut()` y providers de datos en Riverpod (20 min)**
  - **Requisito funcional:** RF-05, RF-08
  - **Descripción:** Completar método de cierre de sesión en el repositorio y exponer `authRepositoryProvider` en `lib/data/providers/auth_providers.dart`.
  - **Comprobación:** `dart analyze lib/data/providers/auth_providers.dart` compila con 0 errores y expone `authRepositoryProvider` y `currentUserProfileProvider`.

---

## Fase 4: Capa de Presentación (Controlador y Estado Reactivo)
*Dependencias: Fase 3.*

- [x] **Tarea 4.1: Definir `AuthState` con estado `AuthEvaluatingRole` (15 min)**
  - **Requisito funcional:** RF-04, RF-05, RF-08
  - **Descripción:** Crear `lib/presentation/controllers/auth_state.dart` con estados inmutables: `AuthInitial`, `AuthLoading`, `AuthEvaluatingRole`, `Authenticated`, `Unauthenticated` y `AuthErrorState`.
  - **Comprobación:** `dart analyze lib/presentation/controllers/auth_state.dart` reporta 0 advertencias.

- [x] **Tarea 4.2: Implementar `AuthController` con Riverpod (30 min)**
  - **Requisito funcional:** RF-01 a RF-06
  - **Descripción:** Crear `lib/presentation/controllers/auth_controller.dart` como `Notifier<AuthState>` gestionando los métodos `register()`, `login()`, `logout()` y la rehidratación inicial de sesión.
  - **Comprobación:** `flutter test test/presentation/controllers/auth_controller_test.dart` pasa al 100% con 7 pruebas unitarias de ciclo de vida y roles.

---

## Fase 5: Enrutamiento y Guardias de Navegación (GoRouter)
*Dependencias: Fase 4.*

- [x] **Tarea 5.1: Crear vista neutral de carga `SplashLoadingScreen` (20 min)**
  - **Requisito funcional:** RF-08
  - **Descripción:** Crear `lib/presentation/screens/splash_loading_screen.dart` con diseño sobrio que muestre logotipo e indicador de carga mientras el estado sea `AuthInitial` o `AuthEvaluatingRole`.
  - **Comprobación:** `flutter test test/presentation/screens/splash_loading_screen_test.dart` pasa al 100% validando renderizado del indicador de progreso.

- [x] **Tarea 5.2: Actualizar `app_router.dart` con guards reactivos por rol (30 min)**
  - **Requisito funcional:** RF-03, RF-04, RF-07, RF-08
  - **Descripción:** Configurar `redirect` en `routerProvider` para consultar reactivamente `authControllerProvider` y redirigir `/` según rol, proteger `/dashboard-empresa`, proteger `/admin-panel` y manejar estado de carga neutral en F5.
  - **Comprobación:** `flutter test test/routing/app_router_guard_test.dart` pasa al 100% con 8 pruebas evaluando todos los escenarios de redirección.

---

## Fase 6: Desacoplamiento de Pantallas de UI (Presentation Layer)
*Dependencias: Fase 5. Asegura cumplimiento del Principio 3 de la Constitución.*

- [x] **Tarea 6.1: Refactorizar `RegisterScreen` a arquitectura limpia (25 min)**
  - **Requisito funcional:** RF-01, RF-03
  - **Descripción:** Reemplazar llamadas directas a Supabase en `lib/presentation/screens/register_screen.dart` por consumo de `ref.read(authControllerProvider.notifier).register(...)`, mostrando errores en SnackBar en español y bloqueando botón mientras carga.
  - **Comprobación:** Cero imports de `package:supabase_flutter` en `lib/presentation/screens/register_screen.dart` y formulario desacoplado y funcional.

- [x] **Tarea 6.2: Refactorizar `LoginScreen` a arquitectura limpia (25 min)**
  - **Requisito funcional:** RF-04, RF-05, RF-06
  - **Descripción:** Reemplazar llamadas directas a Supabase en `lib/presentation/screens/login_screen.dart` por consumo de `authControllerProvider.login(...)`, manejando estados de error en español y deshabilitación durante envío.
  - **Comprobación:** Cero imports de `package:supabase_flutter` en `lib/presentation/screens/login_screen.dart` y validación de credenciales.

- [x] **Tarea 6.3: Integrar acción de Logout en la interfaz de usuario (15 min)**
  - **Requisito funcional:** RF-05, RF-07
  - **Descripción:** Añadir botón o menú de "Cerrar sesión" en la cabecera/perfil de la aplicación web que dispare `authControllerProvider.logout()`.
  - **Comprobación:** Integrado en AppBar móvil y Sidebar de escritorio conectando directamente con `authControllerProvider.logout()`.

---

## Fase 7: Verificación Global y Criterios de Aceptación
*Dependencias: Todas las fases previas.*

- [x] **Tarea 7.1: Ejecutar suite de pruebas unitarias y análisis estático (20 min)**
  - **Requisito funcional:** RF-01 a RF-08 (Principios 4 y 6 de la Constitución)
  - **Descripción:** Ejecutar las herramientas de verificación estática y suite completa de pruebas unitarias para certificar 100% de éxito.
  - **Comprobación:** `flutter analyze lib/` retorna 0 errores y `flutter test` ejecuta 31 pruebas unitarias y de widgets con 100% de éxito en verde.
