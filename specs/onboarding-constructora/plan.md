# Plan Técnico de Implementación: Onboarding y Registro de Constructora

**Feature:** `onboarding-constructora`  
**Documento base:** [`specs/onboarding-constructora/spec.md`](file:///Users/diego/FlutterProjects/vihomeweb/specs/onboarding-constructora/spec.md)  
**Alineación Constitucional:** [`docs/constitution.md`](file:///Users/diego/FlutterProjects/vihomeweb/docs/constitution.md)  
**Estado:** Listo para desglose de tareas  

---

## 1. Estructura de Módulos y Capas

El desarrollo se organiza bajo la estricta separación de capas exigida por el **Principio 3 de la Constitución**:

```text
lib/
├── core/
│   └── errors/
│       └── auth_failure.dart              # Añade EmailNotConfirmedFailure y ConstructoraAlreadyExistsFailure
├── domain/
│   ├── models/
│   │   ├── perfil_usuario.dart            # Incorpora flag isCompleted
│   │   └── constructora_data.dart         # Entidad inmutable con datos de la constructora
│   └── repositories/
│       └── auth_repository.dart           # Contrato con completarOnboarding y reenviarConfirmacion
├── data/
│   ├── repositories/
│   │   └── supabase_auth_repository.dart  # Invoca RPC PostgreSQL y captura excepciones de correo
│   └── providers/
│       └── auth_providers.dart            # Expone providers de Riverpod
├── presentation/
│   ├── controllers/
│   │   ├── auth_state.dart                # Estados de autenticación existentes
│   │   └── auth_controller.dart           # Acciones de onboarding y reenvío de verificación
│   └── screens/
│       ├── login_screen.dart              # Maneja alerta de correo no confirmado y botón de reenvío
│       └── complete_profile_screen.dart   # Pantalla de onboarding con formulario corporativo y logout
└── routing/
    └── app_router.dart                    # Guards actualizados para /complete-profile

supabase/
└── migrations/
    └── 20261014_onboarding_constructora.sql # DDL: is_completed, constraints y función RPC

test/
├── core/errors/
│   └── auth_failure_test.dart             # Pruebas de nuevos subtipos de error
├── domain/models/
│   ├── perfil_usuario_test.dart           # Pruebas de isCompleted y serialización
│   └── constructora_data_test.dart        # Pruebas de validación de entidad constructora
├── presentation/controllers/
│   └── auth_controller_test.dart          # Pruebas de flujo de onboarding y reenvío
├── presentation/screens/
│   └── complete_profile_screen_test.dart  # Pruebas de UI y validación de formulario
└── routing/
    ├── app_router_guard_test.dart         # Pruebas de redirección pura a /complete-profile
    └── app_router_test.dart               # Pruebas de integración del router
```

---

## 2. Modelo de Datos y Contratos de Datos

### 2.1. Script de Base de Datos (`supabase/migrations/20261014_onboarding_constructora.sql`)

```sql
-- 1. Agregar campo is_completed en public.usuarios_web
ALTER TABLE public.usuarios_web
ADD COLUMN IF NOT EXISTS is_completed BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN public.usuarios_web.is_completed IS 'Indica si la constructora completó el onboarding corporativo';

-- 2. Asegurar constraints en public.contructora
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'contructora_id_user_key'
  ) THEN
    ALTER TABLE public.contructora ADD CONSTRAINT contructora_id_user_key UNIQUE (id_user);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'contructora_nit_key'
  ) THEN
    ALTER TABLE public.contructora ADD CONSTRAINT contructora_nit_key UNIQUE (nit);
  END IF;
END $$;

-- 3. Función RPC transaccional atómica para completar onboarding
CREATE OR REPLACE FUNCTION public.completar_onboarding_constructora(
  p_nit TEXT,
  p_nombre TEXT,
  p_telefono TEXT,
  p_direccion TEXT,
  p_ciudad TEXT DEFAULT NULL,
  p_departamento TEXT DEFAULT NULL,
  p_whatsap TEXT DEFAULT NULL,
  p_sitio_web TEXT DEFAULT NULL,
  p_logo_url TEXT DEFAULT NULL
) RETURNS public.usuarios_web
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_perfil public.usuarios_web;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Usuario no autenticado' USING ERRCODE = '42501';
  END IF;

  -- Insertar o actualizar constructora (idempotente)
  INSERT INTO public.contructora (
    id_user,
    nit,
    nombre,
    telefono_fijo,
    direccion,
    ciudad,
    departamento,
    whatsap,
    sitio_web,
    logo_url,
    correo
  ) VALUES (
    v_user_id,
    p_nit,
    p_nombre,
    p_telefono,
    p_direccion,
    p_ciudad,
    p_departamento,
    p_whatsap,
    p_sitio_web,
    p_logo_url,
    (SELECT email FROM public.usuarios_web WHERE id = v_user_id)
  )
  ON CONFLICT (id_user) DO UPDATE SET
    nit = EXCLUDED.nit,
    nombre = EXCLUDED.nombre,
    telefono_fijo = EXCLUDED.telefono_fijo,
    direccion = EXCLUDED.direccion,
    ciudad = EXCLUDED.ciudad,
    departamento = EXCLUDED.departamento,
    whatsap = EXCLUDED.whatsap,
    sitio_web = EXCLUDED.sitio_web,
    logo_url = EXCLUDED.logo_url,
    updated_at = now();

  -- Marcar perfil como completado
  UPDATE public.usuarios_web
  SET is_completed = true,
      updated_at = now()
  WHERE id = v_user_id
  RETURNING * INTO v_perfil;

  RETURN v_perfil;
END;
$$;

GRANT EXECUTE ON FUNCTION public.completar_onboarding_constructora TO authenticated;
```

### 2.2. Entidades Dart

#### `PerfilUsuario` (`lib/domain/models/perfil_usuario.dart`)
Se añade `isCompleted`:
```dart
class PerfilUsuario {
  final String id;
  final String email;
  final UserRole rol;
  final bool activo;
  final bool isCompleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PerfilUsuario({
    required this.id,
    required this.email,
    required this.rol,
    required this.activo,
    this.isCompleted = false,
    this.createdAt,
    this.updatedAt,
  });

  bool get isAccessGranted => activo && rol.isWebAuthorized;

  // Fábrica fromJson
  factory PerfilUsuario.fromJson(Map<String, dynamic> json) {
    return PerfilUsuario(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      rol: UserRole.fromString(json['rol'] as String?),
      activo: json['activo'] as bool? ?? true,
      isCompleted: json['is_completed'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'rol': rol.name.toUpperCase(),
    'activo': activo,
    'is_completed': isCompleted,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };

  PerfilUsuario copyWith({
    String? id,
    String? email,
    UserRole? rol,
    bool? activo,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PerfilUsuario(
      id: id ?? this.id,
      email: email ?? this.email,
      rol: rol ?? this.rol,
      activo: activo ?? this.activo,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

#### `ConstructoraData` (`lib/domain/models/constructora_data.dart`)
```dart
class ConstructoraData {
  final String nit;
  final String nombre;
  final String telefono;
  final String direccion;
  final String? ciudad;
  final String? departamento;
  final String? whatsapp;
  final String? sitioWeb;
  final String? logoUrl;

  const ConstructoraData({
    required this.nit,
    required this.nombre,
    required this.telefono,
    required this.direccion,
    this.ciudad,
    this.departamento,
    this.whatsapp,
    this.sitioWeb,
    this.logoUrl,
  });

  Map<String, dynamic> toRpcParams() => {
    'p_nit': nit.trim(),
    'p_nombre': nombre.trim(),
    'p_telefono': telefono.trim(),
    'p_direccion': direccion.trim(),
    if (ciudad != null && ciudad!.trim().isNotEmpty) 'p_ciudad': ciudad!.trim(),
    if (departamento != null && departamento!.trim().isNotEmpty) 'p_departamento': departamento!.trim(),
    if (whatsapp != null && whatsapp!.trim().isNotEmpty) 'p_whatsap': whatsapp!.trim(),
    if (sitioWeb != null && sitioWeb!.trim().isNotEmpty) 'p_sitio_web': sitioWeb!.trim(),
    if (logoUrl != null && logoUrl!.trim().isNotEmpty) 'p_logo_url': logoUrl!.trim(),
  };
}
```

---

## 3. Algoritmo Principal y Lógica de Redirección (GoRouter)

### 3.1. Matriz de Evaluación de Rutas (`authRedirectLogic`)

```dart
String? authRedirectLogic({
  required AuthState authState,
  required String path,
}) {
  final isPublicRoute =
      path == '/login' ||
      path == '/register' ||
      path == '/forgot-password' ||
      path == '/update-password' ||
      path == '/privacy' ||
      path == '/faq' ||
      path == '/terms';

  // 1. Estados iniciales de rehidratación
  if (authState is AuthInitial || authState is AuthEvaluatingRole) {
    if (path == '/splash') return null;
    return isPublicRoute ? null : '/splash';
  }

  // 2. Estados no autenticados o con error
  if (authState is Unauthenticated || authState is AuthErrorState) {
    if (path == '/splash' || path == '/complete-profile') return '/login';
    return isPublicRoute ? null : '/login';
  }

  // 3. Usuario autenticado
  if (authState is Authenticated) {
    final perfil = authState.perfil;

    // A. Rol ADMIN: acceso directo y exclusivo a panel
    if (perfil.rol == UserRole.admin) {
      if (path == '/admin-panel') return null;
      return '/admin-panel';
    }

    // B. Rol CONSTRUCTORA
    if (perfil.rol == UserRole.constructora) {
      // Caso B.1: Perfil incompleto -> Onboarding obligatorio
      if (!perfil.isCompleted) {
        if (path == '/complete-profile') return null;
        return '/complete-profile';
      }

      // Caso B.2: Perfil completo -> Dashboard habilitado
      if (path == '/login' ||
          path == '/register' ||
          path == '/splash' ||
          path == '/' ||
          path == '/complete-profile') {
        return '/dashboard-empresa';
      }

      // Proteger admin panel
      if (path == '/admin-panel') {
        return '/dashboard-empresa';
      }

      return null;
    }

    // Rol no autorizado (fallback de seguridad)
    return '/login';
  }

  return null;
}
```

---

## 4. Contratos de la Interfaz y Errores Tipados

### 4.1. Nuevos Subtipos de `AuthFailure` (`lib/core/errors/auth_failure.dart`)
```dart
/// Lanzado cuando el usuario intenta iniciar sesión pero su email no está verificado en Supabase.
class EmailNotConfirmedFailure extends AuthFailure {
  const EmailNotConfirmedFailure([
    super.message = 'Debes confirmar tu correo electrónico antes de iniciar sesión. Revisa tu bandeja de entrada o carpeta de spam.',
  ]);
}

/// Lanzado cuando el NIT ingresado ya pertenece a otra constructora registrada.
class ConstructoraAlreadyExistsFailure extends AuthFailure {
  const ConstructoraAlreadyExistsFailure([
    super.message = 'Ya existe una constructora registrada con este NIT.',
  ]);
}
```

### 4.2. Contrato `AuthRepository` (`lib/domain/repositories/auth_repository.dart`)
Se agregan los métodos:
```dart
abstract class AuthRepository {
  Stream<PerfilUsuario?> watchCurrentUser();
  Future<PerfilUsuario?> getCurrentProfile();
  Future<PerfilUsuario> registerConstructora({required String email, required String password});
  Future<PerfilUsuario> signIn({required String email, required String password});
  Future<void> signOut();

  /// Completa el onboarding corporativo invocando la RPC atómica en Supabase.
  Future<PerfilUsuario> completarOnboardingConstructora(ConstructoraData data);

  /// Solicita el reenvío del correo de confirmación de registro a Supabase Auth.
  Future<void> reenviarCorreoConfirmacion(String email);
}
```

### 4.3. Controlador de Presentación (`AuthController`)
```dart
Future<void> completarOnboarding(ConstructoraData data) async {
  state = const AuthLoading();
  try {
    final updatedProfile = await _repository.completarOnboardingConstructora(data);
    state = Authenticated(updatedProfile);
  } on AuthFailure catch (f) {
    state = AuthErrorState(f);
  } catch (e) {
    state = AuthErrorState(UnexpectedAuthFailure(e.toString()));
  }
}

Future<void> reenviarConfirmacion(String email) async {
  try {
    await _repository.reenviarCorreoConfirmacion(email);
  } on AuthFailure catch (f) {
    state = AuthErrorState(f);
  } catch (e) {
    state = AuthErrorState(UnexpectedAuthFailure(e.toString()));
  }
}
```

---

## 5. Dependencias y Versiones Verificadas

En estricto cumplimiento del **Principio 1 de la Constitución**, **no se agregarán nuevas dependencias a `pubspec.yaml`**. Se reutilizan exclusivamente las librerías existentes:
* `flutter_riverpod: ^2.6.1`
* `go_router: ^14.8.1`
* `supabase_flutter: ^2.8.4`

---

## 6. Estrategia de Validación y Pruebas Automatizadas

Siguiendo el enfoque **Test-Driven Development (TDD)** y el **Principio 4 de la Constitución**:

1. **Fase de Dominio:**
   - Pruebas unitarias para `isCompleted` en `PerfilUsuario` (serialización, inmutabilidad y `copyWith`).
   - Pruebas unitarias para `ConstructoraData` (mapeo de parámetros para la RPC).
   - Pruebas para los nuevos subtipos de `AuthFailure`.
2. **Fase de Datos y Fakes:**
   - Actualización de `FakeAuthRepository` con soporte para `completarOnboardingConstructora` y `reenviarCorreoConfirmacion`.
   - Implementación de `SupabaseAuthRepository` con captura de excepciones de confirmación de email y unicidad de NIT (código PostgreSQL `23505`).
3. **Fase de Controlador:**
   - Pruebas de `AuthController.completarOnboarding` pasando de perfil incompleto a completo.
   - Pruebas de login capturando `EmailNotConfirmedFailure`.
4. **Fase de Enrutamiento (Route Guards):**
   - Pruebas de redirección a `/complete-profile` si `!isCompleted`.
   - Pruebas de acceso permitido a `/dashboard-empresa` si `isCompleted`.
   - Pruebas de exención directa a `/admin-panel` para `ADMIN`.
   - Pruebas de revocación y expulsión para `CLIENTE` o usuarios inactivos en `/complete-profile`.
5. **Fase de UI:**
   - Pruebas de widget para `CompleteProfileScreen` validando campos obligatorios, estado de carga y botón de cerrar sesión.
