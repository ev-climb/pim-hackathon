# Что настроить руками до старта разработки

Всё, что Claude Code не сделает за тебя. Около 30 минут. Порядок важен: часть значений нужна на следующем шаге.

Выписывай значения в менеджер паролей — в конце сводка.

---

## A. Supabase (10 минут)

**A1.** supabase.com → **New project**
- Name: `pim-hackathon`
- Database Password — сгенерируй длинный, сразу в менеджер паролей (восстановить нельзя, только сбросить)
- **Region: Central EU (Frankfurt)** — данные сотрудников остаются в ЕС
- Plan: Free

**A2. Settings → API**, скопировать:
- **Project URL** — `https://<ref>.supabase.co`
- **anon public** — поедет в бандл фронта, это нормально
- **service_role** — **никуда не копировать.** Обходит все политики, нужен только внутри дашборда

Сразу запиши адрес колбэка, пригодится в части B:
`https://<ref>.supabase.co/auth/v1/callback`

**A3. SQL Editor** — выполнить содержимое §3 из `SPEC.md` по порядку: таблицы → функции и триггеры → вью → права. Не одним куском, смотри на ошибки после каждого блока.

**Перед запуском впиши свою почту** в `app.is_admin()` — там заглушка. Можно перечислить несколько через запятую.

**A4. Authentication → Sign In / Providers**
- **Google** — включить, поля Client ID и Secret заполнишь после части B
- Глобальный тумблер **«Allow new users to sign up» не выключай** — он рубит и OAuth тоже, первый вход через Google перестанет работать. Посторонних режет триггер доменов

---

## B. Google Cloud Console (15 минут)

**B1.** console.cloud.google.com → новый проект `pim-hackathon`

**B2. APIs & Services → OAuth consent screen**

Скоупы только `openid`, `email`, `profile`. Любой другой запустит верификацию Google на недели — нам не нужно.

Пробуй **Internal**: если вариант доступен, бери его. Скоупы не показываются на экране согласия, проверка Google не нужна, это самый короткий путь. Недоступен — бери External.

**B3. Credentials → Create Credentials → OAuth client ID**
- Type: **Web application**
- **Authorized redirect URIs** — ровно одна строка, колбэк Supabase из A2. Адрес приложения сюда не добавляй: браузер возвращается на Supabase, а тот уже перекидывает дальше

Client ID и Secret → в Supabase (Authentication → Providers → Google) → Save.

**B4. Сразу проверь вход двумя людьми, по одному с каждого домена.** Не откладывай, все возможные сбои чинятся за минуту, если наткнуться на них сейчас:

- **`org_internal` у второго домена** → домены в разных организациях. Смени User Type на **External** и нажми **Publish app** (статус In production; в Testing потолок 100 человек). Верификация со скоупами `openid`/`email`/`profile` не нужна
- **Не работает вообще ни у кого** → администратор Workspace ограничивает сторонние приложения. Пусть добавит твой Client ID в разрешённые
- **`EMAIL_DOMAIN_NOT_ALLOWED`** → сработал триггер, проверь домены в `app.on_new_user()`

---

## C. Vercel (5 минут)

1. vercel.com → **Add New → Project** → импортировать репозиторий с GitHub
2. Framework Preset: **Vite**
3. Environment Variables:
   ```
   VITE_SUPABASE_URL
   VITE_SUPABASE_ANON_KEY
   ```
4. Deploy. Получишь адрес вида `pim-hackathon.vercel.app`
5. **Вернись в Supabase → Authentication → URL Configuration** и пропиши:
   - Site URL: адрес с Vercel
   - Redirect URLs: `http://localhost:5174/**` и `https://<адрес>.vercel.app/**`

Локальный адрес обязателен, без него вход не заработает на машине разработчика.

Порт локальной разработки закреплён в `vite.config.ts` как **5174** (`strictPort`) — на машине разработчика 5173 занят другим проектом. Порт нельзя оставлять на автоподбор: он прописан здесь, и если Vite молча уедет на соседний, возврат из Google перестанет работать. Освободишь 5173 — поменяй в двух местах, в конфиге и здесь.

Дальше каждый push в `main` деплоится сам.

**Клиентский роутинг Vercel из коробки не понимает** — в отличие от того, что здесь было написано раньше. Для Vite-SPA документация Vercel прямо говорит: «deep linking won't work out of the box». Без переписывания запросов `/ideas` и `/admin` отдают 404 при прямом заходе или обновлении страницы — проверено на статике локально. Поэтому в корне лежит `vercel.json` с одним правилом: любой путь отдаёт `index.html`, а дальше роутер разбирается сам. Отдельно настраивать в дашборде ничего не надо, файл подхватывается автоматически.

---

## D. Локально

Node.js 20+, файл `.env.local` в корне проекта (и сразу в `.gitignore`):

```
VITE_SUPABASE_URL=https://<ref>.supabase.co
VITE_SUPABASE_ANON_KEY=<anon public key>
```

---

## E. Проверка перед стартом

- [ ] `select * from ideas_public;` в SQL Editor выполняется без ошибок (пусто — нормально)
- [ ] `select tgname from pg_trigger where tgrelid = 'auth.users'::regclass;` — триггер на месте
- [ ] В `app.is_admin()` стоит твоя реальная почта, а не заглушка
- [ ] Google-провайдер включён, Client ID заполнен
- [ ] В URL Configuration есть и localhost, и адрес Vercel
- [ ] Вход прошли два человека с разных доменов

---

## Сводка значений

| Что | Где взять | Куда положить |
|---|---|---|
| Project URL | Supabase → Settings → API | `.env.local`, переменные Vercel |
| anon public key | там же | `.env.local`, переменные Vercel |
| service_role key | там же | **никуда**, только менеджер паролей |
| Пароль базы | задаётся при создании | менеджер паролей |
| Callback URL | `https://<ref>.supabase.co/auth/v1/callback` | Google → Authorized redirect URIs |
| Client ID / Secret | Google → Credentials | Supabase → Providers → Google |

---

## Про бесплатный тариф

- Проект **встаёт на паузу после недели без запросов**. Будится кнопкой в дашборде, данные не теряются. Если между демо и запуском пройдёт время — просто не удивляйся
- Автобэкапов на Free нет. Перед запуском на живых людях сделай дамп руками
- Лимиты (500 МБ, 50 тысяч активных пользователей в месяц) для тридцати человек несопоставимо велики
