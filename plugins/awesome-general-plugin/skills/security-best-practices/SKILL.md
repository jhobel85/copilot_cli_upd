---
name: security-best-practices
description: 'Use when reviewing secrets, auth, encryption, permissions, sensitive data handling, or secure defaults.'
license: MIT
---

# Security Best Practices

Use this skill for security-sensitive changes and reviews.

## Use when
- Handling credentials, tokens, or personal data.
- Reviewing auth, encryption, storage, or access control.
- Checking for unsafe defaults in code or config.

## Prefer
- Least privilege.
- Explicit validation and error handling.
- Secure-by-default configuration.

## Avoid
- Plaintext secrets.
- Hidden security assumptions.
- Broad catch-all fallbacks for sensitive flows.
