import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function GET() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  let { data: memberships } = await supabase.from("school_memberships").select("id").eq("user_id", user.id).eq("status", "active").limit(1);
  if (!memberships?.length) {
    const { data: accepted } = await supabase.rpc("accept_school_invites");
    if (accepted) ({ data: memberships } = await supabase.from("school_memberships").select("id").eq("user_id", user.id).eq("status", "active").limit(1));
  }
  return memberships?.length ? NextResponse.json({ ok: true }) : NextResponse.json({ error: "invite_required" }, { status: 403 });
}
