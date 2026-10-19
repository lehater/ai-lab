# Proxy component of Offline Stage 0

This component is part of `bootstrap/stage0`; it is not a separate deployment.

- `install.sh`: installs local v2rayN 7.20.2 DEB and restores the private archive.
- `configure.sh`: configures GNOME user autostart; it does not launch Xray immediately.
- `verify.sh`: validates package, listening port and proxied GitHub connection.

The private configuration and v2rayN DEB are supplied in the adjacent
`../private-proxy/` directory, which has only a placeholder README in Git.

After first installation, launch v2rayN from GNOME and select a server.
