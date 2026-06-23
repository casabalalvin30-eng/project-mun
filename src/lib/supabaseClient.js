import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.REACT_APP_SUPABASE_URL || 'https://dwpafhidhezuebstxfok.supabase.co';
const supabaseAnonKey =
  process.env.REACT_APP_SUPABASE_ANON_KEY ||
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR3cGFmaGlkaGV6dWVic3R4Zm9rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIxNTcxMTgsImV4cCI6MjA5NzczMzExOH0.NT5mkcO9By-Pmrfa4Vox7I8quBrCMIOn1E97OYcuDnw';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

