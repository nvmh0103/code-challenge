# Scoreboard API Service - Architecture Diagram

## System Overview

```mermaid
graph TB
    subgraph "Client Layer"
        A[Frontend Website]
        B[User Actions]
        C[WebSocket Client]
    end
    
    subgraph "API Gateway Layer"
        D[Load Balancer]
        E[Rate Limiter]
        F[JWT Validator]
    end
    
    subgraph "Application Layer"
        G[Score Update API]
        H[Leaderboard API]
        I[WebSocket Service]
    end
    
    subgraph "Data Layer"
        J[PostgreSQL]
        K[Redis Cache]
        L[Redis Pub/Sub]
    end
    
    subgraph "Monitoring Layer"
        M[Prometheus Metrics]
        N[Winston Logging]
        O[Health Checks]
    end
    
    A --> D
    B --> D
    C --> I
    D --> E
    E --> F
    F --> G
    F --> H
    G --> J
    G --> K
    G --> L
    L --> I
    I --> C
    H --> K
    K --> J
    G --> M
    G --> N
    H --> M
    H --> N
    I --> M
    I --> N
```

## Score Update Flow

```mermaid
sequenceDiagram
    participant U as User
    participant F as Frontend
    participant LB as Load Balancer
    participant RL as Rate Limiter
    participant API as Score API
    participant JV as JWT Validator
    participant DB as PostgreSQL
    participant R as Redis
    participant WS as WebSocket Service
    participant C as WebSocket Clients
    
    U->>F: Complete Action
    F->>LB: POST /api/v1/scores/update<br/>Authorization: Bearer <token>
    LB->>RL: Check Rate Limit
    RL->>API: Forward Request
    
    API->>JV: Verify JWT Token
    JV->>DB: Update User Score
    JV->>R: Cache Leaderboard
    JV->>R: Publish Score Update
    
    R->>WS: Score Update Event
    WS->>C: Broadcast Update
    
    API->>F: Return Success Response
    F->>U: Show Updated Score
```

## Security Validation Flow

```mermaid
flowchart TD
    A[Incoming Request] --> B{Valid JWT Token?}
    B -->|No| C[Return 401 Unauthorized]
    B -->|Yes| D{Token Expired?}
    D -->|Yes| E[Return 401 Token Expired]
    D -->|No| F{Token Blacklisted?}
    F -->|Yes| G[Return 401 Token Revoked]
    F -->|No| H{Rate Limit OK?}
    H -->|No| I[Return 429 Too Many Requests]
    H -->|Yes| J[Process Score Update]
    J --> K[Update Database]
    K --> L[Update Cache]
    L --> M[Broadcast Update]
    M --> N[Return Success]
```

## Data Flow Architecture

```mermaid
graph LR
    subgraph "Request Processing"
        A[Client Request] --> B[API Gateway]
        B --> C[Authentication]
        C --> D[Rate Limiting]
        D --> E[Validation]
    end
    
    subgraph "Data Processing"
        E --> F[Score Calculation]
        F --> G[Database Update]
        G --> H[Cache Update]
        H --> I[Event Publishing]
    end
    
    subgraph "Real-time Updates"
        I --> J[Redis Pub/Sub]
        J --> K[WebSocket Service]
        K --> L[Client Broadcast]
    end
    
    subgraph "Monitoring"
        M[Metrics Collection] --> N[Prometheus]
        O[Logging] --> P[Winston]
        Q[Health Checks] --> R[Status Endpoint]
    end
    
    E --> M
    F --> O
    G --> Q
```

## Database Schema Relationships

```mermaid
erDiagram
    USERS {
        uuid id PK
        string username UK
        string email UK
        string secret_key
        timestamp created_at
        timestamp updated_at
    }
    
    SCORES {
        uuid id PK
        uuid user_id FK
        bigint score
        string last_action_id
        timestamp last_action_at
        timestamp created_at
        timestamp updated_at
    }
    
    SCORE_HISTORY {
        uuid id PK
        uuid user_id FK
        string action_id
        integer score_increment
        bigint previous_score
        bigint new_score
        string signature
        string nonce
        inet ip_address
        timestamp created_at
    }
    
    USERS ||--o{ SCORES : "has"
    USERS ||--o{ SCORE_HISTORY : "generates"
    SCORES ||--o{ SCORE_HISTORY : "tracks"
```

## Redis Caching Strategy

```mermaid
graph TD
    A[Score Update Request] --> B{Leaderboard in Cache?}
    B -->|Yes| C[Return Cached Data]
    B -->|No| D[Query Database]
    D --> E[Update Cache with TTL]
    E --> F[Return Fresh Data]
    
    G[Score Update] --> H[Update Database]
    H --> I[Invalidate Cache]
    I --> J[Rebuild Cache]
    J --> K[Set New TTL]
    
    L[WebSocket Event] --> M[Publish to Channel]
    M --> N[Subscribers Receive]
    N --> O[Update Client UI]
```

## Deployment Architecture

```mermaid
graph TB
    subgraph "Production Environment"
        subgraph "Load Balancer Tier"
            LB1[Load Balancer 1]
            LB2[Load Balancer 2]
        end
        
        subgraph "Application Tier"
            API1[API Server 1]
            API2[API Server 2]
            API3[API Server 3]
            WS1[WebSocket Server 1]
            WS2[WebSocket Server 2]
        end
        
        subgraph "Data Tier"
            DB1[PostgreSQL Primary]
            DB2[PostgreSQL Replica]
            R1[Redis Master]
            R2[Redis Slave]
        end
        
        subgraph "Monitoring Tier"
            PM[Prometheus]
            GM[Grafana]
            ELK[ELK Stack]
        end
    end
    
    LB1 --> API1
    LB1 --> API2
    LB1 --> API3
    LB2 --> WS1
    LB2 --> WS2
    
    API1 --> DB1
    API2 --> DB1
    API3 --> DB1
    WS1 --> R1
    WS2 --> R1
    
    DB1 --> DB2
    R1 --> R2
    
    API1 --> PM
    API2 --> PM
    API3 --> PM
    WS1 --> PM
    WS2 --> PM
```

## Performance Optimization Flow

```mermaid
flowchart TD
    A[High Traffic] --> B[Connection Pooling]
    B --> C[Query Optimization]
    C --> D[Index Usage]
    D --> E[Cache Hit Ratio]
    E --> F[Redis Clustering]
    F --> G[Database Sharding]
    G --> H[CDN Integration]
    H --> I[Load Balancing]
    I --> J[Auto Scaling]
```

## Security Monitoring Flow

```mermaid
sequenceDiagram
    participant R as Request
    participant S as Security Layer
    participant M as Monitoring
    participant A as Alert System
    participant L as Logging
    
    R->>S: Incoming Request
    S->>M: Check Security Metrics
    M->>L: Log Security Event
    
    alt Suspicious Activity
        M->>A: Trigger Alert
        A->>L: Log Security Incident
        S->>R: Block Request
    else Normal Activity
        S->>R: Process Request
    end
```

---

## Key Design Principles

1. **Security First**: Multiple layers of validation and authentication
2. **Performance**: Caching and optimization at every layer
3. **Scalability**: Horizontal scaling with load balancing
4. **Reliability**: High availability with redundancy
5. **Monitoring**: Comprehensive observability and alerting
6. **Real-time**: WebSocket integration for live updates
7. **Data Integrity**: ACID transactions and audit trails
