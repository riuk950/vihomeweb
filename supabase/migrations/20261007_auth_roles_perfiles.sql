-- =============================================================================
-- Migración: Control de Registro y Acceso por Roles (public.perfiles)
-- Feature: auth-roles (RF-02, RF-04, RF-06)
-- =============================================================================

-- 1. Crear tabla public.perfiles
CREATE TABLE IF NOT EXISTS public.perfiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  rol TEXT NOT NULL DEFAULT 'CONSTRUCTORA' CHECK (rol IN ('CONSTRUCTORA', 'ADMIN', 'CLIENTE')),
  activo BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Comentario en tabla
COMMENT ON TABLE public.perfiles IS 'Almacena el perfil, rol de acceso y estado activo del usuario';

-- 2. Habilitar Row Level Security (RLS)
ALTER TABLE public.perfiles ENABLE ROW LEVEL SECURITY;

-- 3. Políticas RLS
-- Política 1: Lectura para el propio usuario autenticado
CREATE POLICY "perfiles_select_own"
  ON public.perfiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Política 2: Lectura global para administradores activos
CREATE POLICY "perfiles_select_admin"
  ON public.perfiles
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.perfiles p
      WHERE p.id = auth.uid() AND p.rol = 'ADMIN' AND p.activo = true
    )
  );

-- Política 3: Los usuarios regulares no pueden modificar su propio rol ni estado activo
-- Solo administradores o funciones SECURITY DEFINER pueden actualizar perfiles
CREATE POLICY "perfiles_update_admin"
  ON public.perfiles
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.perfiles p
      WHERE p.id = auth.uid() AND p.rol = 'ADMIN' AND p.activo = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.perfiles p
      WHERE p.id = auth.uid() AND p.rol = 'ADMIN' AND p.activo = true
    )
  );
