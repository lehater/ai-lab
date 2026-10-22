# Clipboard: Codex CLI in Wayland Ubuntu → Windows through VMware

**Scope:** host desktop usability; separate from Codex sandbox and n8n. This is a **documented operator workaround**, not a claim that VMware's underlying issue is fixed. The Ubuntu GNOME session remains **Wayland**; switching the VM to X11 was previously tried and rejected due to scaling, resolution, fullscreen and window-management problems.

## Confirmed by operator on lab-test, 2026-10-22

| Copy sequence | Windows paste |
| --- | --- |
| Codex `/copy` → immediately switch to Windows → Ctrl+V | **FAIL:** old Windows clipboard value |
| Codex `/copy` → paste within Ubuntu (`Ctrl+V` or `Shift+Insert`) | **PASS:** correct text inside Ubuntu |
| Codex `/copy` → switch focus **to another Ubuntu window**, then switch to Windows → Ctrl+V | **PASS:** correct copied text in Windows |
| Codex `/copy` → paste into a Linux GUI editor → copy again in that editor → switch to Windows | **PASS**, but unnecessary given the simpler focus workaround |

**Conclusion supported by these tests:** the clipboard text is already correct within the guest; the failing step is propagation to the Windows host when leaving the focused Codex/terminal window immediately. Switching focus to **any other Ubuntu window** before switching to Windows is sufficient in the observed session. This makes PRIMARY-versus-CLIPBOARD confusion an insufficient explanation. It is **plausible** VMware/open-vm-tools publishes clipboard state on a Wayland/window-focus event, but that internal mechanism is *not yet confirmed*.

## Working operator procedure (no installation or host modification)

1. Run `/copy` in Codex (copies last completed response).
2. Switch focus to another **Ubuntu application window** (e.g. `Alt+Tab` if it switches windows within the guest; do not merely send Alt+Tab to the Windows host).
3. Only then switch from the VMware window to Windows and paste using `Ctrl+V`.

**Status:** operator-verified direct Codex-to-Windows clipboard workflow. No need to recopy text through an editor, change to X11, install clipboard helpers or weaken VMware guest isolation for this workaround.

## If focus workaround stops working

Check that `/copy` still pastes correctly *inside Ubuntu*. Then distinguish the host bridge from terminal copying. VMware's Wayland clipboard support is known to have limitations. An optional **one-shot**, user-triggered fallback discussed upstream is:

```bash
# Only if wl-paste (wl-clipboard) and xclip are already installed, or installed deliberately for diagnosis.
wl-paste --no-newline | xclip -selection clipboard
```

This relays the Wayland clipboard into XWayland within the **same Wayland session**. It has **not** been tested on this VM and is **not** required while the focus workaround works. Never build an automatic clipboard sync daemon by default; continual clipboard access risks spreading incidental selections including secrets.

References: [VMware/open-vm-tools Wayland clipboard reports](https://github.com/vmware/open-vm-tools/issues/792), [VMware focus-related clipboard reports](https://github.com/vmware/open-vm-tools/issues/701), [Broadcom guest integration troubleshooting](https://knowledge.broadcom.com/external/article/320995).

## Infrastructure decision

- **Keep as an operator tip**, referenced from the optional Codex workbench documentation and host runbook.
- **Do not add X11 switching, background clipboard bridging, desktop configuration or new dependencies** to S0/S1/S2 from this finding.
- Only reopen engineering work if the one-step focus workaround becomes impractical or unreliable on the supported VM. Any proposed automation should have a concrete test and explicit user opt-in.
