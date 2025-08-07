# Multi-stage build for Claude and Gemini Container with Python & Plotting
FROM node:20-slim AS base

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

# Set up npm global directory
ENV NPM_CONFIG_PREFIX=/opt/npm-global
ENV PATH=$NPM_CONFIG_PREFIX/bin:$PATH
RUN mkdir -p $NPM_CONFIG_PREFIX

# Install Claude Code and Gemini CLI
# Using @latest to ensure we get the most recent version
RUN npm install -g @anthropic-ai/claude-code@latest @google/gemini-cli@latest

# Create workspace directory
RUN mkdir -p /workspace
WORKDIR /workspace

# Create container info script
RUN echo '#!/bin/bash' > /usr/local/bin/container-info && \
    echo 'echo "=== Claude & Gemini Container with Python ===="' >> /usr/local/bin/container-info && \
    echo 'echo "Available tools:"' >> /usr/local/bin/container-info && \
    echo 'echo "  - claude: Claude Code CLI"' >> /usr/local/bin/container-info && \
    echo 'echo "  - gemini: Gemini CLI"' >> /usr/local/bin/container-info && \
    echo 'echo "  - python3: Python with data science libraries"' >> /usr/local/bin/container-info && \
    echo 'echo "  - jupyter: Jupyter notebook"' >> /usr/local/bin/container-info && \
    echo 'echo ""' >> /usr/local/bin/container-info && \
    echo 'echo "Python packages installed:"' >> /usr/local/bin/container-info && \
    echo 'echo "  numpy, pandas, matplotlib, seaborn, plotly,"' >> /usr/local/bin/container-info && \
    echo 'echo "  scipy, scikit-learn, jupyter, ipython, markitdown"' >> /usr/local/bin/container-info && \
    echo 'echo ""' >> /usr/local/bin/container-info && \
    echo 'echo "Set environment variables:"' >> /usr/local/bin/container-info && \
    echo 'echo "  export ANTHROPIC_API_KEY=your_key_here"' >> /usr/local/bin/container-info && \
    echo 'echo "  export GEMINI_API_KEY=your_key_here"' >> /usr/local/bin/container-info && \
    echo 'echo "=============================================="' >> /usr/local/bin/container-info && \
    chmod +x /usr/local/bin/container-info

# Set environment for runtime
ENV NODE_ENV=production
ENV DEBIAN_FRONTEND=noninteractive

# Labels
LABEL maintainer="sahuno"
LABEL description="Claude Code and Gemini CLI container with Python and plotting capabilities"
LABEL version="1.0"

# Default command
CMD ["/bin/bash"]