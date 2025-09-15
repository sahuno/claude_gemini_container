# Multi-stage build for Claude and Gemini Container with Python & Plotting
FROM node:20-slim AS base

# Build arguments to force cache invalidation when CLI versions change
ARG CLAUDE_VERSION=latest
ARG GEMINI_VERSION=latest
ARG BUILD_DATE

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    wget \
    vim \
    nano \
    # Process monitoring tools for Claude
    procps \
    # Python and scientific computing dependencies
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    # Libraries for plotting and visualization
    libfreetype6-dev \
    libpng-dev \
    libjpeg-dev \
    libopenblas-dev \
    liblapack-dev \
    gfortran \
    # Additional dependencies for matplotlib
    libxft-dev \
    libfreetype6 \
    libfontconfig1 \
    # Dependencies for Apptainer
    build-essential \
    libssl-dev \
    uuid-dev \
    libgpgme-dev \
    squashfs-tools \
    libseccomp-dev \
    pkg-config \
    cryptsetup \
    fuse \
    fuse2fs \
    libfuse3-3 \
    uidmap \
    # Clean up
    && rm -rf /var/lib/apt/lists/*

# Set up Python environment
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1

# Create virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python plotting and data science packages
RUN pip install --upgrade pip && \
    pip install \
    numpy \
    pandas \
    matplotlib \
    seaborn \
    plotly \
    scipy \
    scikit-learn \
    jupyter \
    ipython \
    markitdown

# Install Apptainer (formerly Singularity) - only for AMD64
# Note: Apptainer is primarily needed on HPC systems, not for local development
# ARM64 builds (e.g., Mac M1/M2) skip Apptainer installation
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "${ARCH}" = "amd64" ]; then \
        export APPTAINER_VERSION=1.3.5 && \
        echo "Installing Apptainer ${APPTAINER_VERSION} for amd64..." && \
        echo "Download URL: https://github.com/apptainer/apptainer/releases/download/v${APPTAINER_VERSION}/apptainer_${APPTAINER_VERSION}_amd64.deb" && \
        wget --tries=3 --timeout=60 --progress=dot:giga \
            https://github.com/apptainer/apptainer/releases/download/v${APPTAINER_VERSION}/apptainer_${APPTAINER_VERSION}_amd64.deb \
            || (echo "wget failed, trying curl..." && \
                curl -L --retry 3 --retry-delay 5 -o apptainer_${APPTAINER_VERSION}_amd64.deb \
                https://github.com/apptainer/apptainer/releases/download/v${APPTAINER_VERSION}/apptainer_${APPTAINER_VERSION}_amd64.deb) && \
        echo "Download complete. File size:" && \
        ls -lh apptainer_${APPTAINER_VERSION}_amd64.deb && \
        dpkg -i apptainer_${APPTAINER_VERSION}_amd64.deb && \
        rm -f apptainer_${APPTAINER_VERSION}_amd64.deb && \
        echo "Apptainer installation completed successfully"; \
    else \
        echo "Skipping Apptainer installation for ${ARCH} architecture"; \
        echo "Apptainer is primarily needed for HPC environments, not local Docker containers"; \
    fi

# Set up npm global directory
ENV NPM_CONFIG_PREFIX=/opt/npm-global
ENV PATH=$NPM_CONFIG_PREFIX/bin:$PATH
RUN mkdir -p $NPM_CONFIG_PREFIX

# Install Claude Code, Gemini CLI, and OpenAI Codex CLI
# Build args force cache invalidation when versions change
RUN echo "Installing AI CLI tools: Claude Code ${CLAUDE_VERSION}, Gemini CLI ${GEMINI_VERSION}, and OpenAI Codex" && \
    npm cache clean --force && \
    npm install -g @anthropic-ai/claude-code@latest @google/gemini-cli@latest @openai/codex@latest

# Create workspace directory
RUN mkdir -p /workspace
WORKDIR /workspace

# Create container info script
RUN echo '#!/bin/bash' > /usr/local/bin/container-info && \
    echo 'echo "=== AI CLI Container with Python ===="' >> /usr/local/bin/container-info && \
    echo 'echo "Available tools:"' >> /usr/local/bin/container-info && \
    echo 'echo "  - claude: Claude Code CLI"' >> /usr/local/bin/container-info && \
    echo 'echo "  - gemini: Gemini CLI"' >> /usr/local/bin/container-info && \
    echo 'echo "  - codex: OpenAI Codex CLI"' >> /usr/local/bin/container-info && \
    echo 'echo "  - python3: Python with data science libraries"' >> /usr/local/bin/container-info && \
    echo 'echo "  - jupyter: Jupyter notebook"' >> /usr/local/bin/container-info && \
    echo 'if command -v apptainer >/dev/null 2>&1; then echo "  - apptainer: Container runtime (v1.3.5)"; fi' >> /usr/local/bin/container-info && \
    echo 'echo ""' >> /usr/local/bin/container-info && \
    echo 'echo "Python packages installed:"' >> /usr/local/bin/container-info && \
    echo 'echo "  numpy, pandas, matplotlib, seaborn, plotly,"' >> /usr/local/bin/container-info && \
    echo 'echo "  scipy, scikit-learn, jupyter, ipython, markitdown"' >> /usr/local/bin/container-info && \
    echo 'echo ""' >> /usr/local/bin/container-info && \
    echo 'echo "Set environment variables:"' >> /usr/local/bin/container-info && \
    echo 'echo "  export ANTHROPIC_API_KEY=your_key_here"' >> /usr/local/bin/container-info && \
    echo 'echo "  export GEMINI_API_KEY=your_key_here"' >> /usr/local/bin/container-info && \
    echo 'echo "  export OPENAI_API_KEY=your_key_here (for Codex)"' >> /usr/local/bin/container-info && \
    echo 'echo "=============================================="' >> /usr/local/bin/container-info && \
    chmod +x /usr/local/bin/container-info

# Set environment for runtime
ENV NODE_ENV=production
ENV DEBIAN_FRONTEND=noninteractive

# Labels
LABEL maintainer="sahuno"
LABEL description="AI CLI tools container with Claude, Gemini, Codex, and Python capabilities"
LABEL version="1.0"
LABEL claude.version="${CLAUDE_VERSION}"
LABEL gemini.version="${GEMINI_VERSION}"
LABEL build.date="${BUILD_DATE}"

# Default command
CMD ["/bin/bash"]