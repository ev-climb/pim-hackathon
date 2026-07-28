<script setup lang="ts">
import { onMounted, ref } from 'vue'
import CircuitBackground from '@/components/CircuitBackground.vue'
import { signInWithGoogle } from '@/api/auth'

const domainError = ref(false)
const busy = ref(false)

// Барьер держит база: триггер app.on_new_user() роняет вход с чужого домена,
// Supabase возвращает нас сюда с ошибкой в хэше. Фронт отвечает только за формулировку (§5.1).
onMounted(() => {
  const params = new URLSearchParams(window.location.hash.slice(1))
  const description = params.get('error_description') ?? ''
  if (params.get('error') || description) {
    domainError.value = true
    history.replaceState(null, '', window.location.pathname)
  }
})

async function enter() {
  busy.value = true
  const { error } = await signInWithGoogle()
  if (error) {
    domainError.value = true
    busy.value = false
  }
}
</script>

<template>
  <section class="login">
    <div class="glow"></div>
    <CircuitBackground />
    <div class="wrap">
      <div class="inner">
        <div>
          <span class="eyebrow">Сбор идей · опрос сотрудников</span>
          <h1 class="hero-title">
            PIM <span class="y">SUMMER</span><br />HACKATHON<br /><span class="y">2026</span>
          </h1>
          <p class="hero-sub">
            Мы ещё выбираем формат и темы. Накидайте идеи в общее облако и поддержите те, что
            зашли — на них соберём команды и составим программу.
          </p>
          <div class="hero-meta">
            <div><div class="k">Когда</div><div class="v">2-я половина августа</div></div>
            <div><div class="k">Формат</div><div class="v">2 дня онлайн</div></div>
          </div>
        </div>

        <div class="login-cards">
          <div class="lcard entry">
            <span class="eyebrow" style="font-size: 11px">Вход</span>
            <h3 style="margin-top: 14px">Рабочий Google-аккаунт</h3>
            <p>
              Один клик, без паролей. Предложить идею или поддержать чужую можно без обязательства
              участвовать в хакатоне.
            </p>
            <button class="g-btn" :disabled="busy" @click="enter">
              <svg width="18" height="18" viewBox="0 0 48 48">
                <path
                  fill="#EA4335"
                  d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"
                />
                <path
                  fill="#4285F4"
                  d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"
                />
                <path
                  fill="#FBBC05"
                  d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"
                />
                <path
                  fill="#34A853"
                  d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"
                />
              </svg>
              Войти через Google
            </button>
            <div class="domains">Только <b>@pimpay.ru</b> и <b>@pimsolutions.ru</b></div>

            <div class="login-error" :class="{ show: domainError }">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="9" />
                <path d="M12 8v5M12 16.5v.01" />
              </svg>
              <span>
                Вход только с рабочей почты <b>@pimpay.ru</b> или <b>@pimsolutions.ru</b>. Попробуйте
                другой аккаунт Google.
              </span>
            </div>

            <div class="steps">
              <div class="step">
                <span class="sn">1</span>
                <div>
                  <b>Предложите идею</b><small>Название и пара предложений — этого достаточно</small>
                </div>
              </div>
              <div class="step">
                <span class="sn">2</span>
                <div>
                  <b>Раздайте 5 голосов</b><small>И отметьте, над чем готовы поработать</small>
                </div>
              </div>
              <div class="step">
                <span class="sn">3</span>
                <div>
                  <b>Соберём команды</b><small>По самым популярным идеям составим программу</small>
                </div>
              </div>
            </div>

            <div class="privacy" style="margin: 0">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
              </svg>
              <span>
                Коллеги увидят имя из вашего Google-профиля — его можно изменить в любой момент.
                Организаторы видят имя и рабочую почту.
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<style scoped>
.login {
  position: relative;
  min-height: 100vh;
  display: flex;
  align-items: center;
  overflow: hidden;
}
.login .glow {
  position: absolute;
  right: -10%;
  top: -20%;
  width: 60%;
  height: 120%;
  background: radial-gradient(circle at 60% 40%, rgba(246, 201, 21, 0.16), transparent 60%);
  pointer-events: none;
}
.login .inner {
  position: relative;
  z-index: 2;
  display: grid;
  grid-template-columns: 1.1fr 0.9fr;
  gap: 56px;
  align-items: center;
  width: 100%;
  padding: 56px 0;
}
.hero-title {
  font-family: 'Archivo Expanded', sans-serif;
  font-weight: 900;
  line-height: 0.94;
  letter-spacing: -0.01em;
  margin: 20px 0 0;
  font-size: clamp(42px, 6vw, 84px);
}
.hero-title .y {
  color: var(--accent);
}
.hero-sub {
  color: var(--text-dim);
  font-size: 17px;
  line-height: 1.55;
  max-width: 440px;
  margin-top: 22px;
}
.hero-meta {
  display: flex;
  gap: 22px;
  margin-top: 30px;
  flex-wrap: wrap;
}
.hero-meta div {
  border-left: 2px solid var(--accent);
  padding-left: 12px;
}
.hero-meta .k {
  font-size: 11px;
  letter-spacing: 0.13em;
  text-transform: uppercase;
  color: var(--text-faint);
}
.hero-meta .v {
  font-weight: 700;
  font-size: 15px;
  margin-top: 3px;
}

.login-cards {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.lcard {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--r-lg);
  padding: 26px;
  transition: 0.22s;
}
.lcard.entry:hover {
  border-color: var(--border-strong);
}
.lcard h3 {
  margin: 0;
  font-size: 19px;
  font-weight: 800;
  display: flex;
  align-items: center;
  gap: 10px;
}
.lcard p {
  margin: 8px 0 18px;
  font-size: 13.5px;
  line-height: 1.5;
  opacity: 0.85;
}
.g-btn {
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 11px;
  background: #fff;
  color: #1f1f23;
  font-weight: 700;
  font-size: 15px;
  padding: 13px;
  border-radius: 12px;
  transition: 0.18s;
}
.g-btn:hover {
  transform: translateY(-1px);
  box-shadow: 0 10px 24px -10px rgba(0, 0, 0, 0.5);
}
.g-btn:disabled {
  opacity: 0.7;
  cursor: progress;
  transform: none;
}
.domains {
  text-align: center;
  font-size: 12.5px;
  color: var(--text-faint);
  margin-top: 11px;
}
.domains b {
  color: var(--text-dim);
  font-weight: 600;
}
.login-error {
  display: none;
  align-items: flex-start;
  gap: 9px;
  margin-top: 14px;
  padding: 12px 14px;
  border-radius: 12px;
  background: rgba(246, 201, 21, 0.09);
  border: 1px solid rgba(246, 201, 21, 0.32);
  font-size: 13px;
  line-height: 1.45;
  color: var(--text-dim);
}
.login-error.show {
  display: flex;
}
.login-error svg {
  width: 16px;
  height: 16px;
  flex: none;
  margin-top: 1px;
  color: var(--accent);
}
.login-error b {
  color: var(--accent);
  font-weight: 700;
}
.steps {
  display: flex;
  flex-direction: column;
  gap: 14px;
  margin: 22px 0;
  padding: 22px 0;
  border-top: 1px solid var(--border);
  border-bottom: 1px solid var(--border);
}
.step {
  display: flex;
  gap: 13px;
  align-items: flex-start;
}
.step .sn {
  width: 26px;
  height: 26px;
  flex: none;
  border-radius: 7px;
  background: var(--accent);
  color: var(--accent-ink);
  display: grid;
  place-items: center;
  font-family: 'JetBrains Mono', monospace;
  font-weight: 700;
  font-size: 13px;
}
.step b {
  display: block;
  font-size: 14px;
  font-weight: 700;
}
.step small {
  display: block;
  color: var(--text-faint);
  font-size: 12.5px;
  line-height: 1.45;
  margin-top: 2px;
}

@media (max-width: 900px) {
  .login .inner {
    grid-template-columns: 1fr;
    gap: 34px;
  }
}
</style>
