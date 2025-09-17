## Problem 5 — A Crude Server

Simple CRUD API using Express + TypeScript with PostgreSQL and Prisma ORM.

## 🚀 How to Run

### Option 1: Docker Compose (Recommended)

```bash

# Start both PostgreSQL and API with one command
docker-compose up --build
```

**Benefits of Docker Compose:**
- ✅ Single command starts everything
- ✅ Automatic service dependencies (API waits for PostgreSQL)
- ✅ Health checks ensure database is ready
- ✅ Automatic database schema setup
- ✅ Isolated environment
- ✅ Easy cleanup with `docker-compose down`

The API will be available at `http://localhost:3000`

### Option 2: Local Development

If you prefer to run the API locally:

```bash
# Step 1: Start PostgreSQL in Docker
docker run --name postgres-problem5 \
  -e POSTGRES_DB=problem5 \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  -d postgres:15-alpine

# Step 2: Setup environment and dependencies
cp env.example .env
npm install
npx prisma db push --accept-data-loss

# Step 3: Start the API server
npm run dev
```

### Test the API

```bash
# Quick test (4 basic tests)
./quick-test.sh

# Full test suite (25 comprehensive tests)
./test-api.sh
```

## 📋 Manual Testing Examples

### Create a resource
```bash
curl -X POST http://localhost:3000/resources \
  -H "Content-Type: application/json" \
  -d '{"name":"My Resource","details":"This is a test resource"}'
```

### List all resources
```bash
curl http://localhost:3000/resources
```

### Search resources
```bash
curl "http://localhost:3000/resources?q=test"
```

### Get specific resource
```bash
curl http://localhost:3000/resources/1
```

### Update resource
```bash
curl -X PUT http://localhost:3000/resources/1 \
  -H "Content-Type: application/json" \
  -d '{"name":"Updated Resource","details":"Updated details"}'
```

### Delete resource
```bash
curl -X DELETE http://localhost:3000/resources/1
```

## 🐳 Docker Commands

```bash
# Start services
docker-compose up --build

# Start in background
docker-compose up --build -d

# Stop services
docker-compose down

# View logs
docker-compose logs api
docker-compose logs postgres

# Rebuild and restart
docker-compose down && docker-compose up --build
```

## 🏗️ Production Build

```bash
npm run build
npm start
```

## 📚 API Documentation

### Endpoints

- **`POST /resources`**
  - Creates a new resource
  - Body: `{ "name": string, "details?": string }`
  - Returns: Created resource with ID and timestamps

- **`GET /resources?q=term&limit=20&offset=0`**
  - Lists resources with optional search and pagination
  - `q`: Search term (searches name and details)
  - `limit`: Number of results (1-100, default: 20)
  - `offset`: Skip results (default: 0)

- **`GET /resources/:id`**
  - Gets a specific resource by ID
  - Returns: Resource details or 404 if not found

- **`PUT /resources/:id`**
  - Updates an existing resource
  - Body: `{ "name?": string, "details?": string }`
  - Returns: Updated resource

- **`DELETE /resources/:id`**
  - Deletes a resource
  - Returns: Deleted resource or 404 if not found

### Response Format

All responses are JSON. Resources have this structure:
```json
{
  "id": "1",
  "name": "Resource Name",
  "details": "Resource details",
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-01T00:00:00.000Z"
}
```

## 🗄️ Database

- **ORM**: Prisma with PostgreSQL
- **Schema**: Defined in `prisma/schema.prisma`
- **Setup**: `npx prisma db push --accept-data-loss`
- **Client generation**: `npx prisma generate`

## ⚙️ Environment Variables

- `DATABASE_URL`: PostgreSQL connection string
- `PORT`: Server port (default: 3000)

See `env.example` for reference.

## 🧪 Testing

The project includes two test scripts:

- **`quick-test.sh`**: 4 basic tests to verify API is working
- **`test-api.sh`**: 25 comprehensive tests covering all CRUD operations, edge cases, and error handling

Both scripts will show colored output with ✓ for passed tests and ✗ for failed tests.
