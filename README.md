# Print Shop — Till & Books

The till you already use, with the books attached.

`PrintShop/` is untouched and still live. This is a **separate app**: the same
tap-to-tally till, plus what the till never knew about — wages, expenses, and
what is actually left at the end of the month.

---

## What is new

A fifth tab, **Books**, with four views:

| View | What it shows |
|---|---|
| Summary | Each week's takings and wages, then the month: takings − wages − expenses = net |
| Days | Every trading day. Who worked, what they are owed, whether wages are paid |
| Expenses | Rent, ink, electricity — anything that is not wages |
| People | The staff you pay, and what each has been paid all told |

## The one idea worth understanding

**The till owns the day's takings.**

Ring up a sale and the day appears in the books on its own, with the figure the
till recorded, tagged *from till*. Nothing to retype and nothing to keep in step
by hand. Void a sale and the day follows.

You can still type a figure over it — for a cash job that never went through the
till. When you do, the day is tagged *typed over*, and the sheet tells you what
the till actually said so the difference is never a mystery. **Use the till
figure** puts it back.

A day the till created, where everything was later voided and no work was
recorded, removes itself rather than sitting at zero.

## Where the numbers live

The same Supabase project as before, in the same tables the standalone sales
ledger uses — `entries`, `expenses`, `employees` — alongside the till's own
`printshop_*` tables. So a day recorded here shows up in the sales ledger, and
the other way round. One set of books, two ways in.

One column was added: `entries.sales_source`, holding `till` or `manual`. That
is what lets a figure be traced back to where it came from.

## Two logins

Tap **Sign in** and pick who you are. One password each, shared by whoever is on
that shift — the passwords are not in this repository.

| | Sell · Sales · Items | Books |
|---|---|---|
| **Staff** | Yes — ring up, void, change prices | Read-only, and can still print the month |
| **Admin** | Yes | Yes — record days, expenses and people |

Books is the finished report, so staff can read every figure and print it but
cannot change what it is built from. Sign in as Admin on the same tablet to make
a correction, then sign back out.

Not signed in counts as staff, so the Books cannot be edited offline. That is
deliberate: a tablet with no signal cannot see what the other tablets have
already recorded, and editing the month from a stale copy is how figures get
lost.

## Syncing across tablets

Every signed-in device, staff or admin, reads and writes the same books. Ring up
a sale on the counter tablet and it is on the office one within half a minute.
Conflicts resolve per row, newest write wins, with the timestamp set by the
database rather than the tablet — so a tablet with the wrong clock cannot
overwrite good figures.

## What has not changed

* **Selling never asks who you are.** Sign-in is only for syncing and for the
  Books. A tablet with no signal takes money exactly as before.
* Everything is written to the tablet first and synced afterwards.
* Deletes are still tombstones, so a removal reaches the other devices instead of
  being undone by whichever one syncs last.

## Running it

Serve it over http — a `file://` URL blocks storage and the script.

```
python3 -m http.server 8778
```

`.claude/launch.json` has a `printshopbooks` entry on port 8778.

## Live

<https://mixelorg-arch.github.io/printshop-books/>

The original till at `PrintShop/` keeps its own address and carries on working.

`supabase/roles.sql` is optional hardening: the app already hides every Books
control from staff, and that script makes the database refuse those writes too.
It changes policies on tables the standalone sales ledger also uses, so read it
before running it.
