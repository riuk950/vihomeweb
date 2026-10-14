# AGENTS.md - Protocolo y Guía de Operación para Agentes

Este documento define el protocolo operativo obligatorio para cualquier agente de IA o desarrollador que interactúe, diseñe o modifique código en el repositorio **vihomeweb**.

---

## 1. Jerarquía de Autoridad y Referencias Obligatorias

Toda acción y decisión técnica en este proyecto debe supeditarse a la siguiente jerarquía de documentos:

1. **Constitución del Proyecto ([docs/constitution.md](file:///Users/diego/FlutterProjects/vihomeweb/docs/constitution.md)) — *Innegociable***:
   - Contiene los 6 principios rectores: simplicidad del stack, prioridad de especificación, separación estricta de capas, política de tests, persistencia local controlada e idioma de cara al usuario final en español.
   - **Ningún agente puede contradecir ni omitir estos principios bajo ninguna circunstancia.**

2. **Especificaciones Funcionales y Técnicas (`specs/`) — *Spec-First***:
   - Todo cambio, nueva característica o refactorización debe estar respaldado por un archivo de especificación en la carpeta `specs/` (ej. `specs/auth.md`, `specs/constructoras.md`).
   - El código implementa especificaciones y criterios de aceptación verificables; **nunca se debe programar sobre suposiciones**.

3. **Arquitectura y CI/CD ([GEMINI.md](file:///Users/diego/FlutterProjects/vihomeweb/GEMINI.md))**:
   - Stack: Flutter Web + Supabase + Firebase Hosting + GitHub Actions.
   - Flujo de integración continua y despliegue.

4. **Sistema de Diseño ([DESIGN.md](file:///Users/diego/FlutterProjects/vihomeweb/DESIGN.md))**:
   - Paleta cromática, tipografías y tokens de diseño para componentes UI.

---

## 2. Flujo de Trabajo Obligatorio para Agentes

Antes de realizar cambios o generar código, los agentes deben seguir estrictamente estas fases:

### Fase 1: Lectura y Alineación Previa (Pre-flight)
- [ ] **Revisar la Constitución:** Confirmar que la tarea respeta los 6 principios de [docs/constitution.md](file:///Users/diego/FlutterProjects/vihomeweb/docs/constitution.md).
- [ ] **Revisar o Crear la Spec:**
  - Si existe un documento en `specs/` para la funcionalidad: leer sus criterios de aceptación y contratos.
  - Si **no** existe un spec o los requerimientos son ambiguos: redactar o solicitar primero la especificación en `specs/` antes de escribir código de producción.

### Fase 2: Arquitectura y Restricciones
- [ ] **Separación Lógica / Interfaz:**
  - La capa de presentación (`lib/presentation/`) sólo dibuja widgets y despacha eventos.
  - Cero lógica de negocio, cálculos complejos o llamadas directas a Supabase dentro de `build()` o métodos de ciclo de vida del widget.
  - La lógica de negocio y comunicación con Supabase pertenece a `lib/domain/`, `lib/data/` y los providers/controllers correspondientes.
- [ ] **Simplicidad del Stack:**
  - No añadir paquetes a `pubspec.yaml` sin justificación técnica demostrada.
  - Mantener un único gestor de estado y evitar dependencias redundantes.
- [ ] **Persistencia:**
  - Supabase es la única fuente de verdad. El almacenamiento local en navegador (`SharedPreferences`, `Web Storage`) es sólo para tokens de sesión y caché temporal efímero.

### Fase 3: Implementación y Experiencia de Usuario
- [ ] **Idioma al Usuario Final:**
  - Todo elemento visible para el usuario (etiquetas, botones, formularios, diálogos, validaciones y alertas) debe estar en **español**.
  - Errores de backend o excepciones técnicas deben capturarse y traducirse a mensajes comprensibles en español antes de presentarse al usuario.

### Fase 4: Verificación y Tests
- [ ] Escribir o actualizar pruebas unitarias para cualquier nueva lógica de negocio, modelo o repositorio en `test/`.
- [ ] Ejecutar la suite de pruebas y análisis estático:
  ```bash
  flutter test
  dart analyze
  ```
- [ ] Ninguna tarea se considera completa si las pruebas fallan o introducen errores de análisis.

---

## 3. Estructura Estándar de una Especificación (`specs/`)

Cada archivo en `specs/<modulo_o_feature>.md` debe estructurarse con las siguientes secciones mínimas:

```markdown
# Spec: [Nombre de la Característica]

## 1. Contexto y Objetivo
Descripción concisa del problema que resuelve y valor para el negocio.

## 2. Requerimientos Funcionales
- RF-01: ...
- RF-02: ...

## 3. Criterios de Aceptación (Gherkin o verificables)
- Dado que [condición], cuando [acción], entonces [resultado esperado].

## 4. Contrato de Datos / Supabase
- Tablas involucradas, consultas esperadas, políticas RLS o estructuras JSON.

## 5. Interfaz y Experiencia (en Español)
- Textos de pantalla, validaciones y mensajes de error orientados al usuario.

## 6. Plan de Pruebas Unitarias
- Casos de prueba a implementar en `test/`.
```

---

## 4. Checklist de Entrega para Agentes

Antes de finalizar la intervención o proponer un commit/PR, verifica:

- [ ] ¿Se respetaron los 6 principios de [docs/constitution.md](file:///Users/diego/FlutterProjects/vihomeweb/docs/constitution.md)?
- [ ] ¿Existe una especificación en `specs/` que respalde los cambios?
- [ ] ¿La capa de presentación quedó libre de lógica de negocio o llamadas directas a Supabase?
- [ ] ¿Todos los textos y mensajes para el usuario están en español?
- [ ] ¿Se crearon o actualizaron las pruebas unitarias correspondientes?
- [ ] ¿Ejecutó `flutter test` y el resultado fue 100% exitoso?
