"use client";

import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/browser";

export default function LoginForm({ phoneEnabled, message, error }: { phoneEnabled: boolean; message?: string; error?: string }) {
  const router = useRouter();
  const [method, setMethod] = useState<"email" | "phone">("email");
  const [phoneStep, setPhoneStep] = useState<"phone" | "code">("phone");
  const [phone, setPhone] = useState("");
  const [notice, setNotice] = useState(message || "");
  const [errorText, setErrorText] = useState(error ? "Bu email taklif qilingan foydalanuvchilar ro‘yxatida yo‘q yoki taklif muddati tugagan." : "");
  const [busy, setBusy] = useState(false);

  async function postSignIn() {
    const result = await fetch("/api/session-check", { cache: "no-store" });
    if (!result.ok) {
      await createClient().auth.signOut();
      setErrorText("Bu hisob maktab tomonidan faollashtirilmagan. Maktab administratoriga murojaat qiling.");
      return;
    }
    router.replace("/portal");
    router.refresh();
  }

  async function googleSignIn() {
    setBusy(true); setErrorText("");
    try {
      const supabase = createClient();
      const { error: authError } = await supabase.auth.signInWithOAuth({ provider: "google", options: { redirectTo: `${window.location.origin}/auth/callback` } });
      if (authError) setErrorText(authError.message);
    } catch (e) { setErrorText(e instanceof Error ? e.message : "Google orqali kirib bo‘lmadi."); }
    finally { setBusy(false); }
  }

  async function emailSignIn(event: FormEvent<HTMLFormElement>) {
    event.preventDefault(); setBusy(true); setErrorText(""); setNotice("");
    const form = new FormData(event.currentTarget);
    try {
      const supabase = createClient();
      const { error: authError } = await supabase.auth.signInWithPassword({ email: String(form.get("email")), password: String(form.get("password")) });
      if (authError) throw authError;
      await postSignIn();
    } catch (e) { setErrorText(e instanceof Error ? "Email yoki parol mos kelmadi. Taklif yuborilgan manzil bilan kiring." : "Kirish amalga oshmadi."); }
    finally { setBusy(false); }
  }

  async function phoneSignIn(event: FormEvent<HTMLFormElement>) {
    event.preventDefault(); setBusy(true); setErrorText(""); setNotice("");
    const form = new FormData(event.currentTarget);
    const supabase = createClient();
    try {
      if (phoneStep === "phone") {
        const value = String(form.get("phone") || "").trim();
        if (!/^\+[1-9]\d{7,14}$/.test(value)) throw new Error("Raqamni xalqaro ko‘rinishda kiriting, masalan +998901234567.");
        const { error: authError } = await supabase.auth.signInWithOtp({ phone: value, options: { shouldCreateUser: false } });
        if (authError) throw authError;
        setPhone(value); setPhoneStep("code"); setNotice("Tasdiqlash kodi yuborildi. SMS provayder xarajatlari qo‘llanadi.");
      } else {
        const { error: authError } = await supabase.auth.verifyOtp({ phone, token: String(form.get("code")), type: "sms" });
        if (authError) throw authError;
        await postSignIn();
      }
    } catch (e) { setErrorText(e instanceof Error ? e.message : "Telefon orqali kirib bo‘lmadi."); }
    finally { setBusy(false); }
  }

  return <>
    {errorText && <div className="notice error" role="alert">{errorText}</div>}{notice && <div className="notice success" role="status">{notice}</div>}
    <div className="provider-buttons"><button className="provider-button" type="button" disabled={busy} onClick={googleSignIn}>G　Google hisobi bilan kirish</button></div>
    <div className="divider">yoki taklif qilingan hisob bilan</div>
    <div className="auth-tabs"><button className={method === "email" ? "active" : ""} type="button" onClick={() => { setMethod("email"); setErrorText(""); }}>Email va parol</button><button className={method === "phone" ? "active" : ""} type="button" disabled={!phoneEnabled} title={!phoneEnabled ? "SMS provayder sozlangach yoqiladi" : undefined} onClick={() => { setMethod("phone"); setErrorText(""); }}>{phoneEnabled ? "Telefon kodi" : "Telefon · sozlanmagan"}</button></div>
    {method === "email" ? <form onSubmit={emailSignIn}><div className="field"><label htmlFor="email">Email</label><input id="email" type="email" name="email" autoComplete="username" required placeholder="ism@maktab.uz"/></div><div className="field"><label htmlFor="password">Parol</label><input id="password" type="password" name="password" autoComplete="current-password" required placeholder="••••••••"/></div><button className="primary" type="submit" disabled={busy}>{busy ? "Tekshirilmoqda…" : "Kirish →"}</button><button className="quiet" formAction={undefined} type="button" disabled={busy} onClick={async()=>{const email=(document.querySelector<HTMLInputElement>("#email")?.value||"").trim();if(!email){setErrorText("Avval email manzilingizni kiriting.");return}setBusy(true);const {error:e}=await createClient().auth.resetPasswordForEmail(email,{redirectTo:`${window.location.origin}/auth/callback?next=/reset-password`});setBusy(false);if(e)setErrorText(e.message);else setNotice("Parolni tiklash havolasi emailingizga yuborildi.")}}>Parolni unutdingizmi?</button></form> : <form onSubmit={phoneSignIn}><div className="field"><label htmlFor="phone">Telefon raqami</label><input id="phone" name="phone" type="tel" autoComplete="tel" placeholder="+998901234567" value={phoneStep === "code" ? phone : undefined} onChange={e=>setPhone(e.target.value)} required disabled={phoneStep === "code"}/></div>{phoneStep === "code" && <div className="field"><label htmlFor="code">SMS kodi</label><input id="code" name="code" inputMode="numeric" autoComplete="one-time-code" required minLength={6} maxLength={8}/></div>}<button className="primary" type="submit" disabled={busy}>{busy ? "Kutilmoqda…" : phoneStep === "phone" ? "Kodni yuborish" : "Kodni tasdiqlash"}</button>{phoneStep === "code" && <button className="quiet" type="button" onClick={()=>{setPhoneStep("phone");setNotice("")}}>Boshqa raqamni kiritish</button>}</form>}
  </>;
}
