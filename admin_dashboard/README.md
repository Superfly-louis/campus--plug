# Campus Plug Admin Dashboard

Static Firebase-backed admin UI for vendor verification.

## Auth

- Uses **Firebase Auth** email/password (same project as the Flutter app).
- After sign-in, loads `users/{uid}` and requires `isAdmin: true`.
- Non-admins see an access-denied screen; logout calls Firebase `signOut`.

## Create / flag the first admin (manual)

There is **no** self-serve admin signup.

1. Create a normal Firebase Auth user (or use an existing account) in Firebase Console → Authentication → Users → Add user (email + password).
2. Ensure a Firestore document exists at `users/{thatUid}` (sign up once in the mobile app, or create the doc manually).
3. In Firestore Console, open `users/{uid}` and set:
   - `isAdmin`: `true` (boolean)
4. Open the admin dashboard, sign in with that email/password.

Only someone with Console access (or an existing admin with a future privileged tool) should set `isAdmin`. Clients cannot self-grant it (enforced in `firestore.rules`).

## Vendor status

- `status`: `active` (default) or `suspended`
- Missing `status` on legacy docs is treated as **active** (no backfill required for correctness)
- Optional one-time Console backfill: set `status: "active"` on all vendors for cleaner admin filtering

Suspension writes `status`, `suspensionReason`, and `suspendedAt`. Reactivate clears the reason/timestamp fields.

## Local serve

```bash
cd admin_dashboard
python -m http.server 8080
```

Open `http://localhost:8080`.
