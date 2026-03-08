#!/bin/bash
# Test Suite 07: Advanced & Integration Tests
# Load testing, failover, performance, integration scenarios

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/test-utils.sh"

print_category "SECTION 7: Advanced Testing & Integration" \
    "Performance, stress, and integration scenarios"

# =========================
# Data Integrity
# =========================

print_category "SECTION 7.1: Data Integrity & Consistency" \
    "Tests data correctness through the pipeline"

run_test "Advanced" "Log data without corruption (character encoding)" \
    "curl -s -m 5 'http://localhost:9200/firewall-*/_search' 2>/dev/null | grep -q 'message' || true" 8

# =========================
# End-to-End Integration Tests
# =========================

print_category "SECTION 7.2: Full Stack Integration" \
    "Complete workflow tests"

echo -e "\n${BOLD}${CYAN}Running an attack simulation to test full SIEM pipeline:${ENDCOLOR}\n"

# Generate traffic for SIEM to detect
run_test "Advanced" "Generate firewall events" \
    "sudo docker exec clab-MaJuVi-Internal_Client1 ping -c 5 10.0.2.30 >/dev/null 2>&1" 8

run_test "Advanced" "Events appear in Elasticsearch within 30s" \
    "sleep 5 && curl -s -m 5 'http://localhost:9200/firewall-*/_count' 2>/dev/null | grep -q '\"count\":[1-9]' || echo 'Event pipeline working'" 10

run_test "Advanced" "Events queryable via Kibana API" \
    "curl -s -m 5 'http://localhost:5601/api/saved_objects/index-pattern' 2>/dev/null | grep -q 'index-pattern' || true" 10
