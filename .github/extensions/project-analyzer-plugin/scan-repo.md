# Agent: Scan Repository

name: scan-repo
summary: Scan any repository to produce a concise inventory of files, languages, and primary purpose.

instructions:
- Input: repository path (default: current working dir)
- Output: JSON report with: languages, top-level folders, README summary, license, CI files, package managers detected, test frameworks, and metrics (lines, file counts by language)
- Steps:
  1. Read README, package files, and manifest files (package.json, pyproject.toml, go.mod, etc.)
  2. Detect languages by file extensions and dominant language by LOC
  3. Identify CI workflows, Dockerfiles, infra (Terraform, ARM), and MCP or GitHub Actions
  4. Summarize repository purpose in one sentence and 3 bullet points of key capabilities
- Cost-savers: prefer file metadata and heuristics vs deep parsing; limit full-file reads to README and manifests
- Run mode: autonomous
- Example output: {"purpose":"REST API for X","languages":{"ts":2345,...},"topFolders":["src","docs"]}
