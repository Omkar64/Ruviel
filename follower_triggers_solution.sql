-- ============================================
-- INSTAGRAM-STYLE FOLLOWER COUNT TRIGGERS
-- ============================================
-- This SQL provides a robust, production-grade solution for
-- maintaining accurate follower and following counts using PostgreSQL triggers
-- ============================================

-- 1️⃣ DROP EXISTING FUNCTIONS/TRIGGERS (Clean slate)
DROP FUNCTION IF EXISTS public.update_followers_following_counts() CASCADE;

-- 2️⃣ CREATE THE TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION public.update_followers_following_counts()
RETURNS TRIGGER AS $$
BEGIN
    -- INSERT: User started following someone
    IF TG_OP = 'INSERT' THEN
        -- Increment following_count for the follower (user who is following)
        UPDATE profiles 
        SET following_count = following_count + 1,
            updated_at = NOW()
        WHERE id = NEW.follower_id;
        
        -- Increment followers_count for the following (user being followed)
        UPDATE profiles 
        SET followers_count = followers_count + 1,
            updated_at = NOW()
        WHERE id = NEW.following_id;
        
        RETURN NEW;
    END IF;
    
    -- DELETE: User unfollowed someone
    IF TG_OP = 'DELETE' THEN
        -- Decrement following_count for the follower, prevent negative
        UPDATE profiles 
        SET following_count = GREATEST(following_count - 1, 0),
            updated_at = NOW()
        WHERE id = OLD.follower_id;
        
        -- Decrement followers_count for the following, prevent negative
        UPDATE profiles 
        SET followers_count = GREATEST(followers_count - 1, 0),
            updated_at = NOW()
        WHERE id = OLD.following_id;
        
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3️⃣ CREATE THE TRIGGER
DROP TRIGGER IF EXISTS on_follow_change ON follows;

CREATE TRIGGER on_follow_change
AFTER INSERT OR DELETE ON follows
FOR EACH ROW EXECUTE FUNCTION public.update_followers_following_counts();

-- 4️⃣ ONE-TIME DATA BACKFILL QUERY
-- Run this ONCE to fix any existing incorrect counts
UPDATE profiles p 
SET 
    followers_count = COALESCE(follower_counts.count, 0),
    following_count = COALESCE(following_counts.count, 0),
    updated_at = NOW()
FROM (
    SELECT 
        p.id,
        COUNT(DISTINCT f1.id) as follower_count,
        COUNT(DISTINCT f2.id) as following_count
    FROM profiles p
    LEFT JOIN follows f1 ON f1.following_id = p.id
    LEFT JOIN follows f2 ON f2.follower_id = p.id
    GROUP BY p.id
) as counts
WHERE 
    p.id = counts.id AND (
    p.followers_count != COALESCE(counts.follower_count, 0) OR
    p.following_count != COALESCE(counts.following_count, 0)
);

-- ============================================
-- VERIFICATION QUERIES (Optional)
-- ============================================

-- Check trigger exists:
-- SELECT * FROM pg_trigger WHERE tgname = 'on_follow_change';

-- Verify counts are accurate:
-- SELECT 
--     p.username,
--     p.followers_count as cached_followers,
--     COUNT(DISTINCT f1.id) as actual_followers,
--     p.following_count as cached_following,
--     COUNT(DISTINCT f2.id) as actual_following
-- FROM profiles p
-- LEFT JOIN follows f1 ON f1.following_id = p.id
-- LEFT JOIN follows f2 ON f2.follower_id = p.id
-- GROUP BY p.id, p.username, p.followers_count, p.following_count
-- ORDER BY p.username;

-- ============================================
-- SOLUTION COMPLETE!
-- ============================================
-- Your follower counts will now:
-- ✅ Stay automatically synchronized
-- ✅ Never go negative
-- ✅ Handle race conditions safely
-- ✅ Work with Supabase RLS
-- ✅ Be production-grade robust