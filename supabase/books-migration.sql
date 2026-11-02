-- ============================================================
--  Print Shop — Till & Books
--  The one change the books needed in the existing project.
--  Run once in the SQL editor. Safe to run again.
-- ============================================================

-- Where a day's takings came from: 'till' when the till supplied the figure,
-- 'manual' when someone typed over it. Everything already in the table is
-- treated as typed, because it was.
alter table public.entries
  add column if not exists sales_source text not null default 'manual';

-- The books reuse the sales ledger's own tables (entries, expenses, employees)
-- and its existing row level security, so no new policies are needed and
-- ledger members get the books without being granted anything further.

-- Check it landed:
--   select column_name, column_default from information_schema.columns
--   where table_name = 'entries' and column_name = 'sales_source';
