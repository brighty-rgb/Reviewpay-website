-- ReviewPay database schema. Run in Supabase SQL Editor.
create extension if not exists pgcrypto;

create type public.member_status as enum ('pending', 'approved', 'suspended');
create type public.task_status as enum ('draft', 'published', 'closed');
create type public.submission_status as enum ('pending', 'approved', 'rejected');
create type public.withdrawal_status as enum ('pending', 'processing', 'paid', 'rejected');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  member_id text unique not null default ('RP-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10))),
  full_name text not null default '',
  email text not null,
  avatar_url text,
  role text not null default 'member' check (role in ('member', 'admin')),
  status public.member_status not null default 'pending',
  created_at timestamptz not null default now()
);

create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null,
  product_url text,
  image_url text,
  deadline timestamptz,
  status public.task_status not null default 'draft',
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create table public.task_claims (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.tasks(id),
  member_id uuid not null references public.profiles(id),
  claimed_at timestamptz not null default now(),
  unique(task_id, member_id)
);

create table public.submissions (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.tasks(id),
  member_id uuid not null references public.profiles(id),
  rating int not null check (rating between 1 and 5),
  review_text text not null,
  photo_url text,
  status public.submission_status not null default 'pending',
  reward_usd numeric(10,2) not null default 0.50 check (reward_usd = 0.50),
  reviewed_by uuid references public.profiles(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  unique(task_id, member_id)
);

create table public.ledger (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.profiles(id),
  submission_id uuid unique references public.submissions(id),
  amount_usd numeric(10,2) not null check (amount_usd > 0),
  entry_type text not null check (entry_type in ('task_reward', 'withdrawal_debit', 'adjustment')),
  created_at timestamptz not null default now()
);

create table public.withdrawals (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.profiles(id),
  gross_usd numeric(10,2) not null check (gross_usd >= 10),
  fee_usd numeric(10,2) not null default 1.00 check (fee_usd = 1.00),
  net_usd numeric(10,2) generated always as (gross_usd - fee_usd) stored,
  status public.withdrawal_status not null default 'pending',
  payout_reference text,
  created_at timestamptz not null default now(),
  processed_at timestamptz
);

create table public.admin_audit_log (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid not null references public.profiles(id),
  action text not null,
  target_table text not null,
  target_id uuid,
  created_at timestamptz not null default now()
);

-- Create a pending member profile automatically after signup.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'full_name', ''));
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Helper used by row-level security policies.
create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin' and status = 'approved'
  );
$$;

alter table public.profiles enable row level security;
alter table public.tasks enable row level security;
alter table public.task_claims enable row level security;
alter table public.submissions enable row level security;
alter table public.ledger enable row level security;
alter table public.withdrawals enable row level security;
alter table public.admin_audit_log enable row level security;

create policy "Members read own profile; admins read all"
on public.profiles for select to authenticated
using (id = auth.uid() or public.is_admin());

-- Member profile edits must be implemented through a server-validated endpoint
-- that only permits safe fields (for example full_name and avatar_url).

create policy "Admins manage profiles"
on public.profiles for all to authenticated
using (public.is_admin()) with check (public.is_admin());

create policy "Approved members read published tasks"
on public.tasks for select to authenticated
using (status = 'published' and exists (
  select 1 from public.profiles p where p.id = auth.uid() and p.status = 'approved'
) or public.is_admin());

create policy "Admins manage tasks"
on public.tasks for all to authenticated
using (public.is_admin()) with check (public.is_admin());

create policy "Members read own claims"
on public.task_claims for select to authenticated using (member_id = auth.uid() or public.is_admin());

create policy "Approved members claim tasks"
on public.task_claims for insert to authenticated
with check (
  member_id = auth.uid()
  and exists (select 1 from public.profiles p where p.id = auth.uid() and p.status = 'approved')
  and exists (select 1 from public.tasks t where t.id = task_id and t.status = 'published')
);

create policy "Members read own submissions; admins read all"
on public.submissions for select to authenticated
using (member_id = auth.uid() or public.is_admin());

create policy "Approved members submit own feedback"
on public.submissions for insert to authenticated
with check (
  member_id = auth.uid()
  and status = 'pending'
  and reward_usd = 0.50
  and exists (select 1 from public.profiles p where p.id = auth.uid() and p.status = 'approved')
);

create policy "Admins moderate submissions"
on public.submissions for update to authenticated
using (public.is_admin()) with check (public.is_admin());

create policy "Members read own ledger; admins read all"
on public.ledger for select to authenticated
using (member_id = auth.uid() or public.is_admin());

create policy "Members read own withdrawals; admins read all"
on public.withdrawals for select to authenticated
using (member_id = auth.uid() or public.is_admin());

-- Withdrawal creation is intentionally not granted directly to browser clients.
-- Implement it as a server-side transaction that locks the member ledger, verifies
-- available balance >= gross amount, deducts gross amount exactly once, and creates
-- the request with a fixed $1 fee.

create policy "Admins manage withdrawals"
on public.withdrawals for update to authenticated
using (public.is_admin()) with check (public.is_admin());

create policy "Admins read audit log"
on public.admin_audit_log for select to authenticated using (public.is_admin());

-- IMPORTANT: Run this separately after creating your own admin user in Supabase Auth.
-- Replace the email below with the private admin email you control.
-- update public.profiles
-- set role = 'admin', status = 'approved'
-- where email = 'YOUR-ADMIN-EMAIL@example.com';
