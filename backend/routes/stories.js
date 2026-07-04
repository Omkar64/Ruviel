import express from 'express';
import crypto from 'crypto';
import { requireAuth } from '../middleware/auth.js';
import supabase from '../utils/auth.js';

const router = express.Router();

const storyExpiryMs = 24 * 60 * 60 * 1000;
const storiesBucket = 'stories';

const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function buildPublicUrl(storagePath) {
  return `${process.env.SUPABASE_URL}/storage/v1/object/public/${storiesBucket}/${storagePath}`;
}

function decodeBase64(data) {
  // Supports both raw base64 and data URLs: data:video/mp4;base64,XXXX
  const parts = data.split(',');
  const base64 = parts.length > 1 ? parts[1] : parts[0];
  return Buffer.from(base64, 'base64');
}

/**
 * POST /api/stories
 * Create a story (image or video)
 * Body: { mediaType: 'image'|'video', mediaBase64: string, caption?: string }
 */
router.post('/', requireAuth, async (req, res) => {
  try {
    const userId = req.userId;
    const { mediaType, mediaBase64 } = req.body;

    if (!mediaType || !['image', 'video'].includes(mediaType)) {
      return res.status(400).json({
        error: 'Bad Request',
        message: "mediaType must be 'image' or 'video'"
      });
    }

    if (!mediaBase64 || typeof mediaBase64 !== 'string') {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'mediaBase64 is required'
      });
    }

    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('id, username')
      .eq('id', userId)
      .single();

    if (profileError || !profile) {
      return res.status(404).json({
        error: 'Profile not found',
        message: 'User profile does not exist'
      });
    }

    const bytes = decodeBase64(mediaBase64);
    if (!bytes || bytes.length === 0) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Invalid mediaBase64'
      });
    }

    const ext = mediaType === 'video' ? 'mp4' : 'jpg';
    const contentType = mediaType === 'video' ? 'video/mp4' : 'image/jpeg';
    const fileName = `story_${Date.now()}_${userId}.${ext}`;
    const storagePath = `${userId}/${fileName}`;

    const { error: uploadError } = await supabase.storage
      .from(storiesBucket)
      .upload(storagePath, bytes, {
        upsert: true,
        contentType
      });

    if (uploadError) {
      console.error('❌ Story upload error:', uploadError);
      return res.status(500).json({
        error: 'Storage error',
        message: 'Failed to upload story media'
      });
    }

    const publicUrl = buildPublicUrl(storagePath);
    const storyId = crypto.randomUUID();
    const createdAt = new Date();
    const expiresAt = new Date(createdAt.getTime() + storyExpiryMs);

    const insert = {
      id: storyId,
      user_id: userId,
      username: profile.username,
      image_url: mediaType === 'image' ? publicUrl : null,
      video_url: mediaType === 'video' ? publicUrl : null,
      created_at: createdAt.toISOString(),
      expires_at: expiresAt.toISOString()
    };

    const { data: story, error: insertError } = await supabase
      .from('stories')
      .insert(insert)
      .select(`
        *,
        profiles!stories_user_id_fkey(username, profile_image_url)
      `)
      .single();

    if (insertError) {
      console.error('❌ Story insert error:', insertError);
      return res.status(500).json({
        error: 'Database error',
        message: 'Failed to create story'
      });
    }

    return res.status(201).json({ story });
  } catch (error) {
    console.error('❌ Create story endpoint error:', error);
    return res.status(500).json({
      error: 'Internal server error',
      message: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * GET /api/stories/following
 * Get active stories for current user and people they follow.
 */
router.get('/following', requireAuth, async (req, res) => {
  try {
    const userId = req.userId;

    const { data: following, error: followingError } = await supabase
      .from('follows')
      .select('following_id')
      .eq('follower_id', userId);

    if (followingError) {
      console.error('❌ Following fetch error:', followingError);
      return res.status(500).json({
        error: 'Database error',
        message: 'Failed to fetch following'
      });
    }

    const followingIds = (following || []).map((f) => f.following_id);
    if (!followingIds.includes(userId)) {
      followingIds.push(userId);
    }

    const now = new Date().toISOString();

    let query = supabase
      .from('stories')
      .select(`
        *,
        profiles!stories_user_id_fkey(username, profile_image_url)
      `)
      .gte('expires_at', now)
      .order('created_at', { ascending: false });

    if (followingIds.length > 0) {
      query = query.in('user_id', followingIds);
    }

    const { data: stories, error: storiesError } = await query;

    if (storiesError) {
      console.error('❌ Stories fetch error:', storiesError);
      return res.status(500).json({
        error: 'Database error',
        message: 'Failed to fetch stories'
      });
    }

    const grouped = {};
    for (const s of stories || []) {
      const uid = s.user_id;
      if (!grouped[uid]) grouped[uid] = [];
      grouped[uid].push(s);
    }

    return res.json({ stories_by_user: grouped });
  } catch (error) {
    console.error('❌ Following stories endpoint error:', error);
    return res.status(500).json({
      error: 'Internal server error',
      message: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * GET /api/stories/user/:id
 * Get active stories for a given user (public).
 */
router.get('/user/:id', async (req, res) => {
  try {
    const { id } = req.params;

    if (!uuidRegex.test(id)) {
      return res.status(400).json({
        error: 'Invalid user ID',
        message: 'User ID must be a valid UUID'
      });
    }

    const now = new Date().toISOString();

    const { data: stories, error } = await supabase
      .from('stories')
      .select(`
        *,
        profiles!stories_user_id_fkey(username, profile_image_url)
      `)
      .eq('user_id', id)
      .gte('expires_at', now)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('❌ User stories fetch error:', error);
      return res.status(500).json({
        error: 'Database error',
        message: 'Failed to fetch user stories'
      });
    }

    return res.json({ stories: stories || [] });
  } catch (error) {
    console.error('❌ User stories endpoint error:', error);
    return res.status(500).json({
      error: 'Internal server error',
      message: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * DELETE /api/stories/:id
 * Delete a specific story
 */
router.delete('/:id', requireAuth, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.userId;

    if (!uuidRegex.test(id)) {
      return res.status(400).json({
        error: 'Invalid story ID',
        message: 'Story ID must be a valid UUID'
      });
    }

    // First, get the story to check ownership
    const { data: story, error: fetchError } = await supabase
      .from('stories')
      .select('*')
      .eq('id', id)
      .single();

    if (fetchError || !story) {
      return res.status(404).json({
        error: 'Story not found',
        message: 'Story does not exist'
      });
    }

    // Check if user owns this story
    if (story.user_id !== userId) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'You can only delete your own stories'
      });
    }

    // Delete the story
    const { error: deleteError } = await supabase
      .from('stories')
      .delete()
      .eq('id', id);

    if (deleteError) {
      console.error('❌ Story delete error:', deleteError);
      return res.status(500).json({
        error: 'Database error',
        message: 'Failed to delete story'
      });
    }

    console.log('✅ Story deleted successfully:', id);
    return res.status(200).json({
      success: true,
      message: 'Story deleted successfully'
    });

  } catch (error) {
    console.error('❌ Delete story endpoint error:', error);
    return res.status(500).json({
      error: 'Internal server error',
      message: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

export default router;
