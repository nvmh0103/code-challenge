#!/bin/bash

# Problem 5 API Testing Script
# This script tests all CRUD operations on the Problem 5 API

BASE_URL="http://localhost:3000"
API_URL="$BASE_URL/resources"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to print test results
print_test() {
    local test_name="$1"
    local status="$2"
    local details="$3"
    
    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} $test_name"
        echo -e "  ${RED}Details: $details${NC}"
        ((TESTS_FAILED++))
    fi
}

# Function to make HTTP requests and check responses
make_request() {
    local method="$1"
    local url="$2"
    local data="$3"
    local expected_status="$4"
    local test_name="$5"
    
    if [ -n "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X "$method" \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$url")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$url")
    fi
    
    # Split response and status code
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "$expected_status" ]; then
        print_test "$test_name" "PASS" ""
        echo "$body" | jq . 2>/dev/null || echo "$body"
    else
        print_test "$test_name" "FAIL" "Expected $expected_status, got $http_code. Response: $body"
    fi
    
    echo ""
}

# Wait for API to be ready
echo -e "${BLUE}Waiting for API to be ready...${NC}"
for i in {1..30}; do
    if curl -s "$BASE_URL" > /dev/null 2>&1; then
        echo -e "${GREEN}API is ready!${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}API failed to start after 30 seconds${NC}"
        exit 1
    fi
    sleep 1
done

echo ""
echo -e "${BLUE}=== Problem 5 API Testing Suite ===${NC}"
echo ""

# Test 1: Health check
make_request "GET" "$BASE_URL" "" "200" "Health check"

# Test 2: List resources (empty)
make_request "GET" "$API_URL" "" "200" "List resources (empty)"

# Test 3: Create resource 1
make_request "POST" "$API_URL" '{"name":"Test Resource 1","details":"This is the first test resource"}' "201" "Create resource 1"

# Test 4: Create resource 2
make_request "POST" "$API_URL" '{"name":"Test Resource 2","details":"This is the second test resource"}' "201" "Create resource 2"

# Test 5: Create resource 3
make_request "POST" "$API_URL" '{"name":"Alpha Resource","details":"This resource starts with Alpha"}' "201" "Create resource 3"

# Test 6: Create resource with minimal data
make_request "POST" "$API_URL" '{"name":"Minimal Resource"}' "201" "Create resource with minimal data"

# Test 7: List all resources
make_request "GET" "$API_URL" "" "200" "List all resources"

# Test 8: Search resources
make_request "GET" "$API_URL?q=Alpha" "" "200" "Search resources by 'Alpha'"

# Test 9: Search resources (case insensitive)
make_request "GET" "$API_URL?q=test" "" "200" "Search resources by 'test' (case insensitive)"

# Test 10: Pagination test
make_request "GET" "$API_URL?limit=2&offset=0" "" "200" "Pagination: first 2 resources"

# Test 11: Pagination test (next page)
make_request "GET" "$API_URL?limit=2&offset=2" "" "200" "Pagination: next 2 resources"

# Test 12: Get specific resource (assuming ID 1 exists)
make_request "GET" "$API_URL/1" "" "200" "Get resource by ID 1"

# Test 13: Get non-existent resource
make_request "GET" "$API_URL/999" "" "404" "Get non-existent resource"

# Test 14: Update resource
make_request "PUT" "$API_URL/1" '{"name":"Updated Resource 1","details":"This resource has been updated"}' "200" "Update resource 1"

# Test 15: Partial update resource
make_request "PUT" "$API_URL/2" '{"details":"Only details updated"}' "200" "Partial update resource 2"

# Test 16: Update non-existent resource
make_request "PUT" "$API_URL/999" '{"name":"Updated"}' "404" "Update non-existent resource"

# Test 17: Create resource with invalid data (missing name)
make_request "POST" "$API_URL" '{"details":"Missing name"}' "400" "Create resource with invalid data"

# Test 18: Create resource with empty name
make_request "POST" "$API_URL" '{"name":"","details":"Empty name"}' "400" "Create resource with empty name"

# Test 19: Delete resource
make_request "DELETE" "$API_URL/3" "" "200" "Delete resource 3"

# Test 20: Delete non-existent resource
make_request "DELETE" "$API_URL/999" "" "404" "Delete non-existent resource"

# Test 21: Verify deletion
make_request "GET" "$API_URL/3" "" "404" "Verify deleted resource is gone"

# Test 22: Final list to see remaining resources
make_request "GET" "$API_URL" "" "200" "Final list of remaining resources"

# Test 23: Test with invalid JSON
echo -e "${YELLOW}Testing invalid JSON...${NC}"
response=$(curl -s -w "\n%{http_code}" -X "POST" \
    -H "Content-Type: application/json" \
    -d '{"name":"Invalid JSON"' \
    "$API_URL")
http_code=$(echo "$response" | tail -n1)
if [ "$http_code" = "400" ]; then
    print_test "Invalid JSON handling" "PASS" ""
else
    print_test "Invalid JSON handling" "FAIL" "Expected 400, got $http_code"
fi
echo ""

# Test 24: Test with very long name
long_name=$(printf 'A%.0s' {1..1000})
make_request "POST" "$API_URL" "{\"name\":\"$long_name\",\"details\":\"Very long name test\"}" "201" "Create resource with very long name"

# Test 25: Test special characters in name
make_request "POST" "$API_URL" '{"name":"Resource with Special Chars: !@#$%^&*()","details":"Testing special characters"}' "201" "Create resource with special characters"

echo ""
echo -e "${BLUE}=== Test Summary ===${NC}"
echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
echo -e "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed.${NC}"
    exit 1
fi
