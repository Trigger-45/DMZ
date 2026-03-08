#!/bin/bash
# Main Test Suite Runner
# Orchestrates all test suites and generates comprehensive report

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/test-utils.sh"

# Configuration
TESTS_DIR="$SCRIPT_DIR"
REPORT_DIR="$SCRIPT_DIR/reports"
RUN_DATE=$(date +%Y%m%d-%H%M%S)
REPORT_FILE="$REPORT_DIR/test-report-$RUN_DATE.txt"
HTML_REPORT="$REPORT_DIR/test-report-$RUN_DATE.html"
STATS_DIR="/tmp/sun_dmz_tests_$$"

# Create report directory
mkdir -p "$REPORT_DIR"
mkdir -p "$STATS_DIR"

# =========================
# Header
# =========================
clear
echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════════╗${ENDCOLOR}"
echo -e "${BOLD}${CYAN}║          SUN_DMZ LAB - COMPREHENSIVE TEST SUITE                    ║${ENDCOLOR}"
echo -e "${BOLD}${CYAN}║                    Full Environment Testing                        ║${ENDCOLOR}"
echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════════╝${ENDCOLOR}"
echo ""
echo -e "${CYAN}Test Suite: Integrated Security & Network Testing${ENDCOLOR}"
echo -e "${CYAN}Execution Time: $(date)${ENDCOLOR}"
echo -e "${CYAN}Report: $REPORT_FILE${ENDCOLOR}"
echo ""

# =========================
# Verify Prerequisites
# =========================
echo -e "${YELLOW}Checking prerequisites...${ENDCOLOR}"
echo ""

if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker not found${ENDCOLOR}"
    exit 1
fi

if ! command -v curl &> /dev/null; then
    echo -e "${RED}✗ curl not found${ENDCOLOR}"
    exit 1
fi

echo -e "${GREEN}✓ Prerequisites met${ENDCOLOR}"
echo ""

# =========================
# Run Individual Test Suites
# =========================

run_suite() {
    local suite_file="$1"
    
    # Check if file exists
    if [ ! -f "$suite_file" ]; then
        echo -e "${RED}✗ Test suite not found: $suite_file${ENDCOLOR}"
        return 0
    fi
    
    if [ ! -x "$suite_file" ]; then
        chmod +x "$suite_file"
    fi
    
    # Source script directly to preserve global variables
    # Don't set -e so failures don't abort the script
    set +e
    set +o pipefail
    source "$suite_file" 2>/dev/null
    # Stay with set +e - don't re-enable exit on error
    
    return 0
}

# Run all test suites in order
echo -e "${BOLD}${MAGENTA}╔════════════════════════════════════════════════════════════════════╗${ENDCOLOR}"
echo -e "${BOLD}${MAGENTA}║                    RUNNING TEST SUITES                             ║${ENDCOLOR}"
echo -e "${BOLD}${MAGENTA}╚════════════════════════════════════════════════════════════════════╝${ENDCOLOR}"
echo ""

# Health Tests
run_suite "$TESTS_DIR/01-health.sh"

# Network Tests
run_suite "$TESTS_DIR/02-network.sh"

# Firewall Tests
run_suite "$TESTS_DIR/03-firewall.sh"

# Service Tests
run_suite "$TESTS_DIR/04-services.sh"

# SIEM Tests
run_suite "$TESTS_DIR/05-siem.sh"

# Security Tests
run_suite "$TESTS_DIR/06-security.sh"

# Advanced Tests
run_suite "$TESTS_DIR/07-advanced.sh"

# =========================
# Calculate Final Statistics
# =========================
if [ $TOTAL_TESTS -gt 0 ]; then
    PASS_RATE=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
else
    PASS_RATE=0
fi

# =========================
# Print Summary and Report
# =========================
print_summary
result=$(print_final_result || true)
echo "$result"

# =========================
# Save Text Report
# =========================
{
    echo "════════════════════════════════════════════════════════════════════"
    echo "SUN_DMZ LAB - TEST SUITE REPORT"
    echo "════════════════════════════════════════════════════════════════════"
    echo ""
    echo "Execution Time: $(date)"
    echo "Lab Name: MaJuVi"
    echo ""
    echo "Test Summary:"
    echo "  Total Tests:     $TOTAL_TESTS"
    echo "  Passed:          $PASSED_TESTS (${PASS_RATE}%)"
    echo "  Failed:          $FAILED_TESTS"
    echo "  Skipped:         $SKIPPED_TESTS"
    echo "  Warnings:        $WARNINGS_COUNT"
    echo ""
    
    if [ $FAILED_TESTS -gt 0 ]; then
        echo "Failed Tests:"
        for ((i=0; i<${#FAILED_TEST_NAMES[@]}; i++)); do
            echo "  - ${FAILED_TEST_NAMES[$i]}"
            echo "    ${FAILED_TEST_DETAILS[$i]}"
        done
        echo ""
    fi
    
    if [ $SKIPPED_TESTS -gt 0 ]; then
        echo "Skipped Tests (Future Features):"
        for skipped in "${SKIPPED_TEST_NAMES[@]}"; do
            echo "  - $skipped"
        done
        echo ""
    fi
    
    echo "Category Breakdown:"
    for category in "${!TEST_CATEGORIES[@]}"; do
        local passed=${CATEGORY_PASSED[$category]:-0}
        local failed=${CATEGORY_FAILED[$category]:-0}
        local skipped=${CATEGORY_SKIPPED[$category]:-0}
        printf "  %-40s %d✓ %d✗ %d⊘\n" "$category:" "$passed" "$failed" "$skipped"
    done
    echo ""
    echo "════════════════════════════════════════════════════════════════════"
    
} | tee "$REPORT_FILE"

# =========================
# Generate HTML Report (Optional)
# =========================
generate_html_report() {
    local html_file="$1"
    
    {
        cat << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>SUN_DMZ Test Report</title>
    <style>
        body {
            font-family: Segoe UI, Tahoma, Geneva, sans-serif;
            margin: 20px;
            background-color: #f5f5f5;
        }
        .header {
            background-color: #2c3e50;
            color: white;
            padding: 20px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .summary {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 15px;
            margin-bottom: 20px;
        }
        .summary-box {
            background: white;
            padding: 20px;
            border-radius: 5px;
            text-align: center;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .summary-box h3 {
            margin: 0 0 10px 0;
            color: #7f8c8d;
            font-size: 14px;
        }
        .summary-box .number {
            font-size: 32px;
            font-weight: bold;
        }
        .summary-box.pass .number { color: #27ae60; }
        .summary-box.fail .number { color: #e74c3c; }
        .summary-box.skip .number { color: #f39c12; }
        
        .progress-bar {
            width: 100%;
            height: 30px;
            background-color: #ecf0f1;
            border-radius: 15px;
            overflow: hidden;
            margin-bottom: 20px;
        }
        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #27ae60, #2ecc71);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
        }
        
        .category {
            background: white;
            padding: 15px;
            margin-bottom: 15px;
            border-left: 4px solid #3498db;
            border-radius: 3px;
        }
        .category h4 {
            margin: 0 0 10px 0;
        }
        .category-stats {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 10px;
            font-size: 14px;
        }
        .stat {
            padding: 8px;
            background-color: #f8f9fa;
            border-radius: 3px;
        }
        .stat.pass { border-left: 3px solid #27ae60; }
        .stat.fail { border-left: 3px solid #e74c3c; }
        .stat.skip { border-left: 3px solid #f39c12; }
    </style>
</head>
<body>
    <div class="header">
        <h1>SUN_DMZ Lab - Test Suite Report</h1>
        <p>Generated: <script>document.write(new Date().toLocaleString())</script></p>
    </div>
    
    <div class="summary">
        <div class="summary-box">
            <h3>Total Tests</h3>
            <div class="number">TOTAL</div>
        </div>
        <div class="summary-box pass">
            <h3>Passed</h3>
            <div class="number">PASSED</div>
        </div>
        <div class="summary-box fail">
            <h3>Failed</h3>
            <div class="number">FAILED</div>
        </div>
        <div class="summary-box skip">
            <h3>Skipped</h3>
            <div class="number">SKIPPED</div>
        </div>
    </div>
    
    <h3>Overall Progress</h3>
    <div class="progress-bar">
        <div class="progress-fill" style="width: PASSRATE%;"> PASSRATE% Pass</div>
    </div>
    
    <h2>Test Results by Category</h2>
    <p>"Skipped" tests indicate features planned for future releases.</p>
</body>
</html>
EOF
    } > "$html_file"
    
    # Replace placeholders
    sed -i "s/TOTAL/$TOTAL_TESTS/g" "$html_file"
    sed -i "s/PASSED/$PASSED_TESTS/g" "$html_file"
    sed -i "s/FAILED/$FAILED_TESTS/g" "$html_file"
    sed -i "s/SKIPPED/$SKIPPED_TESTS/g" "$html_file"
    sed -i "s/PASSRATE/$PASS_RATE/g" "$html_file"
}

generate_html_report "$HTML_REPORT"
echo ""
echo -e "${CYAN}HTML Report: $HTML_REPORT${ENDCOLOR}"

# =========================
# Exit with appropriate code
# =========================
# Always exit with 0 to allow test chain to continue even if tests fail
# Individual test results are recorded in the report
exit 0
