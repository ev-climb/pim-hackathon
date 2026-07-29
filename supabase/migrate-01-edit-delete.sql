-- Миграция 01: автор правит и удаляет свою идею, описание до 500 символов.
--
-- Нужна только базе, которая уже создана по прежней версии schema.sql.
-- На чистом проекте ничего запускать не надо — всё это уже внутри schema.sql.
--
-- Запускать в Supabase → SQL Editor блоками, между разделителями «-- ====»,
-- в ЧИСТОЙ вкладке: редактор выполняет всё её содержимое целиком.
-- Блоки идемпотентны, повторный запуск безвреден.
--
-- После блока 2 PostgREST подхватывает новые функции сам; если rpc отвечает
-- «Could not find the function», нажмите Settings → API → Reload schema cache.

-- ==== 1. Таблица: длина описания и отметка о правке ====
alter table ideas drop constraint if exists ideas_description_check;
alter table ideas add  constraint ideas_description_check check (char_length(description) <= 500);
alter table ideas add column if not exists edited_at timestamptz;

-- ==== 2. Функции правки и удаления ====
-- Через функции, а не через политику на ideas: грант update в Postgres не умеет
-- зависеть от роли, и открытый автору update дал бы ему заодно status и hidden.
create or replace function public.update_my_idea(
  target uuid, new_title text, new_description text,
  new_category category, new_custom_label text, new_is_anonymous boolean
) returns void
language plpgsql security definer set search_path = public, app as $$
declare owner uuid;
begin
  if app.is_blocked() then raise exception 'FORBIDDEN'; end if;
  select author_id into owner from ideas where id = target and not hidden;
  if owner is null or owner <> auth.uid() then raise exception 'NOT_YOUR_IDEA'; end if;
  update ideas set
    title        = new_title,
    description  = new_description,
    category     = new_category,
    -- Своя тема живёт только у «Другого» (§4.5): сменил категорию — тема ушла
    custom_label = case when new_category = 'OTHER' then new_custom_label end,
    is_anonymous = new_is_anonymous,
    edited_at    = now()
  where id = target;
end $$;

-- Удаление — только пока на идею не откликнулись коллеги. Свои же голос,
-- «в команду» и дополнение не в счёт.
create or replace function public.delete_my_idea(target uuid) returns void
language plpgsql security definer set search_path = public, app as $$
declare owner uuid;
begin
  if app.is_blocked() then raise exception 'FORBIDDEN'; end if;
  select author_id into owner from ideas where id = target and not hidden;
  if owner is null or owner <> auth.uid() then raise exception 'NOT_YOUR_IDEA'; end if;
  if exists (select 1 from votes    where idea_id = target and user_id <> owner)
     or exists (select 1 from joins    where idea_id = target and user_id <> owner)
     or exists (select 1 from comments where idea_id = target and user_id <> owner)
  then raise exception 'IDEA_HAS_REACTIONS'; end if;
  delete from ideas where id = target;  -- каскадом уносит собственные отклики автора
end $$;

grant execute on function
  public.update_my_idea(uuid, text, text, category, text, boolean),
  public.delete_my_idea(uuid) to authenticated;

-- ==== 3. Вью с новыми колонками ====
-- Именно drop + create: create or replace view умеет только дописывать колонки
-- в конец, а edited_at встаёт в середину списка.
drop view ideas_public;

create view ideas_public as
select
  i.id, i.title, i.description, i.category, i.custom_label, i.created_at, i.edited_at,
  case when i.is_anonymous then null else p.display_name end as author_name,
  (select count(*) from votes    v where v.idea_id = i.id) as vote_count,
  (select count(*) from joins    j where j.idea_id = i.id) as join_count,
  (select count(*) from comments c where c.idea_id = i.id) as comment_count,
  exists (select 1 from votes v where v.idea_id = i.id and v.user_id = auth.uid()) as has_voted,
  exists (select 1 from joins j where j.idea_id = i.id and j.user_id = auth.uid()) as has_joined,
  coalesce(i.author_id = auth.uid(), false) as is_mine,
  case when i.author_id = auth.uid() then i.is_anonymous else false end as is_anonymous,
  case when i.author_id = auth.uid() then not exists (
         select 1 from votes    v where v.idea_id = i.id and v.user_id <> i.author_id
         union all
         select 1 from joins    j where j.idea_id = i.id and j.user_id <> i.author_id
         union all
         select 1 from comments c where c.idea_id = i.id and c.user_id <> i.author_id)
       else false end as can_delete
from ideas i join profiles p on p.id = i.author_id
where not i.hidden;

grant select on ideas_public to authenticated;  -- drop view уносит и грант

-- ==== 4. Проверка ====
select
  (select count(*) from information_schema.columns
    where table_name='ideas' and column_name='edited_at')                     as "колонка edited_at",
  (select count(*) from information_schema.columns
    where table_name='ideas_public' and column_name in ('is_mine','can_delete')) as "колонки вью",
  (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.proname in ('update_my_idea','delete_my_idea')) as "функции";
-- Ожидается: 1, 2, 2
