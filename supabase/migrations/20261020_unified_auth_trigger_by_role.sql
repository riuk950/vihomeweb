-- =============================================================================
-- Migración: Trigger Unificado de Creación de Usuarios por Rol (Web vs Mobile)
--
-- Ejecuta este script en: Supabase Dashboard -> SQL Editor
--
-- Enrutamiento automático:
-- 1. Rol 'CONSTRUCTORA' o 'ADMIN' (o app = 'web'):
--    -> Se guarda en public.usuarios_web (y opcionalmente crea el enlace base en contructora)
-- 2. Rol 'arrendador' o 'arrendatario' (o app = 'mobile'):
--    -> Se guarda en public.profiles (detecta dinámicamente las columnas existentes
--       para evitar errores si 'updated_at' no existe en profiles)
-- =============================================================================

-- 1. Eliminar triggers previos para evitar ejecuciones duplicadas o conflictivas
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_created_web ON auth.users;

-- 2. Función disparadora inteligente que enruta según el rol del usuario
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_app TEXT := lower(coalesce(new.raw_user_meta_data->>'app', ''));
  v_rol TEXT := lower(coalesce(new.raw_user_meta_data->>'rol', new.raw_user_meta_data->>'role', ''));
  v_cols TEXT[];
  v_vals TEXT[];
  v_sql TEXT;
BEGIN
  -- ---------------------------------------------------------------------------
  -- CASO 1: PLATAFORMA WEB (Constructoras y Administradores)
  -- ---------------------------------------------------------------------------
  IF v_rol IN ('constructora', 'admin') OR v_app = 'web' THEN
    -- A) Guardar en usuarios_web para el ciclo de vida y guards de la plataforma web
    INSERT INTO public.usuarios_web (
      id,
      email,
      rol,
      activo,
      is_completed,
      created_at,
      updated_at
    )
    VALUES (
      new.id,
      coalesce(new.email, ''),
      upper(coalesce(nullif(v_rol, ''), 'CONSTRUCTORA')),
      true,
      false, -- is_completed = false: Requiere completar datos corporativos en /complete-profile
      timezone('utc'::text, now()),
      timezone('utc'::text, now())
    )
    ON CONFLICT (id) DO UPDATE SET
      email = EXCLUDED.email,
      updated_at = timezone('utc'::text, now());

    -- B) Opcional: Si deseas que exista desde ya la fila base en contructora vinculada a id_user
    BEGIN
      INSERT INTO public.contructora (id_user, correo)
      VALUES (new.id, new.email)
      ON CONFLICT (id_user) DO NOTHING;
    EXCEPTION
      WHEN OTHERS THEN
        -- Si la tabla contructora exige columnas obligatorias (NIT, nombre), no bloquear el registro
        NULL;
    END;

  -- ---------------------------------------------------------------------------
  -- CASO 2: APLICACIÓN MOBILE (Arrendadores, Arrendatarios, Clientes o usuarios generales)
  -- ---------------------------------------------------------------------------
  ELSE
    -- Guardar en profiles detectando dinámicamente las columnas que realmente existen
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'profiles') THEN
      v_cols := ARRAY['id'];
      v_vals := ARRAY[quote_literal(new.id::text)];

      -- Detectar si existe columna email
      IF EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'public.profiles'::regclass AND attname = 'email' AND NOT attisdropped) THEN
        v_cols := array_append(v_cols, 'email');
        v_vals := array_append(v_vals, quote_literal(coalesce(new.email, '')));
      END IF;

      -- Detectar columna rol o role
      IF coalesce(v_rol, '') != '' THEN
        IF EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'public.profiles'::regclass AND attname = 'rol' AND NOT attisdropped) THEN
          v_cols := array_append(v_cols, 'rol');
          v_vals := array_append(v_vals, quote_literal(v_rol));
        ELSIF EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'public.profiles'::regclass AND attname = 'role' AND NOT attisdropped) THEN
          v_cols := array_append(v_cols, 'role');
          v_vals := array_append(v_vals, quote_literal(v_rol));
        END IF;
      END IF;

      -- Detectar created_at
      IF EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'public.profiles'::regclass AND attname = 'created_at' AND NOT attisdropped) THEN
        v_cols := array_append(v_cols, 'created_at');
        v_vals := array_append(v_vals, 'timezone(''utc''::text, now())');
      END IF;

      -- Detectar updated_at (solo si existe en la tabla profiles para evitar error 42703)
      IF EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'public.profiles'::regclass AND attname = 'updated_at' AND NOT attisdropped) THEN
        v_cols := array_append(v_cols, 'updated_at');
        v_vals := array_append(v_vals, 'timezone(''utc''::text, now())');
      END IF;

      BEGIN
        v_sql := format(
          'INSERT INTO public.profiles (%s) VALUES (%s) ON CONFLICT (id) DO NOTHING',
          array_to_string(v_cols, ', '),
          array_to_string(v_vals, ', ')
        );
        EXECUTE v_sql;
      EXCEPTION
        WHEN OTHERS THEN
          -- En caso de cualquier inconsistencia en profiles, advertir pero no abortar la creación del auth user
          RAISE WARNING 'No se pudo insertar en profiles: %', SQLERRM;
      END;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- 3. Crear el trigger único sobre auth.users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
