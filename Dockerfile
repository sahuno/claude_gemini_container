# Multi-stage build for Claude and Gemini Container with Python & Plotting
FROM node:20-slim AS base

# Build arguments to force cache invalidation when CLI versions change
ARG CLAUDE_VERSION=1.0.113
ARG GEMINI_VERSION=0.4.1
ARG BUILD_DATE
ARG SNAKEMAKE_VERSION=9.11.2
ARG NF_CORE_VERSION=3.0.0
ARG NEXTFLOW_VERSION=24.10.3
ARG DEBIAN_FRONTEND=noninteractive
ENV DEBIAN_FRONTEND=${DEBIAN_FRONTEND}

# Install system dependencies required for the AI CLIs, plotting stack, and Apptainer on HPCs
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    wget \
    vim \
    nano \
    procps \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    libfreetype6-dev \
    libpng-dev \
    libjpeg-dev \
    libopenblas-dev \
    liblapack-dev \
    gfortran \
    libxft-dev \
    libfreetype6 \
    libfontconfig1 \
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
    # Java 17 for Nextflow (required as of v24.11.0)
    openjdk-17-jre-headless \
    # Additional deps for Snakemake
    rsync \
    && rm -rf /var/lib/apt/lists/*

# Set up Python environment
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1

# Create virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python plotting, data science, and bioinformatics workflow packages
RUN python -m pip install --upgrade pip && \
    python -m pip install --disable-pip-version-check \
    numpy \
    pandas \
    matplotlib \
    seaborn \
    plotly \
    scipy \
    scikit-learn \
    jupyter \
    ipython \
    markitdown \
    snakemake==${SNAKEMAKE_VERSION} \
    nf-core==${NF_CORE_VERSION}

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
            -O /tmp/apptainer_${APPTAINER_VERSION}_amd64.deb \
            || (echo "wget failed, trying curl..." && \
                curl -L --retry 3 --retry-delay 5 -o /tmp/apptainer_${APPTAINER_VERSION}_amd64.deb \
                https://github.com/apptainer/apptainer/releases/download/v${APPTAINER_VERSION}/apptainer_${APPTAINER_VERSION}_amd64.deb) && \
        echo "Download complete. File size:" && \
        ls -lh /tmp/apptainer_${APPTAINER_VERSION}_amd64.deb && \
        apt-get update && \
        apt-get install -y --no-install-recommends /tmp/apptainer_${APPTAINER_VERSION}_amd64.deb && \
        rm -f /tmp/apptainer_${APPTAINER_VERSION}_amd64.deb && \
        rm -rf /var/lib/apt/lists/* && \
        echo "Apptainer installation completed successfully"; \
    else \
        echo "Skipping Apptainer installation for ${ARCH} architecture"; \
        echo "Apptainer is primarily needed for HPC environments, not local Docker containers"; \
    fi

# Install Nextflow (requires Java 17+)
# Pin to the requested release from GitHub
RUN mkdir -p /opt/nextflow && \
    cd /opt/nextflow && \
    curl -fsSL "https://github.com/nextflow-io/nextflow/releases/download/v${NEXTFLOW_VERSION}/nextflow-${NEXTFLOW_VERSION}-all" -o nextflow && \
    chmod +x nextflow && \
    ln -s /opt/nextflow/nextflow /usr/local/bin/nextflow && \
    nextflow info && \
    echo "Nextflow installation completed"

# Set up npm global directory
ENV NPM_CONFIG_PREFIX=/opt/npm-global
ENV PATH=$NPM_CONFIG_PREFIX/bin:$PATH
RUN mkdir -p $NPM_CONFIG_PREFIX

# Install Claude Code, Gemini CLI, and OpenAI Codex CLI
# Build args force cache invalidation when versions change
RUN echo "Installing AI CLI tools: Claude Code ${CLAUDE_VERSION}, Gemini CLI ${GEMINI_VERSION}, and OpenAI Codex" && \
    npm cache clean --force && \
    npm install -g \
        @anthropic-ai/claude-code@${CLAUDE_VERSION} \
        @google/gemini-cli@${GEMINI_VERSION} \
        @openai/codex@latest

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
    echo 'echo ""' >> /usr/local/bin/container-info && \
    echo 'echo "Bioinformatics Workflow Tools:"' >> /usr/local/bin/container-info && \
    echo "echo \"  - snakemake: Workflow management (v${SNAKEMAKE_VERSION})\"" >> /usr/local/bin/container-info && \
    echo "echo \"  - nextflow: Data-driven computational pipelines (v${NEXTFLOW_VERSION})\"" >> /usr/local/bin/container-info && \
    echo "echo \"  - nf-core: Community curated pipelines (v${NF_CORE_VERSION})\"" >> /usr/local/bin/container-info && \
    echo 'if command -v apptainer >/dev/null 2>&1; then echo "  - apptainer: Container runtime (v1.3.5)"; fi' >> /usr/local/bin/container-info && \
    echo 'echo ""' >> /usr/local/bin/container-info && \
    echo 'echo "Python packages installed:"' >> /usr/local/bin/container-info && \
    echo 'echo "  numpy, pandas, matplotlib, seaborn, plotly,"' >> /usr/local/bin/container-info && \
    echo 'echo "  scipy, scikit-learn, jupyter, ipython, markitdown,"' >> /usr/local/bin/container-info && \
    echo 'echo "  snakemake, nf-core"' >> /usr/local/bin/container-info && \
    echo 'echo ""' >> /usr/local/bin/container-info && \
    echo 'echo "Set environment variables:"' >> /usr/local/bin/container-info && \
    echo 'echo "  export ANTHROPIC_API_KEY=your_key_here"' >> /usr/local/bin/container-info && \
    echo 'echo "  export GEMINI_API_KEY=your_key_here"' >> /usr/local/bin/container-info && \
    echo 'echo "  export OPENAI_API_KEY=your_key_here (for Codex)"' >> /usr/local/bin/container-info && \
    echo 'echo "=============================================="' >> /usr/local/bin/container-info && \
    chmod +x /usr/local/bin/container-info

# Set environment for runtime
ENV NODE_ENV=production

# Labels
LABEL maintainer="sahuno"
LABEL description="AI CLI and Bioinformatics workflow container with Claude, Gemini, Codex, Python data science stack, Snakemake, Nextflow, and nf-core"
LABEL version="1.0"
LABEL claude.version="${CLAUDE_VERSION}"
LABEL gemini.version="${GEMINI_VERSION}"
LABEL snakemake.version="${SNAKEMAKE_VERSION}"
LABEL nf-core.version="${NF_CORE_VERSION}"
LABEL nextflow.version="${NEXTFLOW_VERSION}"
LABEL build.date="${BUILD_DATE}"

# Default command
CMD ["/bin/bash"]
