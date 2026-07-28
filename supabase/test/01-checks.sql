\set ON_ERROR_STOP on
\set QUIET on
\pset pager off

-- 21 проверка правил из §4 SPEC.md: приватность, бюджет голосов, блокировка,
-- модерация. Гоняется на пустой базе поверх 00-stub.sql и schema.sql —
-- скрипт вставляет свои данные, повторный запуск упадёт на дубликате ключа.
--
-- ВНИМАНИЕ: адрес 'evgeny.evseev@pimpay.ru' ниже должен присутствовать
-- в списке app.is_admin(). Меняете список организаторов — поменяйте и здесь,
-- иначе проверки 12 и 13 отвалятся с «почта из списка не даёт админа».

-- ============ подготовка данных (от владельца, RLS не применяется) ============

-- 1. чужой домен режется триггером
do $$
begin
  insert into auth.users(id,email) values
    ('99999999-9999-9999-9999-999999999999','someone@gmail.com');
  raise exception 'FAIL 1: посторонний домен прошёл';
exception when others then
  if sqlerrm <> 'EMAIL_DOMAIN_NOT_ALLOWED' then raise; end if;
  raise notice 'OK  1  чужой домен отклонён: %', sqlerrm;
end $$;

-- 2. свои домены проходят, профиль создаётся сам, имя из Google-профиля
insert into auth.users(id,email,raw_user_meta_data) values
  ('11111111-1111-1111-1111-111111111111','e.sokolov@pimsolutions.ru','{"full_name":"Евгений Соколов"}'),
  ('22222222-2222-2222-2222-222222222222','m.kovaleva@pimsolutions.ru','{"full_name":"Марина Ковалёва"}'),
  ('33333333-3333-3333-3333-333333333333','evgeny.evseev@pimpay.ru','{"full_name":"Евгений Организатор"}'),
  ('44444444-4444-4444-4444-444444444444','d.volkov@pimpay.ru','{}');

do $$
declare n int; nm text;
begin
  select count(*) into n from profiles;
  if n <> 4 then raise exception 'FAIL 2: профилей %, ожидалось 4', n; end if;
  select display_name into nm from profiles where email='d.volkov@pimpay.ru';
  if nm <> 'd.volkov' then raise exception 'FAIL 2: фолбэк имени = %', nm; end if;
  raise notice 'OK  2  4 профиля созданы, фолбэк имени без full_name = %', nm;
end $$;

-- 7 идей от Марины
insert into ideas(id,title,description,category,author_id) values
  ('aaaa0001-0000-0000-0000-000000000001','Идея один',   'описание','AI',   '22222222-2222-2222-2222-222222222222'),
  ('aaaa0002-0000-0000-0000-000000000002','Идея два',    'описание','TOOLS','22222222-2222-2222-2222-222222222222'),
  ('aaaa0003-0000-0000-0000-000000000003','Идея три',    'описание','AUTO', '22222222-2222-2222-2222-222222222222'),
  ('aaaa0004-0000-0000-0000-000000000004','Идея четыре', 'описание','GAME', '22222222-2222-2222-2222-222222222222'),
  ('aaaa0005-0000-0000-0000-000000000005','Идея пять',   'описание','EXP',  '22222222-2222-2222-2222-222222222222'),
  ('aaaa0006-0000-0000-0000-000000000006','Идея шесть',  'описание','INTEGR','22222222-2222-2222-2222-222222222222'),
  ('aaaa0007-0000-0000-0000-000000000007','Идея анонима','описание','OTHER','22222222-2222-2222-2222-222222222222');
update ideas set is_anonymous = true where id='aaaa0007-0000-0000-0000-000000000007';
insert into comments(idea_id,user_id,text) values
  ('aaaa0001-0000-0000-0000-000000000001','22222222-2222-2222-2222-222222222222','дополнение к первой');

-- ============ дальше от имени рядового сотрудника ============
select set_config('request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","email":"e.sokolov@pimsolutions.ru"}', false);
set role authenticated;

-- 3. базовые таблицы закрыты
do $$
declare n int;
begin
  select count(*) into n from ideas;
  if n <> 0 then raise exception 'FAIL 3: сотрудник видит % идей в таблице ideas', n; end if;
  select count(*) into n from profiles;
  if n <> 1 then raise exception 'FAIL 3: сотрудник видит % профилей', n; end if;
  raise notice 'OK  3  ideas → 0 строк, profiles → только своя';
end $$;

-- 4. вью отдаёт идеи, но без почт и без имени анонима
do $$
declare n int; a text;
begin
  select count(*) into n from ideas_public;
  if n <> 7 then raise exception 'FAIL 4: ideas_public отдал % строк', n; end if;
  select author_name into a from ideas_public where title='Идея анонима';
  if a is not null then raise exception 'FAIL 4: имя анонима утекло: %', a; end if;
  select author_name into a from ideas_public where title='Идея один';
  if a <> 'Марина Ковалёва' then raise exception 'FAIL 4: автор = %', a; end if;
  raise notice 'OK  4  ideas_public: 7 идей, у анонима author_name = null, у обычной = %', a;
end $$;

-- 5. бюджет голосов: пять проходят, шестой отклоняется базой
insert into votes(user_id,idea_id) values
  ('11111111-1111-1111-1111-111111111111','aaaa0001-0000-0000-0000-000000000001'),
  ('11111111-1111-1111-1111-111111111111','aaaa0002-0000-0000-0000-000000000002'),
  ('11111111-1111-1111-1111-111111111111','aaaa0003-0000-0000-0000-000000000003'),
  ('11111111-1111-1111-1111-111111111111','aaaa0004-0000-0000-0000-000000000004'),
  ('11111111-1111-1111-1111-111111111111','aaaa0005-0000-0000-0000-000000000005');

do $$
begin
  insert into votes(user_id,idea_id) values
    ('11111111-1111-1111-1111-111111111111','aaaa0006-0000-0000-0000-000000000006');
  raise exception 'FAIL 5: шестой голос прошёл — триггер не сработал';
exception when others then
  if sqlerrm <> 'VOTE_BUDGET_EXCEEDED' then raise; end if;
  raise notice 'OK  5  шестой голос отклонён прямым insert: %', sqlerrm;
end $$;

-- 6. me() считает потраченные голоса
do $$
declare j json;
begin
  select public.me() into j;
  if (j->>'votes_used')::int <> 5 then raise exception 'FAIL 6: votes_used = %', j->>'votes_used'; end if;
  if (j->>'is_admin')::boolean then raise exception 'FAIL 6: сотрудник считается админом'; end if;
  if (j->>'blocked')::boolean then raise exception 'FAIL 6: сотрудник считается заблокированным'; end if;
  raise notice 'OK  6  me() = %', j::text;
end $$;

-- 7. снятие голоса возвращает его в бюджет
delete from votes where idea_id='aaaa0005-0000-0000-0000-000000000005';
insert into votes(user_id,idea_id) values
  ('11111111-1111-1111-1111-111111111111','aaaa0006-0000-0000-0000-000000000006');
do $$
begin
  if (select (public.me()->>'votes_used')::int) <> 5 then raise exception 'FAIL 7'; end if;
  raise notice 'OK  7  голос снят и переставлен, votes_used снова 5';
end $$;

-- 8. сотрудник не снимает с себя блокировку и не трогает чужие профили
do $$
declare n int;
begin
  update profiles set display_name='Взломщик' where id<>auth.uid();
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'FAIL 8: переписал % чужих профилей', n; end if;
  raise notice 'OK  8  update чужого профиля затронул 0 строк';
end $$;

do $$
begin
  update profiles set blocked=false where id=auth.uid();
  raise exception 'FAIL 8: сотрудник изменил колонку blocked';
exception when insufficient_privilege then
  raise notice 'OK  8  update blocked запрещён на уровне грантов: %', sqlerrm;
end $$;

do $$
begin
  perform public.set_blocked(auth.uid(), false);
  raise exception 'FAIL 8: set_blocked сработал у неадмина';
exception when others then
  if sqlerrm <> 'FORBIDDEN' then raise; end if;
  raise notice 'OK  8  set_blocked у сотрудника → FORBIDDEN';
end $$;

-- 9. своя идея вставляется, чужим автором — нет
insert into ideas(title,description,category,author_id)
  values ('Моя идея','описание','AI','11111111-1111-1111-1111-111111111111');
do $$
begin
  insert into ideas(title,description,category,author_id)
    values ('Подделка','описание','AI','22222222-2222-2222-2222-222222222222');
  raise exception 'FAIL 9: вставил идею от чужого имени';
exception when insufficient_privilege then
  raise notice 'OK  9  своя идея прошла, чужой author_id отклонён политикой';
end $$;

-- 10. insert с returning падает — это и есть причина «вставлять без .select()»
do $$
declare rid uuid;
begin
  insert into ideas(title,description,category,author_id)
    values ('С возвратом','описание','AI',auth.uid()) returning id into rid;
  raise exception 'FAIL 10: returning отработал (id=%), заметка в SPEC не нужна', rid;
exception when insufficient_privilege then
  raise notice 'OK  10 insert ... returning отклонён select-политикой: %', sqlerrm;
end $$;

-- 11. сотрудник не может менять статус и скрывать идеи
do $$
declare n int;
begin
  update ideas set status='SELECTED', hidden=true;
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'FAIL 11: сотрудник изменил % идей', n; end if;
  raise notice 'OK  11 модерация сотруднику недоступна, затронуто 0 строк';
end $$;

-- ============ модерация от имени организатора ============
reset role;
select set_config('request.jwt.claims',
  '{"sub":"33333333-3333-3333-3333-333333333333","email":"evgeny.evseev@pimpay.ru"}', false);
set role authenticated;

do $$
declare n int;
begin
  if not (select (public.me()->>'is_admin')::boolean) then raise exception 'FAIL 12: почта из списка не даёт админа'; end if;
  select count(*) into n from ideas;    if n <> 8 then raise exception 'FAIL 12: админ видит % идей', n; end if;
  select count(*) into n from profiles; if n <> 4 then raise exception 'FAIL 12: админ видит % профилей', n; end if;
  select count(*) into n from votes;    if n <> 5 then raise exception 'FAIL 12: админ видит % голосов', n; end if;
  select count(*) into n from comments; if n <> 1 then raise exception 'FAIL 12: админ видит % дополнений', n; end if;
  raise notice 'OK  12 организатор читает базовые таблицы: 8 идей, 4 профиля, 5 голосов, 1 дополнение';
end $$;

update ideas set hidden = true where id='aaaa0001-0000-0000-0000-000000000001';
do $$
begin
  if (select hidden from ideas where id='aaaa0001-0000-0000-0000-000000000001') is not true
    then raise exception 'FAIL 13: скрыть не удалось'; end if;
  raise notice 'OK  13 организатор скрыл идею';
end $$;
select public.set_blocked('44444444-4444-4444-4444-444444444444', true);

-- ============ снова сотрудник: скрытие вернуло голос ============
reset role;
select set_config('request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","email":"e.sokolov@pimsolutions.ru"}', false);
set role authenticated;

do $$
declare n int;
begin
  if (select (public.me()->>'votes_used')::int) <> 4 then
    raise exception 'FAIL 14: после скрытия votes_used = %', (select public.me()->>'votes_used'); end if;
  select count(*) into n from ideas_public;
  if n <> 7 then raise exception 'FAIL 14: скрытая идея видна, строк %', n; end if;
  select count(*) into n from comments_public;
  if n <> 0 then raise exception 'FAIL 14: дополнение к скрытой идее читается, строк %', n; end if;
  raise notice 'OK  14 скрытая идея исчезла из ideas_public, её дополнения — из comments_public, голос вернулся в бюджет';
end $$;

-- голос за пятую снова проходит: бюджет освободился
insert into votes(user_id,idea_id) values
  ('11111111-1111-1111-1111-111111111111','aaaa0005-0000-0000-0000-000000000005');
do $$
begin
  if (select (public.me()->>'votes_used')::int) <> 5 then raise exception 'FAIL 15'; end if;
  raise notice 'OK  15 вернувшийся голос отдан другой идее';
end $$;

-- ============ заблокированный ============
reset role;
select set_config('request.jwt.claims',
  '{"sub":"44444444-4444-4444-4444-444444444444","email":"d.volkov@pimpay.ru"}', false);
set role authenticated;

do $$
declare n int;
begin
  if not (select (public.me()->>'blocked')::boolean) then raise exception 'FAIL 16: блокировка не видна в me()'; end if;
  select count(*) into n from ideas_public;
  if n <> 7 then raise exception 'FAIL 16: заблокированный не читает идеи'; end if;
  raise notice 'OK  16 заблокированный читает идеи и видит blocked=true в me()';
end $$;

do $$
begin
  insert into votes(user_id,idea_id) values (auth.uid(),'aaaa0002-0000-0000-0000-000000000002');
  raise exception 'FAIL 17: заблокированный проголосовал';
exception when insufficient_privilege then
  raise notice 'OK  17 голос заблокированного отклонён политикой';
end $$;

do $$
begin
  insert into ideas(title,description,category,author_id) values ('Идея бана','описание','AI',auth.uid());
  raise exception 'FAIL 18: заблокированный подал идею';
exception when insufficient_privilege then
  raise notice 'OK  18 идея заблокированного отклонена политикой';
end $$;

do $$
begin
  insert into comments(idea_id,user_id,text) values ('aaaa0002-0000-0000-0000-000000000002',auth.uid(),'текст');
  raise exception 'FAIL 19: заблокированный написал дополнение';
exception when insufficient_privilege then
  raise notice 'OK  19 дополнение заблокированного отклонено политикой';
end $$;

reset role;
\echo '=== все проверки пройдены ==='
