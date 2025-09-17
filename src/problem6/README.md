# Problem 6: Scoreboard API Service Specification

## 📋 Overview

This specification defines the architecture and implementation requirements for a **Scoreboard API Service** that manages user scores with live updates and security measures to prevent malicious score manipulation.

## 🎯 Requirements Summary

1. **Scoreboard Display**: Website shows top 10 user scores
2. **Live Updates**: Real-time scoreboard updates when scores change
3. **Score Actions**: Users can perform actions that increase their scores
4. **API Integration**: Actions dispatch API calls to update scores
5. **Security**: Prevent unauthorized score manipulation

## 🏗️ System Architecture

### Core Components

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   API Gateway   │    │   Scoreboard    │
│   Website       │◄──►│   Service       │◄──►│   Service       │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   Auth Service  │    │   Database      │
                       │                 │    │   (PostgreSQL)  │
                       └─────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   WebSocket     │    │   Redis Cache   │
                       │   Service       │    │   (Leaderboard) │
                       └─────────────────┘    └─────────────────┘
```

## 🔧 API Service Module Specification

### 1. Score Update Endpoint

**Endpoint**: `POST /api/v1/scores/update`

**Purpose**: Updates user score after action completion

**Request Format**:
```json
{
  "actionId": "string",
  "scoreIncrement": "number",
  "timestamp": "ISO8601"
}
```

**Headers**:
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**Response Format**:
```json
{
  "success": "boolean",
  "message": "string",
  "data": {
    "userId": "string",
    "newScore": "number",
    "rank": "number",
    "leaderboard": [
      {
        "userId": "string",
        "username": "string",
        "score": "number",
        "rank": "number"
      }
    ]
  }
}
```

### 2. Leaderboard Endpoint

**Endpoint**: `GET /api/v1/scores/leaderboard`

**Purpose**: Retrieves current top 10 scores

**Query Parameters**:
- `limit`: Number of results (default: 10, max: 100)
- `offset`: Pagination offset (default: 0)

**Response Format**:
```json
{
  "success": "boolean",
  "data": {
    "leaderboard": [
      {
        "userId": "string",
        "username": "string",
        "score": "number",
        "rank": "number",
        "lastUpdated": "ISO8601"
      }
    ],
    "totalUsers": "number",
    "lastUpdated": "ISO8601"
  }
}
```

### 3. User Score Endpoint

**Endpoint**: `GET /api/v1/scores/user/{userId}`

**Purpose**: Retrieves specific user's score and rank

**Response Format**:
```json
{
  "success": "boolean",
  "data": {
    "userId": "string",
    "username": "string",
    "score": "number",
    "rank": "number",
    "lastUpdated": "ISO8601"
  }
}
```

### 4. Token Refresh Endpoint

**Endpoint**: `POST /api/v1/auth/refresh`

**Purpose**: Refresh expired access tokens

**Request Format**:
```json
{
  "refreshToken": "string"
}
```

**Response Format**:
```json
{
  "success": "boolean",
  "data": {
    "accessToken": "string",
    "refreshToken": "string",
    "expiresIn": "number"
  }
}
```

## 🔐 Security Implementation

### Why JWT Tokens with Quick Expiry?

**Benefits of JWT over HMAC:**
- ✅ **Stateless**: No need to store user secret keys
- ✅ **Scalable**: Works across multiple servers without shared state
- ✅ **Standardized**: Industry-standard authentication method
- ✅ **Self-contained**: Token contains user info and permissions
- ✅ **Revocable**: Can blacklist tokens for immediate revocation
- ✅ **Short-lived**: 5-minute expiry minimizes attack window

**Security Advantages:**
- **Reduced attack surface**: Tokens expire quickly (5 minutes)
- **Automatic cleanup**: Expired tokens become invalid automatically
- **Revocation capability**: Can blacklist compromised tokens
- **No secret key management**: No need to distribute user secret keys
- **Audit trail**: Token ID (jti) provides tracking capability

### 1. JWT Token Authentication

**Token Generation (Server-side)**:
```javascript
// Generate JWT token with short expiry (5 minutes)
const token = jwt.sign(
  {
    userId: user.id,
    username: user.username,
    permissions: ['score_update'],
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + (5 * 60), // 5 minutes
    jti: uuidv4() // Unique token ID for revocation
  },
  process.env.JWT_SECRET,
  { algorithm: 'HS256' }
);
```

**Token Verification (Server-side)**:
```javascript
// Verify JWT token
const token = req.headers.authorization?.replace('Bearer ', '');
if (!token) {
  throw new UnauthorizedError('No token provided');
}

try {
  const decoded = jwt.verify(token, process.env.JWT_SECRET);
  
  // Check token expiry
  if (decoded.exp < Math.floor(Date.now() / 1000)) {
    throw new UnauthorizedError('Token expired');
  }
  
  // Check if token is blacklisted (for revocation)
  const isBlacklisted = await redis.exists(`blacklist:${decoded.jti}`);
  if (isBlacklisted) {
    throw new UnauthorizedError('Token revoked');
  }
  
  req.user = decoded;
} catch (error) {
  throw new UnauthorizedError('Invalid token');
}
```

### 2. Rate Limiting

**Implementation**:
- **Per-user rate limiting**: Max 10 score updates per minute
- **Per-action rate limiting**: Max 1 update per action per user per minute
- **IP-based rate limiting**: Max 100 requests per minute per IP

**Redis-based counters**:
```javascript
const rateLimitKey = `rate_limit:${userId}:${actionId}`;
const currentCount = await redis.incr(rateLimitKey);
if (currentCount === 1) {
  await redis.expire(rateLimitKey, 60); // 1 minute TTL
}
if (currentCount > 1) {
  throw new RateLimitError('Too many requests');
}
```

### 3. Simplified Security Model

**Why Remove Nonce and Action Validation?**

With JWT tokens having **5-minute expiry** and **rate limiting**, we can simplify the security model:

- ✅ **JWT tokens expire quickly** (5 minutes) - prevents long-term replay attacks
- ✅ **Rate limiting** prevents rapid-fire requests
- ✅ **Token revocation** allows immediate blocking of compromised tokens
- ✅ **Stateless design** - no need to track nonces or validate actions server-side

**Simplified Implementation**:
```javascript
// Just verify JWT token and apply rate limiting
const token = req.headers.authorization?.replace('Bearer ', '');
const decoded = jwt.verify(token, process.env.JWT_SECRET);

// Apply rate limiting per user
const rateLimitKey = `rate_limit:${decoded.userId}`;
const currentCount = await redis.incr(rateLimitKey);
if (currentCount === 1) {
  await redis.expire(rateLimitKey, 60); // 1 minute TTL
}
if (currentCount > 10) { // Max 10 requests per minute
  throw new RateLimitError('Too many requests');
}

// Process score update directly
await updateUserScore(decoded.userId, scoreIncrement);
```

## 📊 Database Schema

### Users Table
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username VARCHAR(50) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Scores Table
```sql
CREATE TABLE scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  score BIGINT DEFAULT 0,
  last_action_id VARCHAR(50),
  last_action_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id)
);
```

### Score History Table
```sql
CREATE TABLE score_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  action_id VARCHAR(50) NOT NULL,
  score_increment INTEGER NOT NULL,
  previous_score BIGINT NOT NULL,
  new_score BIGINT NOT NULL,
  token_id VARCHAR(64) NOT NULL, -- JWT token ID (jti)
  ip_address INET,
  created_at TIMESTAMP DEFAULT NOW()
);
```

## 🔄 Real-time Updates

### WebSocket Implementation

**Connection Endpoint**: `wss://api.example.com/ws/leaderboard`

**Message Types**:
```javascript
// Score update broadcast
{
  "type": "score_update",
  "data": {
    "userId": "string",
    "username": "string",
    "newScore": "number",
    "rank": "number",
    "leaderboard": [...]
  }
}

// Leaderboard refresh
{
  "type": "leaderboard_refresh",
  "data": {
    "leaderboard": [...],
    "lastUpdated": "ISO8601"
  }
}
```

**Redis Pub/Sub Integration**:
```javascript
// Publish score update
await redis.publish('score_updates', JSON.stringify({
  userId,
  username,
  newScore,
  rank,
  leaderboard: top10Scores
}));

// Subscribe to updates
redis.subscribe('score_updates');
redis.on('message', (channel, message) => {
  const update = JSON.parse(message);
  websocketClients.forEach(client => {
    client.send(JSON.stringify({
      type: 'score_update',
      data: update
    }));
  });
});
```

## 🚀 Performance Optimizations

### 1. Caching Strategy

**Redis Leaderboard Cache**:
```javascript
// Cache top 100 scores with 30-second TTL
const leaderboardKey = 'leaderboard:top100';
const cachedLeaderboard = await redis.get(leaderboardKey);

if (!cachedLeaderboard) {
  const leaderboard = await db.query(`
    SELECT u.username, s.score, s.user_id
    FROM scores s
    JOIN users u ON s.user_id = u.id
    ORDER BY s.score DESC
    LIMIT 100
  `);
  
  await redis.setex(leaderboardKey, 30, JSON.stringify(leaderboard));
}
```

### 2. Database Indexing

```sql
-- Optimize leaderboard queries
CREATE INDEX idx_scores_score_desc ON scores(score DESC);
CREATE INDEX idx_scores_user_id ON scores(user_id);
CREATE INDEX idx_score_history_user_id ON score_history(user_id);
CREATE INDEX idx_score_history_created_at ON score_history(created_at);
```

### 3. Connection Pooling

```javascript
// PostgreSQL connection pool
const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  max: 20, // Maximum connections
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});
```

## 📈 Monitoring & Analytics

### 1. Metrics Collection

**Key Metrics**:
- Score update requests per second
- Average response time
- WebSocket connection count
- Rate limit violations
- Authentication failures

**Implementation**:
```javascript
// Prometheus metrics
const promClient = require('prom-client');

const scoreUpdateCounter = new promClient.Counter({
  name: 'score_updates_total',
  help: 'Total number of score updates',
  labelNames: ['action_id', 'status']
});

const responseTimeHistogram = new promClient.Histogram({
  name: 'api_response_time_seconds',
  help: 'API response time in seconds',
  labelNames: ['method', 'route', 'status']
});
```

### 2. Logging

**Structured Logging**:
```javascript
const logger = winston.createLogger({
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
});

// Log score updates
logger.info('Score update', {
  userId,
  actionId,
  scoreIncrement,
  newScore,
  rank,
  ipAddress: req.ip,
  userAgent: req.get('User-Agent')
});
```

## 🔧 Configuration

### Environment Variables

```bash
# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/scoreboard
DB_POOL_SIZE=20

# Redis
REDIS_URL=redis://localhost:6379
REDIS_PASSWORD=your_redis_password

# Security
JWT_SECRET=your_jwt_secret_key
HMAC_SECRET=your_hmac_secret_key
RATE_LIMIT_WINDOW=60
RATE_LIMIT_MAX_REQUESTS=10

# WebSocket
WS_PORT=8080
WS_MAX_CONNECTIONS=1000

# Monitoring
PROMETHEUS_PORT=9090
LOG_LEVEL=info
```

## 🧪 Testing Strategy

### 1. Unit Tests

**Test Coverage**:
- Score calculation logic
- Signature verification
- Rate limiting
- Nonce validation
- Action validation

### 2. Integration Tests

**Test Scenarios**:
- Complete score update flow
- WebSocket real-time updates
- Database consistency
- Redis caching behavior

### 3. Load Testing

**Performance Targets**:
- Handle 1000 concurrent score updates/second
- WebSocket connections: 10,000 concurrent
- API response time: < 100ms (95th percentile)
- Database query time: < 50ms (95th percentile)

## 🚨 Error Handling

### Error Response Format

```json
{
  "success": false,
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Too many requests. Please try again later.",
    "details": {
      "retryAfter": 60,
      "limit": 10,
      "window": 60
    }
  },
  "timestamp": "2024-01-01T00:00:00.000Z",
  "requestId": "uuid"
}
```

### Error Codes

- `TOKEN_MISSING`: No JWT token provided
- `TOKEN_INVALID`: JWT token is malformed or invalid
- `TOKEN_EXPIRED`: JWT token has expired
- `TOKEN_REVOKED`: JWT token has been blacklisted
- `RATE_LIMIT_EXCEEDED`: Too many requests
- `USER_NOT_FOUND`: User does not exist
- `DATABASE_ERROR`: Database operation failed
- `CACHE_ERROR`: Redis operation failed

## 🔄 Deployment Considerations

### 1. Horizontal Scaling

**Load Balancer Configuration**:
- Round-robin distribution
- Health check endpoints
- WebSocket sticky sessions

**Database Scaling**:
- Read replicas for leaderboard queries
- Connection pooling
- Query optimization

### 2. High Availability

**Redis Cluster**:
- Master-slave replication
- Automatic failover
- Data persistence

**Database Backup**:
- Daily automated backups
- Point-in-time recovery
- Cross-region replication

## 💡 Additional Improvements

### 1. Advanced Security

**Token Refresh Mechanism**:
```javascript
// Short-lived access tokens (5 minutes) + refresh tokens (1 hour)
const accessToken = jwt.sign(
  { userId, username, permissions: ['score_update'], type: 'access' },
  process.env.JWT_SECRET,
  { expiresIn: '5m' }
);

const refreshToken = jwt.sign(
  { userId, type: 'refresh' },
  process.env.JWT_REFRESH_SECRET,
  { expiresIn: '1h' }
);
```

**Token Revocation**:
```javascript
// Blacklist tokens for immediate revocation
const revokeToken = async (tokenId) => {
  const decoded = jwt.decode(tokenId);
  await redis.setex(`blacklist:${decoded.jti}`, decoded.exp - Math.floor(Date.now() / 1000), 'revoked');
};
```

**IP Whitelisting**:
- Restrict API access to known IP ranges
- Implement geolocation-based restrictions
- Monitor for suspicious activity patterns

### 2. Enhanced Features

**Score Categories**:
- Different leaderboards for different game types
- Seasonal competitions
- Achievement-based scoring

**Anti-Cheating Measures**:
- Behavioral analysis
- Score velocity monitoring
- Suspicious pattern detection

### 3. Analytics Dashboard

**Real-time Metrics**:
- Live leaderboard updates
- User engagement statistics
- Performance monitoring
- Security incident tracking

### 4. API Versioning

**Version Management**:
- Semantic versioning (v1, v2, etc.)
- Backward compatibility
- Deprecation notices
- Migration guides

## 📚 Implementation Timeline

### Phase 1: Core API (Week 1-2)
- Basic score update endpoint
- Database schema implementation
- Authentication and security
- Unit tests

### Phase 2: Real-time Features (Week 3)
- WebSocket implementation
- Redis caching
- Leaderboard optimization
- Integration tests

### Phase 3: Production Ready (Week 4)
- Monitoring and logging
- Load testing
- Performance optimization
- Documentation completion

## 🎯 Success Criteria

- ✅ Handle 1000+ concurrent score updates
- ✅ Real-time leaderboard updates (< 1 second latency)
- ✅ 99.9% uptime
- ✅ Zero successful unauthorized score updates
- ✅ API response time < 100ms (95th percentile)
- ✅ Complete test coverage (> 90%)

---

**Note**: This specification provides a comprehensive foundation for implementing a secure, scalable scoreboard API service. The backend engineering team should prioritize security measures and performance optimization while maintaining code quality and test coverage.
