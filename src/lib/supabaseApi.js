import { supabase } from './supabaseClient';

const MEDIA_BUCKET = 'media';

const orderBy = {
  hero_slides: 'display_order',
  team_members: 'display_order',
  services: 'display_order',
  skills: 'display_order',
  testimonials: 'display_order',
  projects: 'created_at'
};

export const tableForEndpoint = {
  'settings.php': 'settings',
  'team.php': 'team_members',
  'services.php': 'services',
  'skills.php': 'skills',
  'testimonials.php': 'testimonials',
  'projects.php': 'projects',
  'hero.php': 'hero_slides'
};

const cleanPayload = (payload) => {
  const cleaned = { ...payload };
  delete cleaned.id;
  delete cleaned.image;
  delete cleaned.images;
  delete cleaned.videos;
  delete cleaned._method;
  return cleaned;
};

export const listRows = async (table) => {
  const column = orderBy[table] || 'created_at';
  const ascending = column !== 'created_at';
  const { data, error } = await supabase.from(table).select('*').order(column, { ascending });
  if (error) throw error;
  return data || [];
};

export const getSettings = async () => {
  const { data, error } = await supabase.from('settings').select('*').eq('id', 1).maybeSingle();
  if (error) throw error;
  return data || {};
};

export const updateSettingsRow = async (settingsData) => {
  const { data, error } = await supabase
    .from('settings')
    .upsert({ id: 1, ...settingsData }, { onConflict: 'id' })
    .select()
    .single();
  if (error) throw error;
  return data;
};

export const saveRow = async (table, payload) => {
  const cleaned = cleanPayload(payload);
  const query = payload.id
    ? supabase.from(table).update(cleaned).eq('id', payload.id)
    : supabase.from(table).insert(cleaned);
  const { data, error } = await query.select().single();
  if (error) throw error;
  return data;
};

export const deleteRow = async (table, id) => {
  const { error } = await supabase.from(table).delete().eq('id', id);
  if (error) throw error;
};

export const submitContactMessage = async (message) => {
  const { error } = await supabase.from('contact_messages').insert(message);
  if (error) throw error;
};

export const uploadMedia = async (file, folder = 'uploads') => {
  if (!file) return null;
  if (typeof file === 'string') return file;

  const ext = file.name?.split('.').pop() || 'bin';
  const safeName = `${Date.now()}-${Math.random().toString(36).slice(2)}.${ext}`;
  const path = `${folder}/${safeName}`;
  const { error } = await supabase.storage.from(MEDIA_BUCKET).upload(path, file, {
    cacheControl: '3600',
    upsert: false
  });
  if (error) throw error;

  const { data } = supabase.storage.from(MEDIA_BUCKET).getPublicUrl(path);
  return data.publicUrl;
};

