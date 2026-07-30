import { createClient } from '@supabase/supabase-js';

// Same Supabase project as the ESCAPE mobile app (see
// lib/config/supabase_config.dart) — signing in with the same account here
// shows the same friends, profile, and social data as on mobile. The anon
// key is safe to ship in client code; it's public by design and enforced by
// the row-level security policies in supabase/schema.sql.
const supabaseUrl =
  import.meta.env.VITE_SUPABASE_URL ?? 'https://fstptkwoatpedlbvjoxe.supabase.co';

const supabaseAnonKey =
  import.meta.env.VITE_SUPABASE_ANON_KEY ??
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZzdHB0a3dvYXRwZWRsYnZqb3hlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUzMzg3NzIsImV4cCI6MjEwMDkxNDc3Mn0.be_vKAV6vwYY_GLhmf0AiohqYydgwqRLecY1g7kbiJQ';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
