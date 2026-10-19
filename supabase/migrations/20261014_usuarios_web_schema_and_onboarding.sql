-- =============================================================================
-- Migración: Tabla public.usuarios_web y Onboarding de Constructora (Web)
--
-- Ejecuta este script en: Supabase Dashboard -> SQL Editor
-- Totalmente aislado de public.profiles para no interferir con la app Mobile.
-- =============================================================================

-- 1. Tabla exclusiva para la plataforma Web (Constructoras y Admins)
CREATE TABLE IF NOT EXISTS public.usuarios_web (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  rol TEXT NOT NULL DEFAULT 'CONSTRUCTORA' CHECK (rol IN ('CONSTRUCTORA', 'ADMIN', 'CLIENTE')),
  activo BOOLEAN NOT NULL DEFAULT true,
  is_completed BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

COMMENT ON TABLE public.usuarios_web IS 'Usuarios y roles exclusivos de la plataforma web corporativa (vihomeweb)';

-- Función helper para verificar rol admin sin provocar recursión RLS
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.usuarios_web
    WHERE id = auth.uid() AND rol = 'ADMIN' AND activo = true
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;

-- 2. Habilitar y configurar Row Level Security (RLS) en public.usuarios_web
ALTER TABLE public.usuarios_web ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "usuarios_web_select_own" ON public.usuarios_web;
CREATE POLICY "usuarios_web_select_own"
  ON public.usuarios_web FOR SELECT
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "usuarios_web_select_admin" ON public.usuarios_web;
CREATE POLICY "usuarios_web_select_admin"
  ON public.usuarios_web FOR SELECT
  USING (public.is_admin());

DROP POLICY IF EXISTS "usuarios_web_insert_own" ON public.usuarios_web;
CREATE POLICY "usuarios_web_insert_own"
  ON public.usuarios_web FOR INSERT
  WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "usuarios_web_update_own" ON public.usuarios_web;
CREATE POLICY "usuarios_web_update_own"
  ON public.usuarios_web FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "usuarios_web_update_admin" ON public.usuarios_web;
CREATE POLICY "usuarios_web_update_admin"
  ON public.usuarios_web FOR UPDATE
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- 2.1 Sincronizar usuarios preexistentes de auth.users hacia public.usuarios_web
INSERT INTO public.usuarios_web (id, email, rol, activo, is_completed, created_at, updated_at)
SELECT
  id,
  coalesce(email, ''),
  'CONSTRUCTORA',
  true,
  false,
  created_at,
  timezone('utc'::text, now())
FROM auth.users
ON CONFLICT (id) DO NOTHING;

-- 3. Trigger en auth.users para creación automática en public.usuarios_web
-- Condicionado para registrar usuarios web sin alterar registros exclusivos de mobile
CREATE OR REPLACE FUNCTION public.handle_new_user_web()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_app TEXT := new.raw_user_meta_data->>'app';
  v_rol TEXT := coalesce(new.raw_user_meta_data->>'rol', 'CONSTRUCTORA');
BEGIN
  -- Si el registro proviene de la web o indica rol corporativo
  IF v_app = 'web' OR v_rol IN ('CONSTRUCTORA', 'ADMIN') THEN
    INSERT INTO public.usuarios_web (id, email, rol, activo, is_completed, created_at, updated_at)
    VALUES (
      new.id,
      new.email,
      v_rol,
      true,
      false,
      timezone('utc'::text, now()),
      timezone('utc'::text, now())
    )
    ON CONFLICT (id) DO UPDATE SET
      email = EXCLUDED.email,
      updated_at = timezone('utc'::text, now());
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created_web ON auth.users;
CREATE TRIGGER on_auth_user_created_web
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user_web();

-- 4. Asegurar constraints de unicidad en public.contructora
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

-- 5. Función RPC transaccional atómica para completar onboarding sobre usuarios_web
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
  v_existing_nit_user_id UUID;
  v_user_has_constructora BOOLEAN;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Usuario no autenticado' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_perfil FROM public.usuarios_web WHERE id = v_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Perfil de usuario web no encontrado' USING ERRCODE = 'P0002';
  END IF;

  IF NOT v_perfil.activo THEN
    RAISE EXCEPTION 'Cuenta inactiva' USING ERRCODE = '42501';
  END IF;

  -- 1. Verificar si el NIT ya existe en contructora
  SELECT id_user INTO v_existing_nit_user_id
  FROM public.contructora
  WHERE nit = trim(p_nit)
  LIMIT 1;

  IF FOUND THEN
    -- Si el NIT ya existe:
    -- Caso A: Pertenece a este mismo usuario -> se actualiza
    -- Caso B: Pertenece a un registro huérfano (id_user IS NULL o usuario borrado de auth.users) -> se reasigna y actualiza
    -- Caso C: Pertenece a otro usuario activo -> conflicto 23505
    IF v_existing_nit_user_id IS NOT NULL 
       AND v_existing_nit_user_id != v_user_id 
       AND EXISTS (SELECT 1 FROM auth.users WHERE id = v_existing_nit_user_id) THEN
      RAISE EXCEPTION 'Ya existe una constructora registrada con este NIT' USING ERRCODE = '23505';
    END IF;

    -- Si pertenece a este usuario o es huérfano, actualizamos ese registro y vinculamos a v_user_id
    UPDATE public.contructora
    SET
      id_user = v_user_id,
      nombre = trim(p_nombre),
      telefono_fijo = trim(p_telefono),
      direccion = trim(p_direccion),
      ciudad = nullif(trim(p_ciudad), ''),
      departamento = nullif(trim(p_departamento), ''),
      whatsap = nullif(trim(p_whatsap), ''),
      sitio_web = nullif(trim(p_sitio_web), ''),
      logo_url = nullif(trim(p_logo_url), '')
    WHERE nit = trim(p_nit);

  ELSE
    -- 2. El NIT no existe: verificar si el usuario ya tiene una constructora registrada con otro NIT
    SELECT EXISTS (
      SELECT 1 FROM public.contructora WHERE id_user = v_user_id
    ) INTO v_user_has_constructora;

    IF v_user_has_constructora THEN
      UPDATE public.contructora
      SET
        nit = trim(p_nit),
        nombre = trim(p_nombre),
        telefono_fijo = trim(p_telefono),
        direccion = trim(p_direccion),
        ciudad = nullif(trim(p_ciudad), ''),
        departamento = nullif(trim(p_departamento), ''),
        whatsap = nullif(trim(p_whatsap), ''),
        sitio_web = nullif(trim(p_sitio_web), ''),
        logo_url = nullif(trim(p_logo_url), '')
      WHERE id_user = v_user_id;
    ELSE
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
        logo_url
      ) VALUES (
        v_user_id,
        trim(p_nit),
        trim(p_nombre),
        trim(p_telefono),
        trim(p_direccion),
        nullif(trim(p_ciudad), ''),
        nullif(trim(p_departamento), ''),
        nullif(trim(p_whatsap), ''),
        nullif(trim(p_sitio_web), ''),
        nullif(trim(p_logo_url), '')
      );
    END IF;
  END IF;

  -- 3. Actualizar onboarding en usuarios_web
  UPDATE public.usuarios_web
  SET is_completed = true,
      updated_at = timezone('utc'::text, now())
  WHERE id = v_user_id
  RETURNING * INTO v_perfil;

  RETURN v_perfil;
END;
$$;

GRANT EXECUTE ON FUNCTION public.completar_onboarding_constructora(
  TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT
) TO authenticated;
