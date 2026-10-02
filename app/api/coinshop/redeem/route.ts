import { randomBytes, createHash } from "node:crypto";
import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function POST(request: Request) {
  const db = await createClient();
  const { data: { user } } = await db.auth.getUser();
  if (!user) return NextResponse.json({ error: "Avval tizimga kiring." }, { status: 401 });
  const body = await request.json().catch(() => null) as { rewardId?: unknown } | null;
  if (typeof body?.rewardId !== "string") return NextResponse.json({ error: "Mahsulot tanlanmadi." }, { status: 400 });
  const { data: membership } = await db.from("school_memberships").select("school_id,role").eq("user_id", user.id).eq("status", "active").limit(1).maybeSingle();
  if (!membership || membership.role !== "student") return NextResponse.json({ error: "Bu QR faqat o‘quvchi hisobida yaratiladi." }, { status: 403 });
  const { data: reward, error: rewardError } = await db.from("rewards").select("id,name,school_id,active").eq("id", body.rewardId).eq("school_id", membership.school_id).eq("active", true).maybeSingle();
  if (rewardError || !reward) return NextResponse.json({ error: "Mahsulot topilmadi yoki vaqtincha mavjud emas." }, { status: 404 });
  const token = randomBytes(24).toString("base64url");
  const tokenHash = createHash("sha256").update(token).digest("hex");
  const { data: redemptionId, error } = await db.rpc("create_reward_qr", { target_reward: reward.id, target_hash: tokenHash });
  if (error || !redemptionId) return NextResponse.json({ error: error?.message || "QR yaratilmadi." }, { status: 400 });
  return NextResponse.json({ token, redemptionId, product: reward.name, expiresInSeconds: 600 });
}
