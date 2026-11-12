# Security policy

## Reporting a vulnerability

Please don't open a public issue for security problems. Use GitHub's [private vulnerability reporting](https://github.com/gudlyf/TerraformOpenVPN/security/advisories/new) instead, with enough detail to reproduce the problem.

This is a one-person side project, so I can't promise response times, but I do read these and will credit you in the fix unless you'd rather I didn't.

## Supported versions

Only the latest commit on `master` is supported. The pre-2026 configurations (Ubuntu 16.04/18.04, easy-rsa) are unmaintained; please upgrade.

## Scope and known trade-offs

These are documented design decisions, not vulnerabilities:

- Certificate private keys, including the CA key, are stored in Terraform state. Protect your state backend.
- The server's private key is delivered through cloud-init user data and can be read by anyone with access to the instance's metadata or user data.
- Client revocation uses `ccd-exclusive` rather than a CRL and takes effect when the replacement VM boots.

See the "Security notes" section of the [README](README.md#security-notes).
