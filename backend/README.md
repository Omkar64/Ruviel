# Instagram Clone Backend

Node.js + Express middleware layer for the Instagram Clone Flutter app.

## Architecture

- **Authentication**: Supabase JWT verification
- **Database**: Supabase PostgreSQL with RLS
- **Storage**: Supabase Storage
- **API**: RESTful endpoints with Express.js

## Setup

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Environment Configuration

Copy `.env` file and update with your Supabase credentials:

```env
# Supabase Configuration
SUPABASE_URL=your_supabase_project_url
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key

# Server Configuration
PORT=3001
NODE_ENV=development
FRONTEND_URL=http://localhost:3000
```

### 3. Start Server

```bash
# Development
npm run dev

# Production
npm start
```

## API Endpoints

### Health Check
- `GET /api/health` - Server health status

### Authentication
- `GET /api/auth/me` - Get current user profile (requires auth)
- `GET /api/auth/profile/:id` - Get public profile (no auth required)

### Posts
- `GET /api/posts` - Get feed posts (optional auth)
- `GET /api/posts/user/:id` - Get user posts (no auth required)
- `POST /api/posts` - Create new post (requires auth)
- `DELETE /api/posts/:id` - Delete post (requires auth, owner only)

### Likes
- `POST /api/likes/posts/:id/like` - Toggle like on post (requires auth)
- `GET /api/likes/posts/:id/likes` - Get post likes (optional auth)

### Comments
- `POST /api/comments/posts/:id/comment` - Add comment to post (requires auth)
- `GET /api/comments/posts/:id/comments` - Get post comments (optional auth)
- `DELETE /api/comments/:id` - Delete comment (requires auth, owner only)

### Messages (DMs)
- `GET /api/messages?otherUserId=xxx` - Get conversation (requires auth)
- `POST /api/messages` - Send message (requires auth)
- `GET /api/messages/conversations` - Get conversations list (requires auth)
- `PUT /api/messages/:id/read` - Mark message as read (requires auth)

## Authentication Flow

1. **Flutter**: Sign in directly with Supabase Auth
2. **Flutter**: Get Supabase access token
3. **Flutter**: Send `Authorization: Bearer <token>` header to backend
4. **Backend**: Verify JWT token using Supabase Service Role Key
5. **Backend**: Return user data or perform protected operations

## Security Features

- ✅ JWT token verification for all protected endpoints
- ✅ RLS (Row Level Security) respected through Supabase Service Role
- ✅ CORS enabled for frontend domain
- ✅ Input validation and sanitization
- ✅ UUID validation for all ID parameters
- ✅ Rate limiting ready (can be added)
- ✅ Error handling without exposing sensitive data

## Database Operations

All database operations use Supabase Service Role Key, which:
- Bypasses RLS for backend operations
- Allows full CRUD operations
- Maintains data integrity
- Respects existing database constraints

## Migration Strategy

### Phase 1: Read-Only APIs ✅
- Health check
- Auth profile endpoints
- Posts feed endpoints

### Phase 2: Write Operations ✅
- Post creation/deletion
- Like/unlike functionality
- Comments

### Phase 3: DMs ✅
- Message sending/receiving
- Conversations

### Phase 4: Flutter Migration
- Update Flutter services to use HTTP calls
- Remove direct Supabase client usage
- Test all functionality

## Error Handling

Standardized error responses:

```json
{
  "error": "Error type",
  "message": "Human readable message"
}
```

HTTP Status Codes:
- `200` - Success
- `201` - Created
- `400` - Bad Request (validation error)
- `401` - Unauthorized (invalid/missing token)
- `403` - Forbidden (permission denied)
- `404` - Not Found
- `500` - Internal Server Error

## Development Notes

- Uses ES6 modules (`import`/`export`)
- Environment variables with `dotenv`
- Structured with separate route files
- Comprehensive logging with emojis for visibility
- Ready for production deployment

## Testing

```bash
# Health check
curl http://localhost:3001/api/health

# Auth test (requires valid token)
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:3001/api/auth/me
```

## Next Steps

1. Update Flutter services to call backend APIs
2. Remove direct Supabase client usage from Flutter
3. Add rate limiting
4. Add request logging
5. Deploy to production (Vercel, Railway, etc.)