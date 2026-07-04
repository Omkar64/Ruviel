# Post Type Integration Guide

## Overview
The app now supports separate feeds for Instagram posts and Twitter posts. Users can choose where to post when creating new content.

## Database Changes Required

**IMPORTANT:** Run this SQL in your Supabase SQL Editor:

```sql
-- Add post_type column to posts table
ALTER TABLE posts 
ADD COLUMN IF NOT EXISTS post_type TEXT DEFAULT 'instagram' CHECK (post_type IN ('instagram', 'twitter'));

-- Update existing posts to be instagram type (if any exist)
UPDATE posts SET post_type = 'instagram' WHERE post_type IS NULL;

-- Create index for better performance when filtering by type
CREATE INDEX IF NOT EXISTS posts_post_type_idx ON posts(post_type);
CREATE INDEX IF NOT EXISTS posts_post_type_created_at_idx ON posts(post_type, created_at DESC);
```

Or run the file: `update_posts_table.sql`

## What Changed

### 1. Database Schema
- Added `post_type` column to `posts` table
- Values: `'instagram'` or `'twitter'`
- Default: `'instagram'`

### 2. Post Model
- Updated `PostModel` to include `postType` field
- Helper methods: `isInstagram` and `isTwitter`

### 3. Post Service
- `createPost()` now accepts `postType` parameter
- `fetchPosts()` can filter by `postType`
- `fetchUserPosts()` can filter by `postType`

### 4. Feed Screen
- **Only shows Instagram posts** (`postType: 'instagram'`)
- Filtered automatically by PostService

### 5. Tweet Feed Screen
- **Only shows Twitter posts** (`postType: 'twitter'`)
- Filtered automatically by PostService

### 6. New Create Post Flow
1. User taps "Create" button in navigation
2. Opens `SelectPostTypeScreen` - choose Instagram or Twitter
3. Opens `CreatePostScreen` with selected type
4. Post is saved with correct `post_type`

### 7. Navigation
- Added "Create" button in both desktop (NavigationRail) and mobile (BottomNavigationBar)
- Tapping "Create" opens post type selection screen
- Position: Between "Search" and "Reels"

## How It Works

### Creating Instagram Posts
1. Navigate to Home feed
2. Tap "Create" button
3. Select "Instagram Post"
4. Add image and caption
5. Post appears in Home feed (Instagram feed)

### Creating Twitter Posts
1. Navigate anywhere
2. Tap "Create" button
3. Select "Twitter / Threads"
4. Add image and caption (or text only)
5. Post appears in Tweet feed page

### Viewing Feeds
- **Home Feed:** Shows only Instagram posts (`post_type = 'instagram'`)
- **Tweet Feed:** Shows only Twitter posts (`post_type = 'twitter'`)
- **Profile:** Shows all user's posts (both types)

## Navigation Structure

### Desktop (NavigationRail)
- Home (index 0) - Instagram feed
- Search (index 1)
- **Create (index 2)** - Opens post type selector
- Reels (index 3)
- Activity (index 4)
- Profile (index 5)
- Chat (index 6)
- Tweet (index 7) - Twitter feed

### Mobile (BottomNavigationBar)
- Same structure as desktop
- Create button opens post type selector (doesn't change selected tab)

## Testing Checklist

- [ ] Run the SQL to add `post_type` column
- [ ] Create an Instagram post - should appear in Home feed
- [ ] Create a Twitter post - should appear in Tweet feed
- [ ] Verify Instagram posts DON'T appear in Tweet feed
- [ ] Verify Twitter posts DON'T appear in Home feed
- [ ] Check profile shows both types
- [ ] Test "Create" button from navigation (desktop & mobile)

## Troubleshooting

### Issue: All posts show in both feeds
- **Cause:** `post_type` column not added or posts don't have type set
- **Fix:** Run the SQL migration and update existing posts

### Issue: Create button doesn't work
- **Cause:** Navigation index mismatch
- **Fix:** Check that index 2 is handled specially in `onDestinationSelected`

### Issue: Posts created before migration don't have type
- **Fix:** Run: `UPDATE posts SET post_type = 'instagram' WHERE post_type IS NULL;`

## Future Enhancements

- Add filter on profile to show only Instagram or Twitter posts
- Add post type indicator on posts
- Add migration option to move posts between types



