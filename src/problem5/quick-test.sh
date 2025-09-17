#!/bin/bash

# Quick API Test Script for Problem 5
# Simple tests to verify the API is working

BASE_URL="http://localhost:3000"
API_URL="$BASE_URL/resources"

echo "🚀 Quick API Test for Problem 5"
echo "================================"
echo ""

# Test 1: Health check
echo "1. Health check:"
curl -s "$BASE_URL" | jq . 2>/dev/null || curl -s "$BASE_URL"
echo ""

# Test 2: Create a resource
echo "2. Create a resource:"
curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Resource","details":"This is a test"}' | jq . 2>/dev/null || echo "Response received"
echo ""

# Test 3: List resources
echo "3. List resources:"
curl -s "$API_URL" | jq . 2>/dev/null || curl -s "$API_URL"
echo ""

# Test 4: Search resources
echo "4. Search resources:"
curl -s "$API_URL?q=test" | jq . 2>/dev/null || curl -s "$API_URL?q=test"
echo ""

echo "✅ Quick test completed!"
echo ""
echo "To run the full test suite: ./test-api.sh"
