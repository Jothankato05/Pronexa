# Turning on photo reading (optional AI server)

Pronexa works fully offline without this. The server adds two things: reading **photos** of meals, and a second opinion on unusual **descriptions**. Students still check everything on the Confirm screen, and protein numbers still come only from the app's food list.

You need two things only you can create: a hosting account and an Anthropic API key. Setting it up takes about 15 minutes.

## 1. Get an API key

Create a key at platform.claude.com (API keys). Add billing and set a monthly spend limit in the console, so a busy pilot can't run up a surprise bill. Keep the key private: it goes only into the hosting service's secret settings, never into the app, the repository or a chat.

## 2. Deploy the server (Render, free tier)

1. Sign in at render.com with GitHub.
2. **New → Blueprint**, choose the `Pronexa` repository. Render reads `render.yaml`.
3. When asked for `ANTHROPIC_API_KEY`, paste your key.
4. Wait for the deploy, then open `https://<your-service>.onrender.com/health`. It should show `{"ok":true,...}`.

Free Render services sleep when idle, so the first photo after a quiet spell can take 30–60 seconds; the app falls back to Pick if it times out. A paid instance avoids this. Any Docker host works the same way (`server/Dockerfile`, port 8080, `ANTHROPIC_API_KEY` as a secret).

## 3. Point the app at it

The address is built into the app (HTTPS only).

- **Releases from GitHub:** in the repository, **Settings → Secrets and variables → Actions → Variables**, add `PRONEXA_AI_URL` = `https://<your-service>.onrender.com`. The next release build uses it.
- **Local builds:** `flutter build apk --release --dart-define=PRONEXA_AI_URL=https://<your-service>.onrender.com`

In the app, Photo mode then shows **Read the photo**. Low-data mode still keeps photos on the phone.

## Safety built in

The server validates size, type and length, rate-limits each address to 20 requests a minute, logs no meal content, and may only answer with food ids from the list. See `docs/GUARDRAILS.md`.
