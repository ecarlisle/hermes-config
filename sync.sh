#!/usr/bin/env bash

set -euo pipefail

# ── Environment Boundaries ───────────────────────────────────────────
HERMES_HOME="${HOME}/.hermes"
REPO_CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/config"

# ── Dynamic Colorization Styles ──────────────────────────────────────
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

# ── Core Command-Line Help Roster ────────────────────────────────────
usage() {
    echo -e "${CYAN}Hermes Dotfiles Sync Framework${NC}"
    echo "Usage: $0 [pull|push]"
    echo "  pull : Pull live files FROM ~/.hermes/ into this repository"
    echo "  push : Push repository files INTO live ~/.hermes/ environment"
    exit 1
}

if [ $# -ne 1 ]; then
    usage
fi

ACTION="$1"

# ── Safety Assertions ────────────────────────────────────────────────
if [ ! -d "$HERMES_HOME" ]; then
    echo -e "${RED}Error:${NC} Target Hermes core at ${HERMES_HOME} does not exist."
    exit 1
fi

# ── Execution Logic ──────────────────────────────────────────────────
case "$ACTION" in
    pull)
        echo -e "${YELLOW}🔍 PREVIEW: Pulling changes FROM ~/.hermes/ INTO this repository...${NC}"
        
        # Phase A: Dry Run Mirroring Logs
        rsync -avun --delete \
            --include='/config.yaml' \
            --include='/SOUL.md' \
            --include='/memories/' \
            --include='/memories/USER.md' \
            --include='/memories/MEMORY.md' \
            --include='/skills/***' \
            --exclude='*' \
            "$HERMES_HOME/" "$REPO_CONFIG_DIR/"

        read -p "Execute pull into repository? (y/N): " -r CONFIRM
        if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
            mkdir -p "$REPO_CONFIG_DIR"
            rsync -avu --delete \
                --include='/config.yaml' \
                --include='/SOUL.md' \
                --include='/memories/' \
                --include='/memories/USER.md' \
                --include='/memories/MEMORY.md' \
                --include='/skills/***' \
                --exclude='*' \
                "$HERMES_HOME/" "$REPO_CONFIG_DIR/"
            echo -e "${GREEN}✓ Repository configuration matrix updated cleanly from system!${NC}"
        else
            echo -e "${RED}Pull sync canceled.${NC}"
        fi
        ;;

    push)
        echo -e "${RED}⚠️ WARNING: Pushing repository state to overwrite live ~/.hermes/ settings!${NC}"
        
        # Phase B: Dry Run Installation Mirror Logs
        rsync -avun \
            "$REPO_CONFIG_DIR/" "$HERMES_HOME/"

        read -p "Push repository configuration over live system? (y/N): " -r CONFIRM
        if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
            rsync -avu \
                "$REPO_CONFIG_DIR/" "$HERMES_HOME/"
            echo -e "${GREEN}✓ Live system state refreshed from repo! Remember to cycle your gateway daemon.${NC}"
        else
            echo -e "${RED}Push sync canceled.${NC}"
        fi
        ;;

    *)
        usage
        ;;
esac
