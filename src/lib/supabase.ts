import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://dbrfpmrngreaqoggamfx.supabase.co';
const supabaseKey = 'sb_publishable_qsPZ-YBrbZnkFLV6luWbew_o-0D6aNx';

export const supabase = createClient(supabaseUrl, supabaseKey);
