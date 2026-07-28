-- Схема PIM Hackathon Ideas. §3 из docs/SPEC.md.
--
-- Вставлять в Supabase → SQL Editor блоками, между разделителями «-- ====»,
-- и смотреть на ошибки после каждого.
--
-- ВАЖНО: редактор выполняет всё содержимое вкладки, а не только последнюю
-- вставку. Перед каждым блоком чистите вкладку целиком (Ctrl+A, Delete) —
-- иначе предыдущий блок отработает повторно и запуск упадёт на
-- «42710: type "category" already exists». Всё содержимое вкладки идёт одной
-- транзакцией, поэтому после такой ошибки новый блок не применяется вообще.
-- Второй способ: держать файл целиком в одной вкладке и выделять нужный блок
-- мышью — выделенное выполняется отдельно.
--
-- ПЕРЕД ЗАПУСКОМ: впишите реальные рабочие почты организаторов в app.is_admin().
--
-- Проверено на Postgres 16 и 17 набором supabase/test/01-checks.sql.

-- ==== 1. Таблицы ====
create type category    as enum ('AI','TOOLS','AUTO','INTEGR','GAME','EXP','OTHER');
create type idea_status as enum ('REVIEW','SELECTED','RESERVE');

create table profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  email        text not null unique,
  display_name text not null,
  blocked      boolean not null default false,
  created_at   timestamptz not null default now()
);

create table ideas (
  id           uuid primary key default gen_random_uuid(),
  title        text not null check (char_length(title) between 4 and 80),
  description  text not null check (char_length(description) <= 280),
  category     category not null,
  custom_label text check (char_length(custom_label) <= 30),
  is_anonymous boolean not null default false,
  hidden       boolean not null default false,
  status       idea_status not null default 'REVIEW',
  author_id    uuid not null references profiles(id),
  created_at   timestamptz not null default now()
);

create table votes (
  user_id uuid references profiles(id) on delete cascade,
  idea_id uuid references ideas(id) on delete cascade,
  primary key (user_id, idea_id)
);

create table joins (
  user_id uuid references profiles(id) on delete cascade,
  idea_id uuid references ideas(id) on delete cascade,
  primary key (user_id, idea_id)
);

create table comments (
  id         uuid primary key default gen_random_uuid(),
  idea_id    uuid not null references ideas(id) on delete cascade,
  user_id    uuid not null references profiles(id),
  text       text not null check (char_length(text) between 3 and 400),
  created_at timestamptz not null default now()
);

-- ==== 2. Функции и триггеры ====
create schema if not exists app;

-- ЗАМЕНИТЬ на реальные рабочие почты организаторов, можно несколько через запятую.
-- Личный gmail сюда не подойдёт: вход с чужого домена рубит триггер ниже.
create function app.is_admin() returns boolean language sql stable as $$
  select coalesce(auth.jwt() ->> 'email', '') in (
    'evgeny.evseev@pimpay.ru',
    'vera.miroshnichenko@pimpay.ru',
    'va@pimsolutions.ru',
    'dmitrii.rybin@pimpay.ru',
    'ekaterina.mitrofanova@pimsolutions.ru',
    'aleksey.novikov@pimsolutions.ru',
    'galina.konurina@pimsolutions.ru',
    'alexandra.mavrina@pimsolutions.ru'
  )
$$;

create function app.on_new_user() returns trigger
language plpgsql security definer as $$
begin
  if split_part(new.email, '@', 2) not in ('pimpay.ru','pimsolutions.ru') then
    raise exception 'EMAIL_DOMAIN_NOT_ALLOWED';
  end if;
  insert into public.profiles (id, email, display_name)
  values (new.id, new.email,
          coalesce(nullif(new.raw_user_meta_data->>'full_name',''),
                   split_part(new.email,'@',1)));
  return new;
end $$;

create trigger on_auth_user_created after insert on auth.users
  for each row execute function app.on_new_user();

create function app.is_blocked() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select blocked from profiles where id = auth.uid()), false)
$$;

create function app.vote_budget() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if (select count(*) from votes v join ideas i on i.id = v.idea_id
      where v.user_id = new.user_id and not i.hidden) >= 5 then
    raise exception 'VOTE_BUDGET_EXCEEDED';
  end if;
  return new;
end $$;

create trigger votes_budget before insert on votes
  for each row execute function app.vote_budget();

create function public.set_blocked(target uuid, val boolean) returns void
language plpgsql security definer set search_path = public, app as $$
begin
  if not app.is_admin() then raise exception 'FORBIDDEN'; end if;
  update profiles set blocked = val where id = target;
end $$;

create function public.me() returns json
language sql stable security definer set search_path = public, app as $$
  select json_build_object(
    'display_name', (select display_name from profiles where id = auth.uid()),
    'is_admin',     app.is_admin(),
    'votes_used',   (select count(*) from votes v join ideas i on i.id = v.idea_id
                     where v.user_id = auth.uid() and not i.hidden),
    'vote_budget',  5,
    'blocked',      app.is_blocked()
  )
$$;

-- ==== 3. Вью для сотрудников ====
create view ideas_public as
select
  i.id, i.title, i.description, i.category, i.custom_label, i.created_at,
  case when i.is_anonymous then null else p.display_name end as author_name,
  (select count(*) from votes    v where v.idea_id = i.id) as vote_count,
  (select count(*) from joins    j where j.idea_id = i.id) as join_count,
  (select count(*) from comments c where c.idea_id = i.id) as comment_count,
  exists (select 1 from votes v where v.idea_id = i.id and v.user_id = auth.uid()) as has_voted,
  exists (select 1 from joins j where j.idea_id = i.id and j.user_id = auth.uid()) as has_joined
from ideas i join profiles p on p.id = i.author_id
where not i.hidden;

create view comments_public as
select c.id, c.idea_id, c.text, c.created_at, p.display_name as author_name
from comments c
  join profiles p on p.id = c.user_id
  join ideas   i on i.id = c.idea_id
where not i.hidden;

-- ==== 4. Права и политики ====
revoke all on all tables in schema public from anon, authenticated;
grant select on ideas_public, comments_public to authenticated;
grant execute on function public.me(), public.set_blocked(uuid, boolean) to authenticated;

alter table profiles enable row level security;
alter table ideas    enable row level security;
alter table votes    enable row level security;
alter table joins    enable row level security;
alter table comments enable row level security;

grant select on profiles to authenticated;
grant update (display_name) on profiles to authenticated;
grant select, insert, update on ideas to authenticated;
grant select, insert, delete on votes, joins to authenticated;
grant select, insert on comments to authenticated;

create policy p_self   on profiles for select to authenticated using (id = auth.uid() or app.is_admin());
create policy p_rename on profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

create policy i_admin  on ideas for select to authenticated using (app.is_admin());
create policy i_new    on ideas for insert to authenticated with check (author_id = auth.uid() and not app.is_blocked());
create policy i_mod    on ideas for update to authenticated using (app.is_admin()) with check (app.is_admin());

create policy v_read   on votes for select to authenticated using (user_id = auth.uid() or app.is_admin());
create policy v_add    on votes for insert to authenticated with check (user_id = auth.uid() and not app.is_blocked());
create policy v_del    on votes for delete to authenticated using (user_id = auth.uid());

create policy j_read   on joins for select to authenticated using (user_id = auth.uid() or app.is_admin());
create policy j_add    on joins for insert to authenticated with check (user_id = auth.uid() and not app.is_blocked());
create policy j_del    on joins for delete to authenticated using (user_id = auth.uid());

create policy c_read   on comments for select to authenticated using (app.is_admin());
create policy c_add    on comments for insert to authenticated with check (user_id = auth.uid() and not app.is_blocked());
