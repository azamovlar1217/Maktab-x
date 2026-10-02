import "server-only";
import { createClient as createSupabaseClient } from "@supabase/supabase-js";

export function createAdminClient(){
 const url=process.env.NEXT_PUBLIC_SUPABASE_URL; const key=process.env.SUPABASE_SERVICE_ROLE_KEY;
 if(!url||!key) throw new Error("Server sozlamasida Supabase URL va service role key kerak.");
 return createSupabaseClient(url,key,{auth:{autoRefreshToken:false,persistSession:false}});
}
