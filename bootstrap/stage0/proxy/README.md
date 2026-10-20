# Proxy component of Offline Stage 0

This component is part of `bootstrap/stage0`; it is not a separate deployment.

- `install.sh`: installs local v2rayN 7.20.2 DEB and restores the private archive.
- `configure.sh`: configures GNOME user autostart for future logins.
- `start.sh`: launches v2rayN immediately in the current GUI session (unless already running) and waits up to 180 seconds for Xray.
- `verify.sh`: validates package, listening port and proxied GitHub connection.

The private configuration and v2rayN DEB are supplied in the adjacent
`../private-proxy/` directory, which has only a placeholder README in Git.

After first installation, Stage 0 launches v2rayN. A user may still need to select and activate a server in its window. Autostart applies on subsequent graphical logins.
