import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { PortalShell } from "@/components/portal-shell";
import { AppRole, roles } from "@/lib/roles";

export const dynamic = "force-dynamic";

export default async function PortalLayout({children}:{children:React.ReactNode}) {
  const supabase=await createClient(); const {data:{user}}=await supabase.auth.getUser(); if(!user) redirect("/login");
  const {data:isPlatformAdmin}=await supabase.rpc("is_platform_super_admin");
  if(isPlatformAdmin){const {data:profile}=await supabase.from("mx_profiles").select("full_name").eq("id",user.id).maybeSingle();return <PortalShell role="super_admin" name={profile?.full_name||user.email||"Platforma admini"} school="MAKTAB X platformasi">{children}</PortalShell>}
  const {data:membership}=await supabase.from("school_memberships").select("role,school_id,schools(name)").eq("user_id",user.id).eq("status","active").limit(1).maybeSingle();
  if(!membership || !roles.includes(membership.role as AppRole)) redirect("/login?error=invite");
  const schoolData=membership.schools as unknown as {name:string}|null;
  const {data:profile}=await supabase.from("mx_profiles").select("full_name").eq("id",user.id).maybeSingle();
  return <PortalShell role={membership.role as AppRole} name={profile?.full_name||user.email||"Foydalanuvchi"} school={schoolData?.name||"Maktab"}>{children}</PortalShell>;
}
