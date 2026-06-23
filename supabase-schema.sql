create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

create table if not exists public.admin_users (
  id uuid primary key default gen_random_uuid(),
  email text not null unique,
  password_hash text not null,
  name text default 'Admin User',
  role text default 'Administrator',
  phone text,
  location text,
  bio text,
  is_active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.settings (
  id integer primary key default 1 check (id = 1),
  site_title text default 'Project MUN',
  site_email text default 'projectmun.team@gmail.com',
  site_phone text default '+63 (XXX) XXX-XXXX',
  site_location text default 'Philippines',
  site_github text default '#',
  site_linkedin text default '#',
  site_facebook text default '#',
  site_twitter text default '#',
  updated_at timestamptz default now()
);

create table if not exists public.hero_slides (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  subtitle text,
  description text,
  button_text text default 'Learn More',
  button_link text default '#portfolio',
  image_url text,
  display_order integer default 0,
  is_active boolean default true,
  created_at timestamptz default now()
);

create table if not exists public.team_members (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  role text not null,
  initials text,
  description text,
  linkedin text,
  github text,
  email text,
  image_url text,
  display_order integer default 0,
  created_at timestamptz default now()
);

create table if not exists public.services (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null,
  icon text default 'Code',
  color text default 'blue',
  features jsonb default '[]'::jsonb,
  display_order integer default 0,
  is_active boolean default true,
  created_at timestamptz default now()
);

create table if not exists public.skills (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text default 'Frontend',
  icon text default 'Cpu',
  color text default '#3B82F6',
  proficiency integer default 80 check (proficiency between 0 and 100),
  display_order integer default 0,
  is_active boolean default true,
  created_at timestamptz default now()
);

create table if not exists public.testimonials (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  role text,
  content text not null,
  rating integer default 5 check (rating between 1 and 5),
  image_url text,
  display_order integer default 0,
  is_active boolean default true,
  created_at timestamptz default now()
);

create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  category text default 'Web Development',
  status text default 'Pending',
  image_url text,
  project_url text,
  video_url text,
  video_two_url text,
  created_at timestamptz default now()
);

create table if not exists public.contact_messages (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  email text not null,
  subject text not null,
  message text not null,
  created_at timestamptz default now()
);

insert into public.settings (id) values (1) on conflict (id) do nothing;

-- Change this email and password before running in production.
-- The app logs in against public.admin_users, not Supabase Auth.
insert into public.admin_users (email, password_hash, name, role)
values (
  'admin@projectmun.com',
  extensions.crypt('ChangeMe123!', extensions.gen_salt('bf')),
  'Project MUN Admin',
  'Administrator'
)
on conflict (email) do nothing;

insert into storage.buckets (id, name, public)
values ('media', 'media', true)
on conflict (id) do update set public = true;

create or replace function public.verify_admin_login(login_email text, login_password text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  admin_record public.admin_users;
begin
  select *
  into admin_record
  from public.admin_users
  where lower(email) = lower(login_email)
    and is_active = true
    and password_hash = extensions.crypt(login_password, password_hash)
  limit 1;

  if admin_record.id is null then
    return jsonb_build_object('success', false, 'message', 'Invalid email or password');
  end if;

  return jsonb_build_object(
    'success', true,
    'user', jsonb_build_object(
      'id', admin_record.id,
      'email', admin_record.email,
      'name', admin_record.name,
      'role', admin_record.role,
      'phone', coalesce(admin_record.phone, ''),
      'location', coalesce(admin_record.location, ''),
      'bio', coalesce(admin_record.bio, '')
    )
  );
end;
$$;

grant execute on function public.verify_admin_login(text, text) to anon;

create or replace function public.set_admin_password(admin_email text, new_password text)
returns void
language sql
security definer
set search_path = public
as $$
  update public.admin_users
  set password_hash = extensions.crypt(new_password, extensions.gen_salt('bf')),
      updated_at = now()
  where lower(email) = lower(admin_email);
$$;

revoke execute on function public.set_admin_password(text, text) from public;
revoke execute on function public.set_admin_password(text, text) from anon;
revoke execute on function public.set_admin_password(text, text) from authenticated;

create or replace function public.update_admin_profile(
  admin_id uuid,
  admin_name text,
  admin_email text,
  admin_role text,
  admin_phone text,
  admin_location text,
  admin_bio text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  admin_record public.admin_users;
begin
  update public.admin_users
  set name = admin_name,
      email = admin_email,
      role = admin_role,
      phone = admin_phone,
      location = admin_location,
      bio = admin_bio,
      updated_at = now()
  where id = admin_id
  returning * into admin_record;

  if admin_record.id is null then
    raise exception 'Admin user not found';
  end if;

  return jsonb_build_object(
    'id', admin_record.id,
    'email', admin_record.email,
    'name', admin_record.name,
    'role', admin_record.role,
    'phone', coalesce(admin_record.phone, ''),
    'location', coalesce(admin_record.location, ''),
    'bio', coalesce(admin_record.bio, '')
  );
end;
$$;

grant execute on function public.update_admin_profile(uuid, text, text, text, text, text, text) to anon;

alter table public.settings enable row level security;
alter table public.admin_users enable row level security;
alter table public.hero_slides enable row level security;
alter table public.team_members enable row level security;
alter table public.services enable row level security;
alter table public.skills enable row level security;
alter table public.testimonials enable row level security;
alter table public.projects enable row level security;
alter table public.contact_messages enable row level security;

drop policy if exists "Public can read settings" on public.settings;
drop policy if exists "Public can update admin profile" on public.admin_users;
drop policy if exists "Public can read hero slides" on public.hero_slides;
drop policy if exists "Public can read team members" on public.team_members;
drop policy if exists "Public can read services" on public.services;
drop policy if exists "Public can read skills" on public.skills;
drop policy if exists "Public can read testimonials" on public.testimonials;
drop policy if exists "Public can read projects" on public.projects;
drop policy if exists "Public can submit contact messages" on public.contact_messages;
drop policy if exists "Authenticated admins can write settings" on public.settings;
drop policy if exists "Custom admin can write settings" on public.settings;
drop policy if exists "Custom admin can write hero slides" on public.hero_slides;
drop policy if exists "Custom admin can write team members" on public.team_members;
drop policy if exists "Custom admin can write services" on public.services;
drop policy if exists "Custom admin can write skills" on public.skills;
drop policy if exists "Custom admin can write testimonials" on public.testimonials;
drop policy if exists "Custom admin can write projects" on public.projects;
drop policy if exists "Custom admin can read contact messages" on public.contact_messages;
drop policy if exists "Custom admin can upload media" on storage.objects;
drop policy if exists "Custom admin can update media" on storage.objects;
drop policy if exists "Custom admin can delete media" on storage.objects;
drop policy if exists "Authenticated admins can write hero slides" on public.hero_slides;
drop policy if exists "Authenticated admins can write team members" on public.team_members;
drop policy if exists "Authenticated admins can write services" on public.services;
drop policy if exists "Authenticated admins can write skills" on public.skills;
drop policy if exists "Authenticated admins can write testimonials" on public.testimonials;
drop policy if exists "Authenticated admins can write projects" on public.projects;
drop policy if exists "Authenticated admins can read contact messages" on public.contact_messages;
drop policy if exists "Public can read media" on storage.objects;
drop policy if exists "Authenticated admins can upload media" on storage.objects;
drop policy if exists "Authenticated admins can update media" on storage.objects;
drop policy if exists "Authenticated admins can delete media" on storage.objects;

create policy "Public can read settings" on public.settings for select using (true);
create policy "Public can read hero slides" on public.hero_slides for select using (true);
create policy "Public can read team members" on public.team_members for select using (true);
create policy "Public can read services" on public.services for select using (true);
create policy "Public can read skills" on public.skills for select using (true);
create policy "Public can read testimonials" on public.testimonials for select using (true);
create policy "Public can read projects" on public.projects for select using (true);
create policy "Public can submit contact messages" on public.contact_messages for insert with check (true);

-- Custom admin login is handled by the app, not by Supabase Auth.
-- These write policies are open to the anon API key so the existing admin UI can save data.
-- For stronger production security, put these writes behind a server/API route.
create policy "Custom admin can write settings" on public.settings for all using (true) with check (true);
create policy "Custom admin can write hero slides" on public.hero_slides for all using (true) with check (true);
create policy "Custom admin can write team members" on public.team_members for all using (true) with check (true);
create policy "Custom admin can write services" on public.services for all using (true) with check (true);
create policy "Custom admin can write skills" on public.skills for all using (true) with check (true);
create policy "Custom admin can write testimonials" on public.testimonials for all using (true) with check (true);
create policy "Custom admin can write projects" on public.projects for all using (true) with check (true);
create policy "Custom admin can read contact messages" on public.contact_messages for select using (true);

create policy "Public can read media" on storage.objects for select using (bucket_id = 'media');
create policy "Custom admin can upload media" on storage.objects for insert with check (bucket_id = 'media');
create policy "Custom admin can update media" on storage.objects for update using (bucket_id = 'media') with check (bucket_id = 'media');
create policy "Custom admin can delete media" on storage.objects for delete using (bucket_id = 'media');
