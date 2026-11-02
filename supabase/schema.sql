-- Print Shop till — database schema
-- Lives in the existing "ledger" Supabase project, but every object is
-- prefixed printshop_ so it stays completely separate from the projectdrex
-- sales ledger (employees / entries / expenses) sharing the same database.
--
-- Run in Supabase → SQL Editor → New query. Safe to re-run.

-- ---------------------------------------------------------------- data

-- One row per completed sale. The line items ride along as jsonb: a sale is
-- never edited after the fact, only voided, so there is nothing to gain from
-- splitting them into their own table.
create table if not exists public.printshop_sales (
  id         text primary key,
  sold_at    timestamptz not null,
  items      jsonb   not null default '[]'::jsonb,  -- [{name,cat,price,qty}]
  total      numeric not null default 0,
  cash       numeric not null default 0,
  change_due numeric not null default 0,
  voided     boolean not null default false,
  device     text    not null default '',
  deleted    boolean not null default false,
  updated_at timestamptz not null default now()
);

-- The price list, so every tablet shows the same services and prices.
create table if not exists public.printshop_services (
  id         text primary key,
  name       text    not null,
  cat        text    not null default 'Others',
  price      numeric not null default 0,
  deleted    boolean not null default false,
  updated_at timestamptz not null default now()
);

create index if not exists printshop_sales_sold_idx     on public.printshop_sales (sold_at);
create index if not exists printshop_sales_updated_idx  on public.printshop_sales (updated_at);
create index if not exists printshop_services_updated_idx on public.printshop_services (updated_at);

-- updated_at is stamped by the database, never trusted from the client — that
-- is what makes last-write-wins reliable across tablets with wrong clocks.
-- public.touch_updated_at() already exists in this project; create it only if
-- this schema is ever run somewhere fresh.
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

do $$
declare t text;
begin
  foreach t in array array['printshop_sales','printshop_services'] loop
    execute format('drop trigger if exists touch_%1$s on public.%1$I', t);
    execute format(
      'create trigger touch_%1$s before insert or update on public.%1$I
         for each row execute function public.touch_updated_at()', t);
  end loop;
end $$;

-- ---------------------------------------------------------------- security
--
-- Same gate as the rest of the ledger: you must be an approved member.
-- public.is_member() is defined by the ledger schema and reused here.

alter table public.printshop_sales    enable row level security;
alter table public.printshop_services enable row level security;

do $$
declare t text;
begin
  foreach t in array array['printshop_sales','printshop_services'] loop
    execute format('drop policy if exists members_all on public.%I', t);
    execute format(
      'create policy members_all on public.%I for all
         using (public.is_member()) with check (public.is_member())', t);
  end loop;
end $$;

-- ---------------------------------------------------------------- reporting
--
-- The daily sales report, straight from the database. Voided and deleted sales
-- are excluded. security_invoker makes the view obey the caller's RLS rather
-- than the view owner's, so it cannot leak past the members check above.
create or replace view public.printshop_daily_totals
with (security_invoker = true) as
select
  (sold_at at time zone 'Asia/Manila')::date as day,
  count(*)                                   as transactions,
  sum(total)                                 as sales,
  sum((select coalesce(sum((i->>'qty')::numeric),0)
       from jsonb_array_elements(items) i))  as items_sold
from public.printshop_sales
where not voided and not deleted
group by 1
order by 1 desc;
