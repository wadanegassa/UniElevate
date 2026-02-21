import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://lsgtrvyjljeedowxkigs.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxzZ3RydnlqbGplZWRvd3hraWdzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE2NDYzNDcsImV4cCI6MjA4NzIyMjM0N30.Oq4RUFehlxhH0Y1EsmdZrZfTunRUygooGoblh51Pg_E';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
