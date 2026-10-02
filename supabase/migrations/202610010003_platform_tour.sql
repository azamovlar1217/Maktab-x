-- Public onboarding cards managed by school administrators. Published content is intentionally public.
create table if not exists public.platform_tour_slides(
 id uuid primary key default gen_random_uuid(), slug text unique not null,
 title text not null, body text not null, question text not null,
 options text[] not null default '{}', media_type text not null default 'image' check(media_type in ('image','video')),
 media_url text, position integer not null default 0, active boolean not null default true,
 updated_by uuid references public.mx_profiles(id) on delete set null, updated_at timestamptz not null default now()
);
alter table public.platform_tour_slides enable row level security;
drop policy if exists mx_tour_public_read on public.platform_tour_slides;
create policy mx_tour_public_read on public.platform_tour_slides for select to anon,authenticated using(active or exists(select 1 from public.school_memberships m where m.user_id=auth.uid() and m.status='active' and m.role='admin'));
drop policy if exists mx_tour_admin_manage on public.platform_tour_slides;
create policy mx_tour_admin_manage on public.platform_tour_slides for all to authenticated using(exists(select 1 from public.school_memberships m where m.user_id=auth.uid() and m.status='active' and m.role='admin')) with check(exists(select 1 from public.school_memberships m where m.user_id=auth.uid() and m.status='active' and m.role='admin') and (updated_by is null or updated_by=auth.uid()));
grant select on public.platform_tour_slides to anon,authenticated;
grant insert,update,delete on public.platform_tour_slides to authenticated;

insert into public.platform_tour_slides(slug,title,body,question,options,media_type,media_url,position)
values
 ('welcome','MAKTAB X ga xush kelibsiz!','Bilimcha siz bilan maktabdagi yangi bilimlar, do‘stlar va yutuqlar sari yo‘l oladi.','Qaysi sarguzashtni boshlaymiz?','{"Darslarni ko‘raman","Kitob mutolaa qilaman"}','image','/assets/onboarding-welcome.png',0),
 ('learning','Har kuni oz-ozdan o‘rganamiz','Qiziqarli mini-darslar, tanlovli savollar va foydali kitoblar bilimingizni mustahkamlaydi.','Bugun nimani sinab ko‘rasiz?','{"O‘yinli dars","Yangi kitob"}','image','/assets/onboarding-learning.png',1),
 ('rewards','Harakat — yutuqlarga olib boradi','Topshiriqlar va maktabdagi faollik orqali X Coin yig‘ing, CoinShop’dagi mukofotlarga almashtiring.','Qaysi maqsad sizga yoqadi?','{"Yangi maqsad qo‘yaman","Avval platformani ko‘raman"}','image','/assets/onboarding-reward.png',2)
on conflict(slug) do nothing;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('mx-tour-assets','mx-tour-assets',true,52428800,array['image/jpeg','image/png','image/webp','video/mp4','video/webm'])
on conflict(id) do update set public=true,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;
drop policy if exists mx_tour_asset_admin_upload on storage.objects;
create policy mx_tour_asset_admin_upload on storage.objects for insert to authenticated with check(bucket_id='mx-tour-assets' and exists(select 1 from public.school_memberships m where m.user_id=auth.uid() and m.status='active' and m.role='admin'));
drop policy if exists mx_tour_asset_admin_update on storage.objects;
create policy mx_tour_asset_admin_update on storage.objects for update to authenticated using(bucket_id='mx-tour-assets' and exists(select 1 from public.school_memberships m where m.user_id=auth.uid() and m.status='active' and m.role='admin')) with check(bucket_id='mx-tour-assets' and exists(select 1 from public.school_memberships m where m.user_id=auth.uid() and m.status='active' and m.role='admin'));
drop policy if exists mx_tour_asset_admin_delete on storage.objects;
create policy mx_tour_asset_admin_delete on storage.objects for delete to authenticated using(bucket_id='mx-tour-assets' and exists(select 1 from public.school_memberships m where m.user_id=auth.uid() and m.status='active' and m.role='admin'));
