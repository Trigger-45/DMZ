#!/bin/bash
# Test Suite 04: Service Availability & Functionality
# Tests web services, database, application endpoints

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/test-utils.sh"

print_category "SECTION 4: Service Availability & Functionality" \
    "Tests all application services"

# =========================
# Web Application (Webserver)
# =========================

print_category "SECTION 4.1: Web Application (Flask Webserver)" \
    "10.0.2.30:8080"

run_test "Services" "Webserver responds on port 8080" \
    "curl -s -m 5 http://localhost:8080 >/dev/null 2>&1" 8

run_test "Services" "Webserver returns HTTP 200" \
    "[ \"\$(curl -s -m 5 -o /dev/null -w '%{http_code}' http://localhost:8080)\" = \"200\" ]" 8

run_test "Services" "Webserver login page accessible" \
    "curl -s -m 5 http://localhost:8080 | grep -q -i 'login'" 8

run_test "Services" "Webserver serves CSS/JavaScript" \
    "curl -s -m 5 http://localhost:8080 | grep -q -i '<script\\|<link'" 8

# =========================
# Database Services
# =========================

print_category "SECTION 4.2: Database Services" \
    "PostgreSQL database connectivity"

run_test "Services" "Database PostgreSQL is accepting connections" \
    "sudo docker exec clab-MaJuVi-Database pg_isready -U admin_user >/dev/null 2>&1" 5

run_test "Services" "Database has required tables" \
    "sudo docker exec clab-MaJuVi-Database psql -U admin_user -d admin_db -c '\\dt' 2>/dev/null | grep -q -E 'users|accounts'" 5

run_test "Services" "Database can be queried" \
    "sudo docker exec clab-MaJuVi-Database psql -U admin_user -d admin_db -c 'SELECT 1' 2>/dev/null | grep -q '^.*1'" 5

# =========================
# API Endpoints
# =========================

print_category "SECTION 4.3: API Endpoints" \
    "Tests REST API functionality"

run_test "Services" "Webserver /api/status endpoint exists" \
    "curl -s -m 5 http://localhost:8080/api/status 2>/dev/null | grep -q -i '\"status\"'" 8

run_test "Services" "Webserver /api/health endpoint responds" \
    "[ \"\$(curl -s -m 5 -o /dev/null -w '%{http_code}' http://localhost:8080/api/health)\" = \"200\" ]" 8

# =========================
# WAF / Proxy
# =========================

print_category "SECTION 4.4: WAF / Proxy Services" \
    "10.0.2.10:8080 - Proxy_WAF"

run_test "Services" "WAF responds on port 8080" \
    "curl -s -m 5 -L http://localhost:8080 >/dev/null 2>&1" 8

run_test "Services" "WAF passes through valid requests" \
    "curl -s -m 5 http://localhost:8080 | grep -q -i 'login'" 8

run_test "Services" "WAF blocks SQLi attempts (403)" \
    "status=\$(curl -s -m 5 -o /dev/null -w '%{http_code}' \"http://localhost:8080/?id=1' or '1'='1\"); [ \"\$status\" = \"403\" ] || [ \"\$status\" = \"400\" ]" 8

run_test "Services" "WAF blocks XSS attempts" \
    "status=\$(curl -s -m 5 -o /dev/null -w '%{http_code}' \"http://localhost:8080/?search=<script>alert('xss')</script>\"); [ \"\$status\" = \"403\" ] || [ \"\$status\" = \"400\" ] || [ \"\$status\" != \"200\" ]" 8

# =========================
# SIEM Services - Elasticsearch
# =========================

print_category "SECTION 4.5: Elasticsearch - Search & Analytics" \
    "Port 9200"

run_test "Services" "Elasticsearch cluster is healthy" \
    "curl -s -m 5 http://localhost:9200/_cluster/health 2>/dev/null | grep -q '\"status\":\"green\"\\|\"status\":\"yellow\"'" 8

run_test "Services" "Elasticsearch API responds" \
    "curl -s -m 5 http://localhost:9200 2>/dev/null | grep -q 'tagline'" 8

run_test "Services" "Elasticsearch indices created" \
    "curl -s -m 5 http://localhost:9200/_cat/indices 2>/dev/null | grep -q -E 'firewall|suricata|logstash'" 10

run_test "Services" "Elasticsearch firewall index exists" \
    "curl -s -m 5 http://localhost:9200/_cat/indices 2>/dev/null | grep -q 'firewall-'" 8

run_test "Services" "Elasticsearch has documents" \
    "curl -s -m 5 http://localhost:9200/_cat/indices 2>/dev/null | awk '{print \$7}' | tail -1 | grep -q '[0-9]'" 8

# =========================
# SIEM Services - Logstash
# =========================

print_category "SECTION 4.6: Logstash - Data Pipeline" \
    "Port 5044 (Beats), 9600 (API)"

run_test "Services" "Logstash beats port listening" \
    "sudo docker exec clab-MaJuVi-logstash timeout 2 bash -c 'echo > /dev/tcp/127.0.0.1/5044' 2>/dev/null" 5

run_test "Services" "Logstash API responding" \
    "curl -s -m 5 http://localhost:9600 2>/dev/null | grep -q 'host'" 8

run_test "Services" "Logstash pipeline active" \
    "curl -s -m 5 http://localhost:9600/api/node/stats/pipeline 2>/dev/null | grep -q 'pipeline'" 8

run_test "Services" "Logstash connected to Elasticsearch" \
    "sudo docker logs clab-MaJuVi-logstash 2>&1 | grep -i 'connected to es\|elasticsearch' | tail -1 | grep -q 'Connected'" 5

# =========================
# SIEM Services - Kibana
# =========================

print_category "SECTION 4.7: Kibana - Visualization & Dashboards" \
    "Port 5601"

run_test "Services" "Kibana Web UI responding" \
    "curl -s -m 5 http://localhost:5601 >/dev/null 2>&1" 8

run_test "Services" "Kibana API status endpoint" \
    "curl -s -m 5 http://localhost:5601/api/status 2>/dev/null | grep -q 'state\\|version'" 10

run_test "Services" "Kibana page status is green" \
    "curl -s -m 5 http://localhost:5601/api/status 2>/dev/null | grep -q 'green'" 10

# =========================
# Service Dependencies
# =========================

print_category "SECTION 4.8: Service Interdependencies" \
    "Verifies services can communicate"

run_test "Services" "Webserver connects to Database" \
    "sudo docker exec clab-MaJuVi-Flask_Webserver timeout 5 bash -c 'echo > /dev/tcp/10.0.2.70/5432' 2>/dev/null" 5

run_test "Services" "Logstash connects to Elasticsearch" \
    "sudo docker exec clab-MaJuVi-logstash timeout 5 bash -c 'echo > /dev/tcp/172.20.20.3/9200' 2>/dev/null" 5

run_test "Services" "Kibana connects to Elasticsearch" \
    "sudo docker exec clab-MaJuVi-kibana timeout 5 bash -c 'echo > /dev/tcp/172.20.20.3/9200' 2>/dev/null" 5
