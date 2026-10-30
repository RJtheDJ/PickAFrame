# Firestore security rules

`firestore.rules` is the server-side check for everything the app writes.
The app's own checks can be bypassed; these cannot.

| Collection | Who can read | Who can write |
|---|---|---|
| `users/{uid}` | the owner | the owner; the role can be set once |
| `vendors/{id}` | anyone | a frame shop, only its own (`id` = its uid) |
| `mouldings/{id}` | anyone | the shop named in `vendorId`, with valid fields |
| `drafts/{id}` | the owner | the owner |
| `orders/{id}` | the customer and the shop | customer creates (unquoted, `submitted`); shop changes only `stage` (forwards) and `quoteRm` |

## Test

```bash
npm install
npm test
```

This runs `rules.test.mjs` on the Firestore emulator, which needs Java 21 or newer.
Android Studio's bundled JDK works: set `JAVA_HOME` to its `jbr` folder.
On Windows, if the emulator fails with "Unable to establish loopback connection",
set `JAVA_TOOL_OPTIONS=-Djdk.net.unixdomain.tmpdir=C:\some\short\temp\dir`.

## Deploy

```bash
npx firebase login
npm run deploy
```

You need access to the `pick-a-frame` Firebase project.

## Manual steps in the consoles

1. Deploy these rules (above). Until then the database runs on whatever rules the console has.
2. Redeploy the Worker: `cd cloudflare/artwork-worker && npx wrangler deploy`. This adds the PNG check and security headers.
3. Google Cloud console → Credentials → restrict the Maps API key to Android apps, package `com.example.pickaframe_application`, with the debug and release SHA-1s.
4. Optional: turn on Firebase App Check (Play Integrity) to block scripted clients.
