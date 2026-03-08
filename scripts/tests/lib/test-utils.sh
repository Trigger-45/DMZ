#!/bin/bash
# Test Utilities Library
# Provides common functions for all tests

# Don't use -e so test failures don't abort the script
set -u

# =========================
# Terminal Colors
# =========================
RED="\e[31m"
GREEN="\e[32m"
BLUE="\e[34m"
YELLOW="\e[33m"
CYAN="\e[36m"
MAGENTA="\e[35m"
BOLD="\e[1m"
ENDCOLOR="\e[0m"

# =========================
# Global Statistics
# =========================
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0
WARNINGS_COUNT=0
declare -a FAILED_TEST_NAMES
declare -a FAILED_TEST_DETAILS
declare -a SKIPPED_TEST_NAMES
declare -a WARNING_MESSAGES

# =========================
# Test Result Tracking
# =========================
declare -A TEST_CATEGORIES
declare -A CATEGORY_PASSED
declare -A CATEGORY_FAILED
declare -A CATEGORY_SKIPPED

# =========================
# Core Test Function
# =========================
run_test() {
    local category="$1"
    local test_name="$2"
    local test_command="$3"
    local timeout="${4:-10}"
    local critical="${5:-false}"  # Mark as critical if fail should affect overall result
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    # Initialize category if not exists
    if [[ ! -v CATEGORY_PASSED["$category"] ]]; then
        TEST_CATEGORIES["$category"]=1
        CATEGORY_PASSED["$category"]=0
        CATEGORY_FAILED["$category"]=0
        CATEGORY_SKIPPED["$category"]=0
    fi
    
    # Print test header
    printf "%-70s" "  $(printf '%02d' $TOTAL_TESTS) ${test_name}..."
    echo -ne "${YELLOW}[RUNNING]${ENDCOLOR}\r"
    
    # Run test with timeout
    local output
    local exit_code=0
    
    output=$(timeout $timeout bash -c "$test_command" 2>&1) || exit_code=$?
    
    # Move cursor back to overwrite and clear line
    echo -ne "\r\033[K"
    printf "%-70s" "  $(printf '%02d' $TOTAL_TESTS) ${test_name}..."
    
    # Check result
    if [ $exit_code -eq 124 ]; then
        echo -e "${RED}[TIMEOUT]${ENDCOLOR}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        CATEGORY_FAILED["$category"]=$((${CATEGORY_FAILED["$category"]} + 1))
        FAILED_TEST_NAMES+=("[$category] $test_name")
        FAILED_TEST_DETAILS+=("TIMEOUT after ${timeout}s")
        return 1
    elif [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}[PASS]${ENDCOLOR}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        CATEGORY_PASSED["$category"]=$((${CATEGORY_PASSED["$category"]} + 1))
        return 0
    else
        echo -e "${RED}[FAIL]${ENDCOLOR}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        CATEGORY_FAILED["$category"]=$((${CATEGORY_FAILED["$category"]} + 1))
        FAILED_TEST_NAMES+=("[$category] $test_name")
        local short_output="${output:0:120}"
        FAILED_TEST_DETAILS+=("Exit: $exit_code | ${short_output}")
        return 1
    fi
}

# =========================
# Test Skip Function
# =========================
skip_test() {
    local category="$1"
    local test_name="$2"
    local reason="${3:-No reason provided}"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
    
    if [[ ! -v CATEGORY_SKIPPED["$category"] ]]; then
        CATEGORY_SKIPPED["$category"]=0
    fi
    CATEGORY_SKIPPED["$category"]=$((${CATEGORY_SKIPPED["$category"]} + 1))
    
    printf "%-70s" "  $(printf '%02d' $TOTAL_TESTS) ${test_name}..."
    echo -e "${MAGENTA}[SKIP]${ENDCOLOR} ($reason)"
    SKIPPED_TEST_NAMES+=("[$category] $test_name: $reason")
    return 0
}

# =========================
# Warning Function
# =========================
add_warning() {
    local test_name="$1"
    local message="$2"
    
    WARNINGS_COUNT=$((WARNINGS_COUNT + 1))
    printf "%-70s" "  WARNING: ${test_name}"
    echo -e "${YELLOW}[WARN]${ENDCOLOR}"
    WARNING_MESSAGES+=("$test_name: $message")
}

# =========================
# Category Header
# =========================
print_category() {
    local category="$1"
    local description="${2:-}"
    echo ""
    echo -e "${BOLD}${MAGENTA}═══ ${category} ═══${ENDCOLOR}"
    if [ -n "$description" ]; then
        echo -e "${CYAN}${description}${ENDCOLOR}"
    fi
    echo ""
}

# =========================
# Test Summary Report
# =========================
print_summary() {
    echo ""
    echo ""
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════════╗${ENDCOLOR}"
    echo -e "${BOLD}${CYAN}║                      TEST SUITE SUMMARY                            ║${ENDCOLOR}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════════╝${ENDCOLOR}"
    echo ""
    echo -e "${BOLD}Total Tests:${ENDCOLOR}    $TOTAL_TESTS"
    echo -e "${GREEN}${BOLD}✓ Passed:${ENDCOLOR}        $PASSED_TESTS${ENDCOLOR}"
    echo -e "${RED}${BOLD}✗ Failed:${ENDCOLOR}        $FAILED_TESTS${ENDCOLOR}"
    echo -e "${MAGENTA}${BOLD}⊘ Skipped:${ENDCOLOR}       $SKIPPED_TESTS${ENDCOLOR}"
    if [ $WARNINGS_COUNT -gt 0 ]; then
        echo -e "${YELLOW}${BOLD}⚠ Warnings:${ENDCOLOR}      $WARNINGS_COUNT${ENDCOLOR}"
    fi
    echo ""
    
    # Calculate pass rate
    if [ $TOTAL_TESTS -gt 0 ]; then
        PASS_RATE=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
    else
        PASS_RATE=0
    fi
    
    # Progress bar (only if we have tests)
    if [ $TOTAL_TESTS -gt 0 ]; then
        echo -ne "${BOLD}Progress: ${ENDCOLOR}["
        FILLED=$(( PASSED_TESTS * 50 / TOTAL_TESTS ))
        EMPTY=$(( 50 - FILLED ))
        printf "${GREEN}%0.s█${ENDCOLOR}" $(seq 1 $FILLED)
        printf "${RED}%0.s░${ENDCOLOR}" $(seq 1 $EMPTY)
        echo "] ${PASS_RATE}%"
    else
        echo -e "${YELLOW}No tests were executed${ENDCOLOR}"
    fi
    echo ""
    
    # Category Breakdown
    echo -e "${BOLD}Category Breakdown:${ENDCOLOR}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${ENDCOLOR}"
    for category in "${!TEST_CATEGORIES[@]}"; do
        local passed=${CATEGORY_PASSED[$category]:-0}
        local failed=${CATEGORY_FAILED[$category]:-0}
        local skipped=${CATEGORY_SKIPPED[$category]:-0}
        local total=$((passed + failed + skipped))
        printf "  %-35s" "$category"
        echo -e "${GREEN}$passed${ENDCOLOR}✓ ${RED}$failed${ENDCOLOR}✗ ${MAGENTA}$skipped${ENDCOLOR}⊘"
    done
    echo ""
    
    # Failed Tests Details
    if [ $FAILED_TESTS -gt 0 ]; then
        echo -e "${RED}${BOLD}Failed Tests Details:${ENDCOLOR}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${ENDCOLOR}"
        
        for ((i=0; i<${#FAILED_TEST_NAMES[@]}; i++)); do
            echo -e "${RED}✗ ${FAILED_TEST_NAMES[$i]}${ENDCOLOR}"
            echo -e "${YELLOW}  ${FAILED_TEST_DETAILS[$i]}${ENDCOLOR}"
            echo ""
        done
    fi
    
    # Skipped Tests Details
    if [ $SKIPPED_TESTS -gt 0 ]; then
        echo -e "${MAGENTA}${BOLD}Skipped Tests:${ENDCOLOR}"
        echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${ENDCOLOR}"
        for skipped_test in "${SKIPPED_TEST_NAMES[@]}"; do
            echo -e "${MAGENTA}⊘ ${skipped_test}${ENDCOLOR}"
        done
        echo ""
    fi
    
    # Warnings Details
    if [ $WARNINGS_COUNT -gt 0 ]; then
        echo -e "${YELLOW}${BOLD}Warnings:${ENDCOLOR}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${ENDCOLOR}"
        for warning in "${WARNING_MESSAGES[@]}"; do
            echo -e "${YELLOW}⚠ ${warning}${ENDCOLOR}"
        done
        echo ""
    fi
}

# =========================
# Final Result
# =========================
print_final_result() {
    echo ""
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}${BOLD}╔════════════════════════════════════════╗${ENDCOLOR}"
        echo -e "${GREEN}${BOLD}║   ALL TESTS PASSED SUCCESSFULLY! ✓     ║${ENDCOLOR}"
        echo -e "${GREEN}${BOLD}╚════════════════════════════════════════╝${ENDCOLOR}"
        return 0
    else
        echo -e "${YELLOW}${BOLD}╔════════════════════════════════════════╗${ENDCOLOR}"
        echo -e "${YELLOW}${BOLD}║     SOME TESTS FAILED                  ║${ENDCOLOR}"
        echo -e "${YELLOW}${BOLD}║  Pass Rate: ${PASS_RATE}%              ║${ENDCOLOR}"
        echo -e "${YELLOW}${BOLD}╚════════════════════════════════════════╝${ENDCOLOR}"
        return 1
    fi
}

# =========================
# Save Report to File
# =========================
save_report() {
    local report_file="${1:-reports/test-report-$(date +%Y%m%d-%H%M%S).txt}"
    
    {
        echo "Test Suite Report - $(date)"
        echo "======================================"
        echo ""
        echo "Total Tests: $TOTAL_TESTS"
        echo "Passed: $PASSED_TESTS"
        echo "Failed: $FAILED_TESTS"
        echo "Skipped: $SKIPPED_TESTS"
        echo "Pass Rate: ${PASS_RATE}%"
        echo ""
        
        if [ $FAILED_TESTS -gt 0 ]; then
            echo "Failed Tests:"
            for ((i=0; i<${#FAILED_TEST_NAMES[@]}; i++)); do
                echo "  - ${FAILED_TEST_NAMES[$i]}"
                echo "    ${FAILED_TEST_DETAILS[$i]}"
            done
        fi
    } > "$report_file"
    
    echo "Report saved to: $report_file"
}

# =========================
# Helper: Docker Container Check
# =========================
container_running() {
    local container_name="$1"
    sudo docker ps --filter "name=$container_name" --format '{{.Names}}' | grep -q "$container_name"
}

# =========================
# Helper: Container Exec Timeout
# =========================
container_exec_test() {
    local container="$1"
    local command="$2"
    local timeout="${3:-10}"
    
    timeout $timeout sudo docker exec "$container" bash -c "$command" >/dev/null 2>&1
}

# =========================
# Helper: Port Check
# =========================
port_open() {
    local host="${1:-localhost}"
    local port="$2"
    local timeout="${3:-5}"
    
    timeout $timeout bash -c "echo > /dev/tcp/$host/$port" >/dev/null 2>&1
}

# =========================
# Helper: HTTP Status Check
# =========================
http_status() {
    local url="$1"
    local timeout="${2:-10}"
    
    curl -s -m $timeout -o /dev/null -w "%{http_code}" "$url" 2>/dev/null
}

# =========================
# Helper: JSON Response Check
# =========================
json_contains() {
    local url="$1"
    local json_key="$2"
    local timeout="${3:-10}"
    
    curl -s -m $timeout "$url" 2>/dev/null | grep -q "$json_key"
}

export -f run_test skip_test add_warning print_category print_summary print_final_result save_report
export -f container_running container_exec_test port_open http_status json_contains
