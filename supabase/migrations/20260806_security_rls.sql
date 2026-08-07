-- =============================================================================
-- Seguridad: Políticas Row Level Security (RLS)
--
-- IMPORTANTE: En una app web la SUPABASE_ANON_KEY es pública por diseño
-- (está embebida en el bundle). Por lo tanto TODA la autorización debe
-- vivirse en la base de datos con RLS, no en el cliente.
--
-- Ejecuta este script en: Supabase Dashboard -> SQL Editor
-- Ajusta nombres de tablas/columnas si tu esquema difiere.
-- =============================================================================

-- 1) Asegurar que RLS está habilitado y quitar permisos por defecto.
alter table public.contructora enable row level security;
alter table public.proyectos   enable row level security;

-- 2) Helper: ¿el usuario autenticado es dueño de la constructora?
create or replace function public.user_owns_constructora(
  target_id uuid
) returns boolean
security definer
set search_path = public
language sql
stable
as $$
  select exists (
    select 1
    from public.contructora c
    where c.id = target_id
      and c.id_user = auth.uid()
  );
$$;

-- =============================================================================
-- Tabla: contructora
-- El usuario solo puede ver/crear/modificar/eliminar SUS constructoras.
-- =============================================================================

create policy "owner_select_own_constructora" on public.contructora
  for select using (auth.uid() = id_user);

create policy "owner_insert_own_constructora" on public.contructora
  for insert with check (auth.uid() = id_user);

create policy "owner_update_own_constructora" on public.contructora
  for update using (auth.uid() = id_user)
  with check (auth.uid() = id_user);

create policy "owner_delete_own_constructora" on public.contructora
  for delete using (auth.uid() = id_user);

-- =============================================================================
-- Tabla: proyectos
-- El usuario solo accede a proyectos de constructoras que le pertenecen.
-- =============================================================================

create policy "owner_select_own_proyectos" on public.proyectos
  for select using (
    public.user_owns_constructora(proyectos.constructora_id)
  );

create policy "owner_insert_own_proyectos" on public.proyectos
  for insert with check (
    public.user_owns_constructora(proyectos.constructora_id)
  );

create policy "owner_update_own_proyectos" on public.proyectos
  for update using (
    public.user_owns_constructora(proyectos.constructora_id)
  ) with check (
    public.user_owns_constructora(proyectos.constructora_id)
  );

create policy "owner_delete_own_proyectos" on public.proyectos
  for delete using (
    public.user_owns_constructora(proyectos.constructora_id)
  );

-- =============================================================================
-- (Opcional) Revocar el acceso anónimo a tablas sensibles del esquema public.
-- anon es el rol no autenticado; deja solo lo que deba ser público.
-- =============================================================================

revoke all on table public.contructora from anon;
revoke all on table public.proyectos from anon;

grant select, insert, update, delete on table public.contructora to authenticated;
grant select, insert, update, delete on table public.proyectos to authenticated;

-- =============================================================================
-- (Opcional) Alertas de inyección SQL: habilita logs para detectar patrones
-- sospechosos en PostgREST. Solo en producción según sea necesario.
-- =============================================================================
-- alter database postgres set log_statement = 'ddl';
