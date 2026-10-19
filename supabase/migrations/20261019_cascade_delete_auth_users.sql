-- =============================================================================
-- Migración: Borrado en Cascada para Usuarios de Supabase Auth
--
-- Ejecuta este script en: Supabase Dashboard -> SQL Editor
--
-- Resuelve el error al eliminar usuarios desde Authentication -> Users,
-- garantizando que al borrar un usuario en auth.users se eliminen automáticamente
-- en cascada sus registros en usuarios_web, profiles, contructora y proyectos.
-- =============================================================================

-- 1. Actualizar dinámicamente cualquier foreign key en public que apunte a auth.users a ON DELETE CASCADE
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN (
    SELECT
      tc.table_schema,
      tc.table_name,
      tc.constraint_name,
      kcu.column_name,
      ccu.table_schema AS foreign_table_schema,
      ccu.table_name AS foreign_table_name,
      ccu.column_name AS foreign_column_name,
      rc.delete_rule
    FROM information_schema.table_constraints AS tc
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
    JOIN information_schema.referential_constraints AS rc
      ON rc.constraint_name = tc.constraint_name
    WHERE tc.constraint_type = 'FOREIGN KEY'
      AND tc.table_schema = 'public'
      AND ccu.table_schema = 'auth'
      AND ccu.table_name = 'users'
      AND rc.delete_rule != 'CASCADE'
  ) LOOP
    RAISE NOTICE 'Actualizando constraint % en tabla %.% a ON DELETE CASCADE', r.constraint_name, r.table_schema, r.table_name;
    EXECUTE format('ALTER TABLE %I.%I DROP CONSTRAINT %I', r.table_schema, r.table_name, r.constraint_name);
    EXECUTE format(
      'ALTER TABLE %I.%I ADD CONSTRAINT %I FOREIGN KEY (%I) REFERENCES %I.%I(%I) ON DELETE CASCADE',
      r.table_schema, r.table_name, r.constraint_name, r.column_name,
      r.foreign_table_schema, r.foreign_table_name, r.foreign_column_name
    );
  END LOOP;
END $$;

-- 2. Asegurar que public.contructora.id_user apunte a auth.users(id) con ON DELETE CASCADE
DO $$
DECLARE
  v_conname TEXT;
BEGIN
  -- Buscar si existe alguna constraint foránea en contructora sobre id_user
  SELECT tc.constraint_name INTO v_conname
  FROM information_schema.table_constraints tc
  JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
  WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public'
    AND tc.table_name = 'contructora'
    AND kcu.column_name = 'id_user'
  LIMIT 1;

  IF v_conname IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.contructora DROP CONSTRAINT %I', v_conname);
  END IF;

  -- Si hay registros huérfanos con id_user de usuarios ya borrados en auth.users, poner en NULL
  UPDATE public.contructora
  SET id_user = NULL
  WHERE id_user IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM auth.users WHERE id = public.contructora.id_user);

  -- Agregar FK estricta con ON DELETE CASCADE
  ALTER TABLE public.contructora
    ADD CONSTRAINT contructora_id_user_fkey
    FOREIGN KEY (id_user)
    REFERENCES auth.users(id)
    ON DELETE CASCADE;
END $$;

-- 3. Asegurar que public.profiles (si existe) tenga ON DELETE CASCADE hacia auth.users
DO $$
DECLARE
  v_conname TEXT;
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'profiles') THEN
    SELECT tc.constraint_name INTO v_conname
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    WHERE tc.constraint_type = 'FOREIGN KEY'
      AND tc.table_schema = 'public'
      AND tc.table_name = 'profiles'
      AND kcu.column_name = 'id'
    LIMIT 1;

    IF v_conname IS NOT NULL THEN
      EXECUTE format('ALTER TABLE public.profiles DROP CONSTRAINT %I', v_conname);
    END IF;

    ALTER TABLE public.profiles
      ADD CONSTRAINT profiles_id_fkey
      FOREIGN KEY (id)
      REFERENCES auth.users(id)
      ON DELETE CASCADE;
  END IF;
END $$;

-- 4. Asegurar que public.proyectos.constructora_id tenga ON DELETE CASCADE hacia public.contructora
DO $$
DECLARE
  v_conname TEXT;
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'proyectos') THEN
    SELECT tc.constraint_name INTO v_conname
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    WHERE tc.constraint_type = 'FOREIGN KEY'
      AND tc.table_schema = 'public'
      AND tc.table_name = 'proyectos'
      AND kcu.column_name = 'constructora_id'
    LIMIT 1;

    IF v_conname IS NOT NULL THEN
      EXECUTE format('ALTER TABLE public.proyectos DROP CONSTRAINT %I', v_conname);
    END IF;

    -- Agregar FK hacia contructora con ON DELETE CASCADE
    ALTER TABLE public.proyectos
      ADD CONSTRAINT proyectos_constructora_id_fkey
      FOREIGN KEY (constructora_id)
      REFERENCES public.contructora(id)
      ON DELETE CASCADE;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    -- Si la tabla proyectos tiene tipos incompatibles u otra estructura, no bloquear la migración
    RAISE NOTICE 'No se pudo aplicar FK en proyectos: %', SQLERRM;
END $$;

-- 5. Consulta de verificación: Comprobar que todas las referencias a auth.users tengan delete_rule = 'CASCADE'
SELECT
  tc.table_name,
  kcu.column_name,
  tc.constraint_name,
  rc.delete_rule
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
JOIN information_schema.referential_constraints AS rc
  ON rc.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
  AND ccu.table_schema = 'auth'
  AND ccu.table_name = 'users';
