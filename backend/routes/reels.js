import express from 'express';
import crypto from 'crypto';
import { requireAuth, optionalJWT } from '../middleware/auth.js';
import supabase from '../utils/auth.js';

const router = express.Router();

const reelsBucket = 'reels';

function buildPublicUrl(storagePath) {
  return `${process.env.SUPABASE_URL}/storage/v1/object/public/${reelsBucket}/${storagePath}`;
}

function decodeBase64(data) {
  // Supports both raw base64 and data URLs: data:video/mp4;base64,XXXX
  const parts = data.split(',');
  const base64 = parts.length > 1 ? parts[1] : parts[0];
  return Buffer.from(base64, 'base64');
}

/**
 * GET /api/reels
 * Fetch reels feed (paginated)
 * Supports optional authentication for personalized data
 * Query params: limit, offset
 */
router.get('/', optionalJWT, async (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit) || 20, 50); // Max 50 reels
    const offset = parseInt(req.query.offset) || 0;
    const userId = req.userId;

    // Build query
    let query = supabase
      .from('reels')
      .select(`
        *,
        profiles!reels_user_id_fkey(username, profile_image_url),
        reel_likes(user_id),
        reel_comments(id)
      `);

    // Execute query with pagination
    const { data: reels, error } = await query
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) {
      console.error('❌ Reels fetch error:', error);
      return res.status(500).json({
        error: 'Database error',
        message: 'Failed to fetch reels'
      });
    }

    // Process reels to add like status and counts
    const processedReels = reels.map(reel => {
      const likesList = reel.reel_likes || [];
      const commentsList = reel.reel_comments || [];

      const likesCount = reel.likes_count ?? likesList.length;
      const commentsCount = reel.comments_count ?? commentsList.length;

      const isLiked = userId && likesList.some(
        like => like.user_id === userId
      );

      return {
        id: reel.id,
        user_id: reel.user_id,
        username: reel.username || reel.profiles?.username || 'Unknown',
        profile_image_url: reel.profiles?.profile_image_url,
        video_url: reel.video_url,
        caption: reel.caption,
        music: reel.music,
        likes_count: likesCount,
        comments_count: commentsCount,
        is_liked: isLiked,
        created_at: reel.created_at
      };
    });

    res.json({
      reels: processedReels,
      pagination: {
        limit,
        offset,
        has_more: processedReels.length === limit
      }
    });
  } catch (error) {
    console.error('❌ Reels endpoint error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to fetch reels'
    });
  }
});

/**
 * POST /api/reels
 * Create a new reel
 * Requires authentication
 */
router.post('/', requireAuth, async (req, res) => {
  try {
    const userId = req.userId;
    const {
      caption,
      music,
      video_url,
      videoBase64,
    } = req.body;

    // Validate required fields
    if (!video_url && !videoBase64) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Reel must have video URL or base64 video data'
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

    let finalVideoUrl = video_url || null;

    // Upload video if base64 provided
    if (typeof videoBase64 === 'string' && videoBase64.trim().length > 0) {
      const bytes = decodeBase64(videoBase64.trim());
      const fileName = `reel_${Date.now()}_${userId}.mp4`;
      const storagePath = `${userId}/${fileName}`;

      const { error: uploadError } = await supabase.storage
        .from(reelsBucket)
        .upload(storagePath, bytes, {
          upsert: true,
          contentType: 'video/mp4'
        });

      if (uploadError) {
        console.error('❌ Reel video upload error:', uploadError);
        return res.status(500).json({
          error: 'Storage error',
          message: 'Failed to upload reel video'
        });
      }

      finalVideoUrl = buildPublicUrl(storagePath);
    }

    // Create reel record
    const { data: reel, error: reelError } = await supabase
      .from('reels')
      .insert({
        id: crypto.randomUUID(), // ✅ REQUIRED FIX
        user_id: userId,
        username: profile.username,
        video_url: finalVideoUrl,
        caption: caption || null,
        music: music || null,
        likes_count: 0,
        comments_count: 0
      })
      .select()
      .single();


    if (reelError) {
      console.error('❌ Reel creation error:', reelError);
      return res.status(500).json({
        error: 'Database error',
        message: 'Failed to create reel'
      });
    }

    // Get full reel data with profile
    const { data: fullReel, error: fetchError } = await supabase
      .from('reels')
      .select(`
        *,
        profiles!reels_user_id_fkey(username, profile_image_url)
      `)
      .eq('id', reel.id)
      .single();

    if (fetchError) {
      console.error('❌ Reel fetch after creation error:', fetchError);
    }

    const responseData = fullReel || reel;

    res.status(201).json({
      message: 'Reel created successfully',
      reel: {
        id: responseData.id,
        user_id: responseData.user_id,
        username: responseData.username || responseData.profiles?.username || 'Unknown',
        profile_image_url: responseData.profile_image_url || responseData.profiles?.profile_image_url,
        video_url: responseData.video_url,
        caption: responseData.caption,
        music: responseData.music,
        likes_count: responseData.likes_count || 0,
        comments_count: responseData.comments_count || 0,
        is_liked: false,
        created_at: responseData.created_at,
        updated_at: responseData.updated_at
      }
    });
  } catch (error) {
    console.error('❌ Reel creation endpoint error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to create reel'
    });
  }
});

/**
 * DELETE /api/reels/:id
 * Delete a reel
 * Requires authentication and ownership
 */
router.delete('/:id', requireAuth, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.userId;

    // Validate UUID format
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(id)) {
      return res.status(400).json({
        error: 'Invalid reel ID',
        message: 'Reel ID must be a valid UUID'
      });
    }

    // Check if reel exists and user owns it
    const { data: reel, error: fetchError } = await supabase
      .from('reels')
      .select('user_id')
      .eq('id', id)
      .single();

    if (fetchError) {
      return res.status(404).json({
        error: 'Reel not found',
        message: 'Reel does not exist'
      });
    }

    if (reel.user_id !== userId) {
      return res.status(403).json({
        error: 'Access denied',
        message: 'You can only delete your own reels'
      });
    }

    // Delete reel (cascade will handle likes and comments)
    const { error: deleteError } = await supabase
      .from('reels')
      .delete()
      .eq('id', id);

    if (deleteError) {
      console.error('❌ Reel deletion error:', deleteError);
      return res.status(500).json({
        error: 'Database error',
        message: 'Failed to delete reel'
      });
    }

    res.json({
      message: 'Reel deleted successfully'
    });
  } catch (error) {
    console.error('❌ Reel deletion endpoint error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to delete reel'
    });
  }
});

/**
 * GET /api/reels/user/:id
 * Fetch reels for a specific user
 * Supports optional authentication for personalized data
 * Query params: limit, offset
 */
router.get('/user/:id', optionalJWT, async (req, res) => {
  try {
    const { id } = req.params;
    const limit = Math.min(parseInt(req.query.limit) || 20, 50); // Max 50 reels
    const offset = parseInt(req.query.offset) || 0;
    const userId = req.userId;

    // Validate UUID format
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(id)) {
      return res.status(400).json({
        error: 'Invalid user ID',
        message: 'User ID must be a valid UUID'
      });
    }

    // Build query for user-specific reels
    let query = supabase
      .from('reels')
      .select(`
        *,
        profiles!reels_user_id_fkey(username, profile_image_url),
        reel_likes(user_id),
        reel_comments(id)
      `)
      .eq('user_id', id);

    // Execute query with pagination
    const { data: reels, error } = await query
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) {
      console.error('❌ User reels fetch error:', error);
      return res.status(500).json({
        error: 'Database error',
        message: 'Failed to fetch user reels'
      });
    }

    // Process reels to add like status and counts
    const processedReels = reels.map(reel => {
      const likesList = reel.reel_likes || [];
      const commentsList = reel.reel_comments || [];

      const likesCount = reel.likes_count ?? likesList.length;
      const commentsCount = reel.comments_count ?? commentsList.length;

      const isLiked = userId && likesList.some(
        like => like.user_id === userId
      );

      return {
        id: reel.id,
        user_id: reel.user_id,
        username: reel.username || reel.profiles?.username || 'Unknown',
        profile_image_url: reel.profiles?.profile_image_url,
        video_url: reel.video_url,
        caption: reel.caption,
        music: reel.music,
        likes_count: likesCount,
        comments_count: commentsCount,
        is_liked: isLiked,
        created_at: reel.created_at
      };
    });

    res.json({
      reels: processedReels,
      pagination: {
        limit,
        offset,
        has_more: processedReels.length === limit
      }
    });
  } catch (error) {
    console.error('❌ User reels endpoint error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to fetch user reels'
    });
  }
});

/**
 * GET /api/reels/:id/like-status
 * Check if current user liked a specific reel
 * Requires authentication
 */
router.get('/:id/like-status', requireAuth, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.userId;

    // Validate UUID format
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(id)) {
      return res.status(400).json({
        error: 'Invalid reel ID',
        message: 'Reel ID must be a valid UUID'
      });
    }

    // Check if reel exists
    const { data: reel, error: reelError } = await supabase
      .from('reels')
      .select('id')
      .eq('id', id)
      .single();

    if (reelError) {
      return res.status(404).json({
        error: 'Reel not found',
        message: 'Reel does not exist'
      });
    }

    // Check if user liked this reel
    const { data: like, error: likeError } = await supabase
      .from('reel_likes')
      .select('id')
      .eq('reel_id', id)
      .eq('user_id', userId)
      .maybeSingle();

    if (likeError) {
      console.error('❌ Like status check error:', likeError);
      return res.status(500).json({
        error: 'Database error',
        message: 'Failed to check like status'
      });
    }

    res.json({
      is_liked: like !== null,
      reel_id: id
    });
  } catch (error) {
    console.error('❌ Like status endpoint error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to check like status'
    });
  }
});

/**
 * POST /api/reels/:id/like
 * Like a reel
 * Requires authentication
 */
router.post('/:id/like', requireAuth, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.userId;

    // Validate UUID format
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(id)) {
      return res.status(400).json({
        error: 'Invalid reel ID',
        message: 'Reel ID must be a valid UUID'
      });
    }

    // Check if reel exists
    const { data: reel, error: reelError } = await supabase
      .from('reels')
      .select('id, user_id')
      .eq('id', id)
      .single();

    if (reelError) {
      return res.status(404).json({
        error: 'Reel not found',
        message: 'Reel does not exist'
      });
    }

    // Prevent liking own reel
    if (reel.user_id === userId) {
      return res.status(400).json({
        error: 'Bad request',
        message: 'You cannot like your own reel'
      });
    }

    // Check if already liked
    const { data: existingLike, error: checkError } = await supabase
      .from('reel_likes')
      .select('id')
      .eq('reel_id', id)
      .eq('user_id', userId)
      .maybeSingle();

    if (checkError) {
      console.error('❌ Like check error:', checkError);
      return res.status(500).json({
        error: 'Database error',
        message: 'Failed to check like status'
      });
    }

    if (existingLike) {
      return res.status(400).json({
        error: 'Already liked',
        message: 'You have already liked this reel'
      });
    }

    // Create like
    const { error: likeError } = await supabase
      .from('reel_likes')
      .insert({
        reel_id: id,
        user_id: userId
      });

    if (likeError) {
      console.error('❌ Like creation error:', likeError);
      return res.status(500).json({
        error: 'Database error',
        message: 'Failed to like reel'
      });
    }

    // Increment likes count
    const { error: incrementError } = await supabase.rpc('increment_reel_likes_count', {
      reel_id: id
    });

    if (incrementError) {
      console.error('❌ Increment likes count error:', incrementError);
      // Non-critical error, continue
    }

    res.json({
      message: 'Reel liked successfully',
      is_liked: true
    });
  } catch (error) {
    console.error('❌ Like reel endpoint error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to like reel'
    });
  }
});

/**
 * DELETE /api/reels/:id/like
 * Unlike a reel
 * Requires authentication
 */
router.delete('/:id/like', requireAuth, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.userId;

    // Validate UUID format
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(id)) {
      return res.status(400).json({
        error: 'Invalid reel ID',
        message: 'Reel ID must be a valid UUID'
      });
    }

    // Remove like
    const { error: unlikeError } = await supabase
      .from('reel_likes')
      .delete()
      .eq('reel_id', id)
      .eq('user_id', userId);

    if (unlikeError) {
      console.error('❌ Unlike error:', unlikeError);
      return res.status(500).json({
        error: 'Database error',
        message: 'Failed to unlike reel'
      });
    }

    // Decrement likes count
    const { error: decrementError } = await supabase.rpc('decrement_reel_likes_count', {
      reel_id: id
    });

    if (decrementError) {
      console.error('❌ Decrement likes count error:', decrementError);
      // Non-critical error, continue
    }

    res.json({
      message: 'Reel unliked successfully',
      is_liked: false
    });
  } catch (error) {
    console.error('❌ Unlike reel endpoint error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to unlike reel'
    });
  }
});

/**
 * GET /api/reels/:id/comments
 */
router.get('/:id/comments', requireAuth, async (req, res) => {
  const { id } = req.params;

  const { data, error } = await supabase
    .from('reel_comments')
    .select(`
      id,
      comment,
      created_at,
      profiles(username, profile_image_url)
    `)
    .eq('reel_id', id)
    .order('created_at', { ascending: true });

  if (error) {
    console.error('❌ Fetch reel comments error:', error);
    return res.status(500).json({ error: 'Failed to fetch comments' });
  }

  res.json({ comments: data });
});

/**
 * POST /api/reels/:id/comments
 */
router.post('/:id/comments', requireAuth, async (req, res) => {
  const { id } = req.params;
  const userId = req.userId;
  const { comment } = req.body;

  if (!comment || comment.trim().length === 0) {
    return res.status(400).json({ error: 'Comment cannot be empty' });
  }

  // Get username
  const { data: profile } = await supabase
    .from('profiles')
    .select('username')
    .eq('id', userId)
    .single();

  const { data, error } = await supabase
    .from('reel_comments')
    .insert({
      reel_id: id,
      user_id: userId,
      username: profile.username,
      comment: comment.trim()
    })
    .select()
    .single();

  if (error) {
    console.error('❌ Create reel comment error:', error);
    return res.status(500).json({ error: 'Failed to add comment' });
  }

  // increment comment count
  await supabase.rpc('increment_reel_comments_count', { reel_id: id });

  res.status(201).json({ comment: data });
});

export default router;