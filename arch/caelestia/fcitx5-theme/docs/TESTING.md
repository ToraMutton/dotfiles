# Verification record

## Completed locally

- Read only inspection identified Fcitx5, fcitx5-mozc, Caelestia Shell/CLI, Quickshell, Hyprland, and Qt versions. IBus was not installed. The Fcitx5 profile selects Mozc as the default input method.
- Caelestia's generated scheme format and watcher were checked against the installed Caelestia files. The generator uses the XDG state location shown there.
- The theme fields and the reload path were checked against the Fcitx5 5.1.22 Classic UI source. The image assets were generated from fictional sample colours. Six isolated tests passed for fallback, PNG output, readable fallback contrast, reversible config updates, and overwrite protection.
- The illustrative preview is an RGB PNG with no embedded metadata. Source text and candidate files were scanned for local identifiers, email addresses, home paths, private key markers, and cloud key patterns; no actual private value was found. The example generation directory and Python caches are ignored by Git.
- After approval, the user-local theme was installed. The previously absent Classic UI config now contains only `Theme=caelestia-mozc` and `DarkTheme=caelestia-mozc`; a private backup and install record exist. The running Fcitx5 accepted a configuration reload, still reported Mozc as the current input method, and the temporary colour watcher was active. Hyprland reported its global blur option enabled.
- The user visually checked the candidate popup on the live desktop and reported that its appearance was satisfactory. This confirms a visual smoke check, not every interaction or display scenario below.
- The dotfiles Stow package was checked in an isolated target: it linked only the command and service definition, and the symlinked command generated a theme. The full Arch profile dry-run completed successfully. The same two links were then applied to the live user target. The persistent user service passed `systemd-analyze verify`, is enabled and running, and Fcitx5 still reports Mozc as the current input method.
- The theme component was moved into the existing `arch/caelestia` Stow package. Both live links were switched after their old targets were checked, and the old package was moved into a private rollback backup outside Git. The full Stow dry-run, command render, and active/enabled service checks passed after the move. The host-specific Fcitx5 packages and input settings were not changed.

## Needs a live desktop check after installation

- Japanese conversion, candidate selection by number and click, paging, preedit visibility, and focus in GTK, Qt, and native Wayland apps.
- Long Japanese and Latin candidates, annotations, and page indicators.
- Light/dark changes and wallpaper changes while the watcher is running. The watcher is enabled for automatic user-session startup, but this transition has not yet been exercised across a logout/login cycle.
- Actual compositor blur versus transparency, shadow appearance, and contrast with blur disabled.
- Fractional scale, high DPI, multiple monitors, and different monitor scales.
- Uninstall on the live desktop and restoration of the previous theme selection.

The initial sandboxed inspection could not connect to Fcitx5 or Hyprland; the approved installation used the live session. Candidate appearance was visually checked by the user. Visible blur as a distinct effect, detailed input interactions, and multi-monitor behaviour are still **unverified**. A generated preview is illustrative and is not evidence of a live candidate popup.

## Publication scan

Before `git add` and again before committing, list all candidate files, inspect images, and search source text for sensitive patterns. For example:

```sh
git status --short --untracked-files=all
rg -n -i '(/home/[^/[:space:]]+|@[[:alnum:]._-]+\.[[:alpha:]]{2,}|AKIA[0-9A-Z]{16}|BEGIN .*PRIVATE KEY|token|cookie|ssh-rsa)' --glob '!docs/TESTING.md' .
git diff --cached --name-only
git diff --cached
```

The pattern scan can find false positives and miss secrets. Open every tracked file, especially images and example configs, before publishing. Do not add a real candidate screenshot unless notifications, names, paths, typed text, and other private details have been checked visually. Never add Mozc user dictionaries, learning data, cache, or history.
