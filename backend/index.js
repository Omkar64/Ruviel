import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import authRoutes from './routes/auth.js';
import postsRoutes from './routes/posts.js';
import messagesRoutes from './routes/messages.js';
import commentsRoutes from './routes/comments.js';
import likesRoutes from './routes/likes.js';
import followsRoutes from './routes/follows.js';
import activitiesRoutes from './routes/activities.js';
import storiesRoutes from './routes/stories.js';
import profilesRoutes from './routes/profiles.js';
import reelsRoutes from './routes/reels.js';
import bookmarksRoutes from './routes/bookmarks.js';

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

// CORS configuration
app.use(cors({
  origin: (origin, callback) => {
    // Allow non-browser clients (no Origin header)
    if (!origin) return callback(null, true);

    // Allow any localhost port during development (Flutter web uses random ports)
    if (/^http:\/\/localhost(:\d+)?$/i.test(origin)) {
      return callback(null, true);
    }

    const allowed = process.env.FRONTEND_URL;
    if (allowed && origin === allowed) {
      return callback(null, true);
    }

    return callback(new Error('Not allowed by CORS'));
  },
  credentials: true
}));

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// API Routes
app.use('/api/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

app.use('/api/auth', authRoutes);
app.use('/api/posts', postsRoutes);
app.use('/api/messages', messagesRoutes);
app.use('/api/comments', commentsRoutes);
app.use('/api/likes', likesRoutes);
app.use('/api/follows', followsRoutes);
app.use('/api/activities', activitiesRoutes);
app.use('/api/stories', storiesRoutes);
app.use('/api/profiles', profilesRoutes);
app.use('/api/reels', reelsRoutes);
app.use('/api/bookmarks', bookmarksRoutes);

// Global error handler
app.use((err, req, res, next) => {
  console.error('❌ Unhandled error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Not found',
    message: `Route ${req.originalUrl} not found`
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Backend server running on port ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/api/health`);
  console.log(`🔧 Environment: ${process.env.NODE_ENV || 'development'}`);
});

export default app;