import { NextResponse } from "next/server";
import { z } from "zod";
import { createClient } from "@/lib/supabase/server";
const schema=z.object({schoolId:z.string().uuid(),teacherId:z.string().uuid(),classId:z.string().uuid(),subjectId:z.string().uuid().optional(),homeroom:z.boolean()});
export async function POST(request:Request){try{const input=schema.parse(await request.json());const db=await createClient();const {data:{user}}=await db.auth.getUser();if(!user)return NextResponse.json({error:"Avval tizimga kiring."},{status:401});const {error}=await db.rpc("assign_teacher",{target_school:input.schoolId,target_teacher:input.teacherId,target_class:input.classId,target_subject:input.subjectId||"00000000-0000-0000-0000-000000000000",class_teacher:input.homeroom});if(error)throw error;return NextResponse.json({ok:true});}catch(e){return NextResponse.json({error:e instanceof Error?e.message:"O‘qituvchi tayinlanmadi."},{status:400});}}
