"use client";

import Link from "next/link";
import Image from "next/image";
import { usePathname, useRouter } from "next/navigation";
import { useState } from "react";
import { createClient } from "@/lib/supabase/browser";
import { AppRole, navigation, roleLabels } from "@/lib/roles";
import { Bell, ChevronDown, LogOut, Menu, Search, X } from "lucide-react";

export function PortalShell({ children, role, name, school }: { children: React.ReactNode; role: AppRole; name: string; school: string }) {
  const path = usePathname(); const router = useRouter(); const [open,setOpen] = useState(false);
  const current = navigation[role].find(x => x.href === path)?.label ?? "Bosh sahifa";
  const navItems=role==="super_admin"?navigation.super_admin:navigation[role];
  async function logout(){ await createClient().auth.signOut(); router.replace("/login"); router.refresh(); }
  return <div className="portal-frame">
    {open && <button className="mobile-scrim" aria-label="Menyuni yopish" onClick={()=>setOpen(false)} />}
    <aside className={`sidebar ${open ? "sidebar-open" : ""}`}>
      <Link className="brand portal-brand" href="/portal"><Image src="/assets/maktabx-logo.svg" alt="MAKTAB X" width={190} height={44}/><button className="mobile-close" onClick={e=>{e.preventDefault();setOpen(false)}} aria-label="Yopish"><X size={19}/></button></Link>
      <div className="school-switch"><span className="school-dot"/><span><b>{school}</b><small>{roleLabels[role]}</small></span><ChevronDown size={15}/></div>
      <div className="nav-caption">ISH JOYI</div><nav className="side-nav">{navItems.map((item,i)=><Link key={item.href} href={item.href} onClick={()=>setOpen(false)} className={path===item.href?"selected":""}><span className="nav-icon">{["⌂","▦","◷","✓","◎","✦","◈","☆","✉","♧"][i%10]}</span>{item.label}{item.href==="/portal/notifications"&&<i className="nav-unread"/>}</Link>)}</nav>
      <div className="sidebar-bottom"><div className="help-card"><div>✨</div><b>Yordam kerakmi?</b><small>Platformadan foydalanish bo‘yicha yo‘riqnoma</small><a href="mailto:yordam@maktabx.uz">Yordam markazi ↗</a></div><button onClick={logout} className="logout-link"><LogOut size={17}/> Chiqish</button></div>
    </aside>
    <main className="portal-main"><header className="topbar"><button className="icon-button mobile-menu" aria-label="Menyuni ochish" onClick={()=>setOpen(true)}><Menu size={19}/></button><div className="breadcrumbs">Portal <span>/</span> <b>{current}</b></div><div className="top-actions"><button className="icon-button search-action" aria-label="Qidirish"><Search size={18}/></button><Link className="icon-button" href="/portal/notifications" aria-label="Bildirishnomalar"><Bell size={18}/></Link><div className="top-profile"><div className="avatar avatar-small">{name.slice(0,1).toUpperCase()||"M"}</div><span><b>{name}</b><small>{roleLabels[role]}</small></span></div></div></header><div className="portal-content">{children}</div><footer className="portal-footer">© {new Date().getFullYear()} MAKTAB X <span>Ta’lim hamma uchun ✦</span></footer></main>
  </div>;
}
