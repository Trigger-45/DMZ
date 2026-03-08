#!/bin/bash
# Test Suite 02: Network Connectivity & Routing
# Tests IP routing, connectivity between zones, and network paths

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/test-utils.sh"

print_category "SECTION 2: Network Connectivity & Routing" \
    "Verifies network paths work correctly between zones"

# =========================
# Internal Zone Connectivity
# =========================

print_category "SECTION 2.1: Internal Zone (Private Network)" \
    "10.0.1.0/24"

run_test "Network" "Internal_Client1 -> Internal_FW gateway" \
    "sudo docker exec clab-MaJuVi-Internal_Client1 ping -c 2 -W 2 192.168.10.1 >/dev/null 2>&1" 8

run_test "Network" "Internal_Client2 -> Internal_FW gateway" \
    "sudo docker exec clab-MaJuVi-Internal_Client2 ping -c 2 -W 2 192.168.10.1 >/dev/null 2>&1" 8

run_test "Network" "Internal_Client1 <-> Internal_Client2" \
    "sudo docker exec clab-MaJuVi-Internal_Client1 ping -c 2 -W 2 192.168.10.20 >/dev/null 2>&1" 8

# =========================
# DMZ Zone Connectivity
# =========================

print_category "SECTION 2.2: DMZ Zone (Demilitarized Network)" \
    "10.0.2.0/24"

run_test "Network" "Proxy_WAF -> Webserver" \
    "sudo docker exec clab-MaJuVi-Proxy_WAF ping -c 2 -W 2 10.0.2.30 >/dev/null 2>&1" 8

run_test "Network" "Webserver -> Database" \
    "sudo docker exec clab-MaJuVi-Flask_Webserver ping -c 2 -W 2 10.0.2.70 >/dev/null 2>&1" 8

run_test "Network" "Webserver has correct IP (10.0.2.30)" \
    "sudo docker exec clab-MaJuVi-Flask_Webserver ip addr show | grep -q '10.0.2.30'" 5

# =========================
# Firewall-to-Zone Routing
# =========================

print_category "SECTION 2.3: Firewall Routing" \
    "Verifies firewall routing between zones"

run_test "Network" "Internal_FW can reach Internal subnet" \
    "sudo docker exec clab-MaJuVi-Internal_FW ping -c 2 -W 2 192.168.10.10 >/dev/null 2>&1" 8

run_test "Network" "Internal_FW can reach DMZ subnet" \
    "sudo docker exec clab-MaJuVi-Internal_FW ping -c 2 -W 2 10.0.2.30 >/dev/null 2>&1" 8

run_test "Network" "External_FW can reach Internet" \
    "sudo docker exec clab-MaJuVi-External_FW ping -c 2 -W 2 172.168.1.1 >/dev/null 2>&1" 8

# =========================
# Cross-Zone Connectivity (via Firewall)
# =========================

print_category "SECTION 2.4: Cross-Zone Routing (through Firewalls)" \
    "Tests routing through firewall policies"

run_test "Network" "Internal_Client -> Webserver (via Internal_FW)" \
    "sudo docker exec clab-MaJuVi-Internal_Client1 ping -c 2 -W 2 10.0.2.30 >/dev/null 2>&1" 8

run_test "Network" "Internal_Client -> Internet (via External_FW)" \
    "sudo docker exec clab-MaJuVi-Internal_Client1 ping -c 2 -W 2 172.168.2.1 >/dev/null 2>&1" 10

# =========================
# Firewall Block Tests (Negative Tests)
# =========================

print_category "SECTION 2.5: Firewall Traffic Blocking (Security Tests)" \
    "Verifies firewall blocks unauthorized traffic"

run_test "Network" "DMZ -> Internal BLOCKED" \
    "! sudo docker exec clab-MaJuVi-Proxy_WAF timeout 3 ping -c 1 -W 2 192.168.10.10 >/dev/null 2>&1" 5

run_test "Network" "Internet -> Internal BLOCKED" \
    "! sudo docker exec clab-MaJuVi-Attacker timeout 3 ping -c 1 -W 2 192.168.10.10 >/dev/null 2>&1" 5

run_test "Network" "Attacker -> Internal Network BLOCKED" \
    "! sudo docker exec clab-MaJuVi-Attacker timeout 3 ping -c 1 192.168.10.10 >/dev/null 2>&1" 5

# =========================
# SIEM Network Isolation
# =========================

print_category "SECTION 2.6: SIEM Network Isolation" \
    "10.0.3.0/24 - Tests SIEM components network"

run_test "Network" "Logstash can reach Elasticsearch" \
    "sudo docker exec clab-MaJuVi-logstash timeout 3 bash -c 'echo > /dev/tcp/172.20.20.3/9200' 2>/dev/null" 5

run_test "Network" "SIEM_PC can reach Kibana (port 5601)" \
    "sudo docker exec clab-MaJuVi-siem_pc timeout 3 bash -c 'echo > /dev/tcp/172.20.20.15/5601' 2>/dev/null" 5

run_test "Network" "Internal_FW can reach Logstash (port 5044)" \
    "sudo docker exec clab-MaJuVi-Internal_FW timeout 3 bash -c 'echo > /dev/tcp/172.20.20.16/5044' 2>/dev/null" 5

# =========================
# VLAN/Network Segmentation
# =========================

print_category "SECTION 2.7: Network Segmentation" \
    "Verifies proper network isolation"

run_test "Network" "Internal zone has isolated subnet" \
    "sudo docker exec clab-MaJuVi-Internal_Switch ip route show | grep -q '192.168.10.0/24'" 5

run_test "Network" "DMZ zone has isolated subnet" \
    "sudo docker exec clab-MaJuVi-DMZ_Switch ip route show | grep -q '10.0.2.0/24'" 5
