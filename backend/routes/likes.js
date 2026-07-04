import express from 'express';
import { requireAuth } from '../middleware/auth.js';
import supabase from '../utils/auth.js';

const router = express.Router();

/**
 * POST /api/posts/:id/like
 * Toggle like on a post
 * Requires authentication
 */
router.post('/posts/:id/like', requireAuth, async (req, res) => {
  try {
    const userId = req.userId;
    const { id: postId } = req.params;

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

    // Check if already liked
    const { data: existingLike, error: likeError } = await supabase
      .from('likes')
      .select()
      .eq('post_id', postId)
      .eq('user_id', userId)
      .maybeSingle();

    if (likeError) {
      console.error('❌ Like check error:', likeError);
      return res.status(500).json({
        error: 'Database error',
        message: 'Failed to check like status'
      });
    }

    let isLiked;
    let likesCount;

    if (existingLike) {
      // Unlike: Remove the like
      const { error: deleteError } = await supabase
        .from('likes')
        .delete()
        .eq('post_id', postId)
        .eq('user_id', userId);

      if (deleteError) {
        console.error('❌ Unlike error:', deleteError);
        return res.status(500).json({
          error: 'Database error',
          message: 'Failed to unlike post'
        });
      }

      // Decrement likes count
      const { error: countError } = await supabase
        .rpc('decrement_likes_count', { post_id: postId });

      if (countError) {
        console.error('❌ Likes count decrement error:', countError);
      }

      isLiked = false;
      likesCount = await getCurrentLikesCount(postId);
    } else {
      // Like: Add the like
      const { error: insertError } = await supabase
        .from('likes')
        .insert({
          post_id: postId,
          user_id: userId,
          created_at: new Date().toISOString()
        });

      if (insertError) {
        console.error('❌ Like error:', insertError);
        return res.status(500).json({
          error: 'Database error',
          message: 'Failed to like post'
        });
      }

      // Increment likes count
      const { error: countError } = await supabase
        .rpc('increment_likes_count', { post_id: postId });

      if (countError) {
        console.error('❌ Likes count increment error:', countError);
      }

      isLiked = true;
      likesCount = await getCurrentLikesCount(postId);
    }

    res.json({
      message: isLiked ? 'Post liked successfully' : 'Post unliked successfully',
      is_liked: isLiked,
      likes_count: likesCount
    });
  } catch (error) {
    console.error('❌ Like toggle endpoint error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to toggle like'
    });
  }
});

/**
 * GET /api/posts/:id/likes
 * Get likes for a post (paginated)
 * Optional authentication
 */
router.get('/posts/:id/likes', async (req, res) => {
  try {
    const { id: postId } = req.params;
    const limit = Math.min(parseInt(req.query.limit) || 20, 50);
    const offset = parseInt(req.query.offset) || 0;

    if (!postId || typeof postId !== 'string') {
      return res.status(400).json({
        error: 'Invalid post ID',
        message: 'Post ID is required'
      });
    }

    // Fetch likes with user profiles
    const { data: likes, error } = await supabase
      .from('likes')
      .select(`
        *,
        profiles!likes_user_id_fkey(username, profile_image_url)
      `)
      .eq('post_id', postId)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) {
      console.error('❌ Likes fetch error:', error);
      return res.status(500).json({
        error: 'Database error',
        message: 'Failed to fetch likes'
      });
    }

    // Get total likes count
    const { count: totalCount, error: countError } = await supabase
      .from('likes')
      .select('*', { count: 'exact', head: true })
      .eq('post_id', postId);

    if (countError) {
      console.error('❌ Likes count error:', countError);
    }

    res.json({
      likes: likes.map(like => ({
        id: like.id,
        user_id: like.user_id,
        username: like.profiles?.username || 'Unknown',
        profile_image_url: like.profiles?.profile_image_url,
        created_at: like.created_at
      })),
      pagination: {
        limit,
        offset,
        total_count: totalCount || 0,
        has_more: likes.length === limit
      }
    });
  } catch (error) {
    console.error('❌ Likes endpoint error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to fetch likes'
    });
  }
});

/**
 * Helper function to get current likes count
 */
async function getCurrentLikesCount(postId) {
  try {
    const { count, error } = await supabase
      .from('likes')
      .select('*', { count: 'exact', head: true })
      .eq('post_id', postId);

    if (error) {
      console.error('❌ Likes count fetch error:', error);
      return 0;
    }

    return count || 0;
  } catch (error) {
    console.error('❌ Likes count helper error:', error);
    return 0;
  }
}

export default router;