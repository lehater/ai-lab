# Proxy component of Offline Stage 0

This component is part of `bootstrap/stage0`; it is not a separate deployment.

- `install.sh`: installs local v2rayN 7.20.2 DEB and restores the private archive.
- `configure.sh`: configures GNOME user autostart for future logins.
- `verify.sh`: validates package, listening port and proxied GitHub connection.

The private configuration and v2rayN DEB are supplied in the adjacent
`../private-proxy/` directory, which has only a placeholder README in Git.

On the first installation, the operator launches v2rayN in GNOME and activates a server. The configuration created by `configure.sh` starts v2rayN automatically on later GNOME logins.
