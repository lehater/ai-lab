# Clipboard between Ubuntu VMware guest and Windows host

**Optional host UX diagnostic — proposal, not a proven fix for this particular VM.** Clipboard integration belongs to the **VMware/desktop host environment**, not to the Codex CLI installation, the n8n experiment or the S2 Infrastructure Core.

## Observed on lab-test (2026-10-22)

**Operator confirmed the VM must remain in GNOME Wayland:** switching to X11/Xorg had previously broken display scaling, resolution/fullscreen and window handling. X11 is **not an acceptable default remediation**.

Controlled copy test:

1. Codex `/copy` creates the *correct* Ubuntu clipboard text: `Ctrl+V` and `Shift+Insert` paste it **inside the Ubuntu guest**.
2. Switching to Windows, both paste shortcuts still return an **older** clipboard value.
3. Pasting that same text into a Linux graphical text editor, selecting it there and using editor `Ctrl+C`, then pasting in Windows **works immediately**.

This establishes correct Codex-to-Linux copy but **source-dependent VMware guest-to-host propagation**. It rules out a purely PRIMARY-vs-CLIPBOARD explanation; does **not** yet distinguish Wayland-to-XWayland clipboard bridging, MIME/ownership semantics or VMware's focus tracking.

## Relevant public evidence and Wayland-only investigation

- Broadcom's [open-vm-tools known limitations](https://knowledge.broadcom.com/external/article/320995) and [open issue #792](https://github.com/vmware/open-vm-tools/issues/792) document VMware copy/paste shortcomings with Wayland.
- Participants in [issue #792](https://github.com/vmware/open-vm-tools/issues/792) reported a **one-shot** bridge from Wayland to XWayland as a viable workaround for guest-to-host clipboard transfer: `wl-paste | xclip -selection clipboard`. The evidence is on another VMware/desktop combination; **not yet verified for this Ubuntu GNOME VM**.
- In [issue #701](https://github.com/vmware/open-vm-tools/issues/701), a user reported that simply focusing a graphical Linux text field after a copy made VMware propagate the clipboard. This should be tested **without recopying** before installing anything.

**Two minimal tests, no session change:**

1. After Codex `/copy`, focus an existing GNOME text editor **without using Copy or Paste**, then attempt Windows Ctrl+V. Record whether it updated.
2. If not, in a normal Ubuntu terminal check `command -v wl-paste` and `command -v xclip`; if both exist, after Codex `/copy` execute:

   ```bash
   wl-paste --no-newline | xclip -selection clipboard
   ```

   Then immediately paste on Windows. If one command is missing, the optional test-only packages are `wl-clipboard` and `xclip`; installation requires operator consent and APT. Never copy private secrets into experimental clipboard debugging commands.

If this bridge works, a **user-triggered one-shot clipboard relay** is the candidate solution. Do **not** implement a continuously running Wayland↔XWayland watcher yet: clipboard loops have been reported, and always-on clipboard access has privacy implications. No changes to GNOME session type, guest display settings or VMware VMX settings should be made.

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

4. **Do not propose an Xorg session switch for this VM.** The operator has already tried it and reverted because of scaling, resolution/fullscreen and window-management problems. Keep all proposed workarounds inside the Wayland session.
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
