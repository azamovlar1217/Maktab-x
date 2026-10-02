-- Public contact card edited by an authorized MAKTAB X administrator.
create table if not exists public.site_contact(
 id smallint primary key default 1 check(id=1),
 title text not null, body text not null,
 phone text not null, telegram_handle text not null, instagram_handle text not null,
 image_url text, updated_by uuid references public.mx_profiles(id) on delete set null,
 updated_at timestamptz not null default now()
);
alter table public.site_contact enable row level security;
drop policy if exists mx_contact_public_read on public.site_contact;
create policy mx_contact_public_read on public.site_contact for select to anon,authenticated using(true);
drop policy if exists mx_contact_admin_manage on public.site_contact;
create policy mx_contact_admin_manage on public.site_contact for all to authenticated
 using(exists(select 1 from public.school_memberships m where m.user_id=auth.uid() and m.status='active' and m.role='admin'))
 with check(exists(select 1 from public.school_memberships m where m.user_id=auth.uid() and m.status='active' and m.role='admin') and (updated_by is null or updated_by=auth.uid()));
grant select on public.site_contact to anon,authenticated;
grant insert,update,delete on public.site_contact to authenticated;

insert into public.site_contact(id,title,body,phone,telegram_handle,instagram_handle,image_url)
values(1,'Aloqa markazi','Savol, taklif yoki hamkorlik yuzasidan biz bilan bog‘laning. MAKTAB X jamoasi yordam berishga tayyor.','+998950328088','maktabx.official','maktabx.official','/assets/contact-hero.png')
on conflict(id) do nothing;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('mx-tour-assets','mx-tour-assets',true,52428800,array['image/jpeg','image/png','image/webp','video/mp4','video/webm'])
on conflict(id) do nothing;
drop policy if exists mx_tour_asset_admin_upload on storage.objects;
create policy mx_tour_asset_admin_upload on storage.objects for insert to authenticated with check(bucket_id='mx-tour-assets' and exists(select 1 from public.school_memberships m where m.user_id=auth.uid() and m.status='active' and m.role='admin'));
