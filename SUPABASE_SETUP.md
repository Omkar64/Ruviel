# Supabase Setup Guide

Complete step-by-step guide to set up Supabase backend for the Instagram clone app.

## Prerequisites

1. Create a Supabase account at [supabase.com](https://supabase.com)
2. Create a new project
3. Note down your:
   - Project URL (e.g., `https://xxxxx.supabase.co`)
   - Anon Key (from Project Settings > API)

## Step 1: Update Flutter Config

Update `lib/config/supabase_config.dart` with your Supabase credentials:

```dart
class SupabaseConfig {
  static const String url = 'YOUR_SUPABASE_PROJECT_URL';
  static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
  // ... rest of the file
}
```

## Step 2: Database Schema Setup

Go to your Supabase Dashboard > SQL Editor and run these SQL queries in order:

### 2.1 Create Profiles Table

```sql
-- Create profiles table (extends auth.users)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  username TEXT UNIQUE NOT NULL,
  full_name TEXT,
  bio TEXT,
  profile_image_url TEXT,
  followers_count INTEGER DEFAULT 0,
  following_count INTEGER DEFAULT 0,
  posts_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view all profiles
CREATE POLICY "Profiles are viewable by everyone"
  ON profiles FOR SELECT
  USING (true);

-- Policy: Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- Policy: Users can insert their own profile
CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);
```

### 2.2 Create Posts Table

```sql
-- Create posts table
CREATE TABLE IF NOT EXISTS posts (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  username TEXT NOT NULL,
  caption TEXT,
  image_url TEXT,
  video_url TEXT,
  likes_count INTEGER DEFAULT 0,
  comments_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

-- Enable Row Level Security
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- Policy: Everyone can view posts
CREATE POLICY "Posts are viewable by everyone"
  ON posts FOR SELECT
  USING (true);

-- Policy: Users can create posts
CREATE POLICY "Users can create posts"
  ON posts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own posts
CREATE POLICY "Users can update own posts"
  ON posts FOR UPDATE
  USING (auth.uid() = user_id);

-- Policy: Users can delete their own posts
CREATE POLICY "Users can delete own posts"
  ON posts FOR DELETE
  USING (auth.uid() = user_id);

-- Index for better performance
CREATE INDEX IF NOT EXISTS posts_user_id_idx ON posts(user_id);
CREATE INDEX IF NOT EXISTS posts_created_at_idx ON posts(created_at DESC);
```

### 2.3 Create Likes Table

```sql
-- Create likes table
CREATE TABLE IF NOT EXISTS likes (
  id TEXT PRIMARY KEY,
  post_id TEXT REFERENCES posts(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- Enable Row Level Security
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;

-- Policy: Everyone can view likes
CREATE POLICY "Likes are viewable by everyone"
  ON likes FOR SELECT
  USING (true);

-- Policy: Users can create likes
CREATE POLICY "Users can create likes"
  ON likes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own likes
CREATE POLICY "Users can delete own likes"
  ON likes FOR DELETE
  USING (auth.uid() = user_id);

-- Index for better performance
CREATE INDEX IF NOT EXISTS likes_post_id_idx ON likes(post_id);
CREATE INDEX IF NOT EXISTS likes_user_id_idx ON likes(user_id);
```

### 2.4 Create Comments Table

```sql
-- Create comments table
CREATE TABLE IF NOT EXISTS comments (
  id TEXT PRIMARY KEY,
  post_id TEXT REFERENCES posts(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  username TEXT NOT NULL,
  comment TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

-- Enable Row Level Security
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

-- Policy: Everyone can view comments
CREATE POLICY "Comments are viewable by everyone"
  ON comments FOR SELECT
  USING (true);

-- Policy: Users can create comments
CREATE POLICY "Users can create comments"
  ON comments FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own comments
CREATE POLICY "Users can update own comments"
  ON comments FOR UPDATE
  USING (auth.uid() = user_id);

-- Policy: Users can delete their own comments
CREATE POLICY "Users can delete own comments"
  ON comments FOR DELETE
  USING (auth.uid() = user_id);

-- Index for better performance
CREATE INDEX IF NOT EXISTS comments_post_id_idx ON comments(post_id);
CREATE INDEX IF NOT EXISTS comments_user_id_idx ON comments(user_id);
```

### 2.5 Create Stories Table

```sql
-- Create stories table
CREATE TABLE IF NOT EXISTS stories (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  username TEXT NOT NULL,
  image_url TEXT,
  video_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ NOT NULL
);

-- Enable Row Level Security
ALTER TABLE stories ENABLE ROW LEVEL SECURITY;

-- Policy: Everyone can view active stories
CREATE POLICY "Stories are viewable by everyone"
  ON stories FOR SELECT
  USING (expires_at > NOW());

-- Policy: Users can create stories
CREATE POLICY "Users can create stories"
  ON stories FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own stories
CREATE POLICY "Users can delete own stories"
  ON stories FOR DELETE
  USING (auth.uid() = user_id);

-- Index for better performance
CREATE INDEX IF NOT EXISTS stories_user_id_idx ON stories(user_id);
CREATE INDEX IF NOT EXISTS stories_expires_at_idx ON stories(expires_at);
```

### 2.6 Create Reels Table

```sql
-- Create reels table
CREATE TABLE IF NOT EXISTS reels (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  username TEXT NOT NULL,
  video_url TEXT NOT NULL,
  caption TEXT,
  music TEXT,
  likes_count INTEGER DEFAULT 0,
  comments_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE reels ENABLE ROW LEVEL SECURITY;

-- Policy: Everyone can view reels
CREATE POLICY "Reels are viewable by everyone"
  ON reels FOR SELECT
  USING (true);

-- Policy: Users can create reels
CREATE POLICY "Users can create reels"
  ON reels FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own reels
CREATE POLICY "Users can update own reels"
  ON reels FOR UPDATE
  USING (auth.uid() = user_id);

-- Index for better performance
CREATE INDEX IF NOT EXISTS reels_user_id_idx ON reels(user_id);
CREATE INDEX IF NOT EXISTS reels_created_at_idx ON reels(created_at DESC);
```

### 2.7 Create Reel Likes Table

```sql
-- Create reel_likes table
CREATE TABLE IF NOT EXISTS reel_likes (
  id TEXT PRIMARY KEY,
  reel_id TEXT REFERENCES reels(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(reel_id, user_id)
);

-- Enable Row Level Security
ALTER TABLE reel_likes ENABLE ROW LEVEL SECURITY;

-- Policy: Everyone can view reel likes
CREATE POLICY "Reel likes are viewable by everyone"
  ON reel_likes FOR SELECT
  USING (true);

-- Policy: Users can create reel likes
CREATE POLICY "Users can create reel likes"
  ON reel_likes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own reel likes
CREATE POLICY "Users can delete own reel likes"
  ON reel_likes FOR DELETE
  USING (auth.uid() = user_id);
```

### 2.8 Create Follows Table

```sql
-- Create follows table
CREATE TABLE IF NOT EXISTS follows (
  id TEXT PRIMARY KEY,
  follower_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  following_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(follower_id, following_id),
  CHECK (follower_id != following_id)
);

-- Enable Row Level Security
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;

-- Policy: Everyone can view follows
CREATE POLICY "Follows are viewable by everyone"
  ON follows FOR SELECT
  USING (true);

-- Policy: Users can create follows
CREATE POLICY "Users can create follows"
  ON follows FOR INSERT
  WITH CHECK (auth.uid() = follower_id);

-- Policy: Users can delete their own follows
CREATE POLICY "Users can delete own follows"
  ON follows FOR DELETE
  USING (auth.uid() = follower_id);

-- Index for better performance
CREATE INDEX IF NOT EXISTS follows_follower_id_idx ON follows(follower_id);
CREATE INDEX IF NOT EXISTS follows_following_id_idx ON follows(following_id);
```

### 2.9 Create Messages Table

```sql
-- Create messages table
CREATE TABLE IF NOT EXISTS messages (
  id TEXT PRIMARY KEY,
  sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  receiver_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CHECK (sender_id != receiver_id)
);

-- Enable Row Level Security
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view messages they sent or received
CREATE POLICY "Users can view own messages"
  ON messages FOR SELECT
  USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

-- Policy: Users can create messages
CREATE POLICY "Users can create messages"
  ON messages FOR INSERT
  WITH CHECK (auth.uid() = sender_id);

-- Policy: Users can update messages they received (mark as read)
CREATE POLICY "Users can update received messages"
  ON messages FOR UPDATE
  USING (auth.uid() = receiver_id);

-- Index for better performance
CREATE INDEX IF NOT EXISTS messages_sender_id_idx ON messages(sender_id);
CREATE INDEX IF NOT EXISTS messages_receiver_id_idx ON messages(receiver_id);
CREATE INDEX IF NOT EXISTS messages_created_at_idx ON messages(created_at);
```

### 2.10 Create Activities Table

```sql
-- Create activities table
CREATE TABLE IF NOT EXISTS activities (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  target_user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('like', 'comment', 'follow', 'mention')),
  post_id TEXT REFERENCES posts(id) ON DELETE CASCADE,
  comment_text TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE activities ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view activities targeted at them
CREATE POLICY "Users can view own activities"
  ON activities FOR SELECT
  USING (auth.uid() = target_user_id);

-- Policy: System can create activities (using service role)
CREATE POLICY "Activities can be created"
  ON activities FOR INSERT
  WITH CHECK (true);

-- Index for better performance
CREATE INDEX IF NOT EXISTS activities_target_user_id_idx ON activities(target_user_id);
CREATE INDEX IF NOT EXISTS activities_created_at_idx ON activities(created_at DESC);
```

## Step 3: Create Database Functions

### 3.1 Post Count Functions

```sql
-- Function to increment post count
CREATE OR REPLACE FUNCTION increment_posts_count(user_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE profiles 
  SET posts_count = posts_count + 1 
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to decrement post count
CREATE OR REPLACE FUNCTION decrement_posts_count(user_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE profiles 
  SET posts_count = GREATEST(posts_count - 1, 0)
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 3.2 Likes Count Functions

```sql
-- Function to increment likes count
CREATE OR REPLACE FUNCTION increment_likes_count(post_id TEXT)
RETURNS void AS $$
BEGIN
  UPDATE posts 
  SET likes_count = likes_count + 1 
  WHERE id = post_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to decrement likes count
CREATE OR REPLACE FUNCTION decrement_likes_count(post_id TEXT)
RETURNS void AS $$
BEGIN
  UPDATE posts 
  SET likes_count = GREATEST(likes_count - 1, 0)
  WHERE id = post_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 3.3 Comments Count Functions

```sql
-- Function to increment comments count
CREATE OR REPLACE FUNCTION increment_comments_count(post_id TEXT)
RETURNS void AS $$
BEGIN
  UPDATE posts 
  SET comments_count = comments_count + 1 
  WHERE id = post_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to decrement comments count
CREATE OR REPLACE FUNCTION decrement_comments_count(post_id TEXT)
RETURNS void AS $$
BEGIN
  UPDATE posts 
  SET comments_count = GREATEST(comments_count - 1, 0)
  WHERE id = post_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 3.4 Followers/Following Count Functions

```sql
-- Function to increment followers count
CREATE OR REPLACE FUNCTION increment_followers_count(user_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE profiles 
  SET followers_count = followers_count + 1 
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to decrement followers count
CREATE OR REPLACE FUNCTION decrement_followers_count(user_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE profiles 
  SET followers_count = GREATEST(followers_count - 1, 0)
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to increment following count
CREATE OR REPLACE FUNCTION increment_following_count(user_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE profiles 
  SET following_count = following_count + 1 
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to decrement following count
CREATE OR REPLACE FUNCTION decrement_following_count(user_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE profiles 
  SET following_count = GREATEST(following_count - 1, 0)
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 3.5 Reel Likes Count Functions

```sql
-- Function to increment reel likes count
CREATE OR REPLACE FUNCTION increment_reel_likes_count(reel_id TEXT)
RETURNS void AS $$
BEGIN
  UPDATE reels 
  SET likes_count = likes_count + 1 
  WHERE id = reel_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to decrement reel likes count
CREATE OR REPLACE FUNCTION decrement_reel_likes_count(reel_id TEXT)
RETURNS void AS $$
BEGIN
  UPDATE reels 
  SET likes_count = GREATEST(likes_count - 1, 0)
  WHERE id = reel_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 3.6 Auto-create Profile Trigger

```sql
-- Function to automatically create profile when user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, username, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substr(NEW.id::text, 1, 8)),
    NEW.raw_user_meta_data->>'full_name'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to call the function on new user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

## Step 4: Storage Buckets Setup

Go to Storage in your Supabase Dashboard and create these buckets:

### 4.1 Posts Bucket

1. Click "New bucket"
2. Name: `posts`
3. Public bucket: **YES** (checked)
4. File size limit: `10 MB` (or your preference)
5. Allowed MIME types: `image/jpeg, image/png, image/webp`
6. Click "Create bucket"

**Storage Policies for posts bucket:**

```sql
-- Allow public read access
CREATE POLICY "Posts are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'posts');

-- Allow authenticated users to upload
CREATE POLICY "Authenticated users can upload posts"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'posts' AND auth.role() = 'authenticated');

-- Allow users to update their own uploads
CREATE POLICY "Users can update own posts"
ON storage.objects FOR UPDATE
USING (bucket_id = 'posts' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Allow users to delete their own uploads
CREATE POLICY "Users can delete own posts"
ON storage.objects FOR DELETE
USING (bucket_id = 'posts' AND auth.uid()::text = (storage.foldername(name))[1]);
```

### 4.2 Stories Bucket

1. Click "New bucket"
2. Name: `stories`
3. Public bucket: **YES**
4. File size limit: `20 MB`
5. Allowed MIME types: `image/jpeg, image/png, image/webp, video/mp4`
6. Click "Create bucket"

**Storage Policies for stories bucket:**

```sql
-- Allow public read access
CREATE POLICY "Stories are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'stories');

-- Allow authenticated users to upload
CREATE POLICY "Authenticated users can upload stories"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'stories' AND auth.role() = 'authenticated');

-- Allow users to delete their own stories
CREATE POLICY "Users can delete own stories"
ON storage.objects FOR DELETE
USING (bucket_id = 'stories' AND auth.uid()::text = (storage.foldername(name))[1]);
```

### 4.3 Reels Bucket

1. Click "New bucket"
2. Name: `reels`
3. Public bucket: **YES**
4. File size limit: `100 MB` (videos are larger)
5. Allowed MIME types: `video/mp4, video/quicktime`
6. Click "Create bucket"

**Storage Policies for reels bucket:**

```sql
-- Allow public read access
CREATE POLICY "Reels are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'reels');

-- Allow authenticated users to upload
CREATE POLICY "Authenticated users can upload reels"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'reels' AND auth.role() = 'authenticated');

-- Allow users to delete their own reels
CREATE POLICY "Users can delete own reels"
ON storage.objects FOR DELETE
USING (bucket_id = 'reels' AND auth.uid()::text = (storage.foldername(name))[1]);
```

### 4.4 Profiles Bucket

1. Click "New bucket"
2. Name: `profiles`
3. Public bucket: **YES**
4. File size limit: `5 MB`
5. Allowed MIME types: `image/jpeg, image/png, image/webp`
6. Click "Create bucket"

**Storage Policies for profiles bucket:**

```sql
-- Allow public read access
CREATE POLICY "Profiles are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'profiles');

-- Allow authenticated users to upload
CREATE POLICY "Authenticated users can upload profiles"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'profiles' AND auth.role() = 'authenticated');

-- Allow users to update their own profile pictures
CREATE POLICY "Users can update own profile picture"
ON storage.objects FOR UPDATE
USING (bucket_id = 'profiles' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Allow users to delete their own profile pictures
CREATE POLICY "Users can delete own profile picture"
ON storage.objects FOR DELETE
USING (bucket_id = 'profiles' AND auth.uid()::text = (storage.foldername(name))[1]);
```

## Step 5: Enable Realtime (Optional but Recommended)

Go to Database > Replication in Supabase Dashboard and enable replication for:

- `posts` table
- `messages` table  
- `comments` table
- `likes` table

This enables real-time updates in your Flutter app.

## Step 6: Verify Setup

Run this query to verify all tables are created:

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE'
ORDER BY table_name;
```

You should see:
- activities
- comments
- follows
- likes
- messages
- posts
- profiles
- reel_likes
- reels
- stories

## Step 7: Test the Setup

1. Update your `lib/config/supabase_config.dart` with your Supabase URL and key
2. Run `flutter run` in your app
3. Try registering a new user
4. Check the `profiles` table in Supabase - you should see a new row

## Troubleshooting

### Issue: "relation does not exist"
- Make sure you ran all SQL queries in order
- Check that you're in the correct database

### Issue: "permission denied"
- Check RLS policies are correctly set
- Verify you're using the correct auth context

### Issue: Storage upload fails
- Verify bucket policies are set correctly
- Check file size and MIME type restrictions

### Issue: Functions not found
- Make sure all functions are created with `SECURITY DEFINER`
- Verify function names match exactly what's in your service code

## Additional Security Recommendations

1. **Enable email confirmation** in Authentication settings
2. **Set up rate limiting** for API calls
3. **Monitor storage usage** regularly
4. **Set up backups** for your database
5. **Review RLS policies** periodically

## Next Steps

Once setup is complete:
1. Test user registration and login
2. Test creating posts with images
3. Test following/unfollowing users
4. Test messaging functionality

Your Supabase backend is now ready! 🎉

