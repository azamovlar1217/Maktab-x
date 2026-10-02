import Link from "next/link";
import Image from "next/image";
import { createClient } from "@/lib/supabase/server";
import { ArrowRight, BookOpen, CalendarDays, CircleCheck, Clock3, Sparkles } from "lucide-react";

export default async function Dashboard(){
 const db=await createClient(); const {data:{user}}=await db.auth.getUser();
 const {data:m}=await db.from("school_memberships").select("school_id,role").eq("user_id",user!.id).eq("status","active").limit(1).single();
 if(!m) return null;
 const [{data:p},{data:announcements},{count:upcomingHomework},{count:unread}]=await Promise.all([
  db.from("mx_profiles").select("full_name").eq("id",user!.id).maybeSingle(),
  db.from("announcements").select("id,title,body,published_at").eq("school_id",m.school_id).not("published_at","is",null).order("published_at",{ascending:false}).limit(3),
  db.from("homework").select("id",{count:"exact",head:true}).eq("school_id",m.school_id).gte("due_at",new Date().toISOString()),
  db.from("notifications").select("id",{count:"exact",head:true}).eq("recipient_id",user!.id).is("read_at",null),
 ]);
 const title=p?.full_name?.split(" ")[0]||"xush kelibsiz";
 return <><section className="welcome-row"><div><div className="eyebrow"><span className="pulse-dot"/> SHAXSIY ISH JOYINGIZ</div><h1>Assalomu alaykum, {title} <span>✦</span></h1><p>Bugungi o‘quv kuningizga xush kelibsiz. Kerakli ma’lumotlaringiz shu yerda.</p></div><div className="date-chip"><CalendarDays size={17}/>{new Intl.DateTimeFormat("uz-UZ",{weekday:"long",day:"numeric",month:"long"}).format(new Date())}</div></section>
 <section className="dashboard-hero"><div className="hero-copy"><span className="hero-tag"><Sparkles size={14}/> MAKTAB X TA’LIM MUHITI</span><h2>Har bir kun —<br/><em>yangi imkoniyat.</em></h2><p>Darslar, topshiriqlar va yangiliklaringiz bir joyda.</p><Link href="/portal/schedule" className="hero-cta">Dars jadvalim <ArrowRight size={16}/></Link></div><Image src="/assets/student-boy.png" alt="Maktab X o‘quvchisi" width={512} height={768}/><div className="hero-orbit"/></section>
 <section className="stat-grid"><Stat icon={<BookOpen size={18}/>}label="Topshirish kutilayotgan vazifa"value={upcomingHomework??0}tone="blue"/><Stat icon={<CircleCheck size={18}/>}label="O‘qilmagan bildirishnoma"value={unread??0}tone="purple"/><Stat icon={<Clock3 size={18}/>}label="Faol ish joyi"value="Tayyor"tone="green"/></section>
 <div className="dashboard-columns"><section className="panel"><div className="panel-heading"><div><h3>Maktab yangiliklari</h3><p>Rahbariyat va o‘qituvchilar e’lonlari</p></div><Link href="/portal/announcements">Barchasi <ArrowRight size={14}/></Link></div>{announcements?.length? <div className="announcement-list">{announcements.map((a)=><article className="announcement" key={a.id}><span className="announcement-icon">✦</span><div><h4>{a.title}</h4><p>{a.body}</p><small>{a.published_at?new Intl.DateTimeFormat("uz-UZ",{dateStyle:"medium"}).format(new Date(a.published_at)):""}</small></div></article>)}</div>:<Empty text="Hozircha e’lonlar yo‘q. Yangi e’lonlar shu yerda ko‘rinadi."/>}</section><section className="panel quick-panel"><div className="panel-heading"><div><h3>Tezkor bo‘limlar</h3><p>Ishni davom ettiring</p></div></div><div className="quick-links"><Quick href="/portal/grades" icon="◈" label="Baholarim"/><Quick href="/portal/schedule" icon="▦" label="Dars jadvali"/><Quick href="/portal/homework" icon="✓" label="Uy vazifalari"/><Quick href="/portal/notifications" icon="♧" label="Xabarnomalar"/></div></section></div>
 <div className="privacy-note"><span>🔒</span><span><b>Ma’lumotlaringiz himoyalangan</b><small>Ushbu maktab ish joyida ko‘rinadigan ma’lumotlar hisobingiz va rolingizga qarab belgilanadi.</small></span></div></>;
}
function Stat({icon,label,value,tone}:{icon:React.ReactNode;label:string;value:string|number;tone:string}){return <div className="stat-card"><div className={`stat-icon ${tone}`}>{icon}</div><div><span>{label}</span><b>{value}</b></div><i>↗</i></div>}
function Empty({text}:{text:string}){return <div className="empty-state"><span>✦</span><p>{text}</p></div>}
function Quick({href,icon,label}:{href:string;icon:string;label:string}){return <Link href={href}><span>{icon}</span><b>{label}</b><ArrowRight size={15}/></Link>}
