# ReviewPay starter kit

A starter implementation plan and secure Supabase schema for ReviewPay.

## Business rules
- Members must register and wait for manual admin approval.
- Members have full profiles (name, email, member ID, optional photo, status).
- Only admins can create, edit, publish, or delete tasks.
- Every approved task earns exactly USD $0.50.
- Withdrawals require at least USD $10.00 gross balance.
- Each withdrawal has a disclosed USD $1.00 fee; a $10.00 gross withdrawal pays $9.00 net.
- Admin reviews submissions and processes withdrawal requests.

## Important
This is a starter kit, not a deployed or production-complete website. It does not process real payments.
Do not collect an upfront fee to unlock a member's earnings. Show the $1 fee transparently and deduct it from the withdrawal amount.
Use genuine product research and disclose incentives. Do not ask members to post undisclosed paid reviews on third-party retail platforms.

## Setup
1. Create a Supabase project.
2. In Supabase SQL Editor, run `supabase/schema.sql`.
3. In Supabase Authentication settings, enable email/password and email confirmation.
4. Create the first admin account through Supabase's secure invite/user flow.
5. Run the admin promotion SQL at the bottom of `supabase/schema.sql`, replacing the email with the admin email.
6. Create a Next.js app and install `@supabase/supabase-js` and `@supabase/ssr`.
7. Copy `.env.example` to `.env.local` and add your Supabase project URL and anon/publishable key.
8. Deploy to Vercel and configure the same environment variables there.

## Admin access
There is no public admin registration. The first admin account is created privately by the site owner in Supabase Auth, then assigned the `admin` role in the database. Never put an admin password in source code, SQL, GitHub, or a public form. Use a strong unique password and enable MFA if available.

## Required production work before launch
- Build protected Next.js pages and server-side actions for task management, review moderation, profile editing, and withdrawal processing.
- Validate every reward and balance change on the server; never trust browser-calculated balances.
- Add an audit log for admin actions and payment status changes.
- Configure storage policies for profile photos.
- Add rate limiting, abuse prevention, privacy policy, terms, and a clear complaints/contact process.
- Choose and integrate a compliant payout provider for the countries you will serve.
- Test all row-level security policies with separate member and admin accounts.
