# Contributing

Thanks for taking a look. This is a small personal project, so the process is light: open an issue for anything bigger than a typo so we can agree on the approach, then send a PR.

## Layout

| Path | What it is |
| --- | --- |
| `modules/openvpn-config` | Cloud-agnostic core: PKI, cloud-init document, client profiles. Most OpenVPN behavior lives here. |
| `modules/aws`, `modules/azure`, `modules/gcp` | Per-cloud networking, firewall, static IP and VM. No provider blocks, so they work as child modules. |
| `AWS/`, `Azure/`, `GCP/` | Thin root configurations: provider block, module call, variables. This is what most users run. |
| `AzureMktPlace/` | Standalone OpenVPN Access Server deployment. It doesn't use the shared modules. |
| `tests/integration` | Docker end-to-end test of the generated server and client configuration. |

A few rules of thumb:

- OpenVPN behavior belongs in `modules/openvpn-config`, so every cloud gets it.
- New variables need a `type`, a `description` and, where it makes sense, a `validation` block.
- Keep shell out of Terraform templates. Scripts go in `modules/openvpn-config/files/` as plain files that shellcheck can lint.
- Keep defaults safe: SSH closed, no secrets in non-sensitive outputs.
- If you add a variable to a cloud module, consider whether the root configuration in `AWS/`, `Azure/` or `GCP/` should expose it too.

## Tools

- Terraform 1.6+ (CI also runs OpenTofu)
- Docker, for the integration test, shellcheck and tflint
- Optional: [pre-commit](https://pre-commit.com/), [tflint](https://github.com/terraform-linters/tflint), [terraform-docs](https://terraform-docs.io/)

## Checks

Everything below runs in CI. None of it needs cloud credentials.

```sh
# Formatting
terraform fmt -recursive

# Validate every configuration
for d in modules/* AWS Azure GCP AzureMktPlace; do
  (cd "$d" && terraform init -backend=false -input=false >/dev/null && terraform validate)
done

# Unit tests. The cloud modules run against mocked providers.
for d in modules/*; do (cd "$d" && terraform test); done

# Lint
tflint --recursive --config "$PWD/.tflint.hcl"
docker run --rm -v "$PWD:/mnt" -w /mnt koalaman/shellcheck:stable \
  modules/openvpn-config/files/openvpn-nat tests/integration/*.sh

# End to end: boots an Ubuntu 24.04 server container from the generated
# cloud-init, connects a client container with a generated .ovpn, routes
# traffic through the tunnel, and checks that a revoked client is refused.
tests/integration/run.sh
```

`pre-commit install` sets up formatting, validation, tflint and the terraform-docs README sections to run on every commit.

### Testing against a real cloud

CI can't create cloud resources, so for changes to `modules/aws`, `modules/azure` or `modules/gcp`, please deploy once with the matching root configuration, connect a client, and say so in the PR (which cloud and region, and that traffic went through the tunnel). Destroy it afterwards.

## Module documentation

The input and output tables in `modules/*/README.md` are generated. After changing variables or outputs, run:

```sh
for d in modules/*; do terraform-docs "$d"; done
```

## Commits and pull requests

- Keep PRs focused; unrelated cleanups go in their own PR.
- Update `CHANGELOG.md` under "Unreleased" for anything a user would notice.
- Reference the issue a PR fixes (`Fixes #123`).

By contributing, you agree that your contributions are licensed under the project's [GPL-3.0](LICENSE) license.
