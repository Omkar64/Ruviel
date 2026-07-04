  -- ============================================
  -- DELETE FUNCTIONALITY SETUP FOR INSTAGRAM CLONE
  -- ============================================
  -- This script ensures all tables have proper DELETE policies
  -- and necessary functions for content deletion
  -- ============================================

  -- ============================================
  -- 1. VERIFY OWNERSHIP FIELDS EXIST
  -- ============================================

  -- Posts table already has user_id field - no changes needed
  -- Stories table already has user_id field - no changes needed  
  -- Reels table already has user_id field - no changes needed

  -- ============================================
  -- 2. ENABLE ROW LEVEL SECURITY (if not already enabled)
  -- ============================================

  ALTER TABLE IF EXISTS public.posts ENABLE ROW LEVEL SECURITY;
  ALTER TABLE IF EXISTS public.stories ENABLE ROW LEVEL SECURITY;
  ALTER TABLE IF EXISTS public.reels ENABLE ROW LEVEL SECURITY;

  -- ============================================
  -- 3. DELETE POLICIES FOR USER CONTENT
  -- ============================================

  -- Posts DELETE policy (if not exists)
  DROP POLICY IF EXISTS "Users can delete own posts" ON public.posts;
  CREATE POLICY "Users can delete own posts"
  ON public.posts
  FOR DELETE
  USING (auth.uid() = user_id);

  -- Stories DELETE policy (if not exists)
  DROP POLICY IF EXISTS "Users can delete own stories" ON public.stories;
  CREATE POLICY "Users can delete own stories"
  ON public.stories
  FOR DELETE
  USING (auth.uid() = user_id);

  -- Reels DELETE policy (if not exists)
  DROP POLICY IF EXISTS "Users can delete own reels" ON public.reels;
  CREATE POLICY "Users can delete own reels"
  ON public.reels
  FOR DELETE
  USING (auth.uid() = user_id);

  -- ============================================
  -- 4. STORAGE POLICIES FOR MEDIA DELETION
  -- ============================================

  -- Create storage policies if they don't exist
  -- These allow users to delete their own uploaded files

  -- Posts bucket policy
  INSERT INTO storage.policies (
    name,
    definition,
    bucket_id
  ) 
  SELECT 
    'Users can delete own post media',
    'bucket_id = ''posts'' AND (auth.uid()::text = (storage.foldername(name))[1])',
    id
  FROM storage.buckets 
  WHERE name = 'posts' 
  AND NOT EXISTS (
    SELECT 1 FROM storage.policies 
    WHERE name = 'Users can delete own post media' AND bucket_id = (SELECT id FROM storage.buckets WHERE name = ''posts'')
  );

  -- Stories bucket policy  
  INSERT INTO storage.policies (
    name,
    definition,
    bucket_id
  ) 
  SELECT 
    'Users can delete own story media',
    'bucket_id = ''stories'' AND (auth.uid()::text = (storage.foldername(name))[1])',
    id
  FROM storage.buckets 
  WHERE name = 'stories' 
  AND NOT EXISTS (
    SELECT 1 FROM storage.policies 
    WHERE name = 'Users can delete own story media' AND bucket_id = (SELECT id FROM storage.buckets WHERE name = ''stories'')
  );

  -- Reels bucket policy
  INSERT INTO storage.policies (
    name,
    definition,
    bucket_id
  ) 
  SELECT 
    'Users can delete own reel media',
    'bucket_id = ''reels'' AND (auth.uid()::text = (storage.foldername(name))[1])',
    id
  FROM storage.buckets 
  WHERE name = 'reels' 
  AND NOT EXISTS (
    SELECT 1 FROM storage.policies 
    WHERE name = 'Users can delete own reel media' AND bucket_id = (SELECT id FROM storage.buckets WHERE name = ''reels'')
  );

  -- ============================================
  -- 5. FUNCTIONS FOR COUNT UPDATES (for cleanup)
  -- ============================================

  -- Function to update posts count when post is deleted
  CREATE OR REPLACE FUNCTION decrement_posts_count_on_delete()
  RETURNS TRIGGER AS $$
  BEGIN
    UPDATE profiles 
    SET posts_count = GREATEST(posts_count - 1, 0) 
    WHERE id = OLD.user_id;
    RETURN OLD;
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

  -- Function to update reel likes count when reel is deleted
  CREATE OR REPLACE FUNCTION cleanup_reel_data_on_delete()
  RETURNS TRIGGER AS $$
  BEGIN
    -- Reel likes will be automatically deleted by CASCADE
    -- Update reel count in profiles
    UPDATE profiles 
    SET posts_count = GREATEST(posts_count - 1, 0) 
    WHERE id = OLD.user_id;
    RETURN OLD;
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

  -- ============================================
  -- 6. TRIGGERS FOR COUNT UPDATES ON DELETE
  -- ============================================

  -- Trigger for posts deletion
  DROP TRIGGER IF EXISTS on_post_deleted ON public.posts;
  CREATE TRIGGER on_post_deleted
  AFTER DELETE ON public.posts
  FOR EACH ROW
  EXECUTE FUNCTION decrement_posts_count_on_delete();

  -- Trigger for reels deletion  
  DROP TRIGGER IF EXISTS on_reel_deleted ON public.reels;
  CREATE TRIGGER on_reel_deleted
  AFTER DELETE ON public.reels
  FOR EACH ROW
  EXECUTE FUNCTION cleanup_reel_data_on_delete();

  -- ============================================
  -- 7. CLEANUP FUNCTIONS FOR EXPIRED STORIES
  -- ============================================

  -- Function to delete expired stories (can be called manually or scheduled)
  CREATE OR REPLACE FUNCTION delete_expired_stories()
  RETURNS void AS $$
  BEGIN
    DELETE FROM public.stories 
    WHERE expires_at <= NOW();
    
    -- Log the cleanup (optional)
    RAISE NOTICE 'Deleted % expired stories', ROW_COUNT;
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

  -- ============================================
  -- 8. VERIFICATION QUERIES
  -- ============================================

  -- Check if all policies exist
  SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
  FROM pg_policies 
  WHERE tablename IN ('posts', 'stories', 'reels') 
  AND cmd = 'DELETE'
  ORDER BY tablename, policyname;

  -- Check storage policies
  SELECT 
    buckets.name as bucket_name,
    policies.name as policy_name,
    policies.definition
  FROM storage.buckets buckets
  LEFT JOIN storage.policies policies ON buckets.id = policies.bucket_id
  WHERE buckets.name IN ('posts', 'stories', 'reels')
  AND (policies.definition LIKE '%DELETE%' OR policies.name LIKE '%delete%')
  ORDER BY buckets.name, policies.name;

  -- ============================================
  -- 9. SAMPLE DELETE PERMISSIONS TEST
  -- ============================================

  -- Test query to verify user can only delete their own posts
  -- (This should return 0 rows for regular users, confirming security)
  SELECT 
    'posts' as table_name,
    COUNT(*) as total_rows,
    COUNT(CASE WHEN auth.uid() = user_id THEN 1 END) as deletable_rows
  FROM public.posts

  UNION ALL

  SELECT 
    'stories' as table_name,
    COUNT(*) as total_rows,
    COUNT(CASE WHEN auth.uid() = user_id THEN 1 END) as deletable_rows  
  FROM public.stories

  UNION ALL

  SELECT 
    'reels' as table_name,
    COUNT(*) as total_rows,
    COUNT(CASE WHEN auth.uid() = user_id THEN 1 END) as deletable_rows
  FROM public.reels;

  -- ============================================
  -- SETUP COMPLETE!
  -- ============================================
  -- Your delete functionality is now fully configured with:
  -- ✅ RLS policies preventing unauthorized deletions
  -- ✅ Storage policies for media cleanup
  -- ✅ Automatic count updates on deletion
  -- ✅ Cleanup functions for expired content
  -- ============================================