## Container Versions

| Tool         | Version          |
|--------------|------------------|
| Claude Code  | `CLAUDE_VER`     |
| Gemini CLI   | `GEMINI_VER`     |
| OpenAI Codex | `CODEX_VER`      |
| Snakemake    | `SNAKEMAKE_VER`  |
| nf-core      | `NF_CORE_VER`    |

## Docker Pull Commands

```bash
# Always-latest
docker pull sahuno/claude_gemini_container:latest

# Pinned to this Claude Code version
docker pull sahuno/claude_gemini_container:claude-CLAUDE_VER

# Date-pinned (fully reproducible)
docker pull sahuno/claude_gemini_container:DATE_TAG_VAL
```

## Quality Gates Passed

- Smoke tests: Claude, Gemini, Codex, Python stack (numpy/pandas/matplotlib), Snakemake ✅
- Trivy security scan: CRITICAL/HIGH findings reported to Security tab ✅
- Multi-arch: `linux/amd64` + `linux/arm64` ✅
