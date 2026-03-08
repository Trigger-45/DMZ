#!/bin/bash
# Quick Start - Run Full Test Suite
# This script runs all tests and opens the report
# Tests will continue even if some fail - all results collected in report

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🧪 Starting SUN_DMZ Full Test Suite..."
echo ""

# Make all scripts executable
chmod +x "$SCRIPT_DIR"/*.sh
chmod +x "$SCRIPT_DIR/lib"/*.sh

# Run main test runner (don't exit on failure)
if ! "$SCRIPT_DIR/test-runner.sh"; then
    echo ""
    echo -e "\033[33m⚠️  Some tests failed. Continuing to generate report...\033[0m"
    echo ""
fi

# Open report if available (on Linux with xdg-open)
LATEST_REPORT=$(ls -t "$SCRIPT_DIR/reports"/*.txt 2>/dev/null | head -1)
if [ -n "$LATEST_REPORT" ]; then
    echo ""
    echo "📋 Latest Report: $LATEST_REPORT"
    echo ""
    echo "Run the following to view:"
    echo "  cat $LATEST_REPORT"
fi
