# MAKTAB X

MAKTAB X is an invite-only school workspace built with Next.js, Supabase Auth and Postgres RLS. No demo student, grade, attendance, timetable, or school records are seeded. Public signup is disabled.

## Local setup

1. Install Node.js 20.9 or newer and pnpm.
2. Copy `.env.example` to `.env.local`. Set `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, and `PLATFORM_BOOTSTRAP_EMAIL`. Keep the service role key server-only.
3. Create a Supabase project and run every file in `supabase/migrations` in filename order.
4. Configure Google OAuth in Supabase Auth and the Google Cloud Console. Set local and production redirect URLs.
5. Create/invite the trusted first platform administrator. Sign in using the exact `PLATFORM_BOOTSTRAP_EMAIL`, then visit `/platform/setup` once. That account becomes the platform super-admin. It can provision schools and invite their first school admins. Invited users set their own passwords or sign in with the invited Google account.
6. Run `pnpm install`, `pnpm dev`, then open `http://localhost:3000`.

Invitations require Supabase email delivery settings and the server-only service role key. Phone OTP is disabled unless an SMS provider is configured and `NEXT_PUBLIC_PHONE_AUTH_ENABLED=true`.

## Roles and data

School roles are admin, director, teacher, student, parent, and cook. Platform super-admin is a separate platform-wide role. Database policies enforce school membership, director/teacher responsibilities, student rosters, class leaders, and school-level data boundaries. There are no seeded demo records.

Before applying migrations to real student data, review them and test against a separate Supabase project. Production use also requires Google OAuth, email invitation delivery, backups, and privacy/retention policies.

## Deploy

`render.yaml` prepares a Render free web service. Add every secret environment variable in Render's dashboard before deploy. Free service availability is limited; see Render's current [free instance limits](https://render.com/docs/free). The app also needs a GitHub repository connected to Render.

## Visual assets and current scope

Original school/robot art lives in `public/assets`. The onboarding admin can manage image/video slides. Full workflow CRUD is still incomplete for some modules; SMS, actual generated video/audio deliverables, and AI tutoring are not yet production integrations.
