import express from 'express';
import crypto from 'crypto';
import { requireAuth, optionalJWT } from '../middleware/auth.js';
import supabase from '../utils/auth.js';

const router = express.Router();

async function fetchLikeActivities(currentUserId, { limit, postType }) {
  const { data, error } = await supabase
    .from('likes')
    .select(`
      id,
      user_id,
      post_id,
      created_at,
      posts!likes_post_id_fkey(user_id, image_url, post_type),
      profiles!likes_user_id_fkey(username, profile_image_url)
    `)
    .eq('posts.user_id', currentUserId)
    .eq('posts.post_type', postType)
    .neq('user_id', currentUserId)
    .order('created_at', { ascending: false })
    .limit(limit);

  if (error) throw error;

  return (data || []).map((row) => ({
    id: row.id,
    user_id: row.user_id,
    type: 'like',
    post_id: row.post_id,
    comment_text: null,
    created_at: row.created_at,
    profiles: row.profiles,
    posts: row.posts,
  }));
}

async function fetchCommentActivities(currentUserId, { limit, postType }) {
  const { data, error } = await supabase
    .from('comments')
    .select(`
      id,
      user_id,
      post_id,
      comment,
      created_at,
      posts!comments_post_id_fkey(user_id, image_url, post_type),
      profiles!comments_user_id_fkey(username, profile_image_url)
    `)
    .eq('posts.user_id', currentUserId)
    .eq('posts.post_type', postType)
    .neq('user_id', currentUserId)
    .order('created_at', { ascending: false })
    .limit(limit);

  if (error) throw error;

  return (data || []).map((row) => ({
    id: row.id,
    user_id: row.user_id,
    type: 'comment',
    post_id: row.post_id,
    comment_text: row.comment,
    created_at: row.created_at,
    profiles: row.profiles,
    posts: row.posts,
  }));
}

async function fetchFollowActivities(currentUserId, { limit }) {
  const { data, error } = await supabase
    .from('follows')
    .select(`
      id,
      follower_id,
      following_id,
      created_at,
      profiles!follows_follower_id_fkey(username, profile_image_url)
    `)
    .eq('following_id', currentUserId)
    .neq('follower_id', currentUserId)
    .order('created_at', { ascending: false })
    .limit(limit);

  if (error) throw error;

  return (data || []).map((row) => ({
    id: row.id,
    user_id: row.follower_id,
    type: 'follow',
    post_id: null,
    comment_text: null,
    created_at: row.created_at,
    profiles: row.profiles,
    posts: null,
  }));
}

/**
 * GET /api/activities/feed
 * Build activity feed for current user from likes/comments/follows.
 * Query: limit, post_type (instagram|twitter), includeFollows (true|false)
 */
router.get('/feed', requireAuth, async (req, res) => {
  try {
    const currentUserId = req.userId;
    const limit = Math.min(parseInt(req.query.limit) || 50, 100);
    const postType = req.query.post_type === 'twitter' ? 'twitter' : 'instagram';
    const includeFollows = String(req.query.includeFollows ?? 'true') !== 'false';

    const futures = [
      fetchLikeActivities(currentUserId, { limit, postType }),
      fetchCommentActivities(currentUserId, { limit, postType }),
      includeFollows ? fetchFollowActivities(currentUserId, { limit }) : Promise.resolve([]),
    ];

    const [likes, comments, follows] = await Promise.all(futures);
    const all = [...likes, ...comments, ...follows];

    all.sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());

    res.json({
      activities: all.slice(0, limit),
    });
  } catch (error) {
    console.error('❌ Get activity feed error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
});

/**
 * Get activities for current user
 * GET /api/activities
 */
router.get('/', requireAuth, async (req, res) => {
  try {
    const currentUserId = req.userId;
    const { limit = 50 } = req.query;

    // Fetch activities where user is either target or actor
    const { data: activities, error } = await supabase
      .from('activities')
      .select(`
        *,
        profiles!activities_user_id_fkey(username, profile_image_url),
        posts(image_url)
      `)
      .eq('target_user_id', currentUserId)
      .order('created_at', { ascending: false })
      .limit(parseInt(limit));


    if (error) {
      throw error;
    }

    res.json({
      activities: activities || []
    });

  } catch (error) {
    console.error('❌ Get activities error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * Create a new activity
 * POST /api/activities
 */
router.post('/', requireAuth, async (req, res) => {
  try {
    const currentUserId = req.userId;
    const { type, targetUserId, postId, commentText } = req.body;

    // Validate activity type
    const validTypes = ['like', 'comment', 'follow', 'mention'];
    if (!validTypes.includes(type)) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Invalid activity type'
      });
    }

    // Generate activity ID
    const activityId = crypto.randomUUID();

    const { data: activity, error } = await supabase
      .from('activities')
      .insert({
        id: activityId,
        user_id: currentUserId,
        target_user_id: targetUserId,
        type,
        post_id: postId,
        comment_text: commentText
      })
      .select()
      .single();

    if (error) {
      throw error;
    }

    res.status(201).json({
      message: 'Activity created successfully',
      activity
    });

  } catch (error) {
    console.error('❌ Create activity error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * Delete an activity
 * DELETE /api/activities/:id
 */
router.delete('/:id', requireAuth, async (req, res) => {
  try {
    const { id } = req.params;
    const currentUserId = req.userId;

    const { error } = await supabase
      .from('activities')
      .delete()
      .eq('id', id)
      .eq('user_id', currentUserId); // Only allow users to delete their own activities

    if (error) {
      throw error;
    }

    res.json({
      message: 'Activity deleted successfully'
    });

  } catch (error) {
    console.error('❌ Delete activity error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

export default router;