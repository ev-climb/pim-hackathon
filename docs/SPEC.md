# PIM Hackathon Ideas — техническое задание

Внутреннее приложение для сбора идей к хакатону. Разовый опрос, ~30 человек, живёт две недели.

Рядом лежит `hackathon-ideas-prototype.html` — **утверждённый кликабельный прототип**, источник правды по визуалу и поведению.

**Держи в голове масштаб.** Это не платформа. Не добавляй абстракций, слоёв и обобщений «на будущее» — будущего у этого кода нет. Работающий сценарий целиком важнее аккуратной архитектуры.

---

## 0. Как работать с прототипом

1. Открой его в браузере и прокликай три режима (переключатель вверху — это леса прототипа, в продакшене их нет).
2. Дизайн не переделывать. Вёрстка, токены, тексты, отступы, анимации — как есть. Кажется неверным — спроси.
3. Логика внутри на моках; переписать под реальные данные, **правила поведения сохранить дословно** (§4).
4. Тексты интерфейса выверены, переносить буквально, включая кавычки-ёлочки.

---

## 1. Роли

| Роль | Вход | Что может |
|---|---|---|
| **Сотрудник** | Google, домены `pimpay.ru` и `pimsolutions.ru` | Предлагать идеи, голосовать (лимит 5), отмечать «В команду», писать дополнения |
| **Организатор** | тот же Google, почта в списке админов | Всё то же + вкладка `/admin`: рейтинг, авторы с почтами, кто голосовал, кто в команду, дополнения, смена статуса |

Отдельного входа по паролю нет. Организатор — обычный пользователь, чья почта перечислена в SQL-функции. Одна учётка, один способ входа.

---

## 2. Стек

- **Фронт:** Vue 3 (`<script setup>`) + Vite + TypeScript + Pinia + Vue Router + Tailwind
- **Бэк:** Supabase — Postgres, Google Auth, RLS. Серверного кода нет.
- **Хостинг:** Vercel, подключённый к репозиторию (деплой на каждый push в `main`)

Публичный `anon`-ключ лежит в бандле — так задумано. Данные защищают политики доступа, а не секретность ключа.

**Задел на переезд внутрь компании,** если попросит служба безопасности: схема — чистый Postgres; вызовы Supabase только в `src/api/`, в компонентах и сторах ни одного прямого импорта клиента.

---

## 3. База

Весь SQL ниже — один файл `supabase/schema.sql`. Меньше страницы, вставляется один раз.

### 3.1 Таблицы

```sql
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
  description  text not null check (char_length(description) <= 500),
  category     category not null,
  custom_label text check (char_length(custom_label) <= 30),
  is_anonymous boolean not null default false,
  hidden       boolean not null default false,
  status       idea_status not null default 'REVIEW',
  author_id    uuid not null references profiles(id),
  created_at   timestamptz not null default now(),
  edited_at    timestamptz              -- null, пока автор не правил идею
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
```

Категории (порядок в UI сохранить): `AI` AI-агенты `#F6C915` · `TOOLS` Внутр. инструменты `#7DD3FC` · `AUTO` Автоматизация `#A78BFA` · `INTEGR` Интеграции `#F472B6` · `GAME` Игровые проекты `#4ADE80` · `EXP` Эксперименты `#FB923C` · `OTHER` Другое `#9C9CA6`

Статусы: `REVIEW` «На рассмотрении», `SELECTED` «В программу», `RESERVE` «В резерв».

Значения enum ходят по приложению как есть, в верхнем регистре. В прототипе они в нижнем (`ai`, `review`) — это его внутренняя условность, переносить её не надо: слоя перекодировки быть не должно, только один словарь `AI → { label, color }` для подписей и точек в чипах.

### 3.2 Функции и триггеры

```sql
create schema if not exists app;

-- админы: просто список почт. Заменить на реальные при настройке.
create function app.is_admin() returns boolean language sql stable as $$
  select coalesce(auth.jwt() ->> 'email', '') in (
    'evgeny@pimpay.ru'
  )
$$;

-- новый пользователь: режем чужие домены, имя берём из Google-профиля
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

-- заблокированный читает, но не пишет
create function app.is_blocked() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select blocked from profiles where id = auth.uid()), false)
$$;

-- бюджет голосов: обойти нельзя даже прямым запросом.
-- голоса за скрытые идеи не считаются — бюджет возвращается сам.
-- security definer обязателен: без него джойн с ideas читается от имени сотрудника,
-- политика i_admin вернёт ноль строк и лимит просто не сработает
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

-- блокировка: только через функцию, иначе человек снимет её с себя сам
create function public.set_blocked(target uuid, val boolean) returns void
language plpgsql security definer set search_path = public, app as $$
begin
  if not app.is_admin() then raise exception 'FORBIDDEN'; end if;
  update profiles set blocked = val where id = target;
end $$;

-- правка своей идеи: функция, а не политика. грант update в Postgres не умеет
-- зависеть от роли, и открытый автору update дал бы ему заодно status и hidden.
-- меняются ровно пять колонок, edited_at штампуется здесь же
create function public.update_my_idea(
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
    title = new_title, description = new_description, category = new_category,
    custom_label = case when new_category = 'OTHER' then new_custom_label end,
    is_anonymous = new_is_anonymous, edited_at = now()
  where id = target;
end $$;

-- удаление своей идеи — только пока на неё не откликнулись коллеги.
-- свои голос, «в команду» и дополнение не в счёт, иначе автор, поддержавший
-- собственную идею, лишался бы права её убрать
create function public.delete_my_idea(target uuid) returns void
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
  delete from ideas where id = target;
end $$;

-- один запрос вместо трёх на старте приложения
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
```

### 3.3 Вью для сотрудников

Всё, что видит рядовой участник. Обрати внимание: ни почт, ни `author_id`, ни чужой анонимности, ни поимённых списков голосовавших — этих данных просто нет в ответе. Свою идею вью помечает сама: `is_mine`, `can_delete` и `is_anonymous` считаются по `auth.uid()`, поэтому кнопки «Изменить» и «Удалить» рисуются по ответу базы, а не по угадыванию на клиенте.

```sql
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
  -- анонимность отдаётся только автору: форма правки открывается с той же галочкой
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

create view comments_public as
select c.id, c.idea_id, c.text, c.created_at, p.display_name as author_name
from comments c
  join profiles p on p.id = c.user_id
  join ideas   i on i.id = c.idea_id
where not i.hidden;   -- иначе дополнения к скрытой идее читаются по idea_id
```

Вью принадлежат владельцу схемы и читают таблицы в обход RLS — именно поэтому базовые таблицы можно держать закрытыми.

### 3.4 Права

Отдельных админских вью нет: организатор читает базовые таблицы, все остальные — только вью.

```sql
revoke all on all tables in schema public from anon, authenticated;
grant select on ideas_public, comments_public to authenticated;
grant execute on function public.me(), public.set_blocked(uuid, boolean) to authenticated;
grant execute on function                                   -- правка и удаление своей идеи
  public.update_my_idea(uuid, text, text, category, text, boolean),
  public.delete_my_idea(uuid) to authenticated;

alter table profiles enable row level security;
alter table ideas    enable row level security;
alter table votes    enable row level security;
alter table joins    enable row level security;
alter table comments enable row level security;

grant select on profiles to authenticated;
grant update (display_name) on profiles to authenticated;   -- blocked менять нельзя, только через set_blocked
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
```

Политика `i_mod` покрывает и смену статуса, и скрытие идеи — обе операции доступны только организатору. Автор своей идеи под неё не попадает: правка и удаление идут через `update_my_idea()` и `delete_my_idea()`. Причина — грант `update` в Postgres не умеет зависеть от роли: колоночный грант пришлось бы выдавать обеим ролям сразу, и вместе с текстом автор получил бы `status` и `hidden`, то есть возможность самому выбрать себя в программу.

Сотрудник читает свои голоса — по ним считается остаток бюджета. Организатор читает все и джойнит с профилями на клиенте: этого хватает для колонок «кто голосовал» и «кто в команду».

**Вставлять без `.select()`.** Сотруднику `insert` в `ideas` разрешён, а `select` — нет, поэтому `insert(...).select()` упадёт на политике: `returning` проверяется select-политикой. Пишем `insert(...)` без цепочки и перечитываем список из `ideas_public` — то же и для `comments`. Голоса и «В команду» этого не касаются, там сотрудник читает свои строки.

Демо-данные из прототипа положи в `supabase/seed.sql` — на них удобно показывать приложение, пока в него не зашли живые люди.

---

## 4. Правила, которые нельзя нарушить

1. **5 голосов на человека.** Снимаются и переставляются свободно. Шестой отклоняет база с `VOTE_BUDGET_EXCEEDED` — фронт ловит и показывает тост: *«Голоса закончились. Снимите голос с другой идеи, чтобы отдать его этой»*. Голос за свою идею разрешён. Отметок «В команду» и дополнений — без лимита.
2. **Анонимность** скрывает автора только от коллег; организатор видит имя, почту и бейдж «АНОНИМ ДЛЯ КОЛЛЕГ». Действует только на саму идею: голоса и дополнения всегда под именем, в UI это написано прямым текстом.
3. **Приватность** обеспечивается структурой вью, а не фильтрацией в компонентах. Сотруднику не уходят ничьи почты, имя автора анонимной идеи и поимённые списки.
4. **Отображаемое имя** подставляется из Google-профиля при первом входе. Меняется по ссылке «Изменить имя» в шапке и подтягивается везде — оно хранится в профиле, в записи не копируется. Отдельного экрана онбординга нет.
5. **Категория «Другое»** открывает необязательное поле «Своя тема одним-двумя словами». В UI: `Другое · <тема>`, если заполнено, иначе просто «Другое».
6. **Модерация.** Организатор может **скрыть** идею (не удалить: скрытая исчезает у сотрудников, но остаётся в админке с пометкой и возвращается одной кнопкой) и **заблокировать** автора (читать может, публиковать и голосовать — нет; заблокированный видит понятный баннер, а не молча ломающиеся кнопки). Скрытие идеи возвращает потраченные на неё голоса в бюджет проголосовавших — это происходит само, потому что бюджет считается только по видимым идеям. Блокировка не скрывает уже поданные идеи, это отдельное действие.
7. **Сортировка по умолчанию — «Новые»**, «Популярные» вторым переключателем. Иначе поздние идеи никто не увидит.
8. **Своя идея правится и удаляется автором.** Правка — в любой момент, все поля разом, включая категорию и анонимность; после неё в углу карточки и в модалке появляется подпись «изменено», голоса и дополнения остаются на месте. Удаление — **только пока на идею не откликнулись коллеги**: чужой голос, «в команду» или дополнение закрывают его насовсем, дальше остаётся правка или просьба к организаторам скрыть идею. Собственные отклики автора не в счёт, иначе поддержавший свою идею лишался бы права её убрать. Кнопка удаления остаётся видимой и в закрытом случае — она объясняет отказ тостом, а не исчезает молча. Заблокированному недоступно ни то, ни другое. Проверяет всё база: `update_my_idea()` и `delete_my_idea()`, а не спрятанные кнопки.

---

## 5. Фронтенд

### 5.1 Роуты

```
/        LoginView  — для неавторизованных
/ideas   IdeasView  — облако идей
/admin   AdminView  — только если me().is_admin
```

Гвард глобальный. Сотрудник, зашедший на `/admin`, редиректится на `/ideas` — и данных всё равно не получит, политики вернут пусто.

Организатор — такой же сотрудник: он может предложить идею и проголосовать наравне со всеми. Поэтому при `is_admin` в шапке появляется переключатель разделов «Облако идей» / «Рейтинг»; у остальных его нет.

Кнопки модерации живут внутри развёрнутой строки рейтинга, а не в самой строке: лишний клик здесь полезен, случайно скрыть идею не получится. Блокировка требует подтверждения в модалке, скрытие — нет, оно обратимо.

На старте приложения один вызов `me()`: имя, признак админа, потраченные голоса.

Экран входа — одна карточка с кнопкой Google, тремя шагами «как это устроено» и приписками про домены и приватность. Отдельного входа для организаторов нет. Блок ошибки в карточке показывается при `EMAIL_DOMAIN_NOT_ALLOWED`: «Вход только с рабочей почты @pimpay.ru или @pimsolutions.ru». В прототипе его можно посмотреть кнопкой «Ошибка домена» в верхней панели. Барьер держит база, фронт отвечает за формулировку.

Отдельного экрана онбординга нет: имя приходит из Google-профиля, меняется через «Изменить имя» в шапке.

### 5.2 Компоненты

Разбирай прототип по блокам: `CircuitBackground`, `IdeaComposer`, `CategoryChips`, `VoteBudget`, `SortToggle`, `IdeaCard`, `IdeaModal`, `BaseModal`, `ToastHost`, `KpiCards`, `RankRow`.

Правка идеи отдельной формы не получила: `IdeaEditModal` — это `BaseModal` с тем же `IdeaComposer`, которому передали идею. Одна форма, одни ограничения полей, ничего не разъезжается.

Сторы: `auth`, `ideas` (список, фильтры, сортировка, оптимистичные апдейты), `toasts`.

### 5.3 Токены

```
Фон #0D0D0F · поверхности #161619 / #1E1E22 / #26262B
Границы rgba(255,255,255,.09), сильная .16
Акцент #F6C915 (hover #FFD84D, текст на нём #0D0D0F)
Текст #F4F4F5 / #9C9CA6 / #6A6A73 · успех #4ADE80
Радиусы 22 / 16 / 11 · тень 0 24px 60px -20px rgba(0,0,0,.7)
```

Шрифты: **Archivo Expanded** 800/900 — крупные заголовки, **Archivo** 500–800 — текст, **JetBrains Mono** — почты и счётчики. Фирменный элемент — «схемные» линии с пульсирующими узлами на экране входа (`.circuit`), перенести как есть.

### 5.4 Качество

Адаптив (проверить 375 и 1440), видимый фокус, Escape и клик вне закрывают модалки, `aria-label` на иконочных кнопках, `prefers-reduced-motion` отключает пульсацию, оптимистичные обновления голосов с откатом при ошибке, пустые состояния из прототипа.

---

## 6. Порядок сборки

1. Каркас Vite + Vue + TS + Tailwind, токены, шрифты, пустые роуты.
2. Экран входа один в один с прототипом.
3. `schema.sql` целиком + `seed.sql`.
4. Google-вход, `me()`, гварды.
5. Облако идей из `ideas_public`: фильтры, сортировка «Новые» по умолчанию, карточки.
6. Форма идеи: «Другое» с полем темы, анонимность.
7. Голоса с бюджетом (три места объяснения в UI: текст под заголовком, счётчик-пилюля, тосты) и «В команду».
8. Модалка идеи с дополнениями.
9. Админ: KPI, рейтинг, поиск, фильтры, развёртка строки с почтами, смена статуса.
10. Деплой, проверка входа с обоих доменов.

---

## 7. Проверочный список

Пункты со звёздочкой проверяй из консоли браузера под обычной учёткой — именно так это сломает любопытный коллега.

- [ ] \* `supabase.from('ideas').select('*')` возвращает пусто (доступа к таблице нет).
- [ ] \* `supabase.from('profiles').select('*')` возвращает только свою строку.
- [ ] \* Прямой `insert` шестого голоса отклоняется базой.
- [ ] В ответах на `/ideas` нет почт и нет имени автора анонимной идеи.
- [ ] Вход с посторонней почты не проходит, на экране понятное сообщение.
- [ ] Смена имени меняет его на старых идеях, голосах и дополнениях.
- [ ] Повторный клик по 👍 снимает голос и возвращает его в бюджет.
- [ ] \* Заблокированный не может вставить голос или идею прямым запросом.
- [ ] \* Сотрудник не может снять с себя блокировку: `update profiles set blocked=false` не проходит.
- [ ] Скрытая идея исчезает у сотрудников, а голоса за неё возвращаются в бюджет.
- [ ] Правка своей идеи меняет текст у всех и оставляет подпись «изменено»; голоса и дополнения на месте.
- [ ] \* `select public.update_my_idea('<чужая идея>', …)` отвечает `NOT_YOUR_IDEA`.
- [ ] Идея без откликов удаляется автором; после чужого 👍 или дополнения кнопка объясняет отказ.
- [ ] Идея в «Другое» без темы не ломает вёрстку.
- [ ] На 375px ничего не выезжает, модалка скроллится, Escape закрывает.

---

## 8. Не делать

Ответы на дополнения, уведомления, экспорт, подсказку про дубли, realtime, ленту активности, роли сложнее двух, i18n. Если рука тянется что-то обобщить — не надо, это разовый опрос на две недели.

**Что вышло из этого списка после первой недели:** правка и удаление своей идеи (§4.8) и проверки схемы `supabase/test/01-checks.sql`. Первое попросили люди — опечатку в собственной идее иначе было не исправить; второе окупилось на первой же перестройке вью.
