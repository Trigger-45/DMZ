#!/bin/bash
set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Load dependencies
source "${SCRIPT_DIR}/scripts/lib/logging.sh"
source "${SCRIPT_DIR}/config/variables.sh"

# Check if purge mode is requested
PURGE_MODE=false
if [[ "${1:-}" == "--purge" ]]; then
    PURGE_MODE=true
fi

# =========================
# Cleanup/Destroy
# =========================
if [ "$PURGE_MODE" = true ]; then
    log_section "Purging SUN_DMZ Lab (Complete Removal)"
else
    log_section "SECTION 1: Environment Cleanup"
fi

log_step "1/8" "Stopping all running ${LAB_NAME} containers..."
RUNNING=$(sudo docker ps -q --filter "name=clab-${LAB_NAME}" 2>/dev/null)
if [ -n "$RUNNING" ]; then
    echo "$RUNNING" | xargs -r sudo docker stop || true
    log_ok "Containers stopped"
else
    log_info "No running containers found"
fi

log_step "2/8" "Destroying containerlab topology..."
sudo containerlab destroy --topo "topology/${TOPO_FILE}" --cleanup 2>/dev/null || true
sudo containerlab destroy --all --cleanup 2>/dev/null || true
log_ok "Containerlab destroyed"

log_step "3/8" "Removing all ${LAB_NAME} containers..."
sudo docker ps -a --filter "name=clab-${LAB_NAME}" -q 2>/dev/null | xargs -r sudo docker rm -f || true
sudo docker container prune -f || true
log_ok "All containers removed"

log_step "4/8" "Removing containerlab networks..."
sudo docker network ls --filter "name=clab" -q 2>/dev/null | xargs -r sudo docker network rm || true
sudo docker network prune -f || true
log_ok "Networks removed"

log_step "5/8" "Cleaning up temporary files..."
rm -f "${SCRIPT_DIR}/topology/${TOPO_FILE}" 2>/dev/null || true
log_ok "Temporary files cleaned"

log_step "6/8" "Removing unused Docker volumes..."
sudo docker volume prune -f || true
log_ok "Unused volumes removed"

log_step "7/8" "Removing unused Docker images..."
sudo docker image prune -f || true
log_ok "Unused images removed"

# =========================
# Purge Mode: Remove ALL lab images
# =========================
if [ "$PURGE_MODE" = true ]; then
    log_step "8/8" "Removing all Docker images used by the lab..."
    
    IMAGES=(
        "${IMG_ALPINE}" "${IMG_UBUNTU}" "${IMG_DEBIAN}" "${IMG_FRR}"
        "${IMG_NGINX}" "${IMG_POSTGRES}" "${IMG_SURICATA}" "${IMG_KALI}"
        "${IMG_MODSECURITY}" "${IMG_ELASTICSEARCH}" "${IMG_LOGSTASH}" "${IMG_KIBANA}"
    )
    
    REMOVED=0
    for IMAGE in "${IMAGES[@]}"; do
        if sudo docker image inspect "${IMAGE}" &> /dev/null; then
            sudo docker rmi "${IMAGE}" &> /dev/null && REMOVED=$((REMOVED + 1)) || true
        fi
    done
    
    log_ok "Removed ${REMOVED}/${#IMAGES[@]} Docker images"
    
    # Clean logs
    rm -rf "${SCRIPT_DIR}/logs/"*.log 2>/dev/null || true
    
    log_section "Purge Complete!"
    sudo docker system df || true
else
    log_step "8/8" "Final cleanup..."
    sudo docker system prune -f || true
    log_ok "System pruned"
fi

echo ""
log_ok "Environment cleanup completed"