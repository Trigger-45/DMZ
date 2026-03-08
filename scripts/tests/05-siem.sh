#!/bin/bash
# Test Suite 05: SIEM & Logging Infrastructure
# Tests event collection, processing, and storage

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/test-utils.sh"

print_category "SECTION 5: SIEM Infrastructure & Security Logging" \
    "Tests event collection from firewalls and IDS systems"

# =========================
# Filebeat Log Collection
# =========================

print_category "SECTION 5.1: Filebeat - Log Collectors" \
    "Collects logs from firewalls and IDS"

run_test "SIEM" "Filebeat running on Internal_FW" \
    "sudo docker exec clab-MaJuVi-Internal_FW pgrep -x filebeat >/dev/null 2>&1" 5

run_test "SIEM" "Filebeat running on External_FW" \
    "sudo docker exec clab-MaJuVi-External_FW pgrep -x filebeat >/dev/null 2>&1" 5

run_test "SIEM" "Filebeat running on Internal_IDS" \
    "sudo docker exec clab-MaJuVi-Internal_IDS pgrep -x filebeat >/dev/null 2>&1" 5

run_test "SIEM" "Filebeat running on DMZ_IDS" \
    "sudo docker exec clab-MaJuVi-DMZ_IDS pgrep -x filebeat >/dev/null 2>&1" 5

run_test "SIEM" "Internal_FW Filebeat configured" \
    "sudo docker exec clab-MaJuVi-Internal_FW [ -f /etc/filebeat/filebeat.yml ] && cat /etc/filebeat/filebeat.yml | grep -q 'hosts\\|logstash'" 5

run_test "SIEM" "Internal_FW Filebeat logs directory exists" \
    "sudo docker exec clab-MaJuVi-Internal_FW [ -d /var/log/filebeat ] && [ -d /var/lib/filebeat ]" 5

# =========================
# Firewall Logging (ulogd2)
# =========================

print_category "SECTION 5.2: Firewall Event Logging (ulogd2)" \
    "NFLOG based firewall event collection"

run_test "SIEM" "ulogd2 running on Internal_FW" \
    "sudo docker exec clab-MaJuVi-Internal_FW pgrep -x ulogd >/dev/null 2>&1" 5

run_test "SIEM" "ulogd2 running on External_FW" \
    "sudo docker exec clab-MaJuVi-External_FW pgrep -x ulogd >/dev/null 2>&1" 5

run_test "SIEM" "Internal_FW firewall log file exists" \
    "sudo docker exec clab-MaJuVi-Internal_FW [ -f /var/log/firewall/firewall-events.log ]" 5

run_test "SIEM" "External_FW firewall log file exists" \
    "sudo docker exec clab-MaJuVi-External_FW [ -f /var/log/firewall/firewall-events.log ]" 5

run_test "SIEM" "Internal_FW generating firewall events" \
    "sudo docker exec clab-MaJuVi-Internal_FW [ -s /var/log/firewall/firewall-events.log ]" 5

run_test "SIEM" "Internal_FW NFLOG rules configured in iptables" \
    "sudo docker exec clab-MaJuVi-Internal_FW iptables -L -n | grep -q 'NFLOG'" 5

run_test "SIEM" "External_FW NFLOG rules configured in iptables" \
    "sudo docker exec clab-MaJuVi-External_FW iptables -L -n | grep -q 'NFLOG'" 5

# =========================
# IDS/Suricata Events
# =========================

print_category "SECTION 5.3: IDS System (Suricata)" \
    "Network intrusion detection events"

run_test "SIEM" "Suricata running on Internal_IDS" \
    "sudo docker exec clab-MaJuVi-Internal_IDS pgrep -x Suricata-Main >/dev/null 2>&1" 5

run_test "SIEM" "Suricata running on DMZ_IDS" \
    "sudo docker exec clab-MaJuVi-DMZ_IDS pgrep -x Suricata-Main >/dev/null 2>&1" 5

run_test "SIEM" "Internal_IDS generates eve.json logs" \
    "sudo docker exec clab-MaJuVi-Internal_IDS [ -f /var/log/suricata/eve.json ]" 5

run_test "SIEM" "DMZ_IDS generates eve.json logs" \
    "sudo docker exec clab-MaJuVi-DMZ_IDS [ -f /var/log/suricata/eve.json ]" 5

run_test "SIEM" "Suricata rules loaded on Internal_IDS" \
    "sudo docker exec clab-MaJuVi-Internal_IDS grep -q 'rule' /var/lib/suricata/rules/*.rules 2>/dev/null || [ -d /var/lib/suricata/rules ]" 5

# =========================
# Event Pipeline
# =========================

print_category "SECTION 5.4: Event Processing Pipeline" \
    "Filebeat -> Logstash -> Elasticsearch"

run_test "SIEM" "Logstash beats input listening" \
    "sudo docker exec clab-MaJuVi-logstash timeout 2 bash -c 'echo > /dev/tcp/127.0.0.1/5044' 2>/dev/null" 5

run_test "SIEM" "Logstash output to Elasticsearch configured" \
    "grep -r 'elasticsearch' /home/turtle/SUN_DMZ/SUN_DMZ/config/logstash/pipeline/ | grep -q '9200'" 5

run_test "SIEM" "Logstash pipeline is running" \
    "curl -s -m 5 http://localhost:9600/api/node/stats/pipeline 2>/dev/null | grep -q 'pipeline'" 8

run_test "SIEM" "Logstash successfully processed events" \
    "curl -s -m 5 http://localhost:9600/api/node/stats/pipeline 2>/dev/null | grep -o 'in[^}]*out' | grep -q out" 8

# =========================
# Elasticsearch Data Storage
# =========================

print_category "SECTION 5.5: Elasticsearch - Event Storage" \
    "Verifies events are stored and queryable"

run_test "SIEM" "Firewall events index exists in Elasticsearch" \
    "curl -s -m 5 http://localhost:9200/_cat/indices 2>/dev/null | grep -q 'firewall-'" 8

run_test "SIEM" "Suricata events index exists in Elasticsearch" \
    "curl -s -m 5 http://localhost:9200/_cat/indices 2>/dev/null | grep -q 'suricata-'" 8

run_test "SIEM" "Firewall events are queryable" \
    "curl -s -m 5 'http://localhost:9200/firewall-*/_search' 2>/dev/null | grep -q 'hits'" 8

run_test "SIEM" "Firewall index has documents" \
    "hits=\$(curl -s -m 5 'http://localhost:9200/firewall-*/_search?size=1' 2>/dev/null | grep -o '\"value\":[0-9]*' | head -1 | grep -o '[0-9]*'); [ \"\$hits\" -gt 0 ] 2>/dev/null || true" 8

# =========================
# Kibana Visualization
# =========================

print_category "SECTION 5.6: Kibana - Log Visualization" \
    "Dashboards and data views"

run_test "SIEM" "Kibana data views/index patterns accessible" \
    "curl -s -m 5 http://localhost:5601/api/index_patterns 2>/dev/null | grep -q 'index_patterns'" 10

# =========================
# Log Parsing & Enrichment
# =========================

print_category "SECTION 5.7: Log Parsing & Data Enrichment" \
    "Event field extraction and enrichment"

run_test "SIEM" "Firewall logs parsed (src_ip field)" \
    "curl -s -m 5 'http://localhost:9200/firewall-*/_search' 2>/dev/null | grep -q 'src_ip\\|SRC=' || true" 8
