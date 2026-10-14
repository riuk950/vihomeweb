# Plan Técnico de Implementación: Control de Registro y Acceso por Roles

**Feature:** `auth-roles`  
**Documento base:** `specs/auth-roles/spec.md`  
**Alineación:** `docs/constitution.md`  
**Estado:** Listo para desarrollo  

---

## 1. Estructura de Módulos y Capas

El desarrollo se organiza bajo los principios de Arquitectura Limpia y separación estricta exigidos por el **Principio 3 de la Constitución**, respetando el árbol de carpetas de `vihomeweb`:

```text
lib/
├── core/
│   ├── errors/
│   │   └── auth_failure.dart           # Excepciones de negocio tipadas en español
│   └── theme/
│       └── ...
├── domain/
│   ├── models/
│   │   ├── user_role.dart              # Enum de roles: constructora, admin, cliente, desconocido
│   │   └── perfil_usuario.dart         # Entidad de dominio inmutable
│   └── repositories/
│       └── auth_repository.dart        # Contrato abstracto del repositorio de autenticación
├── data/
│   ├── repositories/
│   │   └── supabase_auth_repository.dart # Implementación concreta contra Supabase
│   └── providers/
│       └── auth_providers.dart         # Providers de Riverpod (repositorio, controller, router)
├── presentation/
│   ├── controllers/
│   │   ├── auth_state.dart             # Estados de autenticación (unauthenticated, loading, etc.)
│   │   └── auth_controller.dart        # Notifier que orquesta la lógica y mutaciones
│   └── screens/
│       ├── login_screen.dart           # Vista pura (sin llamadas directas a Supabase)
│       ├── register_screen.dart        # Vista pura de registro
│       └── splash_loading_screen.dart  # Vista neutral de rehidratación/carga
└── routing/
    └── app_router.dart                 # GoRouter con guards y redirección reactiva

test/
├── domain/
│   └── models/
│       └── perfil_usuario_test.dart    # Pruebas de serialización y reglas de rol
├── presentation/
│   └── controllers/
│       └── auth_controller_test.dart   # Pruebas de lógica con FakeAuthRepository
└── routing/
    └── app_router_guard_test.dart      # Pruebas unitarias de redirección de rutas
```

---

## 2. Modelo de Datos y Contratos de Datos

### 2.1. Contrato en Base de Datos (Supabase / PostgreSQL)

```sql
-- Tabla: public.perfiles
CREATE TABLE IF NOT EXISTS public.perfiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  rol TEXT NOT NULL DEFAULT 'CONSTRUCTORA' CHECK (rol IN ('CONSTRUCTORA', 'ADMIN', 'CLIENTE')),
  activo BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Trigger de integridad: creación automática al registrarse en auth.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.perfiles (id, email, rol, activo)
  VALUES (new.id, new.email, 'CONSTRUCTORA', true)
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Políticas RLS
ALTER TABLE public.perfiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuarios pueden leer su propio perfil"
  ON public.perfiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Admins pueden leer todos los perfiles"
  ON public.perfiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.perfiles p
      WHERE p.id = auth.uid() AND p.rol = 'ADMIN' AND p.activo = true
    )
  );
```

### 2.2. Esquema JSON de Transferencia
Representación del payload entre Supabase y la capa Data:
```json
{
  "id": "3e0d872b-594c-817b-bc27-0002f38581cd",
  "email": "contacto@constructora.com",
  "rol": "CONSTRUCTORA",
  "activo": true,
  "created_at": "2026-10-07T16:00:00.000Z",
  "updated_at": "2026-10-07T16:00:00.000Z"
}
```

### 2.3. Entidades de Dominio en Dart

* **Enum `UserRole`**:
  * Valores: `constructora`, `admin`, `cliente`, `desconocido`.
  * Conversor desde String: insensible a mayúsculas/minúsculas con fallback seguro a `desconocido`.
  * Propiedad booleana `isWebAuthorized`: `true` únicamente si es `constructora` o `admin`.

* **Entidad inmutable `PerfilUsuario`**:
  * Propiedades:
    * `final String id;`
    * `final String email;`
    * `final UserRole rol;`
    * `final bool activo;`
    * `final DateTime createdAt;`
    * `final DateTime updatedAt;`
  * Métodos de utilidad:
    * `bool get isAccessGranted => rol.isWebAuthorized && activo;`
  * Mapeo: `PerfilUsuario.fromJson(Map<String, dynamic> json)` y `Map<String, dynamic> toJson()`.

---

## 3. Algoritmos Principales

### 3.1. Algoritmo de Registro Web con Manejo de Race Condition
Resuelve el hallazgo de QA sobre latencia del trigger de base de datos y duplicidad de correos.

```text
Entrada: email (String), password (String)
Salida: PerfilUsuario autenticado o AuthFailure

Paso 1: Validar formato local en cliente:
        - Correo válido mediante regex estándar RFC 5322.
        - Contraseña no vacía, >= 6 caracteres, <= 64 caracteres.
        Si falla: emitir AuthFailure.invalidInput con mensaje en español.

Paso 2: Invocar Supabase Auth: client.auth.signUp(email, password).
        - Si captura AuthException con código 'user_already_exists':
          Emitir AuthFailure.userAlreadyExists("Este correo ya se encuentra registrado.").

Paso 3: Obtener ID del usuario creado (userId).
        Si la sesión es nula (requiere confirmación según Supabase):
          Emitir AuthFailure.emailConfirmationRequired("Por favor verifica tu correo para continuar.").

Paso 4: Recuperación de Perfil con Reintento Seguro (Mitigación Race Condition):
        Definir intentos = 3, espera = 300ms.
        Bucle (intento = 1 hasta 3):
          Consultar public.perfiles por id = userId.
          Si existe registro:
            Mapear a PerfilUsuario y Salir del bucle con éxito.
          Si no existe y quedan intentos:
            Esperar 300ms y reintentar.
        Si tras 3 intentos no existe:
          Emitir AuthFailure.profileNotFound("No se pudo inicializar el perfil de constructora.").

Paso 5: Actualizar estado en AuthController a AuthState.authenticated(perfil).
        GoRouter reacciona y redirige a '/dashboard-empresa'.
```

### 3.2. Algoritmo de Inicio de Sesión y Revocación Preventiva
Resuelve el hallazgo de QA sobre fuga de tokens y parpadeo visual en usuarios con rol `CLIENTE` o cuentas inactivas.

```text
Entrada: email (String), password (String)
Salida: PerfilUsuario o AuthFailure

Paso 1: AuthController transiciona a AuthState.loading().

Paso 2: Invocar client.auth.signInWithPassword(email, password).
        Si falla por credenciales incorrectas:
          Emitir AuthFailure.invalidCredentials("Correo o contraseña incorrectos.").

Paso 3: AuthController transiciona a AuthState.evaluatingRole() 
        (Estado intermedio que mantiene la UI en espera y BLOQUEA la navegación a rutas privadas).

Paso 4: Consultar public.perfiles WHERE id = user.id.
        Si perfil no existe o rol == UserRole.desconocido:
          Ejecutar client.auth.signOut().
          Emitir AuthFailure.unauthorizedRole("Tu cuenta no tiene un rol configurado para la plataforma web.").

Paso 5: Evaluar rol y estado:
        Caso A: rol == UserRole.cliente
          Ejecutar client.auth.signOut().
          Emitir AuthFailure.unauthorizedRole("Acceso denegado: Esta plataforma es exclusiva para constructoras y administradores.").
        
        Caso B: activo == false
          Ejecutar client.auth.signOut().
          Emitir AuthFailure.accountInactive("Tu cuenta se encuentra inactiva. Comunícate con soporte.").

        Caso C: rol in (constructora, admin) Y activo == true
          Persistir en memoria el PerfilUsuario activo.
          Transicionar a AuthState.authenticated(perfil).
          GoRouter evalúa destino:
            - Si rol == constructora -> '/dashboard-empresa'
            - Si rol == admin        -> '/admin-panel'
```

### 3.3. Algoritmo de Guards de Enrutamiento y Rehidratación (F5)
Resuelve el hallazgo de QA sobre parpadeos, deep links, timeout de red y ruta raíz `/`.

```text
Entradas de Redirección (BuildContext context, GoRouterState state):
Ruta actual: state.matchedLocation
Estado de Auth: authState

1. Si authState es AuthState.initial() o AuthState.evaluatingRole():
   - Si la ruta solicitada no es pública (login/registro/etc.):
     Mostrar vista neutral SplashLoadingScreen (evita parpadeo y redirección prematura).
   - Retornar null (mantener en espera hasta resolución).

2. Si la consulta de rehidratación excede 7 segundos (Timeout de red):
   - AuthController transiciona a AuthState.networkError("Tiempo de espera agotado al conectar con el servidor.").
   - Redirigir a '/login' mostrando notificación de error.

3. Si authState es AuthState.unauthenticated() o AuthState.error():
   - Si la ruta actual es una ruta protegida ('/dashboard-empresa', '/admin-panel', etc.):
     Retornar '/login'.
   - Si navega a la raíz '/':
     Retornar '/login'.
   - Si la ruta es pública ('/login', '/register', '/privacy', '/faq', '/terms'):
     Retornar null (permitir acceso).

4. Si authState es AuthState.authenticated(perfil):
   - Si navega a la raíz '/' o a rutas de login/registro ('/login', '/register'):
     Retornar perfil.rol == admin ? '/admin-panel' : '/dashboard-empresa'.
   - Si navega a '/admin-panel' y perfil.rol != admin:
     Notificar denegación de permisos y retornar '/dashboard-empresa'.
   - En cualquier otra ruta autorizada:
     Retornar null (permitir renderizado).
```

---

## 4. Contratos de la Interfaz Técnica

### 4.1. Contrato del Repositorio (`AuthRepository`)
```dart
abstract interface class AuthRepository {
  /// Emite cambios reactivos del perfil de usuario autenticado
  Stream<PerfilUsuario?> watchCurrentUser();

  /// Consulta el perfil del usuario actual en memoria o BD
  Future<PerfilUsuario?> getCurrentProfile();

  /// Registra una nueva constructora
  Future<PerfilUsuario> registerConstructora({
    required String email,
    required String password,
  });

  /// Inicia sesión y valida rol autorizado
  Future<PerfilUsuario> signIn({
    required String email,
    required String password,
  });

  /// Cierra sesión voluntariamente y limpia almacenamiento local
  Future<void> signOut();
}
```

### 4.2. Contrato de Fallos de Negocio (`AuthFailure`)
```dart
sealed class AuthFailure {
  final String message;
  const AuthFailure(this.message);
}

final class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure([String msg = 'Correo o contraseña incorrectos.']) : super(msg);
}

final class UnauthorizedRoleFailure extends AuthFailure {
  const UnauthorizedRoleFailure([String msg = 'Acceso denegado: Esta plataforma es exclusiva para constructoras y administradores.']) : super(msg);
}

final class AccountInactiveFailure extends AuthFailure {
  const AccountInactiveFailure([String msg = 'Tu cuenta se encuentra inactiva. Comunícate con soporte.']) : super(msg);
}

final class UserAlreadyExistsFailure extends AuthFailure {
  const UserAlreadyExistsFailure([String msg = 'Este correo ya se encuentra registrado.']) : super(msg);
}

final class NetworkFailure extends AuthFailure {
  const NetworkFailure([String msg = 'Error de conexión con el servidor. Inténtalo más tarde.']) : super(msg);
}

final class UnexpectedAuthFailure extends AuthFailure {
  const UnexpectedAuthFailure([String msg = 'Ocurrió un error inesperado.']) : super(msg);
}
```

### 4.3. Contrato de Estado de Presentación (`AuthState`)
```dart
sealed class AuthState {
  const AuthState();
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthEvaluatingRole extends AuthState {
  const AuthEvaluatingRole();
}

final class Authenticated extends AuthState {
  final PerfilUsuario perfil;
  const Authenticated(this.perfil);
}

final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

final class AuthErrorState extends AuthState {
  final AuthFailure failure;
  const AuthErrorState(this.failure);
}
```

---

## 5. Dependencias con Versiones Verificadas

En estricto cumplimiento del **Principio 1 de la Constitución** (Simplicidad del Stack), **no se agrega ningún paquete externo**. Se utilizan exclusivamente las dependencias ya instaladas y verificadas directamente en `pubspec.lock`:

| Dependencia | Versión Verificada (`pubspec.lock`) | Propósito Técnico |
| :--- | :--- | :--- |
| `flutter` | SDK Flutter | Framework base |
| `flutter_riverpod` | `3.2.1` | Gestión de estado reactivo y desacoplamiento de capas |
| `supabase_flutter` | `2.12.0` | Cliente de Supabase Auth, PostgreSQL y RLS |
| `go_router` | `17.1.0` | Enrutamiento declarativo para web con guards de navegación |
| `web` | `1.1.1` | Interoperabilidad web estándar en Dart |
| `flutter_lints` | `5.0.0` | Análisis estático del código base |
| `flutter_test` | SDK Flutter | Ejecución de pruebas unitarias y de widgets |

> **Nota arquitectónica de pruebas:** Para simular las operaciones de Supabase en las pruebas unitarias, se implementarán clases de prueba simuladas (*Fakes*) directamente implementando `AuthRepository` (ej. `FakeAuthRepository`), eliminando por completo la necesidad de añadir librerías pesadas como `mockito` o `build_runner`.

---

## 6. Estrategia de Validación con Tests

Conforme al **Principio 4 de la Constitución** (`flutter test` obligatorio al 100% en verde):

### 6.1. Matriz de Pruebas Unitarias

| Componente | Caso de Prueba | Entrada | Resultado Esperado |
| :--- | :--- | :--- | :--- |
| `PerfilUsuario` | Deserialización JSON válida | JSON con rol `CONSTRUCTORA` y `activo: true` | Objeto válido, `isAccessGranted == true` |
| `PerfilUsuario` | Rol no reconocido | JSON con rol `DESCONOCIDO_XYZ` | Rol mapeado a `UserRole.desconocido`, `isAccessGranted == false` |
| `PerfilUsuario` | Cuenta inactiva | JSON con `activo: false` | `isAccessGranted == false` |
| `AuthController` | Login exitoso Constructora | Correo y pass válidos | Emite `Authenticated` con rol constructora |
| `AuthController` | Login exitoso Admin | Correo y pass de Admin | Emite `Authenticated` con rol admin |
| `AuthController` | Rechazo rol Cliente | Correo de cliente móvil | Ejecuta `signOut`, emite `AuthErrorState(UnauthorizedRoleFailure)` |
| `AuthController` | Rechazo cuenta inactiva | Usuario inactivo | Ejecuta `signOut`, emite `AuthErrorState(AccountInactiveFailure)` |
| `AuthController` | Error credenciales | Clave incorrecta | Emite `AuthErrorState(InvalidCredentialsFailure)` |
| `AppRouter` | Acceso anónimo a dashboard | Ruta `/dashboard-empresa` sin auth | Redirección obligatoria a `/login` |
| `AppRouter` | Constructora intenta ruta Admin | Ruta `/admin-panel` con rol constructora | Redirección a `/dashboard-empresa` |
| `AppRouter` | Usuario autenticado en login | Ruta `/login` con rol constructora | Redirección a `/dashboard-empresa` |
| `AppRouter` | Ruta raíz `/` | Anónimo vs autenticado | Anónimo $\rightarrow$ `/login`, Autenticado $\rightarrow$ Dashboard según rol |

### 6.2. Criterio de Verificación de Entrega
Antes de considerar aprobada la implementación técnica:
```bash
flutter test
dart analyze
```
Ambos comandos deben reportar cero fallos y cero advertencias críticas.
