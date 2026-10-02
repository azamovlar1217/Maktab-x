"use client";

import { FormEvent, useCallback, useEffect, useMemo, useState } from "react";
import { MessageCircle, Send, Users } from "lucide-react";
import { createClient } from "@/lib/supabase/browser";

type Member = { id:string; full_name:string };
type Message = { id:string; sender_id:string; body:string; created_at:string };
type Thread = { id:string; peer:string; label:string; latest:string };

export function SchoolMessenger({schoolId,userId,name}:{schoolId:string;userId:string;name:string}){
 const db=useMemo(()=>createClient(),[]);
 const [members,setMembers]=useState<Member[]>([]);const [threads,setThreads]=useState<Thread[]>([]);const [messages,setMessages]=useState<Message[]>([]);const [active,setActive]=useState("");const [draft,setDraft]=useState("");const [error,setError]=useState("");const [busy,setBusy]=useState(false);
 const load=useCallback(async()=>{
  const {data:memberRows,error:memberError}=await db.from("school_memberships").select("user_id,mx_profiles!inner(id,full_name)").eq("school_id",schoolId).eq("status","active");
  if(memberError){setError("Maktab a’zolari yuklanmadi.");return}
  const memberList=(memberRows||[]).map((m:{user_id:string;mx_profiles:{full_name:string}[]})=>({id:m.user_id,full_name:m.mx_profiles?.[0]?.full_name||"Maktab a’zosi"})).filter((m:Member)=>m.id!==userId) as Member[];setMembers(memberList);
  const {data:participantRows}=await db.from("conversation_participants").select("conversation_id,user_id").eq("user_id",userId);
  const ids=(participantRows||[]).map(x=>x.conversation_id);if(!ids.length){setThreads([]);return}
  const [{data:conversations},{data:people},{data:latestMessages}]=await Promise.all([
   db.from("conversations").select("id,subject").in("id",ids).eq("school_id",schoolId),
   db.from("conversation_participants").select("conversation_id,user_id").in("conversation_id",ids),
   db.from("messages").select("id,conversation_id,sender_id,body,created_at").in("conversation_id",ids).order("created_at",{ascending:false}).limit(200)
  ]);
  const threadsNext=(conversations||[]).map(c=>{const peer=(people||[]).find(p=>p.conversation_id===c.id&&p.user_id!==userId)?.user_id||"";const msg=(latestMessages||[]).find(m=>m.conversation_id===c.id);return{id:c.id,peer,label:memberList.find(m=>m.id===peer)?.full_name||"Maktab a’zosi",latest:msg?.body||"Yangi yozishma"}});
  setThreads(threadsNext);if(active&&!ids.includes(active))setActive("");
 },[db,schoolId,userId,active]);
 useEffect(()=>{const timer=window.setTimeout(()=>void load(),0);return()=>window.clearTimeout(timer)},[load]);
 useEffect(()=>{if(!active)return;const refresh=async()=>{const {data}=await db.from("messages").select("id,sender_id,body,created_at").eq("conversation_id",active).order("created_at").limit(300);setMessages((data||[]) as Message[])};void refresh();const timer=window.setInterval(()=>void refresh(),8000);return()=>window.clearInterval(timer)},[db,active]);
 async function open(peer:string){setError("");const {data,error:e}=await db.rpc("start_school_conversation",{target_user:peer});if(e){setError(e.message);return}setActive(String(data));await load()}
 async function send(ev:FormEvent){ev.preventDefault();const body=draft.trim();if(!active||!body)return;setBusy(true);setError("");const {error:e}=await db.from("messages").insert({conversation_id:active,sender_id:userId,body});setBusy(false);if(e){setError(e.message);return}setDraft("");const {data}=await db.from("messages").select("id,sender_id,body,created_at").eq("conversation_id",active).order("created_at").limit(300);setMessages((data||[]) as Message[]);void load()}
 return <div className="messenger"><div className="messenger-side"><div className="messenger-heading"><Users size={18}/><div><b>Maktab ichidagi suhbatlar</b><small>Faqat shu maktab a’zolari</small></div></div><select defaultValue="" onChange={e=>{if(e.target.value)void open(e.target.value)}}><option value="">Yangi suhbat boshlash…</option>{members.map(m=><option key={m.id} value={m.id}>{m.full_name}</option>)}</select><div className="messenger-threads">{threads.map(t=><button key={t.id} className={active===t.id?"active":""} onClick={()=>setActive(t.id)}><span className="composer-avatar">{t.label.slice(0,1)}</span><span><b>{t.label}</b><small>{t.latest}</small></span></button>)}</div></div><section className="messenger-chat"><header><MessageCircle size={18}/><div><b>{threads.find(t=>t.id===active)?.label||"Suhbatni tanlang"}</b><small>{active?"Xavfsiz, maktab ichidagi yozishma":`Salom, ${name}`}</small></div></header>{active?<><div className="messenger-messages">{messages.map(m=><p key={m.id} className={m.sender_id===userId?"mine":""}><span>{m.body}</span><small>{new Intl.DateTimeFormat("uz-UZ",{hour:"2-digit",minute:"2-digit"}).format(new Date(m.created_at))}</small></p>)}</div><form onSubmit={send}><input value={draft} onChange={e=>setDraft(e.target.value)} maxLength={10000} placeholder="Xabar yozing…"/><button className="hub-primary" disabled={busy||!draft.trim()}><Send size={15}/> Yuborish</button></form></>:<div className="messenger-empty"><MessageCircle size={26}/><b>O‘qituvchi, ota-ona yoki maktab a’zosiga yozing</b><small>Chap tomondan mavjud suhbatni tanlang yoki yangi suhbat boshlang.</small></div>}</section>{error&&<p className="hub-error">{error}</p>}</div>
}
