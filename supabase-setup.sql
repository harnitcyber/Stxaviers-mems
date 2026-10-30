-- Run this entire script in Supabase > SQL Editor > New query.
-- Create a public image bucket with a 5 MB file limit.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('memes', 'memes', true, 5242880, array['image/jpeg','image/png','image/gif','image/webp'])
on conflict (id) do update set public=true, file_size_limit=5242880,
  allowed_mime_types=array['image/jpeg','image/png','image/gif','image/webp'];

create table if not exists public.memes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  image_url text not null,
  caption text not null default '' check (char_length(caption) <= 300),
  display_name text not null default 'community_member' check (char_length(display_name) <= 24),
  created_at timestamptz not null default now()
);

alter table public.memes enable row level security;

drop policy if exists "Anyone can view memes" on public.memes;
create policy "Anyone can view memes" on public.memes
for select using (true);

drop policy if exists "Signed-in users can post memes" on public.memes;
create policy "Signed-in users can post memes" on public.memes
for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "Users can delete their own memes" on public.memes;
create policy "Users can delete their own memes" on public.memes
for delete to authenticated using (auth.uid() = user_id);

drop policy if exists "Anyone can view meme images" on storage.objects;
create policy "Anyone can view meme images" on storage.objects
for select using (bucket_id = 'memes');

drop policy if exists "Users can upload to their own folder" on storage.objects;
create policy "Users can upload to their own folder" on storage.objects
for insert to authenticated with check (
  bucket_id = 'memes' and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Users can delete their own uploaded images" on storage.objects;
create policy "Users can delete their own uploaded images" on storage.objects
for delete to authenticated using (
  bucket_id = 'memes' and (storage.foldername(name))[1] = auth.uid()::text
);
