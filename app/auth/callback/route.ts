import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function GET(request: Request) {
  const url = new URL(request.url);
  const code = url.searchParams.get("code");
  const requestedNext = url.searchParams.get("next") || "/portal";
  const next = requestedNext.startsWith("/") && !requestedNext.startsWith("//") ? requestedNext : "/portal";
  if (code) {
    const supabase = await createClient();
    const { error } = await supabase.auth.exchangeCodeForSession(code);
    if (!error) {
      const { data: userData } = await supabase.auth.getUser();
      if (userData.user) {
        const { data: memberships } = await supabase.from("school_memberships").select("id").eq("user_id", userData.user.id).eq("status", "active").limit(1);
        if (memberships?.length) return NextResponse.redirect(new URL(next, url.origin));
        const bootstrapEmail = process.env.PLATFORM_BOOTSTRAP_EMAIL?.trim().toLowerCase();
        if (bootstrapEmail && userData.user.email?.toLowerCase() === bootstrapEmail && userData.user.email_confirmed_at) {
          return NextResponse.redirect(new URL("/platform/setup", url.origin));
        }
        const { data: accepted } = await supabase.rpc("accept_school_invites");
        if (accepted) return NextResponse.redirect(new URL(next, url.origin));
      }
      await supabase.auth.signOut();
    }
  }
  return NextResponse.redirect(new URL("/login?error=invite_required", url.origin));
}
