import { NextResponse } from "next/server";
import { z } from "zod";
import { createClient } from "@/lib/supabase/server";
import { createAdminClient } from "@/lib/supabase/admin";

const schema=z.object({schoolId:z.string().uuid(),fullName:z.string().trim().min(2).max(120),email:z.union([z.string().trim().email(),z.literal("")]).optional(),phone:z.union([z.string().trim().regex(/^\+[1-9]\d{7,14}$/),z.literal("")]).optional(),role:z.enum(["admin","director","teacher","student","parent","cook"]) }).refine(v=>Boolean(v.email||v.phone),{message:"Email yoki telefon raqamini kiriting."});
export async function POST(req:Request){
 try{
  const input=schema.parse(await req.json()); const db=await createClient(); const {data:{user}}=await db.auth.getUser(); if(!user) return NextResponse.json({error:"Avval tizimga kiring."},{status:401});
  const {data:myRole}=await db.from("school_memberships").select("role").eq("school_id",input.schoolId).eq("user_id",user.id).eq("status","active").maybeSingle();
  if(!myRole || !(myRole.role==="admin" || (myRole.role==="director"&&input.role!=="admin")) || (myRole.role==="admin"&&input.role==="admin")) return NextResponse.json({error:"Bu amal uchun ruxsat yo‘q."},{status:403});
  if(!process.env.SUPABASE_SERVICE_ROLE_KEY) return NextResponse.json({error:"Taklif emailini yuborish uchun serverdagi SUPABASE_SERVICE_ROLE_KEY sozlanishi kerak. Foydalanuvchi parolini bu platforma yaratmaydi."},{status:503});
  const admin=createAdminClient();
  const email=input.email?.toLowerCase()||null;const phone=input.phone||null;
  const {data:invite,error}=await admin.from("school_invites").insert({school_id:input.schoolId,email,phone,role:input.role,full_name:input.fullName,invited_by:user.id}).select("id").single();
  if(error) throw error;
  const origin=new URL(req.url).origin;
  let sendError:Error|null=null;
  if(email){const {error}=await admin.auth.admin.inviteUserByEmail(email,{data:{full_name:input.fullName},redirectTo:`${origin}/auth/callback?next=/reset-password`});sendError=error}
  else if(phone){const {error}=await admin.auth.admin.createUser({phone,user_metadata:{full_name:input.fullName}});sendError=error}
  if(sendError && !/already (been )?registered|already exists|user already/i.test(sendError.message)){ await admin.from("school_invites").delete().eq("id",invite.id); throw sendError; }
  await admin.from("audit_logs").insert({school_id:input.schoolId,actor_id:user.id,action:"invite.created",entity:"school_invites",entity_id:invite.id,changes:{email,phone,role:input.role}});
  return NextResponse.json({ok:true,existingAccount:Boolean(sendError),phoneOnly:Boolean(phone&&!email)});
 }catch(e){ const msg=e instanceof Error?e.message:"Taklif yuborilmadi."; return NextResponse.json({error:msg},{status:400}); }
}
