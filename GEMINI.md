# CI/CD para Flutter Web + Supabase + Firebase

Guía para implementar integración y despliegue continuo en un proyecto Flutter Web usando Supabase como backend y Firebase Hosting para despliegue.

---

# Arquitectura

Stack del proyecto

- Flutter Web (Frontend)
- Supabase (Database / Auth / Storage / API)
- Firebase Hosting (Deploy)
- GitHub Actions (CI/CD)

Flujo general

1. Push a GitHub → 2. GitHub Actions corre tests → 3. Si pasa → 4. Deploy a Firebase Hosting
