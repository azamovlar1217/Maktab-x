-- MAKTAB X: learning, library, school community and single-use CoinShop QR.
-- Idempotent so it can be applied after recovery from a partial dashboard run.
create extension if not exists pgcrypto;

alter table public.school_memberships drop constraint if exists school_memberships_role_check;
alter table public.school_memberships add constraint school_memberships_role_check
  check (role in ('admin','director','teacher','student','parent','cook'));
alter table public.school_invites drop constraint if exists school_invites_role_check;
alter table public.school_invites add constraint school_invites_role_check
  check (role in ('admin','director','teacher','student','parent','cook'));

alter table public.rewards add column if not exists image_path text;
alter table public.rewards add column if not exists created_by uuid references public.mx_profiles(id) on delete set null;
alter table public.reward_redemptions add column if not exists token_hash text unique;
alter table public.reward_redemptions add column if not exists expires_at timestamptz;
alter table public.reward_redemptions add column if not exists redeemed_by uuid references public.mx_profiles(id) on delete set null;
alter table public.reward_redemptions add column if not exists redeemed_at timestamptz;

create table if not exists public.reading_books (
  id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
  title text not null, author text, language text not null default 'uz',
  license_label text not null, source_url text, file_path text, cover_path text,
  published_by uuid not null references public.mx_profiles(id) on delete restrict,
  created_at timestamptz not null default now(), check (file_path is not null or source_url is not null)
);
create table if not exists public.reading_progress (
  school_id uuid not null references public.schools(id) on delete cascade,
  book_id uuid not null references public.reading_books(id) on delete cascade,
  user_id uuid not null references public.mx_profiles(id) on delete cascade,
  last_page integer not null default 1 check (last_page > 0), percent smallint not null default 0 check(percent between 0 and 100),
  finished_at timestamptz, updated_at timestamptz not null default now(), primary key(book_id,user_id)
);
create table if not exists public.learning_lessons (
  id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
  title text not null, subject text not null, grade_level smallint check(grade_level between 1 and 11),
  description text not null default '', content text not null, created_by uuid not null references public.mx_profiles(id),
  published_at timestamptz, created_at timestamptz not null default now()
);
create table if not exists public.learning_questions (
  id uuid primary key default gen_random_uuid(), lesson_id uuid not null references public.learning_lessons(id) on delete cascade,
  question text not null, choices jsonb not null check(jsonb_typeof(choices)='array' and jsonb_array_length(choices) between 2 and 6),
  answer_key smallint not null check(answer_key between 0 and 5), explanation text not null default '', position smallint not null default 0
);
create table if not exists public.learning_progress (
  school_id uuid not null references public.schools(id) on delete cascade,
  lesson_id uuid not null references public.learning_lessons(id) on delete cascade,
  student_id uuid not null references public.mx_profiles(id) on delete cascade,
  best_score smallint not null default 0 check(best_score between 0 and 100), attempts integer not null default 0,
  completed_at timestamptz, updated_at timestamptz not null default now(), primary key(lesson_id,student_id)
);
create table if not exists public.school_posts (
  id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
  author_id uuid not null references public.mx_profiles(id) on delete cascade,
  body text not null check(length(body) between 1 and 2000), media_path text,
  moderated_at timestamptz, created_at timestamptz not null default now()
);
create table if not exists public.school_post_comments (
  id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
  post_id uuid not null references public.school_posts(id) on delete cascade,
  author_id uuid not null references public.mx_profiles(id) on delete cascade,
  body text not null check(length(body) between 1 and 1000), created_at timestamptz not null default now()
);
create table if not exists public.school_post_likes (
  school_id uuid not null references public.schools(id) on delete cascade,
  post_id uuid not null references public.school_posts(id) on delete cascade,
  user_id uuid not null references public.mx_profiles(id) on delete cascade,
  created_at timestamptz not null default now(), primary key(post_id,user_id)
);
create table if not exists public.school_follows (
  school_id uuid not null references public.schools(id) on delete cascade,
  follower_id uuid not null references public.mx_profiles(id) on delete cascade,
  following_id uuid not null references public.mx_profiles(id) on delete cascade,
  created_at timestamptz not null default now(), primary key(follower_id,following_id),
  check(follower_id<>following_id)
);

create index if not exists mx_books_school_idx on public.reading_books(school_id,created_at desc);
create index if not exists mx_lessons_school_idx on public.learning_lessons(school_id,published_at desc);
create index if not exists mx_posts_school_idx on public.school_posts(school_id,created_at desc);
create index if not exists mx_redemptions_student_idx on public.reward_redemptions(student_id,created_at desc);

create or replace function public.create_reward_qr(target_reward uuid, target_hash text)
returns uuid language plpgsql security definer set search_path=public as $$
declare r public.rewards%rowtype; redemption uuid;
begin
  if auth.uid() is null then raise exception 'Avval tizimga kiring'; end if;
  select * into r from public.rewards where id=target_reward and active for share;
  if not found or not public.is_school_member(r.school_id,array['student']) then raise exception 'Mukofot topilmadi yoki o‘quvchi roli kerak'; end if;
  insert into public.reward_redemptions(school_id,reward_id,student_id,status,token_hash,expires_at)
  values(r.school_id,r.id,auth.uid(),'requested',target_hash,now()+interval '10 minutes') returning id into redemption;
  return redemption;
end $$;
revoke all on function public.create_reward_qr(uuid,text) from public,anon;
grant execute on function public.create_reward_qr(uuid,text) to authenticated;

-- The signed-in cook is checked in the database; row locking makes each QR single-use.
create or replace function public.complete_reward_qr(target_hash text, cook_user uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare d public.reward_redemptions%rowtype; r public.rewards%rowtype; current_balance integer;
begin
  if auth.uid() is null or cook_user<>auth.uid() then raise exception 'Oshpaz hisobi orqali tizimga kiring'; end if;
  select * into d from public.reward_redemptions where token_hash=target_hash and status='requested' and redeemed_at is null and expires_at>now() for update;
  if not found then raise exception 'QR muddati tugagan yoki avval ishlatilgan'; end if;
  if not exists(select 1 from public.school_memberships m where m.school_id=d.school_id and m.user_id=cook_user and m.role='cook' and m.status='active') then raise exception 'Faol oshxona xodimi kerak'; end if;
  select * into r from public.rewards where id=d.reward_id and active for update;
  if not found then raise exception 'Mahsulot mavjud emas'; end if;
  if r.inventory is not null and r.inventory<1 then raise exception 'Mahsulot tugagan'; end if;
  select balance into current_balance from public.coin_accounts where school_id=d.school_id and student_id=d.student_id for update;
  if coalesce(current_balance,0)<r.cost then raise exception 'O‘quvchida X Coin yetarli emas'; end if;
  update public.coin_accounts set balance=balance-r.cost,updated_at=now() where school_id=d.school_id and student_id=d.student_id;
  if r.inventory is not null then update public.rewards set inventory=inventory-1 where id=r.id; end if;
  insert into public.coin_transactions(school_id,student_id,actor_id,amount,reason)
  values(d.school_id,d.student_id,cook_user,-r.cost,'CoinShop: '||r.name);
  update public.reward_redemptions set status='fulfilled',redeemed_by=cook_user,redeemed_at=now(),decided_by=cook_user,decided_at=now() where id=d.id;
  return jsonb_build_object('product',r.name,'cost',r.cost,'remaining',current_balance-r.cost);
end $$;
revoke all on function public.complete_reward_qr(text,uuid) from public,anon;
grant execute on function public.complete_reward_qr(text,uuid) to authenticated;

create or replace function public.submit_learning_quiz(target_lesson uuid, submitted_answers jsonb)
returns jsonb language plpgsql security definer set search_path=public as $$
declare school uuid; question_count integer; correct_count integer; score_value smallint;
begin
  if auth.uid() is null then raise exception 'Avval tizimga kiring'; end if;
  select school_id into school from public.learning_lessons where id=target_lesson and published_at is not null;
  if school is null or not public.is_school_member(school,array['student']) then raise exception 'Dars topilmadi yoki o‘quvchi roli kerak'; end if;
  select count(*),count(*) filter(where (submitted_answers->>(id::text)) ~ '^[0-5]$' and (submitted_answers->>(id::text))::integer=answer_key)
    into question_count,correct_count from public.learning_questions where lesson_id=target_lesson;
  if question_count=0 then raise exception 'Bu darsda savollar yo‘q'; end if;
  score_value:=round(correct_count*100.0/question_count)::smallint;
  insert into public.learning_progress(school_id,lesson_id,student_id,best_score,attempts,completed_at)
    values(school,target_lesson,auth.uid(),score_value,1,now())
    on conflict(lesson_id,student_id) do update set best_score=greatest(public.learning_progress.best_score,excluded.best_score), attempts=public.learning_progress.attempts+1, completed_at=now(),updated_at=now();
  return jsonb_build_object('score',score_value,'correct',correct_count,'total',question_count);
end $$;
revoke all on function public.submit_learning_quiz(uuid,jsonb) from public,anon;
grant execute on function public.submit_learning_quiz(uuid,jsonb) to authenticated;

create or replace function public.start_school_conversation(target_user uuid)
returns uuid language plpgsql security definer set search_path=public as $$
declare current_school uuid; target_conversation uuid;
begin
  if auth.uid() is null or target_user=auth.uid() then raise exception 'Invalid conversation participant'; end if;
  select school_id into current_school from public.school_memberships
    where user_id=auth.uid() and status='active' limit 1;
  if current_school is null or not exists(select 1 from public.school_memberships
    where school_id=current_school and user_id=target_user and status='active') then
    raise exception 'User is not an active member of your school';
  end if;
  select c.id into target_conversation from public.conversations c
    where c.school_id=current_school and exists(select 1 from public.conversation_participants p where p.conversation_id=c.id and p.user_id=auth.uid())
      and exists(select 1 from public.conversation_participants p where p.conversation_id=c.id and p.user_id=target_user)
      and (select count(*) from public.conversation_participants p where p.conversation_id=c.id)=2
    order by c.created_at limit 1;
  if target_conversation is null then
    insert into public.conversations(school_id,subject,created_by) values(current_school,'Maktabdagi yozishma',auth.uid()) returning id into target_conversation;
    insert into public.conversation_participants(conversation_id,user_id) values(target_conversation,auth.uid()),(target_conversation,target_user);
  end if;
  return target_conversation;
end $$;
revoke all on function public.start_school_conversation(uuid) from public;
grant execute on function public.start_school_conversation(uuid) to authenticated;

alter table public.reading_books enable row level security;
alter table public.reading_progress enable row level security;
alter table public.learning_lessons enable row level security;
alter table public.learning_questions enable row level security;
alter table public.learning_progress enable row level security;
alter table public.school_posts enable row level security;
alter table public.school_post_comments enable row level security;
alter table public.school_post_likes enable row level security;
alter table public.school_follows enable row level security;

drop policy if exists mx_books_read on public.reading_books;
create policy mx_books_read on public.reading_books for select to authenticated using(public.is_school_member(school_id));
drop policy if exists mx_books_manage on public.reading_books;
create policy mx_books_manage on public.reading_books for all to authenticated using(public.is_school_member(school_id,array['admin','director','teacher'])) with check(public.is_school_member(school_id,array['admin','director','teacher']) and published_by=auth.uid());
drop policy if exists mx_reading_progress_self on public.reading_progress;
create policy mx_reading_progress_self on public.reading_progress for all to authenticated using(user_id=auth.uid() and public.is_school_member(school_id)) with check(user_id=auth.uid() and public.is_school_member(school_id));
drop policy if exists mx_lessons_read on public.learning_lessons;
create policy mx_lessons_read on public.learning_lessons for select to authenticated using(public.is_school_member(school_id) and (published_at is not null or created_by=auth.uid() or public.is_school_member(school_id,array['admin','director'])));
drop policy if exists mx_lessons_manage on public.learning_lessons;
create policy mx_lessons_manage on public.learning_lessons for all to authenticated using(public.is_school_member(school_id,array['admin','director','teacher'])) with check(public.is_school_member(school_id,array['admin','director','teacher']) and created_by=auth.uid());
drop policy if exists mx_questions_read on public.learning_questions;
create policy mx_questions_read on public.learning_questions for select to authenticated using(exists(select 1 from public.learning_lessons l where l.id=lesson_id and public.is_school_member(l.school_id) and (l.published_at is not null or l.created_by=auth.uid() or public.is_school_member(l.school_id,array['admin','director']))));
drop policy if exists mx_questions_manage on public.learning_questions;
create policy mx_questions_manage on public.learning_questions for all to authenticated using(exists(select 1 from public.learning_lessons l where l.id=lesson_id and l.created_by=auth.uid() and public.is_school_member(l.school_id,array['admin','director','teacher']))) with check(exists(select 1 from public.learning_lessons l where l.id=lesson_id and l.created_by=auth.uid() and public.is_school_member(l.school_id,array['admin','director','teacher'])));
revoke all on public.learning_questions from anon,authenticated;
grant select(id,lesson_id,question,choices,explanation,position) on public.learning_questions to authenticated;
grant insert,update,delete on public.learning_questions to authenticated;
drop policy if exists mx_learning_progress_self on public.learning_progress;
create policy mx_learning_progress_self on public.learning_progress for select to authenticated using(student_id=auth.uid() or public.is_school_member(school_id,array['admin','director','teacher']));
drop policy if exists mx_posts_school_read on public.school_posts;
create policy mx_posts_school_read on public.school_posts for select to authenticated using(public.is_school_member(school_id) and moderated_at is null);
drop policy if exists mx_posts_school_create on public.school_posts;
create policy mx_posts_school_create on public.school_posts for insert to authenticated with check(author_id=auth.uid() and public.is_school_member(school_id,array['student','parent','teacher','admin','director']));
drop policy if exists mx_posts_moderate on public.school_posts;
create policy mx_posts_moderate on public.school_posts for update to authenticated using(public.is_school_member(school_id,array['admin','director'])) with check(public.is_school_member(school_id,array['admin','director']));
drop policy if exists mx_post_comments_read on public.school_post_comments;
create policy mx_post_comments_read on public.school_post_comments for select to authenticated using(public.is_school_member(school_id));
drop policy if exists mx_post_comments_create on public.school_post_comments;
create policy mx_post_comments_create on public.school_post_comments for insert to authenticated with check(author_id=auth.uid() and public.is_school_member(school_id));
drop policy if exists mx_post_likes_manage on public.school_post_likes;
create policy mx_post_likes_manage on public.school_post_likes for all to authenticated using(user_id=auth.uid() and public.is_school_member(school_id)) with check(user_id=auth.uid() and public.is_school_member(school_id));
drop policy if exists mx_follows_manage on public.school_follows;
drop policy if exists mx_follows_read on public.school_follows;
create policy mx_follows_read on public.school_follows for select to authenticated using(public.is_school_member(school_id));
drop policy if exists mx_follows_manage on public.school_follows;
create policy mx_follows_manage on public.school_follows for all to authenticated using(follower_id=auth.uid() and public.is_school_member(school_id)) with check(follower_id=auth.uid() and public.is_school_member(school_id) and exists(select 1 from public.school_memberships m where m.school_id=school_follows.school_id and m.user_id=following_id and m.status='active'));

drop policy if exists rewards_manage on public.rewards;
create policy rewards_manage on public.rewards for all to authenticated using(public.is_school_member(school_id,array['admin','director','cook'])) with check(public.is_school_member(school_id,array['admin','director','cook']));
drop policy if exists cafeteria_items_manage on public.cafeteria_items;
create policy cafeteria_items_manage on public.cafeteria_items for all to authenticated using(public.is_school_member(school_id,array['admin','director','cook'])) with check(public.is_school_member(school_id,array['admin','director','cook']));
drop policy if exists cafeteria_orders_manage on public.cafeteria_orders;
create policy cafeteria_orders_manage on public.cafeteria_orders for update to authenticated using(public.is_school_member(school_id,array['admin','director','cook'])) with check(public.is_school_member(school_id,array['admin','director','cook']));

grant select,insert,update,delete on public.reading_books,public.reading_progress,public.learning_lessons,public.learning_progress,public.school_posts,public.school_post_comments,public.school_post_likes,public.school_follows to authenticated;
grant usage,select on all sequences in schema public to authenticated;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('school-assets','school-assets',false,26214400,array['image/jpeg','image/png','image/webp','application/pdf','application/epub+zip','video/mp4'])
on conflict(id) do update set file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;
drop policy if exists mx_school_assets_read on storage.objects;
create policy mx_school_assets_read on storage.objects for select to authenticated using(bucket_id='school-assets' and public.is_school_member(split_part(name,'/',1)::uuid));
drop policy if exists mx_school_assets_write on storage.objects;
create policy mx_school_assets_write on storage.objects for insert to authenticated with check(bucket_id='school-assets' and public.is_school_member(split_part(name,'/',1)::uuid,array['admin','director','teacher','cook']));
drop policy if exists mx_school_assets_update on storage.objects;
create policy mx_school_assets_update on storage.objects for update to authenticated using(bucket_id='school-assets' and public.is_school_member(split_part(name,'/',1)::uuid,array['admin','director','teacher','cook'])) with check(bucket_id='school-assets' and public.is_school_member(split_part(name,'/',1)::uuid,array['admin','director','teacher','cook']));
drop policy if exists mx_school_assets_delete on storage.objects;
create policy mx_school_assets_delete on storage.objects for delete to authenticated using(bucket_id='school-assets' and public.is_school_member(split_part(name,'/',1)::uuid,array['admin','director','teacher','cook']));
