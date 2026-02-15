create extension if not exists pgcrypto;

create table if not exists public.pedidos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  cliente_nombre text not null,
  cliente_whatsapp text not null,
  total numeric(10,2) not null default 0,
  comprobante_url text not null,
  items jsonb not null default '[]'::jsonb,
  estado text not null default 'pendiente',
  created_at timestamptz not null default now()
);

create table if not exists public.admin_setup (
  id int primary key,
  allowed_email text not null,
  code_hash text not null,
  created_at timestamptz not null default now()
);

alter table public.admin_setup enable row level security;

drop policy if exists admin_setup_block_all on public.admin_setup;
create policy admin_setup_block_all
on public.admin_setup
for all
to anon, authenticated
using (false)
with check (false);

create or replace function public.grant_admin(setup_code text)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  rec record;
  jwt jsonb;
  email text;
  computed_hash text;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  jwt := auth.jwt();
  email := lower(coalesce(jwt->>'email', ''));

  select allowed_email, public.admin_setup.code_hash into rec
  from public.admin_setup
  where id = 1;

  if rec.allowed_email is null then
    raise exception 'admin_setup_not_configured';
  end if;

  if email <> lower(rec.allowed_email) then
    raise exception 'not_allowed';
  end if;

  if setup_code is null or btrim(setup_code) = '' then
    raise exception 'missing_code';
  end if;

  computed_hash := encode(extensions.digest(btrim(setup_code), 'sha256'), 'hex');
  if computed_hash <> rec.code_hash then
    raise exception 'invalid_code';
  end if;

  insert into public.admins (user_id)
  values (auth.uid())
  on conflict do nothing;
end;
$$;

revoke all on function public.grant_admin(text) from public;
grant execute on function public.grant_admin(text) to authenticated;

create or replace function public.email_exists(p_email text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_email is null or btrim(p_email) = '' then
    return false;
  end if;
  return exists (
    select 1
    from auth.users u
    where lower(u.email) = lower(btrim(p_email))
  );
end;
$$;

revoke all on function public.email_exists(text) from public;
grant execute on function public.email_exists(text) to anon, authenticated;

alter table public.pedidos enable row level security;

drop policy if exists pedidos_insert_public on public.pedidos;
create policy pedidos_insert_public
on public.pedidos
for insert
to anon, authenticated
with check (estado = 'pendiente' and (user_id is null or user_id = auth.uid()));

drop policy if exists pedidos_select_own on public.pedidos;
create policy pedidos_select_own
on public.pedidos
for select
to authenticated
using (user_id = auth.uid());

drop policy if exists pedidos_select_admin on public.pedidos;
create policy pedidos_select_admin
on public.pedidos
for select
to authenticated
using (exists (select 1 from public.admins a where a.user_id = auth.uid()));

drop policy if exists pedidos_update_admin on public.pedidos;
create policy pedidos_update_admin
on public.pedidos
for update
to authenticated
using (exists (select 1 from public.admins a where a.user_id = auth.uid()))
with check (exists (select 1 from public.admins a where a.user_id = auth.uid()));

insert into storage.buckets (id, name, public)
values ('comprobantes', 'comprobantes', true)
on conflict (id) do update set public = true;

drop policy if exists comprobantes_upload_public on storage.objects;
create policy comprobantes_upload_public
on storage.objects
for insert
to anon, authenticated
with check (bucket_id = 'comprobantes' and name like 'vouchers/%');
