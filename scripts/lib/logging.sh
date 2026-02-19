#!/bin/bash

# Terminal Colors
RED="\e[31m"
GREEN="\e[32m"
BLUE="\e[34m"
YELLOW="\e[33m"
CYAN="\e[36m"
MAGENTA="\e[35m"
BOLD="\e[1m"
ENDCOLOR="\e[0m"

# Timestamp
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Log functions
log_section() { 
    echo ""
    echo -e "${BOLD}${CYAN}========================================${ENDCOLOR}"
    echo -e "${BOLD}${CYAN}  $1${ENDCOLOR}"
    echo -e "${BOLD}${CYAN}========================================${ENDCOLOR}"
    echo ""
}

log_subsection() {
    echo -e "${MAGENTA}--- $1 ---${ENDCOLOR}"
}

log_info() { 
    echo -e "${BLUE}[$(get_timestamp)]${ENDCOLOR} ${BLUE}[ INFO ]${ENDCOLOR} $1"
}

log_ok() { 
    echo -e "${GREEN}[$(get_timestamp)]${ENDCOLOR} ${GREEN}[  OK  ]${ENDCOLOR} $1"
}

log_error() { 
    echo -e "${RED}[$(get_timestamp)]${ENDCOLOR} ${RED}[ ERROR ]${ENDCOLOR} $1"
}

log_warn() {
    echo -e "${YELLOW}[$(get_timestamp)]${ENDCOLOR} ${YELLOW}[ WARN ]${ENDCOLOR} $1"
}

log_step() {
    echo -e "${CYAN}[$(get_timestamp)]${ENDCOLOR} ${CYAN}[STEP $1]${ENDCOLOR} $2"
}