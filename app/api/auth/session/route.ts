import { NextResponse } from "next/server";
import { z } from "zod";
import { createClient } from "@/lib/supabase/server";

const sessionSchema = z.object({
  access_token: z.string().min(1),
  refresh_token: z.string().min(1),
});

/** Bridges a browser Supabase session into the server-side auth cookies. */
export async function POST(request: Request) {
  const parsed = sessionSchema.safeParse(await request.json().catch(() => null));
  if (!parsed.success) return NextResponse.json({ error: "invalid_session" }, { status: 400 });

  try {
    const supabase = await createClient();
    const { error } = await supabase.auth.setSession(parsed.data);
    if (error) return NextResponse.json({ error: error.message, code: error.code }, { status: 401 });

    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) return NextResponse.json({ error: userError?.message || "User tekshiruvi bajarilmadi." }, { status: 401 });
    return NextResponse.json({ ok: true });
  } catch (error) {
    return NextResponse.json({ error: error instanceof Error ? error.message : "Sessiya endpointida ichki xato." }, { status: 500 });
  }
}
