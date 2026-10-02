import { notFound,redirect } from "next/navigation";
import { TourAdminPanel } from "@/components/tour-admin-panel";
import { createClient } from "@/lib/supabase/server";

export default async function TourAdminPage(){
 const db=await createClient();const {data:{user}}=await db.auth.getUser();if(!user)redirect("/login");
 const {data:member}=await db.from("school_memberships").select("role").eq("user_id",user.id).eq("status","active").eq("role","admin").limit(1).maybeSingle();if(!member)notFound();
 return <TourAdminPanel userId={user.id}/>;
}
