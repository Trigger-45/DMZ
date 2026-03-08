#!/bin/bash
# Test Suite 03: Firewall Rules & Policies
# Tests firewall rule enforcement and iptables configuration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/test-utils.sh"

print_category "SECTION 3: Firewall Rules & Security Policies" \
    "Verifies firewall rules are correctly applied"

# =========================
# Firewall Configuration Checks
# =========================

print_category "SECTION 3.1: Firewall Basic Configuration" \
    "Checks firewall setup and default policies"

run_test "Firewall" "Internal_FW: IP Forwarding enabled" \
    "sudo docker exec clab-MaJuVi-Internal_FW cat /proc/sys/net/ipv4/ip_forward | grep -q '1'" 5

run_test "Firewall" "External_FW: IP Forwarding enabled" \
    "sudo docker exec clab-MaJuVi-External_FW cat /proc/sys/net/ipv4/ip_forward | grep -q '1'" 5

run_test "Firewall" "SIEM_FW: IP Forwarding enabled" \
    "sudo docker exec clab-MaJuVi-SIEM_FW cat /proc/sys/net/ipv4/ip_forward | grep -q '1'" 5

run_test "Firewall" "Internal_FW: Conntrack enabled" \
    "sudo docker exec clab-MaJuVi-Internal_FW cat /proc/sys/net/netfilter/nf_conntrack_max | grep -v '^0$' >/dev/null" 5

run_test "Firewall" "Internal_FW: Default INPUT policy is DROP" \
    "sudo docker exec clab-MaJuVi-Internal_FW iptables -L -n | grep -A 1 '^Chain INPUT' | grep -q 'DROP'" 5

run_test "Firewall" "Internal_FW: Default FORWARD policy is DROP" \
    "sudo docker exec clab-MaJuVi-Internal_FW iptables -L -n | grep -A 1 '^Chain FORWARD' | grep -q 'DROP'" 5

run_test "Firewall" "External_FW: Default FORWARD policy is DROP" \
    "sudo docker exec clab-MaJuVi-External_FW iptables -L -n | grep -A 1 '^Chain FORWARD' | grep -q 'DROP'" 5

# =========================
# NAT Rules
# =========================

print_category "SECTION 3.2: NAT (Network Address Translation)" \
    "Tests port forwarding and NAT configuration"

run_test "Firewall" "External_FW: DNAT rules configured" \
    "sudo docker exec clab-MaJuVi-External_FW iptables -t nat -L -n | grep -q 'DNAT'" 5

run_test "Firewall" "External_FW: SNAT rules configured" \
    "sudo docker exec clab-MaJuVi-External_FW iptables -t nat -L -n | grep -q 'SNAT'" 5

run_test "Firewall" "Internal_FW has SNAT for Internet traffic" \
    "sudo docker exec clab-MaJuVi-Internal_FW iptables -t nat -L -n | grep -q -i 'masquerade\\|snat'" 5

# =========================
# Stateful Firewall Tests
# =========================

print_category "SECTION 3.3: Stateful Connection Tracking" \
    "Tests ESTABLISHED/RELATED state handling"

run_test "Firewall" "Internal_FW: ESTABLISHED connections allowed" \
    "sudo docker exec clab-MaJuVi-Internal_FW iptables -L FORWARD -n | grep -q 'ESTABLISHED'" 5

run_test "Firewall" "Internal_FW: Return traffic allowed" \
    "sudo docker exec clab-MaJuVi-Internal_FW iptables -L FORWARD -n | grep -q 'RELATED.*ACCEPT'" 5

# =========================
# Specific Service Rules
# =========================

print_category "SECTION 3.4: Application-Specific Rules" \
    "Tests rules for specific services"

run_test "Firewall" "Port 8080 (Webserver) rule exists in Internal_FW" \
    "sudo docker exec clab-MaJuVi-Internal_FW iptables -L FORWARD -n | grep -q '8080'" 5

run_test "Firewall" "Port 5044 (Logstash) rule exists in related FW" \
    "sudo docker exec clab-MaJuVi-SIEM_FW iptables -L -n | grep -q '5044'" 5

run_test "Firewall" "Port 9200 (Elasticsearch) rule exists in SIEM_FW" \
    "sudo docker exec clab-MaJuVi-SIEM_FW iptables -L -n | grep -q '9200'" 5

# =========================
# Logging Rules
# =========================

print_category "SECTION 3.5: Firewall Event Logging" \
    "Tests NFLOG and logging rules"

run_test "Firewall" "Internal_FW: NFLOG rules configured" \
    "sudo docker exec clab-MaJuVi-Internal_FW iptables -L -n | grep -q 'NFLOG'" 5

run_test "Firewall" "External_FW: NFLOG rules configured" \
    "sudo docker exec clab-MaJuVi-External_FW iptables -L -n | grep -q 'NFLOG'" 5

run_test "Firewall" "Internal_FW: ulogd logging active" \
    "sudo docker exec clab-MaJuVi-Internal_FW ls -l /var/log/firewall/firewall-events.log >/dev/null 2>&1" 5

run_test "Firewall" "External_FW: ulogd logging active" \
    "sudo docker exec clab-MaJuVi-External_FW ls -l /var/log/firewall/firewall-events.log >/dev/null 2>&1" 5

# =========================
# SIEM Firewall (Logging & Aggregation)
# =========================

print_category "SECTION 3.6: SIEM Firewall Rules" \
    "Tests firewall rules for SIEM traffic"

run_test "Firewall" "SIEM_FW accepts Logstash beat input (5044)" \
    "sudo docker exec clab-MaJuVi-SIEM_FW iptables -L -n | grep -q '5044'" 5

run_test "Firewall" "SIEM_FW accepts Elasticsearch output (9200)" \
    "sudo docker exec clab-MaJuVi-SIEM_FW iptables -L -n | grep -q '9200'" 5

run_test "Firewall" "SIEM_FW accepts Kibana UI (5601)" \
    "sudo docker exec clab-MaJuVi-SIEM_FW iptables -L -n | grep -q '5601'" 5

# =========================
# Custom Chain Tests (Advanced)
# =========================

print_category "SECTION 3.7: Custom iptables Chains (Advanced)" \
    "Tests custom chains for rule organization"

run_test "Firewall" "Internal_FW: Custom LOG_INVALID chain exists" \
    "sudo docker exec clab-MaJuVi-Internal_FW iptables -L -n | grep -q 'LOG_INVALID'" 5
