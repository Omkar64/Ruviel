-- Create comments table
create table if not exists public.comments (
  id uuid default uuid_generate_v4() primary key,
  post_id uuid references public.posts(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  content text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table public.comments enable row level security;

-- Create policies
create policy "Public comments are viewable by everyone"
  on public.comments for select
  using ( true );

create policy "Users can insert their own comments"
  on public.comments for insert
  with check ( auth.uid() = user_id );

create policy "Users can delete their own comments"
  on public.comments for delete
  using ( auth.uid() = user_id );

-- Create index for better performance
create index comments_post_id_idx on public.comments (post_id);
create index comments_user_id_idx on public.comments (user_id);
