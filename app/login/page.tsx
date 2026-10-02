import type { Metadata } from "next";
import Link from "next/link";
import Image from "next/image";
import { ArrowRight } from "lucide-react";
import LoginForm from "./login-form";
import { hasSupabaseEnv } from "@/lib/supabase/env";

export const metadata: Metadata = { title: "Hisobga kirish" };

export default async function LoginPage({ searchParams }: { searchParams: Promise<{ error?: string; message?: string; next?: string }> }) {
  const params = await searchParams;
  return <main className="auth-page"><section className="auth-card"><header className="auth-head"><Image className="auth-logo" src="/assets/maktabx-logo.svg" alt="MAKTAB X" width={220} height={56}/><h1>Hisobingizga kiring</h1><p>O‘qish va maktab jarayonlari bir joyda.</p></header>
    {!hasSupabaseEnv() ? <div className="notice error">Supabase hali ulanmagan. .env.local faylini sozlab, ma’lumotlar bazasi migratsiyasini bajaring.</div> : <LoginForm phoneEnabled={process.env.NEXT_PUBLIC_PHONE_AUTH_ENABLED === "true"} message={params.message} error={params.error} next={params.next}/>}
    <div className="notice">Ommaviy ro‘yxatdan o‘tish yopiq. Hisobingizni maktab admini taklif qiladi. Agar taklif kutayotgan bo‘lsangiz, emailingizni tekshiring.</div><Link className="login-tour-link" href="/welcome"><span><Image src="/assets/x-robot.png" alt="" width={47} height={55}/></span><b>Platforma bilan tanishib chiqing</b><small>Rasmli tanishuv · qisqa savollar</small><ArrowRight size={15}/></Link><Link className="back-link" href="/">← Bosh sahifa</Link>
  </section></main>;
}
