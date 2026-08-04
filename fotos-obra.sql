-- ============================================================
-- CASA LA TRIADA — Agregar Fotos de la obra
-- Pegar TODO este archivo en: Supabase > SQL Editor > New query > Run
-- Es seguro: solo AGREGA una carpeta de fotos nueva y una tabla nueva,
-- no borra ni modifica nada de lo que ya existe.
-- ============================================================

-- 1) Carpeta pública de fotos (bucket de Storage), máx 8 MB por foto
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('fotos-obra','fotos-obra', true, 8388608,
        array['image/jpeg','image/png','image/webp','image/heic','image/heif'])
on conflict (id) do nothing;

-- 2) Tabla para guardar la info de cada foto (etapa, fecha, nota, quién la subió)
create table if not exists public.fotos_obra (
  id uuid primary key default gen_random_uuid(),
  storage_path text not null,
  etapa_id uuid references public.etapas(id) on delete set null,
  fecha date not null default current_date,
  nota text default '',
  subido_por text default '',
  creado timestamptz default now()
);
alter table public.fotos_obra enable row level security;

drop policy if exists leer_fotos_obra on public.fotos_obra;
drop policy if exists ins_fotos_obra on public.fotos_obra;
drop policy if exists del_fotos_obra on public.fotos_obra;

-- Cualquiera con clave válida (admin/inventario/lectura) puede VER las fotos
create policy leer_fotos_obra on public.fotos_obra for select
  to anon, authenticated using (public.triada_rol() <> 'ninguno');

-- Cualquiera con clave válida puede SUBIR fotos (según lo pedido: todos los socios)
create policy ins_fotos_obra on public.fotos_obra for insert
  to anon, authenticated with check (public.triada_rol() <> 'ninguno');

-- Solo el administrador puede BORRAR fotos
create policy del_fotos_obra on public.fotos_obra for delete
  to anon, authenticated using (public.triada_rol() = 'admin');

-- 3) Permisos sobre los archivos de la carpeta fotos-obra
drop policy if exists subir_fotos_obra on storage.objects;
drop policy if exists borrar_fotos_obra on storage.objects;

create policy subir_fotos_obra on storage.objects for insert
  to anon, authenticated
  with check (bucket_id = 'fotos-obra' and public.triada_rol() <> 'ninguno');

create policy borrar_fotos_obra on storage.objects for delete
  to anon, authenticated
  using (bucket_id = 'fotos-obra' and public.triada_rol() = 'admin');

select 'fotos de la obra configuradas' as estado;
