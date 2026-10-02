import { createHash } from "node:crypto";
import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function POST(request: Request) {
  const db = await createClient();
  const { data: { user } } = await db.auth.getUser();
  if (!user) return NextResponse.json({ error: "Avval tizimga kiring." }, { status: 401 });
  const body = await request.json().catch(() => null) as { token?: unknown } | null;
  if (typeof body?.token !== "string" || body.token.length < 24 || body.token.length > 80) return NextResponse.json({ error: "QR kodi yaroqsiz." }, { status: 400 });
  const { data: membership } = await db.from("school_memberships").select("school_id,role").eq("user_id", user.id).eq("status", "active").limit(1).maybeSingle();
  if (!membership || membership.role !== "cook") return NextResponse.json({ error: "Skanerlash faqat maktab oshpazi hisobida mumkin." }, { status: 403 });
  const tokenHash = createHash("sha256").update(body.token).digest("hex");
  const { data, error } = await db.rpc("complete_reward_qr", { target_hash: tokenHash, cook_user: user.id });
  if (error) return NextResponse.json({ error: error.message }, { status: 409 });
  return NextResponse.json({ ok: true, ...(data as Record<string, unknown>) });
}
