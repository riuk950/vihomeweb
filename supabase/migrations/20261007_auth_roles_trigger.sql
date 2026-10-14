-- =============================================================================
-- Migración: Trigger de Asignación Inmutable de Rol CONSTRUCTORA
-- Feature: auth-roles (RF-01, RF-02)
-- =============================================================================

-- 1. Función para manejar la inserción automática en public.perfiles
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.perfiles (id, email, rol, activo, created_at, updated_at)
  VALUES (
    new.id,
    new.email,
    'CONSTRUCTORA',
    true,
    now(),
    now()
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 2. Trigger sobre auth.users para interceptar cualquier registro
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
