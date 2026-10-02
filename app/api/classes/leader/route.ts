import { NextResponse } from "next/server";
import { z } from "zod";
import { createClient } from "@/lib/supabase/server";
const schema=z.object({classId:z.string().uuid(),studentId:z.string().uuid()});
export async function POST(request:Request){try{const {classId,studentId}=schema.parse(await request.json());const db=await createClient();const {data:{user}}=await db.auth.getUser();if(!user)return NextResponse.json({error:"Avval tizimga kiring."},{status:401});const {error}=await db.rpc("set_class_leader",{target_class:classId,target_student:studentId});if(error)throw error;return NextResponse.json({ok:true});}catch(e){return NextResponse.json({error:e instanceof Error?e.message:"Sardor saqlanmadi."},{status:400});}}
