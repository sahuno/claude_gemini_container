# Claude & Gemini Container

This repository provides containerized versions of Claude Code and Gemini CLI with Python and plotting capabilities.

## Available Formats

### Docker (Recommended)

The Docker image includes:
- Claude Code CLI
- Gemini CLI
- Python 3 with data science libraries (numpy, pandas, matplotlib, seaborn, plotly, scipy, scikit-learn)
- Jupyter notebook support

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
  -v $(pwd):/workspace \
  sahuno/claude_gemini_container:latest

# Run specific command
docker run --rm \
  -e ANTHROPIC_API_KEY=your_anthropic_key \
  -v $(pwd):/workspace \
  sahuno/claude_gemini_container:latest \
  claude --help
```

### Singularity (HPC environments)

#### Build the image
```bash
singularity build --remote claude.sif claude.def
```

Note: Remote build requires Singularity Cloud authentication:
1. Generate a token at https://cloud.sylabs.io/tokens
2. Run `singularity remote login` to add your token

#### Run Singularity container
```bash
# Set API keys
export ANTHROPIC_API_KEY=your_anthropic_key
export GEMINI_API_KEY=your_gemini_key

# Run Claude
singularity exec claude.sif claude

# Run Gemini
singularity exec claude.sif gemini
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

- **claude**: Claude Code CLI for AI-assisted coding
- **gemini**: Google's Gemini CLI
- **python3**: Python with scientific computing libraries
- **jupyter**: Jupyter notebook for interactive Python
- **git, vim, nano**: Development tools

## Python Libraries

The container includes these pre-installed Python packages:
- numpy, pandas: Data manipulation
- matplotlib, seaborn, plotly: Visualization
- scipy, scikit-learn: Scientific computing and ML
- jupyter, ipython: Interactive computing