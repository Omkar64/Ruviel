import express from 'express';
import { requireAuth } from '../middleware/auth.js';
import supabase from '../utils/auth.js';

const router = express.Router();

/**
 * POST /api/posts/:id/comment
 * Add a comment to a post
 * Requires authentication
 */
router.post('/posts/:id/comment', requireAuth, async (req, res) => {
  try {
    const userId = req.userId;
    const { id: postId } = req.params;
    const { comment } = req.body;

    // Validate inputs
    if (!comment || typeof comment !== 'string' || comment.trim().length === 0) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Comment text is required and cannot be empty'
      });
    }

    if (comment.length > 1000) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Comment cannot exceed 1000 characters'
      });
    }

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

    // Get user profile for username
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('username')
      .eq('id', userId)
      .single();

    if (profileError || !profile) {
      return res.status(404).json({
        error: 'Profile not found',
        message: 'User profile does not exist'
      });
    }

    // Generate comment ID
    const commentId = Date.now().toString() + '_' + Math.random().toString(36).substring(2, 11);

    // Create comment
    const { data: newComment, error } = await supabase
      .from('comments')
      .insert({
        id: commentId,
        post_id: postId,
        user_id: userId,
        username: profile.username,
        comment: comment.trim(),
        created_at: new Date().toISOString()
      })
      .select(`
        *,
        profiles!comments_user_id_fkey(username, profile_image_url)
      `)
      .single();

    if (error) {
      console.error('❌ Comment creation error:', error);
      return res.status(500).json({
        error: 'Database error',
        message: 'Failed to create comment'
      });
    }

    // Increment comments count
    const { error: countError } = await supabase
      .rpc('increment_comments_count', { post_id: postId });

    if (countError) {
      console.error('❌ Comments count increment error:', countError);
    }

    res.status(201).json({
      message: 'Comment added successfully',
      comment: {
        id: newComment.id,
        post_id: newComment.post_id,
        user_id: newComment.user_id,
        username: newComment.username,
        profile_image_url: newComment.profiles?.profile_image_url,
        comment: newComment.comment,
        created_at: newComment.created_at
      }
    });
  } catch (error) {
    console.error('❌ Comment creation endpoint error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to create comment'
    });
  }
});

/**
 * GET /api/posts/:id/comments
 * Get comments for a post (paginated)
 * Optional authentication
 */
router.get('/posts/:id/comments', async (req, res) => {
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

    // Fetch comments with user profiles
    const { data: comments, error } = await supabase
      .from('comments')
      .select(`
        *,
        profiles!comments_user_id_fkey(username, profile_image_url)
      `)
      .eq('post_id', postId)
      .order('created_at', { ascending: true })
      .range(offset, offset + limit - 1);

    if (error) {
      console.error('❌ Comments fetch error:', error);
      return res.status(500).json({
        error: 'Database error',
        message: 'Failed to fetch comments'
      });
    }

    // Get total comments count
    const { count: totalCount, error: countError } = await supabase
      .from('comments')
      .select('*', { count: 'exact', head: true })
      .eq('post_id', postId);

    if (countError) {
      console.error('❌ Comments count error:', countError);
    }

    res.json({
      comments: comments.map(comment => ({
        id: comment.id,
        post_id: comment.post_id,
        user_id: comment.user_id,
        username: comment.username,
        profile_image_url: comment.profiles?.profile_image_url,
        comment: comment.comment,
        created_at: comment.created_at
      })),
      pagination: {
        limit,
        offset,
        total_count: totalCount || 0,
        has_more: comments.length === limit
      }
    });
  } catch (error) {
    console.error('❌ Comments endpoint error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to fetch comments'
    });
  }
});

/**
 * DELETE /api/comments/:id
 * Delete a comment (only by owner)
 * Requires authentication
 */
router.delete('/:id', requireAuth, async (req, res) => {
  try {
    const userId = req.userId;
    const { id: commentId } = req.params;

    if (!commentId || typeof commentId !== 'string') {
      return res.status(400).json({
        error: 'Invalid comment ID',
        message: 'Comment ID is required'
      });
    }

    // First verify ownership and get post_id
    const { data: comment, error: fetchError } = await supabase
      .from('comments')
      .select('user_id, post_id')
      .eq('id', commentId)
      .single();

    if (fetchError || !comment) {
      return res.status(404).json({
        error: 'Comment not found',
        message: 'Comment does not exist'
      });
    }

    if (comment.user_id !== userId) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'You can only delete your own comments'
      });
    }

    // Delete comment
    const { error } = await supabase
      .from('comments')
      .delete()
      .eq('id', commentId);

    if (error) {
      console.error('❌ Comment deletion error:', error);
      return res.status(500).json({
        error: 'Database error',
        message: 'Failed to delete comment'
      });
    }

    // Decrement comments count
    const { error: countError } = await supabase
      .rpc('decrement_comments_count', { post_id: comment.post_id });

    if (countError) {
      console.error('❌ Comments count decrement error:', countError);
    }

    res.json({
      message: 'Comment deleted successfully'
    });
  } catch (error) {
    console.error('❌ Comment deletion endpoint error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to delete comment'
    });
  }
});

export default router;