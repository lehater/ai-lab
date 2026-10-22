# Clipboard between Ubuntu VMware guest and Windows host

**Optional host UX diagnostic — proposal, not a proven fix for this particular VM.** Clipboard integration belongs to the **VMware/desktop host environment**, not to the Codex CLI installation, the n8n experiment or the S2 Infrastructure Core.

## Symptoms reported on lab-test (2026-10-22)

When text is highlighted or copied in Codex CLI in an Ubuntu 24.04 VMware guest, Windows sometimes pastes an older value. Copying through a GNOME graphical text editor and then copying again makes the new content appear in Windows. Root cause is **not yet confirmed** by a `$XDG_SESSION_TYPE` check or by controlled copy tests.

Two distinct failure modes must not be conflated:

- **X11 PRIMARY versus CLIPBOARD.** Selecting text with a mouse may set only PRIMARY; explicit `Copy` or `Ctrl+Shift+C` in a terminal sets CLIPBOARD. These are different selections; Windows uses its normal clipboard.
- **VMware guest ↔ host synchronization.** Even if the Linux CLIPBOARD is correct, `open-vm-tools-desktop`/VMware may not propagate it to Windows. Broadcom documents limitations with Wayland and recommends X11/Xorg for Workstation/Fusion guest copy/paste.

## Codex built-in copying (no extra software)

Before manually selecting text, try the **existing Codex CLI feature** (documented in the official CLI reference):

- **`/copy`** or **Ctrl+O** copies the latest completed agent response to Ubuntu's native clipboard. A copy inside Ubuntu does not by itself prove VMware propagated it to Windows.
- **`/raw`** toggles more copy-friendly raw scrollback.
- **`/tui` → Scrollback** switches away from the fullscreen/alternate-screen experience after restarting Codex, so terminal selection is easier.

These commands are not verified on the operator's running `0.163.0` instance yet; their availability is documented upstream. Avoid `/export` for ad hoc cross-VM clipboard tests if the complete conversation could include secrets.

Primary reference: [Codex CLI developer commands](https://learn.chatgpt.com/docs/developer-commands); [Codex CLI reference](https://learn.chatgpt.com/docs/cli/reference).

## Smallest observable test, no host changes

1. In the Ubuntu Codex TUI, try **`/copy`** first with a **nonsecret** completed response and test Windows Ctrl+V. If that does not bridge correctly, highlight nonsecret text with the mouse and press **Ctrl+Shift+C** (do not use plain Ctrl+C, which may signal a terminal process).
2. Without intermediate editor, switch to Windows and press Ctrl+V in a scratch text field. Repeat using terminal context menu **Copy** if useful.
3. If it still pastes an older value, run this in the Ubuntu GUI terminal:

   ```bash
   printf 'session=%s\n' "${XDG_SESSION_TYPE:-unknown}"
   dpkg-query -W -f='${Package}: ${Status}\n' open-vm-tools open-vm-tools-desktop 2>/dev/null || true
   pgrep -af 'vmtoolsd|vmware-user' || true
   ```

   The returned process list and package status indicate whether GUI guest integration exists; they do **not** alone prove synchronization.

4. If `session=wayland`, consider a **reversible operator choice**: log out; on Ubuntu's login screen select the cogwheel and **Ubuntu on Xorg**, if offered. Log in again, run `echo "$XDG_SESSION_TYPE"` (expect `x11`), then repeat the copy test **without** changing Codex. Broadcom's VMware Workstation Linux-guest guidance explicitly notes Wayland clipboard limitations. Do not edit GDM configuration or disable Wayland globally merely to test.
5. If already `x11` or still failing under Xorg, verify VMware Workstation **VM Settings → Options → Guest Isolation → Enable copy and paste** and that desktop VMware Tools are running. Review `open-vm-tools-desktop` installation and the VMware guest-integration service before changing settings. Some drag/drop workflows also require `run-vmblock\\x2dfuse.mount`, as documented by Broadcom; do not assume this is the clipboard root cause.

## Optional diagnostic helpers, only after root cause is known

If PRIMARY has the new text but CLIPBOARD has old text **on X11**, `xclip` can transfer a deliberate *specific* selection:

```bash
# Requires xclip, and X11 session; no daemon or automatic sharing.
xclip -o -selection primary | xclip -i -selection clipboard
```

This is **not** a solution for a broken VMware clipboard bridge or a Wayland session. Do not install global automatic PRIMARY→CLIPBOARD sync without a privacy review: it would expose every incidental text selection (possibly credentials) to the host clipboard. Likewise avoid unreviewed third-party Wayland clipboard bridges, custom patched VMware Tools, hidden startup processes or disabling guest isolation without a concrete verified need.

## Acceptance before recording an infrastructure fix

- Identify actual Ubuntu session type and VMware Workstation copy-paste setting.
- Show one **direct** Codex terminal output → Windows clipboard transfer, without a text editor relay, from an ordinary login.
- Confirm copy/paste remains stable after a GNOME logout/login or reboot if choosing Xorg.
- If a host configuration change proves necessary, automate only the **minimal reversible** configuration with an explicit operator opt-in and its own check. Otherwise keep this a user-facing shortcut/diagnostic note.

References: [GNOME PRIMARY and CLIPBOARD semantics](https://wiki.gnome.org/Initiatives/Wayland/PrimarySelection), [Broadcom VMware Linux guest copy/paste and Wayland limitation, KB 320995](https://knowledge.broadcom.com/external/article/320995), [Broadcom clipboard guidance](https://knowledge.broadcom.com/external/article/336880), [upstream open-vm-tools Wayland issue](https://github.com/vmware/open-vm-tools/issues/792).
