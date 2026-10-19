# Spec: Flujo de Verificación de Correo, Onboarding de Perfil y Registro de Constructora

**Feature:** `onboarding-constructora`  
**Historia de Usuario Asociada:** HU 1.1 (Notion)  
**Estado:** Aprobado para desarrollo (Hallazgos de QA Resueltos)  
**Documento Constitucional:** [docs/constitution.md](file:///Users/diego/FlutterProjects/vihomeweb/docs/constitution.md)

---

## 1. Contexto y Objetivo

En la plataforma **vihomeweb**, el autorregistro de empresas constructoras debe garantizar la veracidad de la cuenta mediante la verificación obligatoria de correo electrónico y asegurar que toda constructora registrada complete su información corporativa (NIT, Razón Social, Teléfono, Dirección) antes de obtener acceso operativo al panel de gestión y creación de proyectos.

**Objetivo:** Implementar la detección y bloqueo de cuentas con correo no verificado en el inicio de sesión, el mecanismo de guarda de navegación hacia la pantalla de onboarding obligatorio (`/complete-profile`), y la persistencia de datos corporativos en la tabla `public.contructora`, actualizando la completitud del perfil en `public.usuarios_web` de forma atómica para habilitar el acceso al panel `/dashboard-empresa`.

---

## 2. Requerimientos Funcionales

* **RF-01: Bloqueo de Inicio de Sesión por Correo no Confirmado:**
  * Si un usuario con credenciales correctas intenta iniciar sesión pero su correo no ha sido verificado en Supabase Auth (`email_confirmed_at IS NULL`), el sistema bloquea el ingreso capturando la excepción de autenticación (`AuthException` de confirmación pendiente), no persiste sesión en el cliente y muestra un mensaje claro en español:  
    *"Debes confirmar tu correo electrónico antes de iniciar sesión. Revisa tu bandeja de entrada o carpeta de spam."*
  * Se dispone de una acción para reenviar el correo de confirmación tomando el email ingresado en el formulario de login, aplicando un tiempo de espera (cooldown) de 60 segundos entre reintentos para evitar abusos.

* **RF-02: Bandera de Completitud de Perfil en `public.usuarios_web`:**
  * La entidad y tabla `public.usuarios_web` incorpora el atributo booleano `is_completed` (por defecto `false`).
  * Al registrarse un usuario con rol `CONSTRUCTORA`, su registro en `public.usuarios_web` se inicializa con `is_completed = false`.

* **RF-03: Guardia de Enrutamiento Obligatorio a Onboarding (`/complete-profile`):**
  * Para usuarios autenticados con rol `CONSTRUCTORA`:
    * Si `is_completed == false`: Cualquier intento de navegar a rutas protegidas (`/dashboard-empresa`, `/`) debe redirigir forzosamente a la pantalla de onboarding `/complete-profile`. El usuario no puede eludir esta pantalla por URL directa ni refresco de página (`F5`).
    * Si `is_completed == true`: Si intenta ingresar manualmente a `/complete-profile`, es redirigido automáticamente a `/dashboard-empresa`.
  * Los usuarios con rol `ADMIN` quedan exentos de este flujo y acceden directamente a `/admin-panel`.
  * Si un usuario anónimo intenta acceder a `/complete-profile`, es redirigido a `/login`.
  * Si un usuario con rol `CLIENTE` o cuenta inactiva (`activo == false`) intenta acceder a `/complete-profile`, el sistema revoca de inmediato la sesión (`signOut`) y lo expulsa a `/login` con el mensaje de rechazo correspondiente.

* **RF-04: Cierre Voluntario de Sesión desde Onboarding:**
  * La pantalla `/complete-profile` incluye una opción visible y accesible para cerrar sesión (*"Cerrar sesión"*), permitiendo al usuario desautenticarse limpiamente y regresar a `/login` si desea salir o ingresar con otra cuenta.

* **RF-05: Formulario de Registro Corporativo y Validaciones:**
  * El formulario en `/complete-profile` solicita y valida estrictamente:
    1. **NIT:** Obligatorio, mínimo 6 caracteres alfanuméricos, sanitizado con `trim()`.
    2. **Razón Social / Nombre:** Obligatorio, mínimo 3 caracteres, sanitizado con `trim()`.
    3. **Teléfono de Contacto:** Obligatorio, numérico, entre 7 y 15 dígitos.
    4. **Dirección Principal:** Obligatoria, mínimo 5 caracteres, sanitizada con `trim()`.
  * Campos adicionales opcionales:
    5. Ciudad.
    6. Departamento.
    7. Número de WhatsApp.
    8. Sitio Web corporativo.
    9. Logotipo (URL).

* **RF-06: Persistencia Atómica Transaccional en Base de Datos:**
  * Para evitar condiciones de carrera, inconsistencias de permisos RLS o datos huérfanos, la persistencia se realiza mediante una función PostgreSQL con `SECURITY DEFINER` (`public.completar_onboarding_constructora`):
    1. Valida que `auth.uid()` corresponda a un usuario autenticado y activo en `public.usuarios_web`.
    2. Inserta o actualiza (`UPSERT`) el registro en `public.contructora` asegurando la relación 1:1 (`UNIQUE (id_user)`).
    3. Actualiza atómicamente `is_completed = true` en `public.usuarios_web`.
    4. Si ocurre cualquier fallo o violación de constraint, efectúa un `ROLLBACK` completo.
  * Al completarse la función exitosamente:
    - Se actualiza el estado en memoria (`PerfilUsuario.isCompleted = true`).
    - GoRouter reevalúa los guards y transiciona de `/complete-profile` a `/dashboard-empresa`.

* **RF-07: Prevención de Duplicidad y Concurrencia:**
  * Si ya existe una constructora registrada con el mismo NIT para otro usuario, el sistema captura la restricción de unicidad y muestra: *"Ya existe una constructora registrada con este NIT."*
  * Durante el guardado, el botón principal se deshabilita y muestra un indicador de carga (`CircularProgressIndicator`) para bloquear peticiones concurrentes.

* **RF-08: Desacoplamiento de Registro y Onboarding mediante Verificación de Correo Obligatoria:**
  * Al registrar una constructora desde la pantalla `/register`, el sistema **no** debe iniciar sesión automáticamente ni redirigir al formulario de onboarding (`/complete-profile`).
  * El sistema asegura el cierre de cualquier sesión local no confirmada (`signOut`), manteniendo el estado de la aplicación en no autenticado (`Unauthenticated`).
  * La pantalla `/register` presenta un diálogo modal informativo en español indicando que se ha enviado un enlace de confirmación a su correo electrónico y que debe verificarlo antes de poder iniciar sesión.
  * Al confirmar o cerrar el diálogo, el usuario es redirigido a `/login`.
  * La pantalla `/complete-profile` es inaccesible hasta que el usuario verifique su correo en su cliente de email, inicie sesión por primera vez en `/login` (`signIn`), y el enrutador detecte `is_completed == false`.

---

## 3. Criterios de Aceptación (Escenarios Gherkin)

```gherkin
Característica: Verificación de correo, onboarding obligatorio y registro de constructora

  # -------------------------------------------------------------------------
  # FASE 0: REGISTRO Y REQUERIMIENTO DE VERIFICACIÓN
  # -------------------------------------------------------------------------
  Escenario: Registro de nueva constructora exige verificación de correo antes de login y onboarding
    Dado que una constructora ingresa sus credenciales en "/register"
    Cuando presiona el botón "Registrarse"
    Entonces el sistema crea la cuenta en Supabase Auth
    Y no inicia sesión en el cliente (estado permanece no autenticado)
    Y muestra un diálogo informativo: "Verifica tu correo: Hemos enviado un enlace de confirmación a tu correo electrónico."
    Y al presionar "Ir a Iniciar Sesión", el usuario es redirigido a "/login"
    Y la pantalla "/complete-profile" no es accesible hasta que verifique el correo e inicie sesión

  # -------------------------------------------------------------------------
  # FASE 1: VERIFICACIÓN DE EMAIL EN LOGIN
  # -------------------------------------------------------------------------
  Escenario: Intento de inicio de sesión con correo no confirmado
    Dado que un usuario se registró previamente con correo "empresa@constructora.com"
    Y aún no ha confirmado su correo electrónico ("email_confirmed_at" es nulo en Supabase Auth)
    Cuando ingresa su correo y contraseña en "/login" y presiona "Iniciar Sesión"
    Entonces el sistema bloquea el acceso
    Y no persiste sesión en el cliente web
    Y muestra la alerta: "Debes confirmar tu correo electrónico antes de iniciar sesión. Revisa tu bandeja de entrada o carpeta de spam."
    Y el usuario permanece en la pantalla "/login"

  Escenario: Inicio de sesión exitoso tras confirmar correo
    Dado que el usuario confirmó su correo mediante el enlace de activación
    Cuando inicia sesión con sus credenciales válidas en "/login"
    Entonces el sistema autentica la sesión exitosamente
    Y procede a evaluar el estado de completitud del perfil en "public.usuarios_web"

  # -------------------------------------------------------------------------
  # FASE 2: GUARDS DE ONBOARDING OBLIGATORIO
  # -------------------------------------------------------------------------
  Escenario: Redirección obligatoria a onboarding para constructora con perfil incompleto
    Dado que un usuario con rol "CONSTRUCTORA" tiene sesión activa y "is_completed = false"
    Cuando la aplicación resuelve la ruta inicial o el usuario intenta navegar a "/dashboard-empresa" o "/"
    Entonces el guardia de navegación intercepta la petición
    Y redirige forzosamente al usuario a la ruta "/complete-profile"
    Y la vista muestra el formulario de datos corporativos de la empresa

  Escenario: Intento de saltar onboarding mediante URL directa o recarga F5
    Dado que un usuario autenticado tiene su perfil con "is_completed = false"
    Cuando introduce manualmente en el navegador la URL "/dashboard-empresa" o recarga la página con F5
    Entonces el Route Guard valida el estado reactivo del perfil
    Y mantiene o redirige al usuario a "/complete-profile" sin permitir acceso al panel

  Escenario: Usuario con perfil completado intenta ingresar a /complete-profile
    Dado que un usuario con rol "CONSTRUCTORA" ya completó sus datos ("is_completed = true")
    Cuando navega directamente a la ruta "/complete-profile"
    Entonces el guardia de GoRouter lo redirige automáticamente a "/dashboard-empresa"

  Escenario: Usuario con rol ADMIN no requiere onboarding
    Dado que un usuario inicia sesión con rol "ADMIN" y estado activo
    Cuando la aplicación evalúa su ruta de entrada
    Entonces es redirigido directamente a "/admin-panel" sin pasar por "/complete-profile"

  Escenario: Cierre de sesión voluntario desde la pantalla de onboarding
    Dado que el usuario se encuentra en la pantalla "/complete-profile"
    Cuando presiona el botón "Cerrar sesión"
    Entonces el sistema ejecuta signOut en Supabase
    Y redirige al usuario a la pantalla "/login"

  Escenario: Usuario no autenticado intentando acceder a /complete-profile
    Dado que no existe una sesión activa en el cliente web
    Cuando un visitante intenta acceder a la URL "/complete-profile"
    Entonces el Route Guard intercepta la navegación y lo redirige a "/login"

  Escenario: Usuario con rol CLIENTE intentando acceder a /complete-profile
    Dado que un usuario tiene credenciales con rol "CLIENTE"
    Cuando intenta navegar a la URL "/complete-profile"
    Entonces el Route Guard revoca de inmediato la sesión y lo expulsa a "/login"
    Y muestra el mensaje: "Acceso denegado: Esta plataforma es exclusiva para constructoras y administradores."

  # -------------------------------------------------------------------------
  # FASE 3: FORMULARIO DE ONBOARDING Y PERSISTENCIA CORPORATIVA
  # -------------------------------------------------------------------------
  Escenario: Validación de campos obligatorios en formulario de onboarding
    Dado que el usuario está en "/complete-profile"
    Cuando presiona el botón "Guardar y Continuar" dejando vacíos NIT, Razón Social, Teléfono o Dirección
    Entonces el formulario no realiza la petición a Supabase
    Y resalta visualmente los campos vacíos con mensajes de error descriptivos en español
    Y el usuario permanece en "/complete-profile"

  Escenario: Guardado exitoso de información corporativa y desbloqueo del dashboard
    Dado que el usuario ingresa NIT, Razón Social, Teléfono y Dirección válidos en "/complete-profile"
    Cuando presiona el botón "Guardar y Continuar"
    Entonces el sistema invoca la función atómica de base de datos
    Y se inserta el registro en la tabla "public.contructora" con "id_user = auth.uid()"
    Y se actualiza "is_completed = true" en "public.usuarios_web"
    Y se actualiza el estado de la sesión en Riverpod
    Y el Route Guard redirige automáticamente al usuario a la ruta "/dashboard-empresa"
    Y muestra una notificación de éxito: "Datos de la empresa guardados correctamente."

  Escenario: Manejo de NIT duplicado por otra empresa
    Dado que otra constructora ya está registrada con el NIT "900123456-1"
    Cuando el usuario intenta guardar su empresa con ese mismo NIT
    Entonces la base de datos rechaza la inserción por constraint de unicidad
    Y el sistema captura el fallo mostrando: "Ya existe una constructora registrada con este NIT."
    Y el usuario permanece en "/complete-profile" con sus datos intactos para corregir el valor
```

---

## 4. Contrato de Datos y Supabase

### 4.1. Modificación a la Tabla `public.usuarios_web`
Se agrega la columna de completitud de onboarding:

```sql
ALTER TABLE public.usuarios_web
ADD COLUMN IF NOT EXISTS is_completed BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN public.usuarios_web.is_completed IS 'Indica si la constructora completó el onboarding corporativo';
```

### 4.2. Modificación a la Tabla Existente `public.contructora`
Se garantiza la relación 1 a 1 y unicidad de NIT:

```sql
-- Asegurar unicidad de usuario (1 constructora por cuenta)
ALTER TABLE public.contructora
ADD CONSTRAINT contructora_id_user_key UNIQUE (id_user);

-- Asegurar unicidad de NIT
ALTER TABLE public.contructora
ADD CONSTRAINT contructora_nit_key UNIQUE (nit);
```

### 4.3. Función Transaccional Atómica (`completar_onboarding_constructora`)
Para evitar conflictos de políticas RLS y garantizar atomicidad:

```sql
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
    RAISE EXCEPTION 'Usuario no autenticado';
  END IF;

  -- 1. Insertar o actualizar datos de la constructora (idempotente)
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

  -- 2. Actualizar estado de completitud en perfiles
  UPDATE public.usuarios_web
  SET is_completed = true,
      updated_at = now()
  WHERE id = v_user_id
  RETURNING * INTO v_perfil;

  RETURN v_perfil;
END;
$$;
```

---

## 5. Interfaz de Usuario y Experiencia (en Español)

En cumplimiento estricto del **Principio 6 de la Constitución**, toda la interacción se presenta en español neutro y formal.

### 5.1. Alertas en Pantalla de Login (`/login`)
* **Correo no verificado:**  
  *"Debes confirmar tu correo electrónico antes de iniciar sesión. Revisa tu bandeja de entrada o carpeta de spam."*
* **Acción secundaria:** Enlace/botón *"Reenviar correo de confirmación"*.
* **Confirmación de reenvío:** *"Correo de confirmación reenviado. Por favor revisa tu bandeja."*
* **Alerta de espera (Cooldown):** *"Por favor espera unos segundos antes de solicitar otro correo."*

### 5.2. Pantalla de Onboarding (`/complete-profile`)
* **Encabezado:**
  * Logotipo de Vihome.
  * Título: *"Configura tu Constructora"*
  * Subtítulo: *"Ingresa los datos corporativos de tu empresa para habilitar la gestión de proyectos"*
* **Botón de desconexión:** Botón superior *"Cerrar sesión"*.
* **Campos del formulario:**
  * **Razón Social:** placeholder *"Ej. Constructora Los Andes S.A.S."*, validación *"Ingresa la razón social de la empresa."*
  * **NIT:** placeholder *"Ej. 900123456-7"*, validación *"El NIT es obligatorio (mínimo 6 caracteres)."*
  * **Teléfono:** placeholder *"Ej. 6015551234 o 3001234567"*, validación *"Ingresa un teléfono válido de 7 a 15 dígitos."*
  * **Dirección:** placeholder *"Ej. Calle 100 # 15-20, Oficina 501"*, validación *"La dirección de la constructora es obligatoria."*
  * **Ciudad (Opcional):** placeholder *"Ej. Bogotá"*
  * **Departamento (Opcional):** placeholder *"Ej. Cundinamarca"*
  * **WhatsApp (Opcional):** placeholder *"Ej. 3001234567"*
  * **Sitio Web (Opcional):** placeholder *"https://www.constructora.com"*
* **Acción principal:**
  * Botón *"Guardar y Continuar"* (bloqueado y con spinner durante el envío).
* **Notificaciones SnackBar:**
  * Éxito: *"Constructora registrada exitosamente. Bienvenido a Vihome."*
  * Error general: *"Ocurrió un error al registrar la empresa. Inténtalo de nuevo."*
  * NIT Duplicado: *"Ya existe una constructora registrada con este NIT."*

---

## 6. Plan de Pruebas Automatizadas

Siguiendo el **Principio 4 de la Constitución**, se implementarán pruebas unitarias y de widgets que garanticen el 100% de cobertura sobre las nuevas reglas:

### 6.1. Pruebas Unitarias de Dominio y Modelos
1. **`PerfilUsuario`:**
   - Deserialización de `is_completed` desde JSON (por defecto `false` si es null o no existe).
   - Serialización de `is_completed` hacia JSON.
   - Método `copyWith` que preserve o actualice `isCompleted`.
2. **Entidad `Constructora`:**
   - Deserialización y serialización correcta desde/hacia la estructura de `contructora`.
   - Validación de campos requeridos y formatos.
3. **`AuthFailure`:**
   - Subtipo tipado `EmailNotConfirmedFailure` con mensaje descriptivo en español.
   - Subtipo tipado `ConstructoraAlreadyExistsFailure` para colisión de NIT.

### 6.2. Pruebas de Repositorio y Controlador
1. **`AuthRepository.signIn`:**
   - Retorno / lanzamiento de `EmailNotConfirmedFailure` cuando Supabase Auth indique que el email no está confirmado.
2. **`AuthRepository.completarPerfilConstructora`:**
   - Registro exitoso de la constructora en la base de datos y retorno del perfil actualizado con `isCompleted == true`.
   - Manejo de error de duplicidad de NIT.
3. **`AuthController`:**
   - Flujo de login con correo no verificado emite `AuthErrorState(EmailNotConfirmedFailure)`.
   - Método `completarOnboarding(...)` transiciona el estado de `Authenticated(isCompleted: false)` a `Authenticated(isCompleted: true)`.

### 6.3. Pruebas de Guards de GoRouter (`app_router_guard_test.dart` y `app_router_test.dart`)
1. Usuario autenticado con rol `CONSTRUCTORA` y `isCompleted: false` en `/dashboard-empresa` redirige a `/complete-profile`.
2. Usuario autenticado con rol `CONSTRUCTORA` y `isCompleted: false` en `/complete-profile` permanece en ella (`null`).
3. Usuario autenticado con rol `CONSTRUCTORA` y `isCompleted: true` en `/complete-profile` redirige a `/dashboard-empresa`.
4. Usuario autenticado con rol `ADMIN` en `/` o `/login` redirige a `/admin-panel` sin pasar por `/complete-profile`.
5. Usuario anónimo en `/complete-profile` redirige a `/login`.
6. Usuario con rol `CLIENTE` en `/complete-profile` es revocado y redirigido a `/login`.
