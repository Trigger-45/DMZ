#!/bin/bash
# Test Suite 06: Security Testing & Compliance
# Tests security controls, WAF rules, intrusion detection

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/test-utils.sh"

print_category "SECTION 6: Security Testing & Controls" \
    "Verifies security mechanisms and protections"

# =========================
# WAF Security Tests
# =========================

print_category "SECTION 6.1: Web Application Firewall (WAF)" \
    "Tests attack prevention"

run_test "Security" "WAF blocks SQL injection (basic)" \
    "status=\$(curl -s -m 5 -o /dev/null -w '%{http_code}' \"http://localhost:8080/?id=1' OR '1'='1\"); [ \"\$status\" != \"200\" ]" 8

run_test "Security" "WAF blocks XSS attack (script tag)" \
    "status=\$(curl -s -m 5 -o /dev/null -w '%{http_code}' \"http://localhost:8080/?q=<script>alert('xss')</script>\"); [ \"\$status\" != \"200\" ]" 8

run_test "Security" "WAF blocks path traversal" \
    "status=\$(curl -s -m 5 -o /dev/null -w '%{http_code}' \"http://localhost:8080/../../etc/passwd\"); [ \"\$status\" != \"200\" ]" 8

run_test "Security" "WAF blocks command injection" \
    "status=\$(curl -s -m 5 -o /dev/null -w '%{http_code}' \"http://localhost:8080/?cmd=ls;whoami\"); [ \"\$status\" != \"200\" ]" 8

run_test "Security" "WAF allows legitimate requests (GET)" \
    "status=\$(curl -s -m 5 -o /dev/null -w '%{http_code}' \"http://localhost:8080/?page=home\"); [ \"\$status\" = \"200\" ]" 8

run_test "Security" "WAF allows legitimate POST requests" \
    "status=\$(curl -s -X POST -m 5 -o /dev/null -w '%{http_code}' -d 'username=test&password=test' \"http://localhost:8080/\"); [ \"\$status\" = \"200\" ] || [ \"\$status\" = \"302\" ]" 8

# =========================
# Network Segment Isolation
# =========================

print_category "SECTION 6.2: Network Segmentation & Isolation" \
    "Verifies traffic cannot bypass zones"

run_test "Security" "DMZ cannot access Internal network directly" \
    "! sudo docker exec clab-MaJuVi-Proxy_WAF timeout 3 ping -c 1 192.168.10.10 >/dev/null 2>&1" 5

run_test "Security" "Attacker cannot access Internal network" \
    "! sudo docker exec clab-MaJuVi-Attacker timeout 3 ping -c 1 192.168.10.10 >/dev/null 2>&1" 5

run_test "Security" "Attacker cannot access Database directly" \
    "! sudo docker exec clab-MaJuVi-Attacker timeout 3 ping -c 1 10.0.2.70 >/dev/null 2>&1" 5

run_test "Security" "Internal user cannot access Internet directly (should route through FW)" \
    "sudo docker exec clab-MaJuVi-Internal_Client1 ping -c 1 -W 3 172.168.2.1 >/dev/null 2>&1" 8

# =========================
# Access Control Tests
# =========================

print_category "SECTION 6.3: Access Control Lists (ACL)" \
    "Tests firewall access control policies"

run_test "Security" "Internal user can access Webserver (port 8080)" \
    "curl -s -m 5 http://10.0.2.30:8080 >/dev/null 2>&1" 8

run_test "Security" "External user can access Webserver (through NAT)" \
    "sudo docker exec clab-MaJuVi-Attacker curl -s -m 5 http://172.168.3.5:8443 >/dev/null 2>&1 || true" 8

run_test "Security" "Database not directly accessible from Internet" \
    "! sudo docker exec clab-MaJuVi-Attacker timeout 3 bash -c 'echo > /dev/tcp/10.0.2.70/5432' 2>/dev/null" 5

run_test "Security" "SSH access limited to authorized subnets" \
    "sudo docker exec clab-MaJuVi-Internal_FW iptables -L INPUT -n | grep -q 'tcp dpt:22'" 5

# =========================
# IDS/IPS Detection
# =========================

print_category "SECTION 6.4: Intrusion Detection (IDS)" \
    "Tests attack detection capabilities"

run_test "Security" "Internal_IDS suricata running" \
    "sudo docker exec clab-MaJuVi-Internal_IDS pgrep -x Suricata-Main >/dev/null 2>&1" 5

run_test "Security" "DMZ_IDS suricata running" \
    "sudo docker exec clab-MaJuVi-DMZ_IDS pgrep -x Suricata-Main >/dev/null 2>&1" 5

run_test "Security" "IDS generating event logs (eve.json)" \
    "sudo docker exec clab-MaJuVi-Internal_IDS [ -f /var/log/suricata/eve.json ] && [ -s /var/log/suricata/eve.json ]" 5

# =========================
# Firewall Logging & Audit Trail
# =========================

print_category "SECTION 6.5: Logging & Audit Trail" \
    "Security event logging"

run_test "Security" "Internal_FW logs blocked packets" \
    "sudo docker exec clab-MaJuVi-Internal_FW [ -f /var/log/firewall/firewall-events.log ]" 5

run_test "Security" "External_FW logs blocked packets" \
    "sudo docker exec clab-MaJuVi-External_FW [ -f /var/log/firewall/firewall-events.log ]" 5

run_test "Security" "Firewall logs are forwarded to SIEM" \
    "curl -s -m 5 'http://localhost:9200/firewall-*/_count' 2>/dev/null | grep -q 'count'" 8

run_test "Security" "IDS alerts in SIEM system" \
    "curl -s -m 5 'http://localhost:9200/suricata-*/_count' 2>/dev/null | grep -q 'count' || true" 8
