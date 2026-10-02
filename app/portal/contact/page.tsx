import { notFound,redirect } from "next/navigation";
import { ContactAdminPanel } from "@/components/contact-admin-panel";
import { defaultSiteContact,SiteContact } from "@/lib/site-contact";
import { createClient } from "@/lib/supabase/server";

export default async function ContactAdminPage(){
 const db=await createClient();const {data:{user}}=await db.auth.getUser();if(!user)redirect("/login");
 const {data:member}=await db.from("school_memberships").select("role").eq("user_id",user.id).eq("status","active").eq("role","admin").limit(1).maybeSingle();if(!member)notFound();
 let initial=defaultSiteContact;try{const {data}=await db.from("site_contact").select("id,title,body,phone,telegram_handle,instagram_handle,image_url").eq("id",1).maybeSingle();if(data)initial={...defaultSiteContact,...data} as SiteContact}catch{/* Admin can see the default values until the contact migration is applied. */}
 return <ContactAdminPanel initial={initial} userId={user.id}/>;
}
