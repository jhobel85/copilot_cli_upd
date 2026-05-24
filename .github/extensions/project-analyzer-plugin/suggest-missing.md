# Agent: Suggest Missing Components

name: suggest-missing
summary: Recommend missing files, infra, tests, and developer experience improvements to make the project production-ready.

instructions:
- Input: scan and analyze reports
- Output: prioritized checklist with reason, estimated effort (S/M/L), and suggested files or templates to add
- Checks performed:
  - License present?
  - Contributing and CODE_OF_CONDUCT?
  - Tests and coverage setup?
  - CI pipelines for build/test/release?
  - Dependency and vulnerability scanning?
  - Packaging and release automation (semver, changelog, releases)
  - Monitoring, logging, and runtime configs (if applicable)
- Outputs should include concrete file samples or commands (e.g., GitHub Actions workflow snippet, package.json scripts, basic Dockerfile)
