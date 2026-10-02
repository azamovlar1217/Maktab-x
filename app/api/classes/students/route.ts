import { NextResponse } from "next/server";
import { z } from "zod";
import { createClient } from "@/lib/supabase/server";
const schema=z.object({schoolId:z.string().uuid(),classId:z.string().uuid(),studentId:z.string().uuid()});
export async function POST(request:Request){try{const input=schema.parse(await request.json());const db=await createClient();const {data:{user}}=await db.auth.getUser();if(!user)return NextResponse.json({error:"Avval tizimga kiring."},{status:401});const {error}=await db.rpc("add_student_to_class",{target_school:input.schoolId,target_class:input.classId,target_student:input.studentId});if(error)throw error;return NextResponse.json({ok:true});}catch(e){return NextResponse.json({error:e instanceof Error?e.message:"O‘quvchi sinfga qo‘shilmadi."},{status:400});}}
