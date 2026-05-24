---
name: system-audit
description: 'Perform a deep, high-accuracy audit of the Copilot CLI environment: skills, plugins, MCP servers, agents, and instructions.'
---

# SYSTEM-AUDIT (High-Fidelity + Usage Analysis)

## Purpose

Perform a deep, high-accuracy audit of the Copilot CLI environment:

- skills (existence + real usage)
- plugins
- MCP servers
- agents
- instructions

Identify gaps, redundancies, missing capabilities, misconfigurations, and improvement opportunities.

Audit may take longer to ensure higher reliability.

## Required Inputs

- `skills list`
- `plugins list`
- `mcp list`
- `agents list`
- `instructions show`
- (Optional) recent commands or tasks executed by the user
- (Optional) logs of skill invocations (if available)

If any input is missing or incomplete, request it before continuing.

---

## Audit Methodology

### 1. Structural Analysis

- Count items in each category.
- Detect empty or overloaded categories.
- Detect naming inconsistencies.

### 2. Coverage Analysis

- Compare available skills vs. typical tasks.
- Identify tasks without a matching skill.
- Identify skills that are too broad or too narrow.

### 3. **Usage Analysis**

Determine how Copilot CLI uses or ignores existing skills.

#### 3.1 Expected Usage

Based on:

- skill names
- descriptions
- keywords
- typical user workflows

#### 3.2 Actual Usage

Based on:

- recent commands
- skill invocation logs (if provided)
- patterns in user tasks

#### 3.3 Usage Gaps

Identify:

- skills that exist but are never used
- skills that should be used but are ignored
- skills that are used incorrectly
- skills that overlap and confuse the system
- skills that are triggered too often or too rarely

#### 3.4 Usage Score

For each skill:

- 0 = unused
- 1 = rarely used
- 2 = used but suboptimally
- 3 = used correctly
- 4 = used frequently and effectively

---

### 4. Redundancy & Conflict Detection

- Detect skills with similar names or scopes.
- Detect conflicting responsibilities.
- Detect skills that shadow each other.

### 5. Quality Assessment

Evaluate each skill based on:

- clarity of purpose
- scope correctness
- modularity
- naming consistency
- expected usefulness
- alignment with user workflows
- actual usage score

### 6. Improvement Proposals

For each issue:

- describe the problem
- explain why it matters
- propose a concrete fix
- estimate impact (low / medium / high)

---

## Output Format

### Summary

Short overview of system health.

### Skill Usage Overview

- List of skills with usage scores.
- Skills expected to be used but unused.
- Skills used incorrectly.
- Skills used well.

### Gaps

Missing capabilities with examples.

### Redundancies

Overlapping or unnecessary items.

### Misconfigurations

Broken, unclear, or inconsistent items.

### Improvement Plan

Concrete steps to improve the system.

### Optional Deep Dive

If user requests: provide detailed analysis of each skill, plugin, MCP server, or agent.

---

## Behavior Rules

- No assumptions beyond provided data.
- If data is insufficient, stop and request more.
- Prefer depth over speed.
- Prefer accuracy over brevity.
- Every recommendation must include "Why" + "Impact".
- Never modify system; only analyze.

