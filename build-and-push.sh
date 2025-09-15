#!/bin/bash

# Docker Hub configuration
DOCKER_USERNAME="sahuno"
DOCKER_IMAGE="sahuno/claude_gemini_container"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Docker Image Build and Push Script ===${NC}"
echo "Image: ${DOCKER_IMAGE}"
echo ""

# Check if logged in to Docker Hub
echo -e "${YELLOW}Checking Docker Hub login status...${NC}"
if ! docker info 2>/dev/null | grep -q "Username: ${DOCKER_USERNAME}"; then
    echo -e "${YELLOW}Not logged in to Docker Hub. Logging in...${NC}"
    docker login -u "${DOCKER_USERNAME}"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to login to Docker Hub${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}Already logged in to Docker Hub as ${DOCKER_USERNAME}${NC}"
fi

# Get current CLI versions
echo -e "${YELLOW}Fetching latest CLI versions...${NC}"
CLAUDE_VERSION=$(npm view @anthropic-ai/claude-code version 2>/dev/null)
GEMINI_VERSION=$(npm view @google/gemini-cli version 2>/dev/null)
BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
DATE_TAG=$(date +'%Y%m%d')

# Check if versions were fetched successfully
if [ -z "${CLAUDE_VERSION}" ]; then
    echo -e "${RED}Failed to fetch Claude Code version${NC}"
    exit 1
fi
if [ -z "${GEMINI_VERSION}" ]; then
    echo -e "${RED}Failed to fetch Gemini CLI version${NC}"
    exit 1
fi

echo "Claude Code version: ${CLAUDE_VERSION}"
echo "Gemini CLI version: ${GEMINI_VERSION}"
echo "Build date: ${BUILD_DATE}"
echo ""

# Setup Docker buildx for multi-platform builds
echo -e "${YELLOW}Setting up Docker buildx...${NC}"
if ! docker buildx ls | grep -q "claude-builder"; then
    docker buildx create --name claude-builder --use
    docker buildx inspect --bootstrap
else
    docker buildx use claude-builder
fi

# Build the Docker image (local platform only for testing)
echo -e "${YELLOW}Building Docker image for local platform...${NC}"
docker buildx build \
    --build-arg CLAUDE_VERSION="${CLAUDE_VERSION}" \
    --build-arg GEMINI_VERSION="${GEMINI_VERSION}" \
    --build-arg BUILD_DATE="${BUILD_DATE}" \
    --tag "${DOCKER_IMAGE}:latest" \
    --tag "${DOCKER_IMAGE}:v${CLAUDE_VERSION}_${DATE_TAG}" \
    --load \
    .

if [ $? -ne 0 ]; then
    echo -e "${RED}Docker build failed${NC}"
    exit 1
fi

echo -e "${GREEN}Docker image built successfully${NC}"
echo ""

# Show image size
echo -e "${GREEN}Image built. Size:${NC}"
docker images ${DOCKER_IMAGE}:latest --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}"
echo ""

# Test the image
echo -e "${YELLOW}Testing the built image...${NC}"
if docker run --rm ${DOCKER_IMAGE}:latest claude --version >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Claude Code is working${NC}"
else
    echo -e "${RED}✗ Claude Code test failed${NC}"
    exit 1
fi
if docker run --rm ${DOCKER_IMAGE}:latest python3 -c "import numpy, pandas, matplotlib" 2>/dev/null; then
    echo -e "${GREEN}✓ Python packages are working${NC}"
else
    echo -e "${RED}✗ Python packages test failed${NC}"
    exit 1
fi
echo ""

# Ask for confirmation before pushing
read -p "Do you want to push the image to Docker Hub? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Ask about platform build
    echo -e "${YELLOW}Select target platform(s):${NC}"
    echo "1) Linux AMD64 only (for HPC/servers)"
    echo "2) Linux ARM64 only (for ARM servers)"  
    echo "3) Both Linux platforms (AMD64 + ARM64)"
    read -p "Select [1-3] (default: 1): " -n 1 -r PLATFORM_CHOICE
    echo ""
    
    case "$PLATFORM_CHOICE" in
        2)
            PLATFORMS="--platform linux/arm64"
            echo -e "${YELLOW}Building for Linux ARM64...${NC}"
            ;;
        3)
            PLATFORMS="--platform linux/amd64,linux/arm64"
            echo -e "${YELLOW}Building for both Linux platforms...${NC}"
            ;;
        *)
            PLATFORMS="--platform linux/amd64"
            echo -e "${YELLOW}Building for Linux AMD64 (HPC)...${NC}"
            ;;
    esac
    
    # Build and push image
    docker buildx build \
        --build-arg CLAUDE_VERSION="${CLAUDE_VERSION}" \
        --build-arg GEMINI_VERSION="${GEMINI_VERSION}" \
        --build-arg BUILD_DATE="${BUILD_DATE}" \
        ${PLATFORMS} \
        --tag "${DOCKER_IMAGE}:latest" \
        --tag "${DOCKER_IMAGE}:v${CLAUDE_VERSION}_${DATE_TAG}" \
        --push \
        .
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to push image${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Image pushed successfully!${NC}"
    echo ""
    echo "Images pushed:"
    echo "  - ${DOCKER_IMAGE}:latest"
    echo "  - ${DOCKER_IMAGE}:v${CLAUDE_VERSION}_${DATE_TAG}"
else
    echo -e "${YELLOW}Push cancelled${NC}"
fi

echo ""
echo -e "${GREEN}=== Script Complete ===${NC}"