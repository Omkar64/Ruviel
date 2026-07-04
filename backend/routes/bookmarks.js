import express from 'express';
import { requireAuth } from '../middleware/auth.js';
import supabase from '../utils/auth.js';

const router = express.Router();

/**
 * POST /api/bookmarks/:postId
 * Toggle bookmark on a post
 * Requires authentication
 */
router.post('/:postId', requireAuth, async (req, res) => {
  try {
    const userId = req.userId;
    const { postId } = req.params;

    if (!postId || typeof postId !== 'string') {
      return res.status(400).json({
        error: 'Invalid post ID',
        message: 'Post ID is required'
      });
    }

    // Check if post exists
    const { data: post, error: postError } = await supabase
      .from('posts')
      .select('id')
      .eq('id', postId)
      .single();

    if (postError || !post) {
      return res.status(404).json({
        error: 'Post not found',
        message: 'Post does not exist'
      });
    }

    // Check if already bookmarked
    const { data: existingBookmark, error: bookmarkError } = await supabase
      .from('bookmarks')
      .select()
      .eq('post_id', postId)
      .eq('user_id', userId)
      .maybeSingle();

    if (bookmarkError) {
      console.error('❌ Bookmark check error:', bookmarkError);
      return res.status(500).json({
        error: 'Database error',
        message: 'Failed to check bookmark status'
      });
    }

    let isBookmarked;

    if (existingBookmark) {
      // Remove bookmark
      const { error: deleteError } = await supabase
        .from('bookmarks')
        .delete()
        .eq('post_id', postId)
        .eq('user_id', userId);

      if (deleteError) {
        console.error('❌ Remove bookmark error:', deleteError);
        return res.status(500).json({
          error: 'Database error',
          message: 'Failed to remove bookmark'
        });
      }

      isBookmarked = false;
    } else {
      // Add bookmark
      const { error: insertError } = await supabase
        .from('bookmarks')
        .insert({
          post_id: postId,
          user_id: userId,
          created_at: new Date().toISOString()
        });

      if (insertError) {
        console.error('❌ Add bookmark error:', insertError);
        return res.status(500).json({
          error: 'Database error',
          message: 'Failed to add bookmark'
        });
      }

      isBookmarked = true;
    }

    res.json({
      message: isBookmarked ? 'Post bookmarked successfully' : 'Bookmark removed successfully',
      is_bookmarked: isBookmarked
    });
  } catch (error) {
    console.error('❌ Bookmark toggle endpoint error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to toggle bookmark'
    });
  }
});

/**
 * GET /api/bookmarks/instagram
 * Get user's Instagram bookmarks
 * Requires authentication
 */
router.get('/instagram', requireAuth, async (req, res) => {
  try {
    const userId = req.userId;
    const limit = Math.min(parseInt(req.query.limit) || 20, 50);
    const offset = parseInt(req.query.offset) || 0;

    // Fetch Instagram bookmarks with post and user data
    const { data: bookmarks, error } = await supabase
      .from('bookmarks')
      .select(`
        *,
        posts!inner(
          id,
          user_id,
          caption,
          image_url,
          video_url,
          post_type,
          likes_count,
          comments_count,
          created_at,
          profiles!posts_user_id_fkey(username, profile_image_url)
        )
      `)
      .eq('user_id', userId)
      .eq('posts.post_type', 'instagram')
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) {
      console.error('❌ Instagram bookmarks fetch error:', error);
      return res.status(500).json({
        error: 'Database error',
        message: 'Failed to fetch Instagram bookmarks'
      });
    }

     // Transform data to match PostModel format
     const posts = bookmarks.map(bookmark => ({
       id: bookmark.posts.id,
       user_id: bookmark.posts.user_id || '',
       username: (bookmark.posts.profiles && bookmark.posts.profiles.username) 
         ? bookmark.posts.profiles.username 
         : 'Unknown',
       profile_image_url: bookmark.posts.profiles && bookmark.posts.profiles.profile_image_url
         ? bookmark.posts.profiles.profile_image_url
         : null,
       caption: bookmark.posts.caption || '',
       image_url: bookmark.posts.image_url || null,
       video_url: bookmark.posts.video_url || null,
       post_type: 'instagram',
       likes_count: bookmark.posts.likes_count || 0,
       comments_count: bookmark.posts.comments_count || 0,
       is_liked: false, // Will be populated separately if needed
       is_bookmarked: true,
       created_at: bookmark.posts.created_at,
       updated_at: bookmark.posts.created_at
     }));

    // Get total count - simplified approach
    const instagramPostIds = (await supabase
      .from('posts')
      .select('id')
      .eq('post_type', 'instagram')
    ).data?.map(p => p.id) || [];

     let { count: totalCount, error: countError } = await supabase
       .from('bookmarks')
       .select('post_id', { count: 'exact', head: true })
       .eq('user_id', userId)
       .in('post_id', instagramPostIds);

    if (countError) {
      console.error('❌ Instagram bookmarks count error:', countError);
    }

    res.json({
      posts,
      pagination: {
        limit,
        offset,
        total_count: totalCount || 0,
        has_more: posts.length === limit
      }
    });
  } catch (error) {
    console.error('❌ Instagram bookmarks endpoint error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to fetch Instagram bookmarks'
    });
  }
});

/**
 * GET /api/bookmarks/twitter
 * Get user's Twitter bookmarks
 * Requires authentication
 */
router.get('/twitter', requireAuth, async (req, res) => {
  try {
    const userId = req.userId;
    const limit = Math.min(parseInt(req.query.limit) || 20, 50);
    const offset = parseInt(req.query.offset) || 0;

    // Fetch Twitter bookmarks with post and user data
    const { data: bookmarks, error } = await supabase
      .from('bookmarks')
      .select(`
        *,
        posts!inner(
          id,
          user_id,
          caption,
          image_url,
          video_url,
          post_type,
          likes_count,
          comments_count,
          created_at,
          profiles!posts_user_id_fkey(username, profile_image_url)
        )
      `)
      .eq('user_id', userId)
      .eq('posts.post_type', 'twitter')
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) {
      console.error('❌ Twitter bookmarks fetch error:', error);
      return res.status(500).json({
        error: 'Database error',
        message: 'Failed to fetch Twitter bookmarks'
      });
    }

     // Transform data to match PostModel format
     const posts = bookmarks.map(bookmark => ({
       id: bookmark.posts.id,
       user_id: bookmark.posts.user_id || '',
       username: (bookmark.posts.profiles && bookmark.posts.profiles.username) 
         ? bookmark.posts.profiles.username 
         : 'Unknown',
       profile_image_url: bookmark.posts.profiles && bookmark.posts.profiles.profile_image_url
         ? bookmark.posts.profiles.profile_image_url
         : null,
       caption: bookmark.posts.caption || '',
       image_url: bookmark.posts.image_url || null,
       video_url: bookmark.posts.video_url || null,
       post_type: 'twitter',
       likes_count: bookmark.posts.likes_count || 0,
       comments_count: bookmark.posts.comments_count || 0,
       is_liked: false, // Will be populated separately if needed
       is_bookmarked: true,
       created_at: bookmark.posts.created_at,
       updated_at: bookmark.posts.created_at
     }));

     // Get total count - simplified approach
     let { count: totalCount, error: countError } = await supabase
       .from('bookmarks')
       .select('post_id', { count: 'exact', head: true })
       .eq('user_id', userId)
       .in('post_id', 
         (await supabase
           .from('posts')
           .select('id')
           .eq('post_type', 'twitter')
         ).data?.map(p => p.id) || []
       );

    if (countError) {
      console.error('❌ Twitter bookmarks count error:', countError);
    }

    res.json({
      posts,
      pagination: {
        limit,
        offset,
        total_count: totalCount || 0,
        has_more: posts.length === limit
      }
    });
  } catch (error) {
    console.error('❌ Twitter bookmarks endpoint error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to fetch Twitter bookmarks'
    });
  }
});

export default router;