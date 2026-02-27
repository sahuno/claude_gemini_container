#!/bin/bash
# build-and-push.sh — local helper for building and pushing the AI CLI container.
# Mirrors the logic in .github/workflows/docker-build.yml for local development.
#
# Usage: ./build-and-push.sh

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
DOCKER_USERNAME="sahuno"
DOCKER_IMAGE="sahuno/claude_gemini_container"

# ── Colour helpers ─────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
die()     { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

echo -e "${GREEN}=== AI CLI Container — Build and Push ===${NC}"
echo "Image: ${DOCKER_IMAGE}"
echo ""

# ── Docker Hub login ──────────────────────────────────────────────────────────
info "Checking Docker Hub login status..."
if ! docker info 2>/dev/null | grep -q "Username: ${DOCKER_USERNAME}"; then
    warn "Not logged in. Logging in as ${DOCKER_USERNAME}..."
    docker login -u "${DOCKER_USERNAME}" || die "Docker Hub login failed."
else
    success "Already logged in as ${DOCKER_USERNAME}"
fi

# ── Fetch latest published versions ──────────────────────────────────────────
info "Fetching latest tool versions from npm and PyPI..."

CLAUDE_VERSION=$(npm view @anthropic-ai/claude-code version 2>/dev/null) || die "Failed to fetch Claude Code version."
GEMINI_VERSION=$(npm view @google/gemini-cli    version 2>/dev/null) || die "Failed to fetch Gemini CLI version."
CODEX_VERSION=$(npm view @openai/codex          version 2>/dev/null) || die "Failed to fetch OpenAI Codex version."
SNAKEMAKE_VERSION=$(python3 -c "
import json, urllib.request
data = json.load(urllib.request.urlopen('https://pypi.org/pypi/snakemake/json', timeout=30))
print(data['info']['version'])
" 2>/dev/null) || die "Failed to fetch Snakemake version."
NF_CORE_VERSION=$(python3 -c "
import json, urllib.request
data = json.load(urllib.request.urlopen('https://pypi.org/pypi/nf-core/json', timeout=30))
print(data['info']['version'])
" 2>/dev/null) || die "Failed to fetch nf-core version."

BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
DATE_TAG=$(date +'%Y%m%d')

echo ""
echo "  Claude Code  : ${CLAUDE_VERSION}"
echo "  Gemini CLI   : ${GEMINI_VERSION}"
echo "  OpenAI Codex : ${CODEX_VERSION}"
echo "  Snakemake    : ${SNAKEMAKE_VERSION}"
echo "  nf-core      : ${NF_CORE_VERSION}"
echo "  Build date   : ${BUILD_DATE}"
echo ""

# ── Docker Buildx setup ───────────────────────────────────────────────────────
info "Setting up Docker Buildx..."
if ! docker buildx ls | grep -q "claude-builder"; then
    docker buildx create --name claude-builder --use
    docker buildx inspect --bootstrap
else
    docker buildx use claude-builder
fi

# ── Build local test image (amd64 only, --load) ───────────────────────────────
# Loaded into the local Docker daemon so smoke tests can run against it.
info "Building local amd64 test image..."
docker buildx build \
    --build-arg CLAUDE_VERSION="${CLAUDE_VERSION}" \
    --build-arg GEMINI_VERSION="${GEMINI_VERSION}" \
    --build-arg CODEX_VERSION="${CODEX_VERSION}" \
    --build-arg SNAKEMAKE_VERSION="${SNAKEMAKE_VERSION}" \
    --build-arg NF_CORE_VERSION="${NF_CORE_VERSION}" \
    --build-arg BUILD_DATE="${BUILD_DATE}" \
    --tag "${DOCKER_IMAGE}:test" \
    --platform linux/amd64 \
    --load \
    . || die "Test image build failed."

success "Test image built: ${DOCKER_IMAGE}:test"
echo ""

# ── Smoke tests ───────────────────────────────────────────────────────────────
info "Running smoke tests..."
PASS=true

run_test() {
    local label="$1"; shift
    if "$@" > /dev/null 2>&1; then
        success "  ${label}"
    else
        echo -e "${RED}  [FAIL] ${label}${NC}"
        PASS=false
    fi
}

run_test "Claude Code version" \
    docker run --rm "${DOCKER_IMAGE}:test" claude --version

run_test "Gemini CLI binary present" \
    docker run --rm "${DOCKER_IMAGE}:test" which gemini

run_test "OpenAI Codex binary present" \
    docker run --rm "${DOCKER_IMAGE}:test" which codex

run_test "Python stack (numpy, pandas, matplotlib)" \
    docker run --rm "${DOCKER_IMAGE}:test" \
        python3 -c "import numpy, pandas, matplotlib, seaborn; print('OK')"

run_test "Snakemake version" \
    docker run --rm "${DOCKER_IMAGE}:test" snakemake --version

run_test "container-info script" \
    docker run --rm "${DOCKER_IMAGE}:test" container-info

if [ "${PASS}" = "false" ]; then
    die "One or more smoke tests failed. Fix the image before pushing."
fi
success "All smoke tests passed."
echo ""

# ── Push to Docker Hub ────────────────────────────────────────────────────────
read -p "Push image to Docker Hub? (y/N): " -n 1 -r
echo ""
if [[ ! "${REPLY}" =~ ^[Yy]$ ]]; then
    warn "Push cancelled."
    echo -e "${GREEN}=== Local build complete. Image available as ${DOCKER_IMAGE}:test ===${NC}"
    exit 0
fi

# Platform selection
echo ""
echo -e "${YELLOW}Select target platform(s):${NC}"
echo "  1) Linux AMD64 only  (HPC / servers) [default]"
echo "  2) Linux ARM64 only  (ARM servers)"
echo "  3) Both (AMD64 + ARM64)"
read -p "Select [1-3]: " -n 1 -r PLATFORM_CHOICE
echo ""

case "${PLATFORM_CHOICE}" in
    2) PLATFORMS="linux/arm64"        ; info "Building for ARM64..." ;;
    3) PLATFORMS="linux/amd64,linux/arm64" ; info "Building for AMD64 + ARM64..." ;;
    *) PLATFORMS="linux/amd64"        ; info "Building for AMD64 (default)..." ;;
esac

# Three tags mirroring the CI workflow:
#   :latest            — always the most recent image
#   :claude-X.Y.Z      — pinned to this Claude Code version
#   :YYYYMMDD          — date-pinned for reproducibility
info "Building and pushing multi-arch image..."
docker buildx build \
    --build-arg CLAUDE_VERSION="${CLAUDE_VERSION}" \
    --build-arg GEMINI_VERSION="${GEMINI_VERSION}" \
    --build-arg CODEX_VERSION="${CODEX_VERSION}" \
    --build-arg SNAKEMAKE_VERSION="${SNAKEMAKE_VERSION}" \
    --build-arg NF_CORE_VERSION="${NF_CORE_VERSION}" \
    --build-arg BUILD_DATE="${BUILD_DATE}" \
    --platform "${PLATFORMS}" \
    --tag "${DOCKER_IMAGE}:latest" \
    --tag "${DOCKER_IMAGE}:claude-${CLAUDE_VERSION}" \
    --tag "${DOCKER_IMAGE}:${DATE_TAG}" \
    --push \
    . || die "Multi-arch build/push failed."

echo ""
success "Images pushed:"
echo "  ${DOCKER_IMAGE}:latest"
echo "  ${DOCKER_IMAGE}:claude-${CLAUDE_VERSION}"
echo "  ${DOCKER_IMAGE}:${DATE_TAG}"
echo ""
echo -e "${GREEN}=== Done ===${NC}"
