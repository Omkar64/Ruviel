import express from 'express';
import { requireAuth } from '../middleware/auth.js';
import supabase from '../utils/auth.js';

const router = express.Router();

// Some versions of this project used `read_at` (timestamp) while others used
// `is_read` (boolean). We detect which schema is present and adapt.
let _readMode = null; // 'read_at' | 'is_read'

async function getReadMode() {
  if (_readMode != null) return _readMode;

  try {
    const { error } = await supabase
      .from('messages')
      .select('read_at')
      .limit(1);

    if (!error) {
      _readMode = 'read_at';
      return _readMode;
    }
  } catch (_) {
    // ignore
  }

  _readMode = 'is_read';
  return _readMode;
}

function normalizeMessageRow(row, readMode) {
  const isRead = readMode === 'read_at' ? row.read_at != null : !!row.is_read;
  return {
    id: row.id,
    sender_id: row.sender_id,
    receiver_id: row.receiver_id,
    message: row.message,
    message_type: row.message_type || 'text',
    created_at: row.created_at,
    is_read: isRead,
    sender_username: row.sender_username || 'Unknown',
    sender_profile_image_url: row.sender_profile_image_url || null,
    receiver_username: row.receiver_username || 'Unknown',
    receiver_profile_image_url: row.receiver_profile_image_url || null,
  };
}

async function fetchProfilesMap(userIds) {
  const unique = Array.from(new Set((userIds || []).filter(Boolean)));
  if (unique.length === 0) return {};

  const { data, error } = await supabase
    .from('profiles')
    .select('id, username, profile_image_url')
    .in('id', unique);

  if (error) throw error;

  const map = {};
  for (const p of data || []) {
    map[p.id] = p;
  }
  return map;
}

/**
 * GET /api/messages/users
 * List users for starting a chat (excluding current user)
 * Requires authentication
 */
router.get('/users', requireAuth, async (req, res) => {
  try {
    const userId = req.userId;
    const limit = Math.min(parseInt(req.query.limit) || 200, 500);

    const { data: users, error } = await supabase
      .from('profiles')
      .select('id, email, username, full_name, profile_image_url, created_at')
      .neq('id', userId)
      .order('created_at', { ascending: false })
      .limit(limit);

    if (error) {
      console.error('❌ Users list error:', error);
      return res.status(500).json({
        error: 'Database error',
        message: 'Failed to fetch users'
      });
    }

    res.json({ users: users || [] });
  } catch (error) {
    console.error('❌ Users endpoint error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to fetch users'
    });
  }
});

/**
 * GET /api/messages
 * Get messages between current user and another user
 * Query params: otherUserId (required), limit, offset
 * Requires authentication
 */
router.get('/', requireAuth, async (req, res) => {
  try {
    const readMode = await getReadMode();
    const userId = req.userId;
    const { otherUserId } = req.query;
    const limit = Math.min(parseInt(req.query.limit) || 20, 50);
    const offset = parseInt(req.query.offset) || 0;

    // Validate otherUserId
    if (!otherUserId) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'otherUserId is required'
      });
    }

    // Validate UUID format
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(otherUserId)) {
      return res.status(400).json({
        error: 'Invalid user ID',
        message: 'otherUserId must be a valid UUID'
      });
    }

    // Check if other user exists
    const { data: otherUser, error: userError } = await supabase
      .from('profiles')
      .select('id, username, profile_image_url')
      .eq('id', otherUserId)
      .single();

    if (userError || !otherUser) {
      return res.status(404).json({
        error: 'User not found',
        message: 'The other user does not exist'
      });
    }

    // Fetch messages between the two users
    const { data: messages, error } = await supabase
      .from('messages')
      .select('*')
      .or(`and(sender_id.eq.${userId},receiver_id.eq.${otherUserId}),and(sender_id.eq.${otherUserId},receiver_id.eq.${userId})`)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) {
      console.error('❌ Messages fetch error:', error);
      return res.status(500).json({
        error: 'Database error',
        message: 'Failed to fetch messages'
      });
    }

    // Get total messages count
    const { count: totalCount, error: countError } = await supabase
      .from('messages')
      .select('*', { count: 'exact', head: true })
      .or(`and(sender_id.eq.${userId},receiver_id.eq.${otherUserId}),and(sender_id.eq.${otherUserId},receiver_id.eq.${userId})`);

    if (countError) {
      console.error('❌ Messages count error:', countError);
    }

    // Mark messages as read (where current user is receiver)
    let readUpdate = supabase
      .from('messages')
      .update(readMode === 'read_at'
          ? { read_at: new Date().toISOString() }
          : { is_read: true })
      .eq('sender_id', otherUserId)
      .eq('receiver_id', userId);

    if (readMode === 'read_at') {
      readUpdate = readUpdate.is('read_at', null);
    } else {
      readUpdate = readUpdate.eq('is_read', false);
    }

    const { error: readError } = await readUpdate;

    if (readError) {
      console.error('❌ Mark messages as read error:', readError);
    }

    const profilesMap = await fetchProfilesMap([userId, otherUserId]);

    const enriched = (messages || []).reverse().map((m) => {
      const sender = profilesMap[m.sender_id];
      const receiver = profilesMap[m.receiver_id];
      return normalizeMessageRow(
        {
          ...m,
          sender_username: sender?.username,
          sender_profile_image_url: sender?.profile_image_url,
          receiver_username: receiver?.username,
          receiver_profile_image_url: receiver?.profile_image_url,
        },
        readMode
      );
    });

    res.json({
      messages: enriched,
      other_user: otherUser,
      pagination: {
        limit,
        offset,
        total_count: totalCount || 0,
        has_more: messages.length === limit
      }
    });
  } catch (error) {
    console.error('❌ Messages endpoint error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to fetch messages'
    });
  }
});

/**
 * POST /api/messages
 * Send a message to another user
 * Requires authentication
 */
router.post('/', requireAuth, async (req, res) => {
  try {
    const readMode = await getReadMode();
    const userId = req.userId;
    const { receiver_id, message, message_type = 'text' } = req.body;

    // Validate inputs
    if (!receiver_id || !message) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'receiver_id and message are required'
      });
    }

    if (typeof message !== 'string' || message.trim().length === 0) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Message text is required and cannot be empty'
      });
    }

    if (message.length > 2000) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Message cannot exceed 2000 characters'
      });
    }

    // Validate message type
    if (!['text', 'image', 'video', 'post_reference'].includes(message_type)) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'message_type must be text, image, video, or post_reference'
      });
    }

    // Validate UUID format for receiver
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(receiver_id)) {
      return res.status(400).json({
        error: 'Invalid receiver ID',
        message: 'receiver_id must be a valid UUID'
      });
    }

    // Cannot send message to yourself
    if (receiver_id === userId) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Cannot send message to yourself'
      });
    }

    // Check if receiver exists
    const { data: receiverProfileRow, error: receiverError } = await supabase
      .from('profiles')
      .select('id')
      .eq('id', receiver_id)
      .single();

    if (receiverError || !receiverProfileRow) {
      return res.status(404).json({
        error: 'Receiver not found',
        message: 'The receiver does not exist'
      });
    }

    // Generate message ID
    const messageId = Date.now().toString() + '_' + Math.random().toString(36).substring(2, 11);

    // Create message
    const insert = {
      id: messageId,
      sender_id: userId,
      receiver_id: receiver_id,
      message: message.trim(),
      message_type: message_type,
      created_at: new Date().toISOString()
    };
    if (readMode === 'read_at') {
      insert.read_at = null;
    } else {
      insert.is_read = false;
    }

    const { data: newMessage, error } = await supabase
      .from('messages')
      .insert(insert)
      .select('*')
      .single();

    if (error) {
      console.error('❌ Message creation error:', error);
      return res.status(500).json({
        error: 'Database error',
        message: 'Failed to send message'
      });
    }

    const profilesMap = await fetchProfilesMap([userId, receiver_id]);
    const sender = profilesMap[userId];
    const receiver = profilesMap[receiver_id];

    res.status(201).json({
      message: 'Message sent successfully',
      data: normalizeMessageRow(
        {
          ...newMessage,
          sender_username: sender?.username,
          sender_profile_image_url: sender?.profile_image_url,
          receiver_username: receiver?.username,
          receiver_profile_image_url: receiver?.profile_image_url,
        },
        readMode
      )
    });
  } catch (error) {
    console.error('❌ Message creation endpoint error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to send message'
    });
  }
});

/**
 * GET /api/messages/conversations
 * Get list of conversations for current user
 * Requires authentication
 */
router.get('/conversations', requireAuth, async (req, res) => {
  try {
    const readMode = await getReadMode();
    const userId = req.userId;
    const limit = Math.min(parseInt(req.query.limit) || 20, 50);
    const offset = parseInt(req.query.offset) || 0;

    // Get latest message with each user
    const { data: conversations, error } = await supabase
      .from('messages')
      .select('*')
      .or(`sender_id.eq.${userId},receiver_id.eq.${userId}`)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('❌ Conversations fetch error:', error);
      return res.status(500).json({
        error: 'Database error',
        message: 'Failed to fetch conversations'
      });
    }

    // Group by other user and get latest message
    const conversationMap = new Map();
    
    for (const message of conversations) {
      const otherUserId = message.sender_id === userId ? message.receiver_id : message.sender_id;
      
      if (!conversationMap.has(otherUserId)) {
        conversationMap.set(otherUserId, message);
      }
    }

    // Convert to array and paginate
    const conversationList = Array.from(conversationMap.values())
      .slice(offset, offset + limit);

    const otherUserIds = Array.from(conversationMap.keys());
    const profilesMap = await fetchProfilesMap(otherUserIds);

    // Get unread counts for each conversation
    const unreadCounts = {};
    for (const [otherUserId] of conversationMap) {
      let countQuery = supabase
        .from('messages')
        .select('*', { count: 'exact', head: true })
        .eq('sender_id', otherUserId)
        .eq('receiver_id', userId);

      if (readMode === 'read_at') {
        countQuery = countQuery.is('read_at', null);
      } else {
        countQuery = countQuery.eq('is_read', false);
      }

      const { count, error } = await countQuery;

      if (!error) {
        unreadCounts[otherUserId] = count || 0;
      }
    }

    res.json({
      conversations: conversationList.map(message => {
        const otherUserId = message.sender_id === userId ? message.receiver_id : message.sender_id;
        const otherUser = profilesMap[otherUserId];
        
        return {
          other_user_id: otherUserId,
          other_username: otherUser?.username || 'Unknown',
          other_profile_image_url: otherUser?.profile_image_url,
          last_message: {
            id: message.id,
            message: message.message,
            message_type: message.message_type,
            created_at: message.created_at,
            sender_id: message.sender_id
          },
          unread_count: unreadCounts[otherUserId] || 0
        };
      }),
      pagination: {
        limit,
        offset,
        has_more: conversationList.length === limit
      }
    });
  } catch (error) {
    console.error('❌ Conversations endpoint error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to fetch conversations'
    });
  }
});

/**
 * PUT /api/messages/:id/read
 * Mark a message as read
 * Requires authentication
 */
router.put('/:id/read', requireAuth, async (req, res) => {
  try {
    const readMode = await getReadMode();
    const userId = req.userId;
    const { id: messageId } = req.params;

    if (!messageId || typeof messageId !== 'string') {
      return res.status(400).json({
        error: 'Invalid message ID',
        message: 'Message ID is required'
      });
    }

    // Check if message exists and user is receiver
    const fields = readMode === 'read_at' ? 'receiver_id, read_at' : 'receiver_id, is_read';
    const { data: message, error: fetchError } = await supabase
      .from('messages')
      .select(fields)
      .eq('id', messageId)
      .single();

    if (fetchError || !message) {
      return res.status(404).json({
        error: 'Message not found',
        message: 'Message does not exist'
      });
    }

    if (message.receiver_id !== userId) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'You can only mark messages as read if you are the receiver'
      });
    }

    const alreadyRead = readMode === 'read_at' ? message.read_at != null : !!message.is_read;
    if (alreadyRead) {
      return res.status(200).json({
        message: 'Message already marked as read'
      });
    }

    // Mark as read
    const { error } = await supabase
      .from('messages')
      .update(readMode === 'read_at'
          ? { read_at: new Date().toISOString() }
          : { is_read: true })
      .eq('id', messageId);

    if (error) {
      console.error('❌ Mark message as read error:', error);
      return res.status(500).json({
        error: 'Database error',
        message: 'Failed to mark message as read'
      });
    }

    res.json({
      message: 'Message marked as read successfully'
    });
  } catch (error) {
    console.error('❌ Mark message as read endpoint error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to mark message as read'
    });
  }
});

export default router;