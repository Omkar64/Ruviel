-- Run this SQL in your Supabase SQL Editor to create reels functionality

-- Create reels table
create table if not exists public.reels (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  username text not null,
  video_url text not null,
  caption text,
  music text,
  likes_count integer default 0 not null,
  comments_count integer default 0 not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table public.reels enable row level security;

-- Create policies
create policy "Public reels are viewable by everyone"
  on public.reels for select
  using ( true );

create policy "Users can insert their own reels"
  on public.reels for insert
  with check ( auth.uid() = user_id );

create policy "Users can update their own reels"
  on public.reels for update
  with check ( auth.uid() = user_id );

create policy "Users can delete their own reels"
  on public.reels for delete
  using ( auth.uid() = user_id );

-- Create indexes for better performance
create index if not exists reels_user_id_idx on public.reels (user_id);
create index if not exists reels_created_at_idx on public.reels (created_at);

-- Create reel_likes table
create table if not exists public.reel_likes (
  id uuid default uuid_generate_v4() primary key,
  reel_id uuid references public.reels(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  -- Prevent duplicate likes
  unique(reel_id, user_id)
);

-- Enable RLS
alter table public.reel_likes enable row level security;

-- Create policies
create policy "Users can insert their own reel likes"
  on public.reel_likes for insert
  with check ( auth.uid() = user_id );

create policy "Users can delete their own reel likes"
  on public.reel_likes for delete
  using ( auth.uid() = user_id );

-- Users can view all reel likes (for counting)
create policy "Reel likes are viewable by everyone"
  on public.reel_likes for select
  using ( true );

-- Create indexes for better performance
create index if not exists reel_likes_reel_id_idx on public.reel_likes (reel_id);
create index if not exists reel_likes_user_id_idx on public.reel_likes (user_id);

-- Create RPC function to increment reel likes count
create or replace function increment_reel_likes_count(reel_id uuid)
returns void as $$
begin
  update public.reels 
  set likes_count = likes_count + 1,
      updated_at = now()
  where id = reel_id;
end;
$$ language plpgsql;

-- Create RPC function to decrement reel likes count
create or replace function decrement_reel_likes_count(reel_id uuid)
returns void as $$
begin
  update public.reels 
  set likes_count = greatest(likes_count - 1, 0),
      updated_at = now()
  where id = reel_id;
end;
$$ language plpgsql;

-- Create RPC function to increment reel comments count
create or replace function increment_reel_comments_count(reel_id uuid)
returns void as $$
begin
  update public.reels 
  set comments_count = comments_count + 1,
      updated_at = now()
  where id = reel_id;
end;
$$ language plpgsql;

-- Create RPC function to decrement reel comments count
create or replace function decrement_reel_comments_count(reel_id uuid)
returns void as $$
begin
  update public.reels 
  set comments_count = greatest(comments_count - 1, 0),
      updated_at = now()
  where id = reel_id;
end;
$$ language plpgsql;

-- Grant execute permissions to authenticated users
grant execute on function increment_reel_likes_count(uuid) to authenticated;
grant execute on function decrement_reel_likes_count(uuid) to authenticated;
grant execute on function increment_reel_comments_count(uuid) to authenticated;
grant execute on function decrement_reel_comments_count(uuid) to authenticated;