import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function GET(request: Request) {
  const supabase = await createClient();
  const { data, error } = await supabase.auth.signInWithOAuth({ provider: "google", options: { redirectTo: `${new URL(request.url).origin}/auth/callback` } });
  if (error || !data.url) return NextResponse.redirect(new URL("/login?error=google", request.url));
  return NextResponse.redirect(data.url);
}
