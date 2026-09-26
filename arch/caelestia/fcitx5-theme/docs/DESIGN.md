# Design and technical choices

Caelestia 2.4.0 reads `${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/scheme.json` and exposes Material style colours to its UI. The companion CLI writes that generated file when the scheme changes. This project reads `mode` and seven hex values from `colours`; all other fields are ignored. It never parses a wallpaper path. A missing or malformed file selects the documented fallback palette.

| Caelestia scheme field | Candidate UI use |
| --- | --- |
| `surfaceContainer` | Panel surface, alpha 244/255 in light mode or 239/255 in dark mode |
| `onSurface` | Main and preedit text |
| `onSurfaceVariant` | Candidate numbers, comments, paging chevrons |
| `primaryContainer` | Selected candidate surface and highlighted preedit |
| `onPrimaryContainer` | Text, number, and comment on the selected surface |
| `outlineVariant` | Subtle panel outline |
| `shadow` | Small blurred image shadow |

The panel image is a 96 × 96 PNG with a 16 pixel card radius and a 12 pixel clear border for the shadow. Fcitx5 stretches it as a nine slice image with 32 pixel margins. The selected candidate uses a 48 × 48 PNG with a 10 pixel radius and 14 pixel margins. This avoids the SVG nine slice rendering issue reported for Fcitx5 5.1.22. Text and content margins keep Japanese glyphs away from the edge. The selected candidate is nearly opaque, so it stays legible if blur is absent.

`EnableBlur=True` and a separate rounded `BlurMask` ask Fcitx5 to blur the panel interior. This is only a request. On Wayland the compositor must advertise a blur protocol and enable an actual blur pass. The surface alpha alone is transparency, not blur. The drop shadow is baked into the PNG and does not require compositor shadow rules. Fcitx5 owns popup placement and scale; the theme does not position a Wayland window.

The generated PNGs are small and reused by Classic UI. The watcher polls one file every two seconds, then regenerates and reloads only when its metadata changes. It does not poll the wallpaper image. On a display with fractional scaling, test visual sharpness because it depends on the compositor and Fcitx5. `ForceWaylandDPI` and `EnableFractionalScale` are left at the user's current values. The font is also left alone; the Classic UI font is configured in `classicui.conf`, not in `theme.conf`.

Kimpanel could provide a custom panel protocol, and a Qt/QML frontend could offer native effects and layout controls. Either would need a separate long running process, coordinate handling, focus and candidate event plumbing, and much broader Wayland compatibility testing. Classic UI already handles those parts and has the required theme fields, so it is the lowest impact choice.

To change spacing or radius, edit `theme_conf`, `card_image`, and `highlight_image` together. Keep each image's nine slice margins greater than its corner radius and make the content margin large enough for the panel shadow padding. After changing values, run `render` into `generated/` and inspect the output. For an installed copy, uninstall and install again after reviewing the resulting change; the installer never overwrites an existing theme.

