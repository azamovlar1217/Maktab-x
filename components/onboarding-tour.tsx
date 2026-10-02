"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { ArrowLeft, ArrowRight, Check, ChevronRight, CircleHelp, Sparkles, X } from "lucide-react";
import { createClient } from "@/lib/supabase/browser";

export type TourSlide={id:string;slug:string;title:string;body:string;question:string;options:string[];media_type:"image"|"video";media_url:string|null;position:number;active:boolean};
const defaults:TourSlide[]=[
 {id:"1",slug:"welcome",title:"MAKTAB X ga xush kelibsiz!",body:"Bilimcha siz bilan maktabdagi yangi bilimlar, do‘stlar va yutuqlar sari yo‘l oladi.",question:"Qaysi sarguzashtni boshlaymiz?",options:["Darslarni ko‘raman","Kitob mutolaa qilaman"],media_type:"image",media_url:"/assets/onboarding-welcome.png",position:0,active:true},
 {id:"2",slug:"learning",title:"Har kuni oz-ozdan o‘rganamiz",body:"Qiziqarli mini-darslar, tanlovli savollar va foydali kitoblar bilimingizni mustahkamlaydi.",question:"Bugun nimani sinab ko‘rasiz?",options:["O‘yinli dars","Yangi kitob"],media_type:"image",media_url:"/assets/onboarding-learning.png",position:1,active:true},
 {id:"3",slug:"rewards",title:"Harakat — yutuqlarga olib boradi",body:"Topshiriqlar va maktabdagi faollik orqali X Coin yig‘ing, CoinShop’dagi mukofotlarga almashtiring.",question:"Qaysi maqsad sizga yoqadi?",options:["Yangi maqsad qo‘yaman","Avval platformani ko‘raman"],media_type:"image",media_url:"/assets/onboarding-reward.png",position:2,active:true},
];

export function OnboardingTour(){
 const db=useMemo(()=>createClient(),[]);const router=useRouter();const [slides,setSlides]=useState(defaults);const [step,setStep]=useState(0);const [choice,setChoice]=useState("");const [answers,setAnswers]=useState<string[]>([]);const [busy,setBusy]=useState(true);
 useEffect(()=>{let live=true;const timer=window.setTimeout(()=>{void db.from("platform_tour_slides").select("id,slug,title,body,question,options,media_type,media_url,position,active").eq("active",true).order("position").then(({data,error})=>{if(live&&!error&&data?.length)setSlides(data as TourSlide[]);if(live)setBusy(false)})},0);return()=>{live=false;window.clearTimeout(timer)}},[db]);
 const slide=slides[Math.min(step,slides.length-1)];const final=step===slides.length-1;
 function advance(){if(!choice)return;setAnswers(v=>[...v.slice(0,step),choice]);setChoice("");if(!final)setStep(v=>v+1)}
 function back(){if(step===0)return;setStep(v=>v-1);setChoice(answers[step-1]||"")}
 if(!slide)return null;
 return <main className="tour-page"><header className="tour-top"><Link href="/" className="tour-brand"><img src="/assets/maktabx-logo.svg" alt="MAKTAB X"/></Link><div className="tour-top-right"><span className="tour-step-label">{step+1} / {slides.length} · tanishuv</span><Link href="/login" className="tour-skip">O‘tkazib yuborish <X size={15}/></Link></div></header><div className="tour-progress" aria-label="Tanishuv jarayoni">{slides.map((s,i)=><span key={s.id} className={i<=step?"done":""}/>)}</div>
  <section className="tour-stage" key={slide.id}><div className="tour-copy"><div className="tour-pill"><Sparkles size={14}/> MAKTAB X · BILIM SARGUZASHTI</div><h1>{slide.title}</h1><p className="tour-body">{slide.body}</p><div className="tour-question"><CircleHelp size={19}/><div><small>BILIMCHA SO‘RAYDI</small><b>{slide.question}</b></div></div><div className="tour-options">{slide.options.map((option,i)=><button type="button" key={option} className={choice===option?"selected":""} onClick={()=>setChoice(option)}><span className="tour-option-icon">{choice===option?<Check size={16}/>:String.fromCharCode(65+i)}</span>{option}<ChevronRight size={16}/></button>)}</div><div className="tour-controls"><button className="tour-back" type="button" onClick={back} disabled={step===0}><ArrowLeft size={16}/> Orqaga</button><button className="tour-next" type="button" onClick={final?()=>router.push("/login"):advance} disabled={!choice&&!final}>{final?"Platformaga kirish":"Keyingisi"}<ArrowRight size={16}/></button></div><small className="tour-note">{busy?"Tanishuv yuklanmoqda…":"Javobingiz faqat tanishuv uchun; istalgan vaqtda o‘zgartirishingiz mumkin."}</small></div><div className="tour-art-wrap"><div className="tour-art-glow"/><div className="tour-art-card">{slide.media_url?(slide.media_type==="video"?<video src={slide.media_url} autoPlay muted loop playsInline poster="/assets/onboarding-welcome.png"/>:<img src={slide.media_url} alt="MAKTAB X tanishuv lavhasi"/>):<img src="/assets/x-bilimcha.png" alt="Bilimcha"/>}<span className="tour-art-caption"><i><Sparkles size={15}/></i><span><b>Bilimcha</b><small>Sizning bilim yo‘ldoshingiz</small></span></span></div><div className="tour-floating-star star-one">✦</div><div className="tour-floating-star star-two">✧</div><div className="tour-floating-chip">{step===0?"Yangi sarguzasht":step===1?"O‘rgan · mashq qil":"Harakat · yutuq"}</div></div></section><footer className="tour-footer"><span>✦ Bilim hamma uchun</span><span>MAKTAB X · O‘rganish maroqli bo‘lsin</span></footer>
 </main>
}
