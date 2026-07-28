-- Минимальная имитация того, что Supabase даёт из коробки.
create role anon nologin;
create role authenticated nologin;

create schema auth;

create table auth.users (
  id                 uuid primary key,
  email              text not null,
  raw_user_meta_data jsonb not null default '{}'
);

create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claims', true)::json ->> 'sub','')::uuid
$$;

create function auth.jwt() returns jsonb language sql stable as $$
  select coalesce(nullif(current_setting('request.jwt.claims', true),'')::jsonb, '{}'::jsonb)
$$;

grant usage on schema public to anon, authenticated;
-- Supabase выдаёт это сам при создании проекта, иначе auth.uid() в политиках недоступен
grant usage on schema auth to anon, authenticated;
