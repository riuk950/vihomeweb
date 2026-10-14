# Spec: Control de Registro y Acceso por Roles (Constructora y Admin)

**Feature:** `auth-roles`  
**Historia de Usuario Asociada:** HU 1.0 (Notion)  
**Estado:** Aprobado para desarrollo  

---

## 1. Contexto y Objetivo

La plataforma **vihomeweb** es una solución web de gestión y administración inmobiliaria orientada exclusivamente a empresas constructoras y administradores del sistema. Los clientes finales y compradores interactúan únicamente a través del ecosistema móvil.

**Objetivo:** Garantizar que el autorregistro en el portal web asigne de forma inmutable el rol de `CONSTRUCTORA`, y que el mecanismo de autenticación y navegación restrinja el acceso únicamente a usuarios autorizados y activos con roles `CONSTRUCTORA` o `ADMIN`, bloqueando y revocando cualquier intento de inicio de sesión de roles no autorizados (como `CLIENTE`).

---

## 2. Requerimientos Funcionales

* **RF-01: Autorregistro Web de Constructora:** El formulario público de registro debe solicitar credenciales básicas (correo electrónico y contraseña con confirmación). Al registrarse, el sistema crea la cuenta y le asigna obligatoriamente el rol `CONSTRUCTORA` y estado `activo = true`.
* **RF-02: Protección contra Manipulación de Rol en Registro:** El cliente web no puede determinar ni enviar el rol en la solicitud de creación de cuenta; la asignación del rol `CONSTRUCTORA` debe ser forzada por la lógica del servidor/base de datos (mediante trigger o política en Supabase).
* **RF-03: Inicio de Sesión Automático tras Registro:** Una vez completado exitosamente el registro, el sistema autentica al usuario sin requerir confirmación previa de correo para este MVP, redirigiéndolo de inmediato a la ruta `/dashboard-empresa`.
* **RF-04: Control de Acceso por Roles en Login:** 
  * Usuarios con rol `CONSTRUCTORA` y estado activo son redirigidos a `/dashboard-empresa`.
  * Usuarios con rol `ADMIN` y estado activo son redirigidos a `/admin-panel`.
* **RF-05: Restricción y Revocación para Rol CLIENTE:** Si un usuario con rol `CLIENTE` u otro rol no web intenta autenticarse con credenciales válidas, el sistema debe revocar de inmediato la sesión en el cliente (`signOut` en Supabase), impedir la persistencia del token y presentar un mensaje de acceso denegado.
* **RF-06: Verificación de Estado Activo:** Si un usuario con credenciales correctas y rol permitido tiene su cuenta inactiva (`activo = false`), se debe denegar el acceso, cerrar la sesión y mostrar un mensaje informativo en español.
* **RF-07: Protección de Rutas Web (Guards):** Las rutas protegidas (`/dashboard-empresa`, `/admin-panel`) deben validar que exista una sesión activa con el rol adecuado. Si un usuario no autenticado o no autorizado intenta acceder por URL directa, se debe interceptar y redirigir adecuadamente.
* **RF-08: Gestión de Recarga de Página (Refresh F5 / Deep Links):** Durante el proceso de rehidratación de sesión y consulta del perfil/rol, la aplicación debe mostrar una pantalla de carga o indicador visual limpio, evitando parpadeos o redirecciones prematuras a `/login`.

---

## 3. Criterios de Aceptación (Gherkin)

```gherkin
Característica: Control de Registro y Acceso por Roles en vihomeweb

  # -------------------------------------------------------------------------
  # REGISTRO WEB
  # -------------------------------------------------------------------------
  Escenario: Registro exitoso de una nueva constructora
    Dado que un usuario anónimo se encuentra en la pantalla de registro "/registro"
    Cuando ingresa un correo electrónico válido y una contraseña que cumple los requisitos
    Y confirma la contraseña de manera coincidente
    Y presiona el botón "Crear cuenta"
    Entonces el sistema crea la cuenta en Supabase Auth
    Y crea el registro correspondiente en la tabla pública de perfiles con rol "CONSTRUCTORA" y estado activo
    Y el usuario queda autenticado automáticamente
    Y es redirigido a la ruta "/dashboard-empresa"

  Escenario: Prevención de manipulación de rol durante el registro
    Dado que un usuario o atacante intenta enviar un parámetro de rol "ADMIN" en la petición de registro
    Cuando el backend de Supabase procesa el nuevo registro
    Entonces el rol asignado en la base de datos es forzosamente "CONSTRUCTORA"
    Y bajo ninguna circunstancia se le asignan privilegios de "ADMIN"

  # -------------------------------------------------------------------------
  # INICIO DE SESIÓN (LOGIN) POR ROL
  # -------------------------------------------------------------------------
  Escenario: Inicio de sesión exitoso de usuario con rol CONSTRUCTORA
    Dado que existe un usuario registrado con rol "CONSTRUCTORA" y estado activo
    Cuando ingresa su correo y contraseña válidos en "/login"
    Y presiona el botón "Iniciar sesión"
    Entonces el sistema valida las credenciales y el rol en Supabase
    Y redirige al usuario a "/dashboard-empresa"

  Escenario: Inicio de sesión exitoso de usuario con rol ADMIN
    Dado que existe un usuario registrado con rol "ADMIN" y estado activo
    Cuando ingresa su correo y contraseña válidos en "/login"
    Y presiona el botón "Iniciar sesión"
    Entonces el sistema valida las credenciales y el rol en Supabase
    Y redirige al usuario a "/admin-panel"

  Escenario: Denegación de acceso y revocación inmediata de sesión para rol CLIENTE
    Dado que existe un usuario con credenciales válidas en Supabase pero con rol "CLIENTE"
    Cuando ingresa sus credenciales en la pantalla "/login" de la web
    Entonces el sistema detecta que el rol no está autorizado para la plataforma web
    Y ejecuta inmediatamente el cierre de sesión ("signOut") en el cliente
    Y no persiste tokens ni sesión en el navegador
    Y muestra el mensaje de error: "Acceso denegado: Esta plataforma es exclusiva para constructoras y administradores."
    Y el usuario permanece en la pantalla de inicio de sesión

  Escenario: Intento de inicio de sesión de cuenta inactiva o suspendida
    Dado que un usuario posee rol "CONSTRUCTORA" o "ADMIN" pero su campo "activo" es falso
    Cuando intenta iniciar sesión con credenciales correctas en "/login"
    Entonces el sistema cierra la sesión inmediatamente
    Y muestra el mensaje de error: "Tu cuenta se encuentra inactiva. Comunícate con el soporte de Vihome."
    Y el usuario permanece en la pantalla de inicio de sesión

  # -------------------------------------------------------------------------
  # PROTECCIÓN DE RUTAS Y NAVEGACIÓN
  # -------------------------------------------------------------------------
  Escenario: Intento de acceso directo por URL a ruta protegida sin autenticación
    Dado que un usuario anónimo intenta acceder directamente a la URL "/dashboard-empresa" o "/admin-panel"
    Cuando la aplicación carga la ruta
    Entonces el guardia de navegación intercepta la petición
    Y redirige al usuario a la pantalla "/login"

  Escenario: Intento de acceso de rol CONSTRUCTORA a ruta reservada para ADMIN
    Dado que un usuario tiene sesión iniciada con rol "CONSTRUCTORA"
    Cuando introduce manualmente en la barra del navegador la ruta "/admin-panel"
    Entonces el guardia de navegación deniega la entrada
    Y redirige al usuario a su ruta correspondiente "/dashboard-empresa"
    Y muestra una notificación informativa en español: "No tienes permisos para acceder a esta sección."

  Escenario: Recarga de navegador (F5) en ruta protegida con sesión activa
    Dado que un usuario con rol "CONSTRUCTORA" está en la ruta "/dashboard-empresa"
    Cuando recarga la pestaña del navegador
    Entonces la aplicación muestra una pantalla de carga neutral mientras valida la sesión y perfil
    Y al confirmar la validez de la sesión, permanece en "/dashboard-empresa" sin forzar reautenticación
```

---

## 4. Contrato de Datos y Supabase

### 4.1. Estructura de la Tabla `public.perfiles`
La fuente de verdad del rol y del estado del usuario reside en la base de datos de Supabase, en la tabla pública vinculada a `auth.users`:

| Campo | Tipo | Restricciones / Default | Descripción |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` | PK, References `auth.users(id)` ON DELETE CASCADE | Identificador único del usuario de auth. |
| `email` | `TEXT` | NOT NULL | Correo electrónico del usuario. |
| `rol` | `TEXT` | NOT NULL, DEFAULT `'CONSTRUCTORA'`, CHECK in (`'CONSTRUCTORA'`, `'ADMIN'`, `'CLIENTE'`) | Rol que determina los accesos en el sistema. |
| `activo` | `BOOLEAN` | NOT NULL, DEFAULT `true` | Estado operativo de la cuenta. |
| `created_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT `now()` | Fecha de registro. |
| `updated_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT `now()` | Última actualización del perfil. |

### 4.2. Reglas de Integridad y Seguridad (Triggers y RLS)
1. **Trigger de creación automática:** Un trigger en `auth.users` (`after insert`) inserta automáticamente el registro en `public.perfiles` forzando `rol = 'CONSTRUCTORA'` y `activo = true`, imposibilitando que el cliente inyecte un rol distinto durante el sign-up.
2. **Asignación de rol ADMIN:** No existe endpoint ni pantalla pública para asignar el rol `'ADMIN'`. Este se otorga exclusivamente mediante intervención administrativa directa en la base de datos.
3. **Políticas de Row Level Security (RLS):**
   - **Lectura:** Un usuario autenticado solo puede leer su propio registro en `public.perfiles` (`auth.uid() = id`), excepto usuarios con rol `'ADMIN'` que pueden consultar todos los perfiles.
   - **Actualización:** El usuario común no puede modificar su propio campo `rol` ni su campo `activo` vía cliente web. Solo el administrador o funciones seguras pueden alterarlos.

---

## 5. Interfaz de Usuario y Experiencia (en Español)

En estricto cumplimiento del **Principio 6 de la Constitución**, todos los textos, formularios y alertas deben presentarse en español:

### 5.1. Pantalla de Registro (`/registro`)
* **Título:** "Crear cuenta de Constructora"
* **Subtítulo:** "Regístrate para gestionar tus proyectos inmobiliarios en Vihome"
* **Campos del formulario:**
  * Correo electrónico: placeholder *"ejemplo@constructora.com"*, validación *"Ingresa un correo electrónico válido."*
  * Contraseña: placeholder *"Mínimo 6 caracteres"*, validación *"La contraseña debe tener al menos 6 caracteres."*
  * Confirmación de contraseña: placeholder *"Repite tu contraseña"*, validación *"Las contraseñas no coinciden."*
* **Acciones:**
  * Botón principal: *"Crear cuenta"*
  * Enlace secundario: *"¿Ya tienes una cuenta? Inicia sesión aquí"*

### 5.2. Pantalla de Inicio de Sesión (`/login`)
* **Título:** "Iniciar Sesión"
* **Subtítulo:** "Acceso exclusivo para constructoras y administradores"
* **Mensajes de validación y error:**
  * Credenciales erróneas: *"Correo o contraseña incorrectos."*
  * Rol no autorizado (`CLIENTE`): *"Acceso denegado: Esta plataforma es exclusiva para constructoras y administradores."*
  * Cuenta inactiva: *"Tu cuenta se encuentra inactiva. Comunícate con el soporte de Vihome."*
  * Error genérico de conexión: *"No pudimos conectar con el servidor. Revisa tu conexión a internet e inténtalo de nuevo."*

### 5.3. Navegación y Rutas
* **Ruta de carga:** Pantalla de carga limpia con logotipo e indicador circular cuando se valida la sesión activa.
* **Ruta `/dashboard-empresa`:** Vista principal para el rol `CONSTRUCTORA`.
* **Ruta `/admin-panel`:** Vista principal para el rol `ADMIN`.
* **Manejo de acceso denegado en ruta:** Redirección automática acompañada de mensaje tipo snackbar/toast: *"No tienes permisos para acceder a esta sección."*

---

## 6. Plan de Pruebas Unitarias y Automatizadas

Siguiendo el **Principio 4 de la Constitución**, antes de considerar completa la funcionalidad se deben cubrir los siguientes casos en la suite de pruebas:

### 6.1. Pruebas Unitarias de Modelos y Dominio
1. **Modelo `PerfilUsuario`:**
   - Deserialización correcta desde JSON de Supabase con campos `id`, `email`, `rol` y `activo`.
   - Métodos utilitarios booleanos (`isConstructora`, `isAdmin`, `isWebAuthorized`).
   - Manejo de valores por defecto o tipos nulos inesperados.

### 6.2. Pruebas Unitarias de Lógica y Controladores (`AuthController` / `AuthProvider`)
1. **Flujo de Registro:**
   - Verificación de que el controlador despacha el registro y en caso exitoso expone el estado autenticado con rol `CONSTRUCTORA`.
   - Manejo de excepciones en registro (ej. correo ya registrado) y mapeo a mensaje en español.
2. **Flujo de Inicio de Sesión:**
   - Inicio de sesión con rol `CONSTRUCTORA` transiciona el estado a autenticado con redirección a `/dashboard-empresa`.
   - Inicio de sesión con rol `ADMIN` transiciona el estado a autenticado con redirección a `/admin-panel`.
   - Detección de rol `CLIENTE`: invoca `signOut` en el servicio de autenticación y transiciona el estado a error con el mensaje de rechazo correspondiente.
   - Detección de `activo = false`: invoca `signOut` y transiciona el estado a error de cuenta suspendida.

### 6.3. Pruebas de Guardias de Navegación (`AppRouter` / Route Guards)
1. Redirección a `/login` si un usuario no autenticado navega a `/dashboard-empresa`.
2. Redirección a `/dashboard-empresa` si un usuario `CONSTRUCTORA` intenta navegar a `/admin-panel`.
3. Permisión de acceso directo a `/dashboard-empresa` cuando el usuario es `CONSTRUCTORA` y está activo.
4. Redirección a su dashboard correspondiente si un usuario autenticado intenta navegar a `/login` o `/registro`.
