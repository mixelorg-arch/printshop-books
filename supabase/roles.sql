-- Print Shop Books — two logins, two levels of access.
--
-- OPTIONAL HARDENING. The app already hides every Books control from staff;
-- this makes the database refuse those writes as well, so the limit holds even
-- if someone opens the page in a desktop browser and pokes at it.
--
-- NOT YET APPLIED — it changes policies on entries / expenses / employees,
-- which the standalone sales ledger also uses. Read it before running it.
--
-- Every policy below only ever restricts role 'till_staff'. The owner and the
-- team@ account the sales ledger signs in with keep exactly the access they
-- have today, so applying this should not change that app's behaviour.
--
-- Run in Supabase → SQL Editor → New query. Safe to re-run.

create or replace function public.is_till_staff()
returns boolean language sql stable security definer as $$
  select exists (
    select 1 from public.members
    where user_id = auth.uid() and role = 'till_staff'
  );
$$;

-- ---------------------------------------------------------------- books
-- expenses and employees are pure Books data: staff may read, never write.
do $$
declare t text;
begin
  foreach t in array array['expenses','employees'] loop
    execute format('drop policy if exists members_all   on public.%I', t);
    execute format('drop policy if exists members_read  on public.%I', t);
    execute format('drop policy if exists members_write on public.%I', t);
    execute format(
      'create policy members_read on public.%I for select using (public.is_member())', t);
    execute format(
      'create policy members_write on public.%I for all
         using      (public.is_member() and not public.is_till_staff())
         with check (public.is_member() and not public.is_till_staff())', t);
  end loop;
end $$;

-- entries is the one Books table the till itself writes to: completing a sale
-- stamps that day's takings with sales_source='till'. Staff must be able to do
-- that or selling breaks — but nothing else. Writing a row as 'manual' is how a
-- day gets typed over, and that stays with the admin.
alter table public.entries enable row level security;
drop policy if exists members_all    on public.entries;
drop policy if exists members_read   on public.entries;
drop policy if exists members_write  on public.entries;
drop policy if exists entries_read   on public.entries;
drop policy if exists entries_insert on public.entries;
drop policy if exists entries_update on public.entries;
drop policy if exists entries_delete on public.entries;

create policy entries_read on public.entries
  for select using (public.is_member());

create policy entries_insert on public.entries
  for insert with check (
    public.is_member() and (not public.is_till_staff() or sales_source = 'till')
  );

create policy entries_update on public.entries
  for update
  using      (public.is_member() and (not public.is_till_staff() or sales_source = 'till'))
  with check (public.is_member() and (not public.is_till_staff() or sales_source = 'till'));

-- The app soft-deletes (deleted = true), so this blocks nothing it needs.
create policy entries_delete on public.entries
  for delete using (public.is_member() and not public.is_till_staff());

-- printshop_sales and printshop_services are deliberately left alone: the till
-- and the price list belong to staff.
