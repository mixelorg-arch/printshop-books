// Print Shop Books — backend configuration.
//
// Shares the "ledger" Supabase project with the sales ledger, but the till's
// own data lives in printshop_* tables, so the two never collide.
//
// The anon key is meant to be public — it grants nothing on its own. Row level
// security is what decides who can read and write.
window.PRINTSHOP_CONFIG = {
  supabaseUrl: 'https://snfukbofyadfrhuaggad.supabase.co',
  supabaseAnonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNuZnVrYm9meWFkZnJodWFnZ2FkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgyNjY3NzUsImV4cCI6MjEwMzg0Mjc3NX0.VS7OJ0vTK97AITaiXcuoTE-cJ3-jdADT1fzniDtPTfo',

  // Two shared logins. These addresses are only usernames — they are not
  // mailboxes and nothing is ever sent to them. The passwords are the secret
  // and are never stored here.
  //
  //   Staff — runs the till: Sell, Sales and Items.
  //   Admin — the same, plus editing the Books.
  //
  // Blank both out to run the till purely offline, with no sign-in at all.
  staffEmail: 'staff@projectdrex-sales.com',
  adminEmail: 'admin@projectdrex-sales.com'
};
