-- School hierarchy: country-level platform admins, school admin invitations,
-- class rosters and the elected class leader.
create table if not exists public.platform_super_admins (
  user_id uuid primary key references public.mx_profiles(id) on delete cascade,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.schools add column if not exists school_number text;
alter table public.schools add column if not exists province text;
alter table public.schools add column if not exists district text;
alter table public.schools add column if not exists enabled boolean not null default true;
alter table public.classes add column if not exists class_leader_id uuid;
do $$ begin
 if not exists(select 1 from pg_constraint where conname='classes_class_leader_id_fkey') then
  alter table public.classes add constraint classes_class_leader_id_fkey foreign key(class_leader_id) references public.mx_profiles(id) on delete set null;
 end if;
end $$;

alter table public.school_memberships drop constraint if exists school_memberships_role_check;
alter table public.school_memberships add constraint school_memberships_role_check
  check (role in ('admin','director','teacher','student','parent','cook'));
alter table public.school_invites drop constraint if exists school_invites_role_check;
alter table public.school_invites add constraint school_invites_role_check
  check (role in ('admin','director','teacher','student','parent','cook'));

alter table public.platform_super_admins enable row level security;
drop policy if exists platform_super_admin_self_read on public.platform_super_admins;
create policy platform_super_admin_self_read on public.platform_super_admins
  for select to authenticated using (user_id=auth.uid() and active);
grant select on public.platform_super_admins to authenticated;

create or replace function public.is_platform_super_admin()
returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.platform_super_admins s where s.user_id=auth.uid() and s.active)
$$;
revoke all on function public.is_platform_super_admin() from public, anon;
grant execute on function public.is_platform_super_admin() to authenticated;

create or replace function public.provision_school(
  school_name text, school_slug text, school_number text, school_province text,
  school_district text, school_address text, admin_full_name text, admin_email text, actor uuid default auth.uid()
) returns uuid language plpgsql security definer set search_path=public as $$
declare new_school uuid;
begin
 if coalesce(current_setting('request.jwt.claim.role',true),'')<>'service_role' then
  if auth.uid() is null or actor is distinct from auth.uid() then raise exception 'Audit actor login bilan mos bo‘lishi kerak'; end if;
  if not public.is_platform_super_admin() then raise exception 'Platform super-admin ruxsati kerak'; end if;
 end if;
 if length(trim(school_name))<3 or length(trim(school_slug))<3 then raise exception 'Maktab nomi va kodi talab qilinadi'; end if;
 if length(trim(admin_full_name))<2 or position('@' in admin_email)=0 then raise exception 'Boshlang‘ich adminning ism va emaili kerak'; end if;
 insert into public.schools(name,slug,school_number,province,district,address,region)
 values(trim(school_name),lower(trim(school_slug)),nullif(trim(school_number),''),nullif(trim(school_province),''),nullif(trim(school_district),''),nullif(trim(school_address),''),nullif(trim(school_province),''))
 returning id into new_school;
 insert into public.school_invites(school_id,email,role,full_name,invited_by)
 values(new_school,lower(trim(admin_email)),'admin',trim(admin_full_name),actor);
 insert into public.audit_logs(school_id,actor_id,action,entity,entity_id,changes)
 values(new_school,actor,'school.provisioned','schools',new_school::text,jsonb_build_object('slug',lower(trim(school_slug)),'school_number',school_number,'province',school_province,'district',school_district));
 return new_school;
end $$;
revoke all on function public.provision_school(text,text,text,text,text,text,text,text,uuid) from public,anon;
grant execute on function public.provision_school(text,text,text,text,text,text,text,text,uuid) to authenticated,service_role;

create or replace function public.bootstrap_platform_super_admin(target_email text)
returns void language plpgsql security definer set search_path=public,auth as $$
declare target_user uuid;
begin
 if exists(select 1 from public.platform_super_admins where active) then
   if not public.is_platform_super_admin() then raise exception 'Faqat amaldagi platforma super-admini boshqasini tayinlaydi'; end if;
 elsif current_setting('request.jwt.claim.role',true)<>'service_role' then
   raise exception 'Birinchi super-adminni serverdagi ishonchli boshqaruvchi o‘rnatadi';
 end if;
 select id into target_user from auth.users where lower(email)=lower(trim(target_email));
 if target_user is null then raise exception 'Avval taklif havolasi orqali hisob ochilishi kerak'; end if;
 insert into public.platform_super_admins(user_id,active) values(target_user,true)
 on conflict(user_id) do update set active=true;
end $$;
revoke all on function public.bootstrap_platform_super_admin(text) from public,anon,authenticated;
grant execute on function public.bootstrap_platform_super_admin(text) to service_role;

drop policy if exists school_read_member on public.schools;
create policy school_read_member on public.schools for select to authenticated
 using(public.is_school_member(id) or public.is_platform_super_admin());
drop policy if exists school_manage_admin on public.schools;
create policy school_manage_admin on public.schools for update to authenticated
 using(public.is_school_member(id,array['admin']) or public.is_platform_super_admin())
 with check(public.is_school_member(id,array['admin']) or public.is_platform_super_admin());

drop policy if exists classes_manage_director on public.classes;
create policy classes_manage_director on public.classes for all to authenticated
 using(public.is_school_member(school_id,array['admin','director']) or public.is_platform_super_admin())
 with check(public.is_school_member(school_id,array['admin','director']) or public.is_platform_super_admin());
drop policy if exists class_members_manage on public.class_members;
create policy class_members_manage on public.class_members for all to authenticated
 using(public.is_school_member(school_id,array['admin','director']) or public.is_class_teacher(class_id))
 with check(public.is_school_member(school_id,array['admin','director']) or public.is_class_teacher(class_id));

create or replace function public.set_class_leader(target_class uuid, target_student uuid)
returns void language plpgsql security definer set search_path=public as $$
declare class_school uuid;
begin
 select school_id into class_school from public.classes where id=target_class;
 if class_school is null then raise exception 'Sinf topilmadi'; end if;
 if not (public.is_school_member(class_school,array['admin','director']) or public.is_class_teacher(target_class)) then raise exception 'Sinf rahbari ruxsati kerak'; end if;
 if not exists(select 1 from public.class_members cm join public.school_memberships m on m.user_id=cm.student_id and m.school_id=cm.school_id where cm.class_id=target_class and cm.student_id=target_student and cm.left_at is null and m.role='student' and m.status='active') then raise exception 'Sardor shu sinfning faol o‘quvchisi bo‘lishi kerak'; end if;
 update public.classes set class_leader_id=target_student where id=target_class;
 insert into public.audit_logs(school_id,actor_id,action,entity,entity_id,changes)
 values(class_school,auth.uid(),'class.leader_assigned','classes',target_class::text,jsonb_build_object('student_id',target_student));
end $$;
revoke all on function public.set_class_leader(uuid,uuid) from public,anon;
grant execute on function public.set_class_leader(uuid,uuid) to authenticated;

create or replace function public.assign_teacher(
 target_school uuid,target_teacher uuid,target_class uuid,target_subject uuid,class_teacher boolean default false
) returns void language plpgsql security definer set search_path=public as $$
begin
 if not public.is_school_member(target_school,array['admin','director']) then raise exception 'Direktor yoki maktab admini ruxsati kerak'; end if;
 if not exists(select 1 from public.school_memberships where school_id=target_school and user_id=target_teacher and role='teacher' and status='active') then raise exception 'Faol o‘qituvchi hisobini tanlang'; end if;
 if not exists(select 1 from public.classes where id=target_class and school_id=target_school) then raise exception 'Sinf shu maktabga tegishli emas'; end if;
 if class_teacher then
  update public.classes set homeroom_teacher_id=target_teacher where id=target_class;
 else
  if not exists(select 1 from public.subjects where id=target_subject and school_id=target_school) then raise exception 'Fan shu maktabga tegishli emas'; end if;
  insert into public.teacher_assignments(school_id,teacher_id,class_id,subject_id)
  values(target_school,target_teacher,target_class,target_subject)
  on conflict(teacher_id,class_id,subject_id) do nothing;
 end if;
 insert into public.audit_logs(school_id,actor_id,action,entity,entity_id,changes)
 values(target_school,auth.uid(),case when class_teacher then 'class.teacher_assigned' else 'teacher.subject_assigned' end,'teacher_assignments',target_class::text,jsonb_build_object('teacher_id',target_teacher,'subject_id',target_subject));
end $$;
revoke all on function public.assign_teacher(uuid,uuid,uuid,uuid,boolean) from public,anon;
grant execute on function public.assign_teacher(uuid,uuid,uuid,uuid,boolean) to authenticated;

create or replace function public.create_school_subject(target_school uuid, subject_name text, subject_color text default '#1769f5')
returns uuid language plpgsql security definer set search_path=public as $$
declare new_id uuid;
begin
 if not public.is_school_member(target_school,array['admin','director']) then raise exception 'Direktor yoki maktab admini ruxsati kerak'; end if;
 if length(trim(subject_name))<2 then raise exception 'Fan nomini kiriting'; end if;
 insert into public.subjects(school_id,name,color) values(target_school,trim(subject_name),coalesce(subject_color,'#1769f5'))
 on conflict(school_id,name) do update set name=excluded.name returning id into new_id;
 insert into public.audit_logs(school_id,actor_id,action,entity,entity_id,changes)
 values(target_school,auth.uid(),'subject.created','subjects',new_id::text,jsonb_build_object('name',trim(subject_name)));
 return new_id;
end $$;
revoke all on function public.create_school_subject(uuid,text,text) from public,anon;
grant execute on function public.create_school_subject(uuid,text,text) to authenticated;

create or replace function public.add_student_to_class(target_school uuid,target_class uuid,target_student uuid)
returns void language plpgsql security definer set search_path=public as $$
begin
 if not (public.is_school_member(target_school,array['admin','director']) or public.is_class_teacher(target_class)) then raise exception 'Direktor yoki shu sinf rahbari ruxsati kerak'; end if;
 if not exists(select 1 from public.classes where id=target_class and school_id=target_school) then raise exception 'Sinf shu maktabga tegishli emas'; end if;
 if not exists(select 1 from public.school_memberships where school_id=target_school and user_id=target_student and role='student' and status='active') then raise exception 'Avval o‘quvchini shu maktabga taklif qiling va hisobini faollashtiring'; end if;
 insert into public.class_members(school_id,class_id,student_id) values(target_school,target_class,target_student)
 on conflict(class_id,student_id) do update set left_at=null;
 insert into public.audit_logs(school_id,actor_id,action,entity,entity_id,changes)
 values(target_school,auth.uid(),'student.added_to_class','class_members',target_student::text,jsonb_build_object('class_id',target_class));
end $$;
revoke all on function public.add_student_to_class(uuid,uuid,uuid) from public,anon;
grant execute on function public.add_student_to_class(uuid,uuid,uuid) to authenticated;

drop policy if exists membership_read_self_or_manager on public.school_memberships;
create policy membership_read_self_or_manager on public.school_memberships for select to authenticated using(
 user_id=auth.uid()
 or public.is_school_member(school_id,array['admin','director'])
 or (role='student' and exists(select 1 from public.class_members cm where cm.school_id=school_memberships.school_id and cm.student_id=school_memberships.user_id and public.is_class_teacher(cm.class_id)))
 or public.is_platform_super_admin()
);
create policy memberships_read_super_admin on public.school_memberships for select to authenticated
 using(public.is_platform_super_admin());
create policy memberships_read_roster_students on public.school_memberships for select to authenticated
 using(role='student' and status='active' and (public.is_school_member(school_id,array['admin','director']) or exists(select 1 from public.class_members cm where cm.school_id=school_memberships.school_id and cm.student_id=school_memberships.user_id and public.is_class_teacher(cm.class_id))));
create policy invites_read_super_admin on public.school_invites for select to authenticated
 using(public.is_platform_super_admin());
