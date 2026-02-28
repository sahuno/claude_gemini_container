# Claude & Gemini Container

This repository provides containerized versions of Claude Code and Gemini CLI with Python data science libraries and bioinformatics workflow management tools (Snakemake, Nextflow, nf-core).

## Current Versions (Updated: February 2026)

| Tool | Version | Description |
|------|---------|-------------|
| **Claude Code** | 2.1.63 | Anthropic's AI-assisted coding CLI |
| **Gemini CLI** | 0.31.0 | Google's Gemini AI CLI |
| **OpenAI Codex** | 0.106.0 | OpenAI's Codex CLI |
| **Snakemake** | 9.16.3 | Workflow management system |
| **Nextflow** | latest | Data-driven computational pipelines |
| **nf-core** | 3.5.2 | Community curated Nextflow pipelines |
| **Apptainer** | 1.4.0 | Container runtime (AMD64 only) |
| **Python** | 3.x | With scientific computing stack |
| **Java** | OpenJDK 17 | Required for Nextflow |

## Available Formats

### Docker (Recommended)

The Docker image includes:
- **AI CLI Tools**: Claude Code, Gemini CLI, OpenAI Codex
- **Workflow Management**: Snakemake, Nextflow, nf-core
- **Container Runtime**: Apptainer (AMD64 only, for HPC compatibility)
- **Python 3**: Data science libraries (numpy, pandas, matplotlib, seaborn, plotly, scipy, scikit-learn)
- **Interactive Computing**: Jupyter notebook, IPython
- **Development Tools**: GitHub CLI (gh), git, git-lfs, vim, nano, curl, wget

#### Pull from Docker Hub
```bash
docker pull sahuno/claude_gemini_container:latest
```

#### Build locally
```bash
docker build -t claude_gemini_container .
```

#### Run the container
```bash
# Interactive mode with API keys
docker run -it --rm \
  -e ANTHROPIC_API_KEY=your_anthropic_key \
  -e GEMINI_API_KEY=your_gemini_key \
  -e OPENAI_API_KEY=your_openai_key \
  -v $(pwd):/workspace \
  sahuno/claude_gemini_container:latest

# Run AI CLI tools
docker run --rm \
  -e ANTHROPIC_API_KEY=your_anthropic_key \
  -v $(pwd):/workspace \
  sahuno/claude_gemini_container:latest \
  claude --help

# Run bioinformatics workflows
docker run --rm \
  -v $(pwd):/workspace \
  sahuno/claude_gemini_container:latest \
  snakemake --version

docker run --rm \
  -v $(pwd):/workspace \
  sahuno/claude_gemini_container:latest \
  nextflow info

# Check installed versions
docker run --rm \
  sahuno/claude_gemini_container:latest \
  container-info
```

### Singularity/Apptainer (HPC environments)

#### Build the image
```bash
# Using Singularity
singularity build --remote claude.sif claude.def

# Or using Apptainer
apptainer build --remote claude.sif claude.def
```

Note: Remote build requires Singularity Cloud authentication:
1. Generate a token at https://cloud.sylabs.io/tokens
2. Run `singularity remote login` to add your token

#### Run Singularity/Apptainer container
```bash
# Set API keys
export ANTHROPIC_API_KEY=your_anthropic_key
export GEMINI_API_KEY=your_gemini_key
export OPENAI_API_KEY=your_openai_key

# Run AI CLI tools
singularity exec claude.sif claude
singularity exec claude.sif gemini
singularity exec claude.sif codex

# Run bioinformatics workflows
singularity exec claude.sif snakemake --version
singularity exec claude.sif nextflow info
singularity exec claude.sif nf-core list

# Run with bound directories (for accessing data)
singularity exec --bind /data:/data claude.sif snakemake --cores 4
```

## Architecture Support

The container supports multi-architecture builds:
- **linux/amd64**: Full support including Apptainer (v1.4.0)
- **linux/arm64**: All tools except Apptainer (not available for ARM64)

Note: Apptainer is primarily needed for HPC environments and is automatically skipped on ARM64 builds (e.g., Apple Silicon Macs).

## Environment Variables

Set these environment variables before using AI CLI tools:
```bash
export ANTHROPIC_API_KEY=your_anthropic_key_here
export GEMINI_API_KEY=your_gemini_key_here
export OPENAI_API_KEY=your_openai_key_here  # For Codex
```

Or pass them directly to Docker:
```bash
docker run -it --rm \
  -e ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY \
  -e GEMINI_API_KEY=$GEMINI_API_KEY \
  -e OPENAI_API_KEY=$OPENAI_API_KEY \
  -v $(pwd):/workspace \
  sahuno/claude_gemini_container:latest
```

## GitHub Actions

The repository includes automated Docker builds:
- Daily builds at 2 AM UTC to incorporate latest updates
- Automatic builds on push to main branch
- Multi-architecture support (linux/amd64, linux/arm64)

## Required Secrets for GitHub Actions

Add these secrets to your GitHub repository:
- `DOCKER_USERNAME`: Your Docker Hub username
- `DOCKER_PASSWORD`: Your Docker Hub password or access token

## Tools Included

### AI CLI Tools
- **claude** (v2.1.39): Claude Code CLI for AI-assisted coding
- **gemini** (v0.27.2): Google's Gemini CLI with Gemini 2.5 Pro support
- **codex** (v0.98.0): OpenAI Codex CLI - Lightweight coding agent

### Bioinformatics Workflow Management
- **snakemake** (v9.15.0): Python-based workflow management system with SLURM executor plugin
- **nextflow** (latest): Data-driven computational pipelines with Java 17 support
- **nf-core** (v3.5.1): Community curated bioinformatics pipelines

### Container & Compute
- **apptainer** (v1.4.0): Container runtime for HPC (AMD64 architecture only)
- **python3**: Python with scientific computing libraries
- **jupyter**: Jupyter notebook for interactive Python
- **java**: OpenJDK 17 for Nextflow

### Development Tools
- **gh**: GitHub CLI for working with repositories, PRs, and issues
- **git**: Version control system
- **git-lfs**: Git Large File Storage for managing large files
- **vim, nano**: Text editors
- **curl, wget**: Data download utilities
- **rsync**: File synchronization

## Python Libraries

The container includes these pre-installed Python packages:
- **Data Manipulation**: numpy, pandas
- **Visualization**: matplotlib, seaborn, plotly
- **Scientific Computing & ML**: scipy, scikit-learn
- **Interactive Computing**: jupyter, ipython
- **Workflow Management**: snakemake (v9.15.0) with SLURM executor plugin, nf-core (v3.5.1)
- **Document Conversion**: markitdown

## Using Bioinformatics Workflows

### Snakemake
```bash
# Run a Snakemake workflow locally
docker run --rm -v $(pwd):/workspace \
  sahuno/claude_gemini_container:latest \
  snakemake --cores 4 --configfile config.yaml

# Run with SLURM executor (on HPC)
singularity exec claude.sif \
  snakemake --executor slurm --jobs 100 --default-resources slurm_account=myaccount

# Dry run to check workflow
docker run --rm -v $(pwd):/workspace \
  sahuno/claude_gemini_container:latest \
  snakemake -n
```

### Nextflow
```bash
# Run a Nextflow pipeline
docker run --rm -v $(pwd):/workspace \
  sahuno/claude_gemini_container:latest \
  nextflow run main.nf

# Run nf-core pipeline
docker run --rm -v $(pwd):/workspace \
  sahuno/claude_gemini_container:latest \
  nf-core list
```

## Using GitHub CLI (gh)

The container includes the GitHub CLI for working with repositories, PRs, and issues:

```bash
# Authenticate with GitHub
docker run -it --rm -v $(pwd):/workspace \
  sahuno/claude_gemini_container:latest \
  gh auth login

# View PR information
docker run --rm -v $(pwd):/workspace \
  sahuno/claude_gemini_container:latest \
  gh pr view 123

# Create a PR
docker run --rm -v $(pwd):/workspace \
  sahuno/claude_gemini_container:latest \
  gh pr create --title "My PR" --body "Description"

# List issues
docker run --rm -v $(pwd):/workspace \
  sahuno/claude_gemini_container:latest \
  gh issue list
```

## Using Git LFS

The container includes Git Large File Storage (LFS) for managing large files in repositories:

```bash
# Track large files (e.g., *.fastq.gz, *.bam)
docker run --rm -v $(pwd):/workspace \
  sahuno/claude_gemini_container:latest \
  git lfs track "*.fastq.gz"

# List tracked file patterns
docker run --rm -v $(pwd):/workspace \
  sahuno/claude_gemini_container:latest \
  git lfs track

# Pull LFS files
docker run --rm -v $(pwd):/workspace \
  sahuno/claude_gemini_container:latest \
  git lfs pull

# Check LFS status
docker run --rm -v $(pwd):/workspace \
  sahuno/claude_gemini_container:latest \
  git lfs status
```

## Container Information

To view all installed tools and versions, run:
```bash
docker run --rm sahuno/claude_gemini_container:latest container-info
```

This displays:
- All AI CLI tools with versions
- Bioinformatics workflow tools with versions
- Python packages installed
- Development tools (gh, git, etc.)
- Required environment variables