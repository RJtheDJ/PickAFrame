# Artwork Worker

A small Cloudflare Worker that stores each user's cropped artwork in a
private R2 bucket. The Flutter app sends the image together with the user's
Firebase ID token; the Worker checks the token, takes the user's uid from
it, and saves the PNG at `drafts/{uid}/{draftId}/artwork.png`. Nobody can
read or overwrite another user's images.

Design and task list: [docs/plans/r2-exhibition.md](../../docs/plans/r2-exhibition.md).

## Deployed Worker

```
https://artwork-worker.artwork-worker.workers.dev
```

It uses the real `pick-a-frame` R2 bucket. **To test it you don't need to
install anything**: see [Try it](#try-it). The Flutter app doesn't call it
yet (Task 2). The install and `npm run dev` sections are only for working
on the Worker itself.

## What to install (once)

| Tool | Version | Get it |
|---|---|---|
| Node.js | **22.12 or newer** (the current LTS, 24, is fine) | <https://nodejs.org> → LTS installer. Comes with `npm`. |
| Git | any recent | You already have it if you cloned this repo. |

Check in a new terminal:

```powershell
node --version   # v22.12.0 or higher
npm --version
```

You do **not** need a Cloudflare account to run the Worker on your own
machine. `npm run dev` simulates R2 locally.

## Set up (once per clone)

```powershell
cd cloudflare/artwork-worker
npm install
```

This downloads Wrangler (Cloudflare's CLI), `jose` (token checking) and the
test tools into `node_modules/`. That folder is git-ignored, so everyone runs
`npm install` themselves. Run it again whenever `package.json` changes after
a pull.

## Run it locally

```powershell
cd cloudflare/artwork-worker
npm run dev
```

Wait for `Ready on http://localhost:8787` and leave this terminal open; the
Worker stops when you close it. Use a second terminal for requests.

Uploaded files are kept in `.wrangler/state/` inside this folder (also
git-ignored). They stay on your machine and never reach the real bucket.

## Try it

This saves into the **real** bucket through the deployed Worker. Nothing
needs to be installed; PowerShell is enough.

Every request needs a real Firebase ID token for the `pick-a-frame` project.

1. Get a test account (email + password): Firebase Console →
   Authentication → Users → **Add user**, or ask Kah Han.
2. Get the **web** API key: the `apiKey` inside
   `static const FirebaseOptions web` in `lib/firebase_options.dart`. That
   file is git-ignored, so you only have it if you ran
   `flutterfire configure`; otherwise ask Kah Han. Use the web key; the
   Android/iOS keys may be restricted to the apps.
3. Get a token in PowerShell (valid for one hour):

   ```powershell
   $body = @{ email = "<test email>"; password = "<test password>"; returnSecureToken = $true } | ConvertTo-Json
   $res = Invoke-RestMethod -Method Post -ContentType "application/json" -Body $body -Uri "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=<web API key>"
   $token = $res.idToken
   ```

4. Upload an image, then read it back into `test.png`:

   ```powershell
   $base = "https://artwork-worker.artwork-worker.workers.dev"
   curl.exe -X PUT --data-binary "@web\favicon.png" -H "Content-Type: image/png" -H "Authorization: Bearer $token" "$base/v1/drafts/test1/artwork"
   curl.exe -H "Authorization: Bearer $token" "$base/v1/drafts/test1/artwork" -o test.png
   ```

   The upload should print `{"url":"/v1/drafts/test1/artwork"}`. Run these
   from the repo root so `web\favicon.png` resolves. In PowerShell, type
   `curl.exe`, not `curl` (`curl` is an alias for a different command).

5. Check the bucket: Cloudflare dashboard → R2 → `pick-a-frame` →
   `drafts/{your uid}/test1/artwork.png` (only the account owner can open
   the dashboard).

Each user only sees their own uploads: another account gets `404` for the
same URL. That is the intended behaviour.

To try your own changes to the Worker instead, start `npm run dev` (below)
and set `$base = "http://localhost:8787"`. That uses the local, simulated
bucket, not the real one.

## API

| Request | Result |
|---|---|
| `PUT /v1/drafts/{draftId}/artwork` with `Content-Type: image/png` | `200` `{"url": "/v1/drafts/{draftId}/artwork"}` |
| `GET /v1/drafts/{draftId}/artwork` | `200` the PNG, only for its owner |

Both need `Authorization: Bearer <Firebase ID token>`. Errors:

| Status | Meaning |
|---|---|
| `401` | Token missing, malformed, expired or from another project |
| `404` | Unknown path, or no such image for this user |
| `413` | Image over 25 MiB |
| `415` | Not `image/png` |

## Useful commands

Run these inside `cloudflare/artwork-worker/`:

| Command | What it does |
|---|---|
| `npm run dev` | Start the Worker locally on port 8787 |
| `npm test` | Run the tests (none yet; route tests are planned) |
| `npx tsc --noEmit` | Type-check the TypeScript |
| `npx wrangler types` | Regenerate `worker-configuration.d.ts` after changing `wrangler.jsonc` |
| `npx wrangler r2 object get pick-a-frame/<key> --local --pipe` | Print a stored object from the local R2 |

## Common problems

- **`could not connect to server`**: the `npm run dev` terminal was closed or
  stopped. Start it again.
- **`The specified key does not exist`** from `wrangler r2 object ...`: you
  ran it outside `cloudflare/artwork-worker/`. Local R2 data lives in this
  folder's `.wrangler/`.
- **Always `401`**: the token is older than one hour, or `$token` is empty
  (`$token.Length` prints 0). Get a new one.
- **Red line under `env.SOMETHING`**: run `npx wrangler types` after editing
  `wrangler.jsonc`, then restart `npm run dev`.

## Deploying

Only the owner of the Cloudflare account (Kah Han) can deploy:

```powershell
npx wrangler login     # once, opens the browser
npx wrangler deploy
```

`npm run dev` always uses the local, simulated bucket, so working on the
Worker never touches real data. The deployed Worker always uses the real
bucket.

## Not set up yet

- Connecting the Flutter app (planned in Task 2: the app will read the
  Worker address from `--dart-define=CLOUDFLARE_WORKER_BASE_URL=...`; use
  the deployed address above, or `http://10.0.2.2:8787` to reach a local
  `npm run dev` from the Android emulator).
