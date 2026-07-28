-- Зачистка перед публикацией опроса.
--
-- Запускать в Supabase → SQL Editor. Блоки по одному, в чистой вкладке —
-- редактор выполняет всё содержимое вкладки целиком.
--
-- ЧТО ВАЖНО ПОНИМАТЬ ПРО ПРОФИЛИ:
-- профиль создаётся триггером один раз, при первом входе. Если удалить строку
-- из profiles у живого человека, при следующем входе она НЕ создастся заново:
-- триггер висит на insert в auth.users, а этой записи уже нет. Человек получит
-- сломанное приложение — пустое имя и отказ при публикации идеи.
-- Поэтому профили живых людей здесь не трогаем. Удаляются только демо-люди,
-- которых завёл seed.sql и которые никогда не входили.

-- ==== БЛОК 1. Инвентаризация. Только чтение, ничего не меняет ====

select 'демо-профили из seed'      as что, count(*) as сколько from profiles where id::text like 'dddddd%'
union all
select 'профили живых людей',        count(*) from profiles where id::text not like 'dddddd%'
union all
select 'демо-идеи из seed',          count(*) from ideas    where id::text like 'aaaaaa%'
union all
select 'идеи от живых людей',        count(*) from ideas    where id::text not like 'aaaaaa%'
union all
select 'голосов всего',              count(*) from votes
union all
select 'отметок «в команду» всего',  count(*) from joins
union all
select 'дополнений всего',           count(*) from comments
union all
select 'заблокированных',            count(*) from profiles where blocked;

-- Кто уже заходил в приложение — этих людей сохраняем
select display_name as имя, email as почта, blocked as заблокирован, created_at as первый_вход
from profiles
where id::text not like 'dddddd%'
order by created_at;

-- Что успели создать живые люди. Посмотрите список: если среди этого есть
-- настоящая идея, которую хочется сохранить, используйте вариант Б в блоке 2
select i.title as идея, p.display_name as автор, p.email as почта,
       i.created_at as создана, i.hidden as скрыта,
       (select count(*) from votes v where v.idea_id = i.id) as голосов
from ideas i join profiles p on p.id = i.author_id
where i.id::text not like 'aaaaaa%'
order by i.created_at;

-- ==== БЛОК 2, вариант А. Полная зачистка ====
-- Опрос стартует с нуля: ни одной идеи, ни одного голоса.
-- Профили и учётки живых людей остаются, повторный вход им не нужен.
--
-- Раскомментировать и выполнить:
--
-- begin;
--   delete from ideas;                                    -- каскадом уносит голоса, «в команду» и дополнения
--   delete from auth.users where id::text like 'dddddd%'; -- каскадом уносит демо-профили
--   update profiles set blocked = false where blocked;    -- снимаем блокировки, поставленные при проверке
-- commit;

-- ==== БЛОК 2, вариант Б. Снести только демо и тесты, сохранив выбранные идеи ====
-- Подставьте id идей, которые остаются, в список ниже.
--
-- У сохранённых идей остаются голоса и дополнения живых людей. Голоса демо-людей
-- с них исчезнут — вместе с самими демо-профилями, и это правильно: этих людей
-- не существует. Проверено: у идеи с двумя голосами (демо + живой) остался один.
--
-- begin;
--   delete from ideas
--    where id not in (
--      '00000000-0000-0000-0000-000000000000'   -- сюда id сохраняемых идей, через запятую
--    );
--   delete from auth.users where id::text like 'dddddd%';
--   update profiles set blocked = false where blocked;
-- commit;

-- ==== БЛОК 3. Проверка после зачистки ====

select 'идей'                as что, count(*) as сколько from ideas
union all select 'голосов',          count(*) from votes
union all select 'в команду',        count(*) from joins
union all select 'дополнений',       count(*) from comments
union all select 'демо-профилей',    count(*) from profiles where id::text like 'dddddd%'
union all select 'живых профилей',   count(*) from profiles where id::text not like 'dddddd%'
union all select 'заблокированных',  count(*) from profiles where blocked;
