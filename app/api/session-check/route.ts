import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function GET() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  const bootstrapEmail = process.env.PLATFORM_BOOTSTRAP_EMAIL?.trim().toLowerCase();
  // The first platform administrator has no school membership by design.
  // Let only the preconfigured bootstrap account reach the setup screen.
  if (bootstrapEmail && user.email?.trim().toLowerCase() === bootstrapEmail) {
    return NextResponse.json({ ok: true, platformSetup: true });
  }
  let { data: memberships } = await supabase.from("school_memberships").select("id").eq("user_id", user.id).eq("status", "active").limit(1);
  if (!memberships?.length) {
    const { data: accepted } = await supabase.rpc("accept_school_invites");
    if (accepted) ({ data: memberships } = await supabase.from("school_memberships").select("id").eq("user_id", user.id).eq("status", "active").limit(1));
  }
  if (memberships?.length) return NextResponse.json({ ok: true });
  return NextResponse.json({ error: "invite_required" }, { status: 403 });
}
