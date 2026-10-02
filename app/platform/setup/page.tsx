import { redirect } from "next/navigation";
import Image from "next/image";
import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { PlatformBootstrapForm } from "@/components/platform-bootstrap-form";
export const dynamic="force-dynamic";
export default async function PlatformSetup(){const db=await createClient();const {data:{user}}=await db.auth.getUser();if(!user)redirect("/login?next=/platform/setup");const {data:isAdmin}=await db.rpc("is_platform_super_admin");if(isAdmin)redirect("/portal/schools");return <main className="auth-page"><div className="auth-card"><Link href="/" className="brand"><Image src="/assets/maktabx-logo.svg" alt="MAKTAB X" width={180} height={44}/></Link><PlatformBootstrapForm email={user.email||""}/></div></main>}
