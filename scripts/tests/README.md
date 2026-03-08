# SUN_DMZ Lab - Test Suite Documentation

Complete, modular test suite for the SUN_DMZ security lab environment.

## Overview

The test suite consists of multiple specialized test modules covering all aspects of the lab environment:

- **01-health.sh** - Container health and process verification
- **02-network.sh** - Network connectivity and routing
- **03-firewall.sh** - Firewall rules and policies
- **04-services.sh** - Service availability and functionality
- **05-siem.sh** - SIEM infrastructure and logging
- **06-security.sh** - Security controls and WAF
- **07-advanced.sh** - Advanced, integration, and future tests

## Quick Start

```bash
# Run all tests
cd scripts/tests
./run-all-tests.sh

# Or run the main test runner directly
./test-runner.sh

# Or run individual test suites
./01-health.sh
./05-siem.sh
```

## Test Organization

### Test Categories

Each test suite covers a specific area:

| Suite | Focus | Tests | Future Features |
|-------|-------|-------|-----------------|
| 01 Health | Container & process health | 20+ | Resource monitoring |
| 02 Network | Connectivity & routing | 15+ | DNS, IPv6 |
| 03 Firewall | Rules & policies | 25+ | DDoS, rate limiting |
| 04 Services | Web, DB, APIs | 30+ | Load balancing, caching |
| 05 SIEM | Event collection & storage | 35+ | Alerting, HA, tuning |
| 06 Security | WAF, intrusion detection | 30+ | Vulnerability scanning |
| 07 Advanced | Integration & performance | 20+ | Load testing, DR |

**Total: 175+ tests with 40+ future feature placeholders**

## Understanding Test Results

### Test States

- **PASS** (green) - Test executed successfully
- **FAIL** (red) - Test failed or condition not met
- **SKIP** (magenta) - Test marked for future implementation
- **TIMEOUT** (red) - Test exceeded timeout limit
- **WARN** (yellow) - Test passed but with warnings

### Example Output

```
  01 Internal_Client1 container running...                    [PASS]
  02 Internal_FW: Filebeat configured...                      [PASS]
  03 WAF blocks SQL injection (basic)...                      [FAIL]
  04 DNS service (optional)...                              [SKIP]
```

## Detailed Test Suite Descriptions

### Suite 01: Container Health & Availability (20 tests)

Verifies all containers are running and processes are active.

```bash
./01-health.sh
```

Tests:
- Container running checks (all 19 containers)
- Critical process verification (iptables, ulogd, filebeat, suricata)
- Service responsiveness (API endpoints)
- Resource health (memory, CPU)
- Network interface configuration

**Pass Rate Goal: 100%** (all containers must be running)

---

### Suite 02: Network Connectivity & Routing (20+ tests)

Tests IP routing, connectivity between zones, and network isolation.

```bash
./02-network.sh
```

Tests:
- Internal zone connectivity
- DMZ zone connectivity  
- Firewall routing
- Cross-zone routing
- Firewall blocking (negative tests)
- SIEM network isolation
- Network segmentation

**Future Features:**
- DNS resolution
- IPv6 support
- Service discovery

---

### Suite 03: Firewall Rules & Policies (25+ tests)

Validates firewall configuration and rule enforcement.

```bash
./03-firewall.sh
```

Tests:
- Basic firewall configuration (policies, IP forwarding)
- NAT rules (DNAT, SNAT)
- Stateful connection tracking
- Application-specific rules
- Event logging (NFLOG)
- Custom iptables chains

**Future Features:**
- Rate limiting
- DDoS protection
- Blacklist chains
- SYN flood protection

---

### Suite 04: Service Availability & Functionality (30+ tests)

Tests all application and infrastructure services.

```bash
./04-services.sh
```

Tests:
- Web application (Flask webserver on port 8080)
- Database (PostgreSQL)
- API endpoints
- WAF/Proxy
- Elasticsearch (port 9200)
- Logstash (ports 5044, 9600)
- Kibana (port 5601)
- Service interdependencies

**Future Features:**
- Session management
- Caching (Redis)
- Load balancing
- Database HA
- Metrics collection

---

### Suite 05: SIEM Infrastructure & Logging (35+ tests)

Tests the entire SIEM data pipeline.

```bash
./05-siem.sh
```

Tests:
- Filebeat log collection (4 sources)
- Firewall logging (ulogd2)
- IDS event generation (Suricata)
- Event processing pipeline (Filebeat -> Logstash -> Elasticsearch)
- Elasticsearch data storage
- Kibana visualization
- Log parsing & enrichment

**Future Features:**
- GeoIP enrichment
- Threat intelligence
- Alerting rules
- Email/Slack notifications
- Elasticsearch HA
- Backup/snapshots
- Performance monitoring

---

### Suite 06: Security Testing & Controls (30+ tests)

Tests security mechanisms and attack prevention.

```bash
./06-security.sh
```

Tests:
- WAF attack blocking (SQLi, XSS, path traversal, command injection)
- Network segmentation
- Access control lists (ACL)
- IDS/IPS detection
- Firewall logging & audit trail
- Traffic isolation (DMZ, Internet)

**Future Features:**
- TLS/HTTPS
- Attack detection testing
- Rate limiting
- Network scanning detection
- PCI-DSS compliance
- HIPAA/SOC2 checks
- Vulnerability scanning

---

### Suite 07: Advanced & Integration Tests (20+ tests)

Advanced scenarios, integration tests, and future features.

```bash
./07-advanced.sh
```

Tests:
- Performance and load characteristics
- Failover and redundancy
- Data integrity
- Network resilience
- Container orchestration (K8s ready)
- Incident response
- Compliance & audit
- Disaster recovery
- End-to-end integration

**Future Features:**
- Load testing (100+ concurrent requests)
- Kubernetes support
- Automated failover
- Forensic data collection
- DR procedures
- Prometheus metrics
- Grafana dashboards

## Test Utilities Library

All tests use common utilities from `lib/test-utils.sh`:

```bash
# Run a test
run_test "Category" "Test Name" "command to execute" [timeout]

# Skip a test with reason
skip_test "Category" "Test Name" "reason"

# Add a warning
add_warning "Test Name" "warning message"

# Helper functions
container_running "container-name"
container_exec_test "container-name" "command"
port_open "host" "port"
http_status "url"
json_contains "url" "json_key"
```

## Customization

### Adding New Tests

Create a new test file (e.g., `08-custom.sh`):

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/test-utils.sh"

print_category "SECTION 8: Custom Tests" "Test description"

run_test "Category" "Test name" "test command" 10

print_summary
print_final_result
```

Then add to `test-runner.sh`:

```bash
run_suite "$TESTS_DIR/08-custom.sh"
```

### Modifying Timeouts

Each test has a customizable timeout (default 10s):

```bash
run_test "Category" "Test name" "slow-command" 30  # 30 second timeout
```

### Skipping Categories

All `-skip` variants of tests can be enabled as features are implemented:

1. Rename `skip_test` calls to `run_test`
2. Implement the actual test command
3. Re-run the suite

## Reports

Test results are saved to `/scripts/tests/reports/`:

- `test-report-YYYYMMDD-HHMMSS.txt` - Text report
- `test-report-YYYYMMDD-HHMMSS.html` - HTML report (beta)

View reports:
```bash
cat scripts/tests/reports/test-report-*.txt
```

## Future Enhancements

### Planned Features

- [ ] Real-time dashboard during test execution
- [ ] Slack/email notifications for test failures  
- [ ] Trend analysis across multiple test runs
- [ ] Automatic issue generation from failures
- [ ] Performance baseline tracking
- [ ] Multi-environment testing
- [ ] Kubernetes-native tests
- [ ] Load testing module
- [ ] Chaos engineering tests
- [ ] Compliance automation

### Coming Test Suites

- `08-kubernetes.sh` - K8s deployment tests
- `09-performance.sh` - Load and stress testing
- `10-compliance.sh` - PCI-DSS, HIPAA, SOC2 checks
- `11-chaos.sh` - Chaos engineering tests

## Troubleshooting

### Tests Failing

1. Check container status: `docker ps`
2. View container logs: `docker logs <container-name>`
3. Run single test for debugging: `./01-health.sh 2>&1 | grep -A5 "FAIL"`

### Permission Denied

Make scripts executable:
```bash
chmod +x scripts/tests/*.sh
chmod +x scripts/tests/lib/*.sh
```

### Timeout Issues

Increase timeout for slow environments:
```bash
# In test file, change timeout parameter
run_test "Category" "Test" "command" 30  # increased from 10
```

## Contributing

To add new tests:

1. Identify the appropriate test suite
2. Add test using `run_test()` function
3. Update suite description in this README
4. Test locally: `./test-runner.sh`
5. Commit with clear message: "tests: add X functionality tests"

## License

Part of the SUN_DMZ security lab environment.

---

**Last Updated:** March 2026  
**Test Framework Version:** 1.0  
**Total Tests:** 175+  
**Future Features:** 40+
