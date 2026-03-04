# Claude & Gemini Container

Containerized AI coding assistants (Claude Code, Gemini CLI, OpenAI Codex) with bioinformatics workflow tools (Snakemake, Nextflow, nf-core). Multi-arch: amd64 + arm64.

## Current Versions (Updated: February 2026)

| Tool | Version | Description |
|------|---------|-------------|
| **Claude Code** | 2.1.68 | Anthropic's AI coding CLI |
| **Gemini CLI** | 0.31.0 | Google's Gemini AI CLI |
| **OpenAI Codex** | 0.106.0 | OpenAI's Codex CLI |
| **Snakemake** | 9.16.3 | Workflow management system |
| **nf-core** | 3.5.2 | Community curated Nextflow pipelines |

> Versions are auto-updated daily by CI — see [CI / Automation](#ci--automation).

## Quick Start

```bash
# Pull
docker pull sahuno/claude_gemini_container:latest

# Run interactive with API keys and a workspace mount
docker run -it --rm \
  -e ANTHROPIC_API_KEY=your_key \
  -e GEMINI_API_KEY=your_key \
  -e OPENAI_API_KEY=your_key \
  -v $(pwd):/workspace \
  sahuno/claude_gemini_container:latest

# Show installed tool versions
docker run --rm sahuno/claude_gemini_container:latest container-info
```

## What's Included

- **AI CLI tools** — Claude Code, Gemini CLI, OpenAI Codex
- **Workflow management** — Snakemake (with SLURM executor plugin), Nextflow, nf-core
- **Python 3 scientific stack** — numpy, pandas, matplotlib, seaborn, plotly, scipy, scikit-learn, jupyter
- **Container runtime** — Apptainer 1.4.0 (amd64 only, for HPC compatibility)
- **Java** — OpenJDK 17 (required by Nextflow)
- **Dev tools** — GitHub CLI (`gh`), git, git-lfs, vim, nano, curl, wget, rsync, jq, tree

## Singularity / Apptainer (HPC)

```bash
# Pull from Docker Hub (simplest method)
singularity pull docker://sahuno/claude_gemini_container:latest

# Run with bind mounts
export ANTHROPIC_API_KEY=your_key
singularity exec --bind /data:/data claude_gemini_container_latest.sif claude
singularity exec --bind /data:/data claude_gemini_container_latest.sif snakemake --version
```

## CI / Automation

Two GitHub Actions workflows maintain this image:

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| `check-versions.yml` | Daily at 17:00 UTC + manual | Checks npm/PyPI for new versions of all 5 tools; opens a PR if any changed |
| `docker-build.yml` | Push to `main` + PR (validate only) | Runs smoke tests and Trivy security scan, then builds multi-arch and pushes to Docker Hub |

**Image tags** pushed on each deploy:
- `:latest` — always the newest build
- `:claude-X.Y.Z` — pinned to the Claude Code version
- `:YYYYMMDD` — date-pinned for reproducible pulls

A [GitHub Release](../../releases) is created for every deploy with pinned pull commands.

## Environment Variables

```bash
export ANTHROPIC_API_KEY=your_key   # Claude Code
export GEMINI_API_KEY=your_key      # Gemini CLI
export OPENAI_API_KEY=your_key      # OpenAI Codex
```

## Required Secrets (GitHub Actions)

| Secret | Used by |
|--------|---------|
| `DOCKER_USERNAME` | Docker Hub login |
| `DOCKERHUB_TOKEN` | Docker Hub push + description sync |
