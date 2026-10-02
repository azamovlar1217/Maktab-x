-- MAKTAB X production schema. No demo seed records are inserted.
create extension if not exists pgcrypto;

create table public.mx_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  phone text,
  avatar_path text,
  locale text not null default 'uz-Latn',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.schools (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  region text,
  district text,
  address text,
  timezone text not null default 'Asia/Tashkent',
  academic_year text,
  created_at timestamptz not null default now()
);

create table public.school_memberships (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  user_id uuid not null references public.mx_profiles(id) on delete cascade,
  role text not null check (role in ('admin','director','teacher','student','parent')),
  status text not null default 'active' check (status in ('invited','active','suspended')),
  created_at timestamptz not null default now(),
  unique(school_id,user_id)
);

create table public.school_invites (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  email text,
  phone text,
  role text not null check (role in ('admin','director','teacher','student','parent')),
  full_name text not null,
  invited_by uuid not null references public.mx_profiles(id),
  auth_user_id uuid references auth.users(id),
  status text not null default 'pending' check (status in ('pending','accepted','revoked','expired')),
  expires_at timestamptz not null default now() + interval '7 days',
  accepted_at timestamptz,
  created_at timestamptz not null default now(),
  check (email is not null or phone is not null)
);
create unique index school_invites_pending_email on public.school_invites(school_id,lower(email)) where status='pending' and email is not null;
create unique index school_invites_pending_phone on public.school_invites(school_id,phone) where status='pending' and phone is not null;

create table public.classes (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  name text not null,
  grade_level smallint not null check (grade_level between 1 and 11),
  homeroom_teacher_id uuid references public.mx_profiles(id) on delete set null,
  academic_year text not null,
  room text,
  created_at timestamptz not null default now(),
  unique(school_id,name,academic_year)
);

create table public.class_members (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade,
  student_id uuid not null references public.mx_profiles(id) on delete cascade,
  joined_at date not null default current_date,
  left_at date,
  unique(class_id,student_id)
);

create table public.parent_student_links (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  parent_id uuid not null references public.mx_profiles(id) on delete cascade,
  student_id uuid not null references public.mx_profiles(id) on delete cascade,
  relationship text,
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  unique(school_id,parent_id,student_id)
);

create table public.subjects (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  name text not null,
  color text not null default '#1769f5',
  icon text,
  unique(school_id,name)
);

create table public.teacher_assignments (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  teacher_id uuid not null references public.mx_profiles(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade,
  subject_id uuid not null references public.subjects(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(teacher_id,class_id,subject_id)
);

create table public.lessons (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade,
  subject_id uuid not null references public.subjects(id) on delete restrict,
  teacher_id uuid not null references public.mx_profiles(id) on delete restrict,
  weekday smallint not null check (weekday between 1 and 7),
  starts_at time not null,
  ends_at time not null,
  room text,
  academic_year text not null,
  check (ends_at > starts_at)
);

create table public.grades (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade,
  student_id uuid not null references public.mx_profiles(id) on delete cascade,
  subject_id uuid not null references public.subjects(id) on delete restrict,
  teacher_id uuid not null references public.mx_profiles(id) on delete restrict,
  score numeric(5,2) not null check (score between 0 and 100),
  scale text not null default 'percent' check (scale in ('percent','five_point','ten_point')),
  feedback text,
  assessed_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table public.attendance (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade,
  student_id uuid not null references public.mx_profiles(id) on delete cascade,
  lesson_id uuid references public.lessons(id) on delete set null,
  teacher_id uuid not null references public.mx_profiles(id) on delete restrict,
  status text not null check (status in ('present','late','excused','absent')),
  note text,
  recorded_at timestamptz not null default now(),
  unique(student_id,lesson_id,recorded_at)
);

create table public.homework (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade,
  subject_id uuid not null references public.subjects(id) on delete restrict,
  teacher_id uuid not null references public.mx_profiles(id) on delete restrict,
  title text not null,
  instructions text not null,
  attachment_path text,
  due_at timestamptz not null,
  created_at timestamptz not null default now()
);

create table public.homework_submissions (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  homework_id uuid not null references public.homework(id) on delete cascade,
  student_id uuid not null references public.mx_profiles(id) on delete cascade,
  attachment_path text,
  answer_text text,
  status text not null default 'submitted' check (status in ('submitted','reviewing','graded','returned')),
  score numeric(5,2) check (score between 0 and 100),
  teacher_feedback text,
  submitted_at timestamptz not null default now(),
  reviewed_at timestamptz,
  unique(homework_id,student_id)
);

create table public.tests (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade,
  subject_id uuid not null references public.subjects(id) on delete restrict,
  teacher_id uuid not null references public.mx_profiles(id) on delete restrict,
  title text not null,
  starts_at timestamptz not null,
  duration_minutes smallint check (duration_minutes between 5 and 300),
  description text
);

create table public.announcements (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  author_id uuid not null references public.mx_profiles(id) on delete restrict,
  title text not null,
  body text not null,
  target_roles text[] not null default array['admin','director','teacher','student','parent'],
  class_id uuid references public.classes(id) on delete cascade,
  published_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.coin_accounts (
  school_id uuid not null references public.schools(id) on delete cascade,
  student_id uuid not null references public.mx_profiles(id) on delete cascade,
  balance integer not null default 0 check (balance >= 0),
  updated_at timestamptz not null default now(),
  primary key(school_id,student_id)
);
create table public.coin_transactions (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  student_id uuid not null references public.mx_profiles(id) on delete cascade,
  actor_id uuid references public.mx_profiles(id) on delete set null,
  amount integer not null check (amount <> 0),
  reason text not null,
  created_at timestamptz not null default now()
);
create table public.rewards (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  name text not null,
  description text,
  cost integer not null check (cost > 0),
  inventory integer check (inventory is null or inventory >= 0),
  active boolean not null default true
);
create table public.reward_redemptions (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  reward_id uuid not null references public.rewards(id) on delete restrict,
  student_id uuid not null references public.mx_profiles(id) on delete cascade,
  status text not null default 'requested' check (status in ('requested','approved','fulfilled','declined')),
  created_at timestamptz not null default now(),
  decided_by uuid references public.mx_profiles(id),
  decided_at timestamptz
);

create table public.cafeteria_items (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  name text not null,
  description text,
  price numeric(10,2) not null check (price >= 0),
  available boolean not null default true
);
create table public.cafeteria_orders (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  buyer_id uuid not null references public.mx_profiles(id) on delete restrict,
  status text not null default 'placed' check (status in ('placed','preparing','ready','collected','cancelled')),
  qr_token_hash text unique,
  created_at timestamptz not null default now()
);
create table public.cafeteria_order_items (
  order_id uuid not null references public.cafeteria_orders(id) on delete cascade,
  item_id uuid not null references public.cafeteria_items(id) on delete restrict,
  quantity smallint not null check (quantity between 1 and 50),
  unit_price numeric(10,2) not null check (unit_price >= 0),
  primary key(order_id,item_id)
);

create table public.posts (
  id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
  author_id uuid not null references public.mx_profiles(id) on delete cascade, body text not null check (length(body) <= 2000),
  visibility text not null default 'school' check (visibility in ('school','class')), class_id uuid references public.classes(id),
  moderated_at timestamptz, created_at timestamptz not null default now()
);
create table public.comments (
  id uuid primary key default gen_random_uuid(), post_id uuid not null references public.posts(id) on delete cascade,
  author_id uuid not null references public.mx_profiles(id) on delete cascade, body text not null check (length(body) <= 1000),
  created_at timestamptz not null default now()
);
create table public.conversations (
  id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
  subject text, created_by uuid not null references public.mx_profiles(id), created_at timestamptz not null default now()
);
create table public.conversation_participants (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references public.mx_profiles(id) on delete cascade,
  primary key(conversation_id,user_id)
);
create table public.messages (
  id uuid primary key default gen_random_uuid(), conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.mx_profiles(id) on delete restrict, body text not null check (length(body) <= 10000),
  created_at timestamptz not null default now(), read_at timestamptz
);
create table public.notifications (
  id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
  recipient_id uuid not null references public.mx_profiles(id) on delete cascade, category text not null,
  title text not null, body text not null, read_at timestamptz, created_at timestamptz not null default now()
);
create table public.audit_logs (
  id bigint generated always as identity primary key, school_id uuid references public.schools(id) on delete set null,
  actor_id uuid references public.mx_profiles(id) on delete set null, action text not null, entity text not null,
  entity_id text, changes jsonb not null default '{}'::jsonb, created_at timestamptz not null default now()
);

create index school_memberships_user_idx on public.school_memberships(user_id,status);
create index class_members_student_idx on public.class_members(student_id,class_id);
create index grades_student_date_idx on public.grades(student_id,assessed_at desc);
create index attendance_student_date_idx on public.attendance(student_id,recorded_at desc);
create index homework_class_due_idx on public.homework(class_id,due_at);
create index announcements_school_published_idx on public.announcements(school_id,published_at desc);
create index notifications_recipient_idx on public.notifications(recipient_id,created_at desc);
create index messages_conversation_idx on public.messages(conversation_id,created_at);

create or replace function public.is_school_member(target_school uuid, allowed_roles text[] default null)
returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.school_memberships m where m.school_id=target_school and m.user_id=auth.uid() and m.status='active' and (allowed_roles is null or m.role=any(allowed_roles)))
$$;
create or replace function public.is_class_teacher(target_class uuid)
returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.teacher_assignments a join public.school_memberships m on m.school_id=a.school_id and m.user_id=a.teacher_id where a.class_id=target_class and a.teacher_id=auth.uid() and m.role='teacher' and m.status='active')
  or exists(select 1 from public.classes c join public.school_memberships m on m.school_id=c.school_id and m.user_id=c.homeroom_teacher_id where c.id=target_class and c.homeroom_teacher_id=auth.uid() and m.status='active')
$$;
create or replace function public.is_parent_of(target_student uuid, target_school uuid)
returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.parent_student_links l join public.school_memberships m on m.school_id=l.school_id and m.user_id=l.parent_id where l.school_id=target_school and l.parent_id=auth.uid() and l.student_id=target_student and l.verified_at is not null and m.status='active')
$$;
create or replace function public.is_conversation_participant(target_conversation uuid)
returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.conversation_participants cp where cp.conversation_id=target_conversation and cp.user_id=auth.uid())
$$;
revoke all on function public.is_school_member(uuid,text[]) from public;
revoke all on function public.is_class_teacher(uuid) from public;
revoke all on function public.is_parent_of(uuid,uuid) from public;
revoke all on function public.is_conversation_participant(uuid) from public;
grant execute on function public.is_school_member(uuid,text[]) to authenticated;
grant execute on function public.is_class_teacher(uuid) to authenticated;
grant execute on function public.is_parent_of(uuid,uuid) to authenticated;
grant execute on function public.is_conversation_participant(uuid) to authenticated;

-- A reward redemption and its coin debit are one database transaction.
create or replace function public.redeem_reward(target_reward uuid)
returns uuid language plpgsql security definer set search_path=public as $$
declare r public.rewards%rowtype; current_balance integer; redemption uuid;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select * into r from public.rewards where id=target_reward and active for update;
  if not found then raise exception 'Reward is unavailable'; end if;
  if not public.is_school_member(r.school_id,array['student']) then raise exception 'Student membership required'; end if;
  insert into public.coin_accounts(school_id,student_id,balance) values(r.school_id,auth.uid(),0) on conflict(school_id,student_id) do nothing;
  select balance into current_balance from public.coin_accounts where school_id=r.school_id and student_id=auth.uid() for update;
  if current_balance < r.cost then raise exception 'Not enough X Coin'; end if;
  if r.inventory is not null and r.inventory < 1 then raise exception 'Reward is out of stock'; end if;
  update public.coin_accounts set balance=balance-r.cost,updated_at=now() where school_id=r.school_id and student_id=auth.uid();
  if r.inventory is not null then update public.rewards set inventory=inventory-1 where id=r.id; end if;
  insert into public.coin_transactions(school_id,student_id,actor_id,amount,reason) values(r.school_id,auth.uid(),auth.uid(),-r.cost,'Mukofot: '||r.name);
  insert into public.reward_redemptions(school_id,reward_id,student_id) values(r.school_id,r.id,auth.uid()) returning id into redemption;
  return redemption;
end $$;
revoke all on function public.redeem_reward(uuid) from public;
grant execute on function public.redeem_reward(uuid) to authenticated;

create or replace function public.handle_new_auth_user()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  insert into public.mx_profiles(id,full_name,phone) values(new.id,coalesce(new.raw_user_meta_data->>'full_name',''),new.phone)
  on conflict(id) do nothing;
  return new;
end $$;
create trigger on_maktab_x_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_auth_user();

create or replace function public.accept_school_invites()
returns boolean language plpgsql security definer set search_path=public,auth as $$
declare current_email text; current_phone text; invite record; did_accept boolean := false;
begin
  select lower(email),phone into current_email,current_phone from auth.users where id=auth.uid() and (email_confirmed_at is not null or phone_confirmed_at is not null);
  if auth.uid() is null then return false; end if;
  for invite in select * from public.school_invites i where i.status='pending' and i.expires_at>now() and ((current_email is not null and lower(i.email)=current_email) or (current_phone is not null and i.phone=current_phone)) loop
    insert into public.mx_profiles(id,full_name,phone) values(auth.uid(),invite.full_name,current_phone) on conflict(id) do update set full_name=excluded.full_name,phone=coalesce(excluded.phone,public.mx_profiles.phone);
    insert into public.school_memberships(school_id,user_id,role,status) values(invite.school_id,auth.uid(),invite.role,'active') on conflict(school_id,user_id) do update set role=excluded.role,status='active';
    update public.school_invites set status='accepted',auth_user_id=auth.uid(),accepted_at=now() where id=invite.id;
    did_accept := true;
  end loop;
  return did_accept;
end $$;
revoke all on function public.accept_school_invites() from public;
grant execute on function public.accept_school_invites() to authenticated;

alter table public.mx_profiles enable row level security;
alter table public.schools enable row level security;
alter table public.school_memberships enable row level security;
alter table public.school_invites enable row level security;
alter table public.classes enable row level security;
alter table public.class_members enable row level security;
alter table public.parent_student_links enable row level security;
alter table public.subjects enable row level security;
alter table public.teacher_assignments enable row level security;
alter table public.lessons enable row level security;
alter table public.grades enable row level security;
alter table public.attendance enable row level security;
alter table public.homework enable row level security;
alter table public.homework_submissions enable row level security;
alter table public.tests enable row level security;
alter table public.announcements enable row level security;
alter table public.coin_accounts enable row level security;
alter table public.coin_transactions enable row level security;
alter table public.rewards enable row level security;
alter table public.reward_redemptions enable row level security;
alter table public.cafeteria_items enable row level security;
alter table public.cafeteria_orders enable row level security;
alter table public.cafeteria_order_items enable row level security;
alter table public.posts enable row level security;
alter table public.comments enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_participants enable row level security;
alter table public.messages enable row level security;
alter table public.notifications enable row level security;
alter table public.audit_logs enable row level security;

create policy profile_read_related on public.mx_profiles for select to authenticated using (
  id=auth.uid() or exists(select 1 from public.school_memberships mine join public.school_memberships theirs on theirs.school_id=mine.school_id where mine.user_id=auth.uid() and mine.status='active' and theirs.user_id=mx_profiles.id and theirs.status='active' and mine.role in ('admin','director','teacher'))
  or exists(select 1 from public.parent_student_links l where l.parent_id=auth.uid() and l.student_id=mx_profiles.id and l.verified_at is not null)
);
create policy profile_update_self on public.mx_profiles for update to authenticated using(id=auth.uid()) with check(id=auth.uid());
create policy school_read_member on public.schools for select to authenticated using(public.is_school_member(id));
create policy membership_read_self_or_manager on public.school_memberships for select to authenticated using(user_id=auth.uid() or public.is_school_member(school_id,array['admin','director']));
create policy invites_read_manager_or_invitee on public.school_invites for select to authenticated using(public.is_school_member(school_id,array['admin','director']) or lower(email)=lower(auth.jwt()->>'email') or phone=auth.jwt()->>'phone');
create policy invites_create_manager on public.school_invites for insert to authenticated with check (
  public.is_school_member(school_id,array['admin']) or (public.is_school_member(school_id,array['director']) and role<>'admin')
);
create policy invites_revoke_manager on public.school_invites for update to authenticated using(public.is_school_member(school_id,array['admin','director'])) with check(public.is_school_member(school_id,array['admin','director']));

create policy classes_read_school on public.classes for select to authenticated using(public.is_school_member(school_id));
create policy classes_manage_director on public.classes for all to authenticated using(public.is_school_member(school_id,array['admin','director'])) with check(public.is_school_member(school_id,array['admin','director']));
create policy class_members_read on public.class_members for select to authenticated using(student_id=auth.uid() or public.is_parent_of(student_id,school_id) or public.is_class_teacher(class_id) or public.is_school_member(school_id,array['admin','director']));
create policy class_members_manage on public.class_members for all to authenticated using(public.is_school_member(school_id,array['admin','director'])) with check(public.is_school_member(school_id,array['admin','director']));
create policy parents_read_links on public.parent_student_links for select to authenticated using(parent_id=auth.uid() or student_id=auth.uid() or public.is_school_member(school_id,array['admin','director']));
create policy parents_manage_links on public.parent_student_links for all to authenticated using(public.is_school_member(school_id,array['admin','director'])) with check(public.is_school_member(school_id,array['admin','director']));

create policy subjects_read on public.subjects for select to authenticated using(public.is_school_member(school_id));
create policy subjects_manage on public.subjects for all to authenticated using(public.is_school_member(school_id,array['admin','director'])) with check(public.is_school_member(school_id,array['admin','director']));
create policy teacher_assignments_read on public.teacher_assignments for select to authenticated using(teacher_id=auth.uid() or public.is_school_member(school_id,array['admin','director']) or exists(select 1 from public.class_members cm where cm.class_id=teacher_assignments.class_id and public.is_parent_of(cm.student_id,teacher_assignments.school_id)));
create policy teacher_assignments_manage on public.teacher_assignments for all to authenticated using(public.is_school_member(school_id,array['admin','director'])) with check(public.is_school_member(school_id,array['admin','director']));
create policy lessons_read on public.lessons for select to authenticated using(public.is_school_member(school_id));
create policy lessons_manage on public.lessons for all to authenticated using(public.is_school_member(school_id,array['admin','director']) or public.is_class_teacher(class_id)) with check(public.is_school_member(school_id,array['admin','director']) or public.is_class_teacher(class_id));

create policy grades_read on public.grades for select to authenticated using(student_id=auth.uid() or public.is_parent_of(student_id,school_id) or public.is_class_teacher(class_id) or public.is_school_member(school_id,array['admin','director']));
create policy grades_teacher_write on public.grades for all to authenticated using(public.is_class_teacher(class_id) or public.is_school_member(school_id,array['admin','director'])) with check(public.is_class_teacher(class_id) or public.is_school_member(school_id,array['admin','director']));
create policy attendance_read on public.attendance for select to authenticated using(student_id=auth.uid() or public.is_parent_of(student_id,school_id) or public.is_class_teacher(class_id) or public.is_school_member(school_id,array['admin','director']));
create policy attendance_teacher_write on public.attendance for all to authenticated using(public.is_class_teacher(class_id) or public.is_school_member(school_id,array['admin','director'])) with check(public.is_class_teacher(class_id) or public.is_school_member(school_id,array['admin','director']));
create policy homework_read on public.homework for select to authenticated using(public.is_school_member(school_id,array['admin','director']) or public.is_class_teacher(class_id) or exists(select 1 from public.class_members cm where cm.class_id=homework.class_id and (cm.student_id=auth.uid() or public.is_parent_of(cm.student_id,homework.school_id))));
create policy homework_teacher_write on public.homework for all to authenticated using(public.is_class_teacher(class_id) or public.is_school_member(school_id,array['admin','director'])) with check(public.is_class_teacher(class_id) or public.is_school_member(school_id,array['admin','director']));
create policy submissions_read on public.homework_submissions for select to authenticated using(student_id=auth.uid() or public.is_parent_of(student_id,school_id) or exists(select 1 from public.homework h where h.id=homework_id and public.is_class_teacher(h.class_id)) or public.is_school_member(school_id,array['admin','director']));
create policy submissions_student_add on public.homework_submissions for insert to authenticated with check(student_id=auth.uid() and exists(select 1 from public.class_members cm join public.homework h on h.class_id=cm.class_id where cm.student_id=auth.uid() and h.id=homework_id));
create policy submissions_teacher_review on public.homework_submissions for update to authenticated using(exists(select 1 from public.homework h where h.id=homework_id and public.is_class_teacher(h.class_id))) with check(exists(select 1 from public.homework h where h.id=homework_id and public.is_class_teacher(h.class_id)));
create policy tests_read on public.tests for select to authenticated using(public.is_school_member(school_id,array['admin','director']) or public.is_class_teacher(class_id) or exists(select 1 from public.class_members cm where cm.class_id=tests.class_id and (cm.student_id=auth.uid() or public.is_parent_of(cm.student_id,tests.school_id))));
create policy tests_teacher_write on public.tests for all to authenticated using(public.is_class_teacher(class_id) or public.is_school_member(school_id,array['admin','director'])) with check(public.is_class_teacher(class_id) or public.is_school_member(school_id,array['admin','director']));
create policy announcements_read on public.announcements for select to authenticated using(public.is_school_member(school_id) and (published_at is not null or author_id=auth.uid()) and exists(select 1 from public.school_memberships m where m.school_id=announcements.school_id and m.user_id=auth.uid() and m.status='active' and m.role=any(announcements.target_roles)) and (class_id is null or exists(select 1 from public.class_members cm where cm.class_id=announcements.class_id and (cm.student_id=auth.uid() or public.is_parent_of(cm.student_id,announcements.school_id))) or public.is_class_teacher(class_id) or public.is_school_member(school_id,array['admin','director'])));
create policy announcements_write on public.announcements for all to authenticated using(public.is_school_member(school_id,array['admin','director']) or (author_id=auth.uid() and public.is_school_member(school_id,array['teacher']))) with check(public.is_school_member(school_id,array['admin','director']) or (author_id=auth.uid() and public.is_school_member(school_id,array['teacher'])));

create policy coin_self_read on public.coin_accounts for select to authenticated using(student_id=auth.uid() or public.is_parent_of(student_id,school_id) or public.is_school_member(school_id,array['admin','director']));
create policy coin_ledger_read on public.coin_transactions for select to authenticated using(student_id=auth.uid() or public.is_parent_of(student_id,school_id) or public.is_school_member(school_id,array['admin','director']));
create policy rewards_read on public.rewards for select to authenticated using(public.is_school_member(school_id) and active);
create policy rewards_manage on public.rewards for all to authenticated using(public.is_school_member(school_id,array['admin','director'])) with check(public.is_school_member(school_id,array['admin','director']));
create policy redemption_read on public.reward_redemptions for select to authenticated using(student_id=auth.uid() or public.is_parent_of(student_id,school_id) or public.is_school_member(school_id,array['admin','director']));
create policy redemption_request on public.reward_redemptions for insert to authenticated with check(student_id=auth.uid() and public.is_school_member(school_id,array['student']) and status='requested' and decided_by is null and decided_at is null);
create policy redemption_decide on public.reward_redemptions for update to authenticated using(public.is_school_member(school_id,array['admin','director'])) with check(public.is_school_member(school_id,array['admin','director']));

create policy cafeteria_items_read on public.cafeteria_items for select to authenticated using(public.is_school_member(school_id) and available);
create policy cafeteria_items_manage on public.cafeteria_items for all to authenticated using(public.is_school_member(school_id,array['admin','director'])) with check(public.is_school_member(school_id,array['admin','director']));
create policy cafeteria_orders_read on public.cafeteria_orders for select to authenticated using(buyer_id=auth.uid() or public.is_school_member(school_id,array['admin','director']));
create policy cafeteria_orders_add on public.cafeteria_orders for insert to authenticated with check(buyer_id=auth.uid() and public.is_school_member(school_id,array['student','teacher','parent']) and status='placed' and qr_token_hash is null);
create policy cafeteria_orders_manage on public.cafeteria_orders for update to authenticated using(public.is_school_member(school_id,array['admin','director'])) with check(public.is_school_member(school_id,array['admin','director']));
create policy cafeteria_order_items_read on public.cafeteria_order_items for select to authenticated using(exists(select 1 from public.cafeteria_orders o where o.id=order_id and (o.buyer_id=auth.uid() or public.is_school_member(o.school_id,array['admin','director']))));
create policy cafeteria_order_items_add on public.cafeteria_order_items for insert to authenticated with check(exists(select 1 from public.cafeteria_orders o where o.id=order_id and o.buyer_id=auth.uid()));

create policy posts_read_school on public.posts for select to authenticated using(public.is_school_member(school_id) and moderated_at is null and (visibility='school' or public.is_class_teacher(class_id) or exists(select 1 from public.class_members cm where cm.class_id=posts.class_id and cm.student_id=auth.uid())));
create policy posts_create_self on public.posts for insert to authenticated with check(author_id=auth.uid() and public.is_school_member(school_id,array['student','teacher','parent']));
create policy posts_moderate on public.posts for update to authenticated using(public.is_school_member(school_id,array['admin','director'])) with check(public.is_school_member(school_id,array['admin','director']));
create policy comments_read_post on public.comments for select to authenticated using(exists(select 1 from public.posts p where p.id=post_id));
create policy comments_create_self on public.comments for insert to authenticated with check(author_id=auth.uid() and exists(select 1 from public.posts p where p.id=post_id));
create policy conversations_read_participant on public.conversations for select to authenticated using(public.is_conversation_participant(id));
create policy conversation_participants_read on public.conversation_participants for select to authenticated using(public.is_conversation_participant(conversation_id));
create policy conversations_create_school_member on public.conversations for insert to authenticated with check(created_by=auth.uid() and public.is_school_member(school_id));
create policy participant_add_self on public.conversation_participants for insert to authenticated with check(user_id=auth.uid() and exists(select 1 from public.conversations c where c.id=conversation_id and public.is_school_member(c.school_id)));
create policy messages_read_participant on public.messages for select to authenticated using(exists(select 1 from public.conversation_participants cp where cp.conversation_id=messages.conversation_id and cp.user_id=auth.uid()));
create policy messages_send_participant on public.messages for insert to authenticated with check(sender_id=auth.uid() and exists(select 1 from public.conversation_participants cp where cp.conversation_id=messages.conversation_id and cp.user_id=auth.uid()));
create policy notifications_read_self on public.notifications for select to authenticated using(recipient_id=auth.uid());
create policy notifications_mark_read on public.notifications for update to authenticated using(recipient_id=auth.uid()) with check(recipient_id=auth.uid());
create policy audit_read_managers on public.audit_logs for select to authenticated using(school_id is not null and public.is_school_member(school_id,array['admin','director']));

grant select,update on public.mx_profiles to authenticated;
grant select on public.schools,public.school_memberships,public.school_invites,public.classes,public.class_members,public.parent_student_links,public.subjects,public.teacher_assignments,public.lessons,public.grades,public.attendance,public.homework,public.homework_submissions,public.tests,public.announcements,public.coin_accounts,public.coin_transactions,public.rewards,public.reward_redemptions,public.cafeteria_items,public.cafeteria_orders,public.cafeteria_order_items,public.posts,public.comments,public.conversations,public.conversation_participants,public.messages,public.notifications,public.audit_logs to authenticated;
grant insert,update,delete on public.classes,public.class_members,public.parent_student_links,public.subjects,public.teacher_assignments,public.lessons,public.grades,public.attendance,public.homework,public.homework_submissions,public.tests,public.announcements,public.rewards,public.reward_redemptions,public.cafeteria_items,public.cafeteria_orders,public.cafeteria_order_items,public.posts,public.comments,public.conversations,public.conversation_participants,public.messages,public.notifications to authenticated;
