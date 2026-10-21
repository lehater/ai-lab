# S1 — Host Bootstrap: GitHub SSH-over-proxy slice (candidate)

This is **not the complete S1 milestone**. It configures an isolated GitHub
SSH transport via the existing S0 local proxy. It does not modify S0,
`~/.ssh/config`, user SSH keys, Git remotes or Docker. Target: Ubuntu 24.04
Desktop/amd64 after S0. No on-VM verification has been performed yet.

## Installation on lab-test after S0

Run as the regular desktop user from the checked-out repository:

```bash
bash bootstrap/host/bootstrap.sh
```

The entrypoint checks S0 prerequisites, installs `netcat-openbsd` via the
already configured APT proxy *if absent*, generates
`~/.config/ai-lab/github-ssh.conf`, and checks its settings plus GitHub HTTPS
access through Xray. It is intended to be rerunnable and refuses to
overwrite a modified SSH configuration.

The new alias `ai-lab-github` connects to `ssh.github.com:443` through
HTTP CONNECT using the existing local proxy at `127.0.0.1:10808`.
This is based on [GitHub's SSH-over-port-443 instructions](https://docs.github.com/en/authentication/troubleshooting-ssh/using-ssh-over-the-https-port).
Some proxies may still block the connection.

## Owner-controlled GitHub authorization

The scripts do **not** generate, upload, copy or enroll SSH keys, do not
modify existing remotes, and never accept an unverified SSH server key.

Use a key you explicitly approve and register **only its public half**
with your GitHub account. Then manually connect:

```bash
ssh -F "$HOME/.config/ai-lab/github-ssh.conf" -T ai-lab-github
```

Before accepting the host key, check its fingerprint against
[GitHub's official SSH fingerprints](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints).
GitHub may exit `ssh -T` with code 1 even after successful authentication
(no shell access); inspect its message.

After the key is enrolled and the server key trusted, verify actual Git SSH
operations (not the interactive `ssh -T` exit status):

```bash
bash bootstrap/host/verify.sh --auth
```

The Git transport can also be used for a single command without changing
the global SSH configuration or `origin` URL:

```bash
GIT_SSH_COMMAND="ssh -F $HOME/.config/ai-lab/github-ssh.conf" \
  git ls-remote ai-lab-github:lehater/ai-lab.git HEAD
```

## Validation and boundaries

- Offline checks (mocked SSH, shell syntax, rerun behavior and conflict
  refusal): `bash bootstrap/host/tests/test-configure.sh`.
- Configuration and HTTP(S) proxy check, **not SSH authentication**:
  `bash bootstrap/host/verify.sh --local`.
- GitHub SSH authentication check with an owner-enrolled key:
  `bash bootstrap/host/verify.sh --auth`.
- Full S1 acceptance remains **PENDING**. On a clean `lab-test` snapshot,
  rerun S0 → S1, run S1 twice, check connectivity after reboot, and record
  the precise environment, commands, evidence and any limitations.

This is only the first S1 slice. It does not yet provision a complete
developer host, test after reboot, control GitHub account keys, provide
Docker/S1-D functions, or establish Enterprise-grade compliance.
