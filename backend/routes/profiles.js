import express from 'express';
import { requireAuth } from '../middleware/auth.js';
import supabase from '../utils/auth.js';

const router = express.Router();

const profilesBucket = 'profiles';

function buildPublicUrl(storagePath) {
  return `${process.env.SUPABASE_URL}/storage/v1/object/public/${profilesBucket}/${storagePath}`;
}

function decodeBase64(data) {
  try {
    // Supports both raw base64 and data URLs: data:image/jpeg;base64,XXXX
    const parts = data.split(',');
    const base64 = parts.length > 1 ? parts[1] : parts[0];
    return Buffer.from(base64, 'base64');
  } catch (error) {
    console.error('❌ Base64 decode error:', error);
    throw new Error('Invalid base64 data format');
  }
}

/**
 * GET /api/profiles/me
 * Get current user profile with authentication
 * Requires valid Supabase JWT token
 */
router.get('/me', requireAuth, async (req, res) => {
  try {
    const userId = req.userId;

    // Fetch user profile from Supabase
    const { data: profile, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single();

    if (error) {
      console.error('❌ Profile fetch error:', error);
      return res.status(404).json({
        error: 'Profile not found',
        message: 'User profile does not exist'
      });
    }

    // Return user data (excluding sensitive fields)
    res.json({
      user: {
        id: req.user.id,
        email: req.user.email,
        email_verified: req.user.email_confirmed_at != null,
        created_at: req.user.created_at,
        updated_at: req.user.updated_at
      },
      profile: {
        id: profile.id,
        username: profile.username,
        full_name: profile.full_name,
        bio: profile.bio,
        profile_image_url: profile.profile_image_url,
        followers_count: profile.followers_count || 0,
        following_count: profile.following_count || 0,
        posts_count: profile.posts_count || 0,
        created_at: profile.created_at,
        updated_at: profile.updated_at
      }
    });
  } catch (error) {
    console.error('❌ Profile me endpoint error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to fetch user profile'
    });
  }
});

/**
 * PUT /api/profiles/me
 * Update current user profile
 * Requires authentication
 */
router.put('/me', requireAuth, async (req, res) => {
  try {
    const userId = req.userId;
    const {
      username,
      full_name,
      bio,
    } = req.body;

    // Build updates object
    const updates = {};
    if (username !== undefined) updates.username = username;
    if (full_name !== undefined) updates.full_name = full_name;
    if (bio !== undefined) updates.bio = bio;
    updates.updated_at = new Date().toISOString();

    // Update profile
    const { data: profile, error } = await supabase
      .from('profiles')
      .update(updates)
      .eq('id', userId)
      .select()
      .single();

    if (error) {
      console.error('❌ Profile update error:', error);
      return res.status(500).json({
        error: 'Database error',
        message: 'Failed to update profile'
      });
    }

    res.json({
      message: 'Profile updated successfully',
      profile: {
        id: profile.id,
        username: profile.username,
        full_name: profile.full_name,
        bio: profile.bio,
        profile_image_url: profile.profile_image_url,
        followers_count: profile.followers_count || 0,
        following_count: profile.following_count || 0,
        posts_count: profile.posts_count || 0,
        created_at: profile.created_at,
        updated_at: profile.updated_at
      }
    });
  } catch (error) {
    console.error('❌ Profile update endpoint error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to update profile'
    });
  }
});

/**
 * POST /api/profiles/me/image
 * Upload profile image
 * Requires authentication
 */
router.post('/me/image', requireAuth, async (req, res) => {
  try {
    const userId = req.userId;
    const { imageBase64 } = req.body;

    // Validate input
    if (!imageBase64 || typeof imageBase64 !== 'string') {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Image data is required (imageBase64)'
      });
    }

    console.log('📸 Starting profile image upload for user:', userId);
    
    // Decode and upload image
    let bytes;
    try {
      bytes = decodeBase64(imageBase64.trim());
      console.log('✅ Base64 decoded successfully, size:', bytes.length, 'bytes');
    } catch (decodeError) {
      console.error('❌ Base64 decode error:', decodeError);
      return res.status(400).json({
        error: 'Validation error',
        message: 'Invalid base64 image data'
      });
    }
    
    const fileName = `avatar_${Date.now()}_${userId}.jpg`;
    const storagePath = `${userId}/${fileName}`;
    console.log('📁 Storage path:', storagePath);

    // Upload to Supabase Storage
    const { error: uploadError } = await supabase.storage
      .from(profilesBucket)
      .upload(storagePath, bytes, {
        upsert: true,
        contentType: 'image/jpeg'
      });

    if (uploadError) {
      console.error('❌ Profile image upload error:', uploadError);
      return res.status(500).json({
        error: 'Storage error',
        message: 'Failed to upload profile image to storage',
        details: uploadError.message
      });
    }
    
    console.log('✅ Image uploaded successfully');

    // Get public URL
    const publicUrl = buildPublicUrl(storagePath);
    console.log('🔗 Public URL generated:', publicUrl);

    // Update profile with new image URL
    const { data: profile, error: updateError } = await supabase
      .from('profiles')
      .update({
        profile_image_url: publicUrl,
        updated_at: new Date().toISOString()
      })
      .eq('id', userId)
      .select()
      .single();

    if (updateError) {
      console.error('❌ Profile image URL update error:', updateError);
      return res.status(500).json({
        error: 'Database error',
        message: 'Failed to update profile image URL in database',
        details: updateError.message
      });
    }
    
    console.log('✅ Profile updated successfully with new image');

    res.json({
      message: 'Profile image uploaded successfully',
      profile_image_url: publicUrl,
      profile: {
        id: profile.id,
        username: profile.username,
        full_name: profile.full_name,
        bio: profile.bio,
        profile_image_url: profile.profile_image_url,
        followers_count: profile.followers_count || 0,
        following_count: profile.following_count || 0,
        posts_count: profile.posts_count || 0,
        created_at: profile.created_at,
        updated_at: profile.updated_at
      }
    });
  } catch (error) {
    console.error('❌ Profile image upload endpoint error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to upload profile image'
    });
  }
});

/**
 * GET /api/profiles/:id
 * Get public profile information for any user
 * Does not require authentication (public endpoint)
 */
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    // Validate UUID format
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(id)) {
      return res.status(400).json({
        error: 'Invalid user ID',
        message: 'User ID must be a valid UUID'
      });
    }

    // Fetch public profile data
    const { data: profile, error } = await supabase
      .from('profiles')
      .select('id, username, full_name, bio, profile_image_url, followers_count, following_count, posts_count, created_at')
      .eq('id', id)
      .single();

    if (error) {
      return res.status(404).json({
        error: 'Profile not found',
        message: 'User profile does not exist'
      });
    }

    res.json(profile);
  } catch (error) {
    console.error('❌ Public profile fetch error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to fetch public profile'
    });
  }
});

export default router;