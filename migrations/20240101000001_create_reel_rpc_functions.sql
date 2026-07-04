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