import express from 'express';
import crypto from 'crypto';
import { requireAuth } from '../middleware/auth.js';
import supabase from '../utils/auth.js';

const router = express.Router();

/**
 * Suggested users to follow
 * GET /api/follows/suggestions?limit=10
 */
router.get('/suggestions', requireAuth, async (req, res) => {
  try {
    const currentUserId = req.userId;
    const limit = Math.min(parseInt(req.query.limit) || 10, 50);

    // Get users current user follows
    const { data: following, error: followingError } = await supabase
      .from('follows')
      .select('following_id')
      .eq('follower_id', currentUserId);

    if (followingError) {
      throw followingError;
    }

    const followingIds = (following || []).map((f) => f.following_id);
    followingIds.push(currentUserId); // exclude self

    // PostgREST expects IN filters as a single string: ("a","b")
    const inFilter = `(${followingIds.map((id) => `"${id}"`).join(',')})`;

    // Fetch suggested profiles not followed
    let query = supabase
      .from('profiles')
      .select(
        'id, email, username, full_name, bio, profile_image_url, followers_count, following_count, posts_count, created_at'
      )
      .order('followers_count', { ascending: false })
      .limit(limit);

    if (followingIds.length > 0) {
      query = query.not('id', 'in', inFilter);
    }

    const { data: profiles, error: profilesError } = await query;

    if (profilesError) {
      throw profilesError;
    }

    res.json({ users: profiles || [] });
  } catch (error) {
    console.error('❌ Suggestions error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
});

/**
 * Follow a user
 * POST /api/follows/:userId
 */
router.post('/:userId', requireAuth, async (req, res) => {
  try {
    const { userId: targetUserId } = req.params;
    const currentUserId = req.userId;

    // Validate UUIDs
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(targetUserId)) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Invalid user ID format'
      });
    }

    // Cannot follow yourself
    if (targetUserId === currentUserId) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Cannot follow yourself'
      });
    }

    // Check if target user exists
    const { data: targetUser, error: userError } = await supabase
      .from('profiles')
      .select('id')
      .eq('id', targetUserId)
      .single();

    if (userError || !targetUser) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'User not found'
      });
    }

    // Check if already following
    const { data: existingFollow, error: checkError } = await supabase
      .from('follows')
      .select('*')
      .eq('follower_id', currentUserId)
      .eq('following_id', targetUserId)
      .single();

    if (checkError && checkError.code !== 'PGRST116') {
      throw checkError;
    }

    if (existingFollow) {
      return res.status(409).json({
        error: 'Conflict',
        message: 'Already following this user'
      });
    }

    // Create follow relationship with explicit ID
    const followId = crypto.randomUUID();
    const { data: follow, error: followError } = await supabase
      .from('follows')
      .insert({
        id: followId,
        follower_id: currentUserId,
        following_id: targetUserId
      })
      .select()
      .single();

    if (followError) {
      throw followError;
    }

    res.status(201).json({
      message: 'Successfully followed user',
      follow
    });

  } catch (error) {
    console.error('❌ Follow error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * Unfollow a user
 * DELETE /api/follows/:userId
 */
router.delete('/:userId', requireAuth, async (req, res) => {
  try {
    const { userId: targetUserId } = req.params;
    const currentUserId = req.userId;

    // Validate UUID
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(targetUserId)) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Invalid user ID format'
      });
    }

    // Delete follow relationship
    const { error: unfollowError } = await supabase
      .from('follows')
      .delete()
      .eq('follower_id', currentUserId)
      .eq('following_id', targetUserId);

    if (unfollowError) {
      throw unfollowError;
    }

    res.json({
      message: 'Successfully unfollowed user'
    });

  } catch (error) {
    console.error('❌ Unfollow error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * Check if current user follows a user
 * GET /api/follows/:userId/status
 */
router.get('/:userId/status', requireAuth, async (req, res) => {
  try {
    const { userId: targetUserId } = req.params;
    const currentUserId = req.userId;

    // Validate UUID
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(targetUserId)) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Invalid user ID format'
      });
    }

    const { data: follow, error } = await supabase
      .from('follows')
      .select('*')
      .eq('follower_id', currentUserId)
      .eq('following_id', targetUserId)
      .single();

    if (error && error.code !== 'PGRST116') {
      throw error;
    }

    res.json({
      is_following: !!follow
    });

  } catch (error) {
    console.error('❌ Follow status error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * Get user's followers
 * GET /api/follows/:userId/followers
 */
router.get('/:userId/followers', async (req, res) => {
  try {
    const { userId } = req.params;
    const { limit = 20, offset = 0 } = req.query;

    // Validate UUID
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(userId)) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Invalid user ID format'
      });
    }

    const { data: followers, error } = await supabase
      .from('follows')
      .select(`
        follower_id,
        profiles!follows_follower_id_fkey (
          id,
          username,
          full_name,
          profile_image_url
        )
      `)
      .eq('following_id', userId)
      .range(parseInt(offset), parseInt(offset) + parseInt(limit) - 1)
      .order('created_at', { ascending: false });

    if (error) {
      throw error;
    }

    res.json({
      followers: followers.map(f => f.profiles)
    });

  } catch (error) {
    console.error('❌ Get followers error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * Get user's following
 * GET /api/follows/:userId/following
 */
router.get('/:userId/following', async (req, res) => {
  try {
    const { userId } = req.params;
    const { limit = 20, offset = 0 } = req.query;

    // Validate UUID
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(userId)) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Invalid user ID format'
      });
    }

    const { data: following, error } = await supabase
      .from('follows')
      .select(`
        following_id,
        profiles!follows_following_id_fkey (
          id,
          username,
          full_name,
          profile_image_url
        )
      `)
      .eq('follower_id', userId)
      .range(parseInt(offset), parseInt(offset) + parseInt(limit) - 1)
      .order('created_at', { ascending: false });

    if (error) {
      throw error;
    }

    res.json({
      following: following.map(f => f.profiles)
    });

  } catch (error) {
    console.error('❌ Get following error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

export default router;