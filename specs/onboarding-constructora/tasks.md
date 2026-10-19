# Plan de Tareas: Onboarding y Registro de Constructora (HU 1.1)

**Documentos de referencia:** [`specs/onboarding-constructora/spec.md`](file:///Users/diego/FlutterProjects/vihomeweb/specs/onboarding-constructora/spec.md) | [`specs/onboarding-constructora/plan.md`](file:///Users/diego/FlutterProjects/vihomeweb/specs/onboarding-constructora/plan.md) | [`docs/constitution.md`](file:///Users/diego/FlutterProjects/vihomeweb/docs/constitution.md)  
**Estado general:** Pendiente de ejecución  

---

## Fase 1: Base de Datos y Persistencia Atómica (Supabase / Backend)
*Dependencias: Ninguna. Bloqueante para pruebas de integración reales.*

- [x] **Tarea 1.1: Script DDL de `is_completed` y constraints de unicidad (15 min)**
  - **Requisito funcional:** RF-02, RF-06, RF-07
  - **Descripción:** Crear `supabase/migrations/20261014_usuarios_web_schema_and_onboarding.sql` agregando la columna `is_completed` en `public.usuarios_web` y asegurando constraints `UNIQUE (id_user)` y `UNIQUE (nit)` en `public.contructora`.
  - **Comprobación:** Archivo de migración creado con sintaxis DDL idempotente sin alterar datos existentes.

- [x] **Tarea 1.2: Script de función RPC transaccional `completar_onboarding_constructora` (20 min)**
  - **Requisito funcional:** RF-06, RF-07
  - **Descripción:** Implementar función PL/pgSQL con `SECURITY DEFINER` que inserte/actualice en `public.contructora` y actualice `public.usuarios_web.is_completed = true` en una sola transacción atómica, retornando el perfil modificado.
  - **Comprobación:** Función definida en `supabase/migrations/20261014_usuarios_web_schema_and_onboarding.sql` con manejo de excepciones y `GRANT EXECUTE` para rol autenticado.

---

## Fase 2: Capa de Dominio (Modelos, Excepciones y Contratos)
*Dependencias: Fase 1.*

- [x] **Tarea 2.1: Actualizar `PerfilUsuario` con atributo `isCompleted` (20 min)**
  - **Requisito funcional:** RF-02, RF-03
  - **Descripción:** Actualizar `lib/domain/models/perfil_usuario.dart` incorporando `isCompleted` (default `false`), serialización `fromJson`/`toJson` y método `copyWith`.
  - **Comprobación:** `flutter test test/domain/models/perfil_usuario_test.dart` pasa al 100% verificando deserialización segura con y sin campo `is_completed`.

- [x] **Tarea 2.2: Implementar entidad `ConstructoraData` (15 min)**
  - **Requisito funcional:** RF-05, RF-06
  - **Descripción:** Crear `lib/domain/models/constructora_data.dart` con campos obligatorios (NIT, Razón Social, Teléfono, Dirección) y opcionales, con método `toRpcParams()`.
  - **Comprobación:** Crear `test/domain/models/constructora_data_test.dart` y verificar generación correcta de parámetros RPC.

- [x] **Tarea 2.3: Implementar fallos `EmailNotConfirmedFailure` y `ConstructoraAlreadyExistsFailure` (15 min)**
  - **Requisito funcional:** RF-01, RF-07
  - **Descripción:** Agregar los nuevos subtipos tipados en `lib/core/errors/auth_failure.dart` con mensajes descriptivos en español.
  - **Comprobación:** `flutter test test/core/errors/auth_failure_test.dart` pasa al 100% validando mensajes por defecto y personalizados.

- [x] **Tarea 2.4: Extender contrato `AuthRepository` (15 min)**
  - **Requisito funcional:** RF-01, RF-06
  - **Descripción:** Declarar las firmas `completarOnboardingConstructora(ConstructoraData data)` y `reenviarCorreoConfirmacion(String email)` en `lib/domain/repositories/auth_repository.dart`.
  - **Comprobación:** `dart analyze lib/domain/repositories/auth_repository.dart` compila con 0 advertencias.

---

## Fase 3: Capa de Datos y Soporte para Pruebas
*Dependencias: Fase 2.*

- [x] **Tarea 3.1: Actualizar `FakeAuthRepository` para soporte de onboarding y correo (20 min)**
  - **Requisito funcional:** Principio 4 de la Constitución
  - **Descripción:** Actualizar `test/helpers/fake_auth_repository.dart` simulando `completarOnboardingConstructora` (con actualización de `isCompleted` y simulación de NIT duplicado) y `reenviarCorreoConfirmacion`.
  - **Comprobación:** `flutter test test/helpers/fake_auth_repository_test.dart` pasa al 100% con los nuevos casos.

- [x] **Tarea 3.2: Implementar detección de correo no verificado en `SupabaseAuthRepository.signIn` y reenvío (25 min)**
  - **Requisito funcional:** RF-01
  - **Descripción:** En `lib/data/repositories/supabase_auth_repository.dart`, capturar `AuthException` con mensaje o código de correo no confirmado para lanzar `EmailNotConfirmedFailure`. Implementar `reenviarCorreoConfirmacion` usando `client.auth.resend`.
  - **Comprobación:** `dart analyze lib/data/repositories/supabase_auth_repository.dart` compila con 0 errores.

- [x] **Tarea 3.3: Implementar `SupabaseAuthRepository.completarOnboardingConstructora` (25 min)**
  - **Requisito funcional:** RF-06, RF-07
  - **Descripción:** Implementar la llamada RPC `completar_onboarding_constructora` en `SupabaseAuthRepository`, capturando violación de unicidad (código PostgreSQL `23505`) para lanzar `ConstructoraAlreadyExistsFailure`.
  - **Comprobación:** Implementado con mapeo de errores de base de datos a excepciones de dominio.

---

## Fase 4: Capa de Presentación (Controlador y Estado)
*Dependencias: Fase 3.*

- [x] **Tarea 4.1: Extender `AuthController` con onboarding y reenvío de correo (20 min)**
  - **Requisito funcional:** RF-01, RF-06
  - **Descripción:** Agregar en `lib/presentation/controllers/auth_controller.dart` los métodos `completarOnboarding(ConstructoraData data)` y `reenviarConfirmacion(String email)`.
  - **Comprobación:** `dart analyze lib/presentation/controllers/auth_controller.dart` reporta 0 advertencias.

- [x] **Tarea 4.2: Crear pruebas unitarias en `AuthController` para onboarding (25 min)**
  - **Requisito funcional:** RF-01, RF-06, RF-07
  - **Descripción:** Agregar pruebas en `test/presentation/controllers/auth_controller_test.dart` verificando:
    1. Login con correo sin confirmar emite `EmailNotConfirmedFailure`.
    2. `completarOnboarding` emite `Authenticated` con `isCompleted == true`.
    3. Error por NIT duplicado emite `AuthErrorState(ConstructoraAlreadyExistsFailure)`.
  - **Comprobación:** `flutter test test/presentation/controllers/auth_controller_test.dart` pasa al 100%.

---

## Fase 5: Enrutamiento y Guardias de Navegación (GoRouter)
*Dependencias: Fase 4.*

- [x] **Tarea 5.1: Actualizar `authRedirectLogic` para evaluar `isCompleted` y `/complete-profile` (25 min)**
  - **Requisito funcional:** RF-03, RF-04
  - **Descripción:** Actualizar la función pura `authRedirectLogic` en `lib/routing/app_router.dart`:
    - Constructoras con `!isCompleted` son forzadas a `/complete-profile`.
    - Constructoras con `isCompleted` en `/complete-profile` son redirigidas a `/dashboard-empresa`.
    - Usuarios anónimos en `/complete-profile` van a `/login`.
    - Admins van a `/admin-panel`.
  - **Comprobación:** `flutter test test/routing/app_router_guard_test.dart` pasa al 100% con todos los nuevos casos de onboarding.

- [x] **Tarea 5.2: Registrar ruta `/complete-profile` en `routerProvider` (15 min)**
  - **Requisito funcional:** RF-03
  - **Descripción:** Añadir `GoRoute(path: '/complete-profile', builder: ...)` en `lib/routing/app_router.dart`.
  - **Comprobación:** `app_router.dart` compila y expone la ruta sin conflictos de navegación.

- [x] **Tarea 5.3: Pruebas de integración del router para onboarding (20 min)**
  - **Requisito funcional:** RF-03, RF-04
  - **Descripción:** En `test/routing/app_router_test.dart`, agregar tests verificando que una sesión con `isCompleted: false` redirige automáticamente a `/complete-profile` y tras completar la constructora transiciona al dashboard.
  - **Comprobación:** `flutter test test/routing/app_router_test.dart` pasa al 100%.

---

## Fase 6: Pantallas de Interfaz de Usuario (Presentation Layer)
*Dependencias: Fase 5. Cumplimiento del Principio 3 de la Constitución.*

- [x] **Tarea 6.1: Actualizar `LoginScreen` con alerta y reenvío de confirmación (25 min)**
  - **Requisito funcional:** RF-01
  - **Descripción:** En `lib/presentation/screens/login_screen.dart`, detectar `EmailNotConfirmedFailure` para mostrar el mensaje correspondiente y ofrecer botón de reenvío con cooldown de 60 segundos.
  - **Comprobación:** `flutter test test/presentation/screens/login_screen_test.dart` o análisis estático limpio.

- [x] **Tarea 6.2: Crear pantalla de onboarding `CompleteProfileScreen` (30 min)**
  - **Requisito funcional:** RF-04, RF-05, RF-07
  - **Descripción:** Crear `lib/presentation/screens/complete_profile_screen.dart` desacoplada de Supabase:
    - Formulario con campos obligatorios (NIT, Razón Social, Teléfono, Dirección) y opcionales.
    - Botón de cierre de sesión accesible (`authControllerProvider.logout()`).
    - Deshabilitación de botón y spinner durante guardado.
    - Notificaciones en español con SnackBar.
  - **Comprobación:** `dart analyze lib/presentation/screens/complete_profile_screen.dart` compila con 0 errores.

- [x] **Tarea 6.3: Escribir pruebas de widget para `CompleteProfileScreen` (20 min)**
  - **Requisito funcional:** RF-04, RF-05, RF-07
  - **Descripción:** Crear `test/presentation/screens/complete_profile_screen_test.dart` validando renderizado de campos, validación de obligatorios al presionar submit y acción de logout.
  - **Comprobación:** `flutter test test/presentation/screens/complete_profile_screen_test.dart` pasa al 100%.

---

## Fase 7: Verificación Global y Criterios de Aceptación
*Dependencias: Todas las fases previas.*

- [x] **Tarea 7.1: Ejecutar suite de pruebas completa y análisis estático (20 min)**
  - **Requisito funcional:** RF-01 a RF-07 (Principios 4 y 6 de la Constitución)
  - **Descripción:** Ejecutar `flutter test` y `flutter analyze lib/ test/` para certificar el 100% de éxito en pruebas unitarias, de integración y análisis sin advertencias.
  - **Comprobación:** `flutter test` en verde con 100% de éxito y `flutter analyze` con 0 errores.

---

## Fase 8: Hallazgo de QA - Desacoplamiento de Registro y Verificación Previa Obligatoria
*Dependencias: Fases 1 a 7.*

- [x] **Tarea 8.1: Actualizar pruebas unitarias en `auth_controller_test.dart` (Test-First) (15 min)**
  - **Requisito funcional:** RF-08, Principio 4 de la Constitución
  - **Descripción:** Modificar la prueba de `register` en `test/presentation/controllers/auth_controller_test.dart` para verificar que emite `AuthLoading`, invoca `signOut()` y establece el estado en `Unauthenticated()` (en lugar de `Authenticated`).
  - **Comprobación:** Prueba escrita y en fallo (rojo) previo a la modificación del controlador.

- [x] **Tarea 8.2: Implementar desacoplamiento en `AuthController.register` y `SupabaseAuthRepository` (15 min)**
  - **Requisito funcional:** RF-08
  - **Descripción:** Actualizar `AuthController.register` para revocar sesión efímera con `_repository.signOut()`, retornar `Future<bool>` y emitir `const Unauthenticated()`. En `SupabaseAuthRepository.registerConstructora`, asegurar que cualquier sesión local generada por Supabase en `signUp` se cierre con `signOut()`.
  - **Comprobación:** `flutter test test/presentation/controllers/auth_controller_test.dart` pasa al 100%.

- [x] **Tarea 8.3: Diseñar experiencia de usuario en `RegisterScreen` con diálogo de verificación (20 min)**
  - **Requisito funcional:** RF-08, Principio 6 de la Constitución
  - **Descripción:** En `lib/presentation/screens/register_screen.dart`, al completar exitosamente el registro, mostrar un `AlertDialog` modal con ícono de verificación, mensaje claro en español indicando revisar el correo y botón para redirigir a `/login`.
  - **Comprobación:** Diálogo renderizado y navegación verificada hacia `/login`.

- [x] **Tarea 8.4: Crear pruebas de widget para `RegisterScreen` (20 min)**
  - **Requisito funcional:** RF-08, Principio 4 de la Constitución
  - **Descripción:** Crear `test/presentation/screens/register_screen_test.dart` validando que tras un registro exitoso se despliega el diálogo informativo y al pulsar el botón se redirige a `/login`.
  - **Comprobación:** `flutter test test/presentation/screens/register_screen_test.dart` pasa al 100%.

- [x] **Tarea 8.5: Verificación integral de la suite y análisis estático (15 min)**
  - **Requisito funcional:** Principio 4 de la Constitución
  - **Descripción:** Ejecutar `flutter test` y `flutter analyze lib/ test/` para certificar que todas las pruebas (incluidas las nuevas) pasan al 100% sin advertencias.
  - **Comprobación:** 0 errores de análisis y 100% de tests en verde.
