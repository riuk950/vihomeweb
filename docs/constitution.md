# Constitución del Proyecto: vihomeweb

Este documento establece los 6 principios innegociables que rigen el diseño, desarrollo y evolución de **vihomeweb**. Cada principio es conciso y cuenta con un criterio de verificación objetivo.

---

### 1. Simplicidad del Stack
* **Principio:** Mantener el stack tecnológico al mínimo indispensable, priorizando soluciones estándar de Flutter/Dart y el ecosistema oficial (Flutter Web + Supabase + Firebase Hosting). Queda prohibido incorporar paquetes de terceros sin una justificación técnica explícita y documentada.
* **Criterio de verificación:** Ninguna dependencia nueva ingresa a `pubspec.yaml` sin justificación previa. Se prohíbe tener múltiples soluciones para el mismo problema (por ejemplo, múltiples gestores de estado).

---

### 2. Prioridad de la Especificación sobre el Código
* **Principio:** Ninguna línea de código funcional se escribe sin una especificación previa clara (criterios de aceptación, reglas de negocio o contrato de interfaz). El código implementa especificaciones, no suposiciones.
* **Criterio de verificación:** Todo Pull Request o cambio funcional debe referenciar un requerimiento documentado con criterios de aceptación verificables antes de considerarse listo para revisión.

---

### 3. Separación Estricta entre Lógica e Interfaz
* **Principio:** La capa de presentación (`presentation`) es 100% declarativa y reactiva. Los widgets únicamente renderizan estado y emiten eventos de usuario; nunca ejecutan lógica de negocio ni realizan llamadas directas a APIs o Supabase.
* **Criterio de verificación:** Cero llamadas asíncronas de negocio, transformaciones de datos o consultas directas a backend dentro de los métodos `build()` o ciclos de vida de widgets. Toda la lógica reside en la capa de dominio/aplicación (`providers`, `controllers` o `use cases`).

---

### 4. Política de Tests Automatizados
* **Principio:** La estabilidad del código se garantiza mediante pruebas automatizadas. Todo modelo, caso de uso, repositorio y flujo de negocio crítico debe contar con pruebas unitarias antes de integrarse a la rama principal.
* **Criterio de verificación:** La suite de pruebas (`flutter test`) debe ejecutarse y pasar al 100% en verde en el pipeline de CI/CD (GitHub Actions) como requisito bloqueante para cualquier merge o despliegue.

---

### 5. Persistencia Local Controlada y Segura
* **Principio:** El almacenamiento local en el navegador (Web Storage / SharedPreferences) es estrictamente efímero y auxiliar (sesión de auth, tokens, preferencias de tema o caché temporal). Supabase es la única fuente de verdad (*single source of truth*) del estado de la aplicación.
* **Criterio de verificación:** No se almacenan entidades ni estados de negocio críticos de forma persistente en almacenamiento local del cliente; los datos locales cuentan con mecanismo de expiración y limpieza en logout.

---

### 6. Idioma de Cara al Usuario Final
* **Principio:** Toda la experiencia dirigida al usuario final (interfaz gráfica, navegación, formularios, validaciones, alertas, mensajes de error y contenido de soporte) debe presentarse estrictamente en español.
* **Criterio de verificación:** Cero textos visibles para el usuario en inglés o mensajes de error sin traducir en la interfaz; cualquier respuesta del backend o excepción técnica debe mapearse a un mensaje comprensible en español antes de mostrarse en pantalla.
