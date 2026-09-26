#!/usr/bin/env python3
"""Generate and manage a user-local Fcitx5 Classic UI theme for Caelestia."""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


THEME_NAME = "caelestia-mozc"
MANAGED_KEYS = {"Theme": THEME_NAME, "DarkTheme": THEME_NAME}
HEX = re.compile(r"^[0-9a-fA-F]{6}$")
FALLBACK = {
    "light": {
        "surfaceContainer": "e9eef4", "onSurface": "20272d",
        "onSurfaceVariant": "4b545b", "primaryContainer": "b7ddf3",
        "onPrimaryContainer": "123b50", "outlineVariant": "bac5cc",
        "shadow": "000000",
    },
    "dark": {
        "surfaceContainer": "252d34", "onSurface": "f0f3f6",
        "onSurfaceVariant": "c3cbd1", "primaryContainer": "31566a",
        "onPrimaryContainer": "e4f4fc", "outlineVariant": "495660",
        "shadow": "000000",
    },
}
REQUIRED = tuple(FALLBACK["light"])


def xdg(name: str, suffix: str) -> Path:
    defaults = {
        "XDG_CONFIG_HOME": ".config", "XDG_DATA_HOME": ".local/share",
        "XDG_STATE_HOME": ".local/state",
    }
    raw = os.environ.get(name)
    base = Path(raw) if raw and Path(raw).is_absolute() else Path.home() / defaults[name]
    return base / suffix


def scheme_path() -> Path:
    return xdg("XDG_STATE_HOME", "caelestia/scheme.json")


def theme_path() -> Path:
    return xdg("XDG_DATA_HOME", f"fcitx5/themes/{THEME_NAME}")


def config_path() -> Path:
    return xdg("XDG_CONFIG_HOME", "fcitx5/conf/classicui.conf")


def install_state() -> Path:
    return xdg("XDG_STATE_HOME", "caelestia-fcitx5-theme/install.json")


def load_palette(source: Path, fallback_mode: str) -> tuple[str, dict[str, str], bool]:
    try:
        data = json.loads(source.read_text(encoding="utf-8"))
        mode = data["mode"]
        colours = data["colours"]
        if mode not in FALLBACK or not isinstance(colours, dict):
            raise ValueError("unsupported scheme format")
        palette = {key: colours[key] for key in REQUIRED}
        if not all(isinstance(value, str) and HEX.fullmatch(value) for value in palette.values()):
            raise ValueError("invalid colour value")
        return mode, palette, False
    except (OSError, ValueError, KeyError, TypeError, json.JSONDecodeError):
        return fallback_mode, FALLBACK[fallback_mode].copy(), True


def rgba(colour: str, alpha: int = 255) -> tuple[int, int, int, int]:
    return tuple(bytes.fromhex(colour)) + (alpha,)


def card_image(palette: dict[str, str], mode: str) -> tuple[Image.Image, Image.Image]:
    size = 96
    bounds = (12, 12, 84, 84)
    mask = Image.new("L", (size, size))
    ImageDraw.Draw(mask).rounded_rectangle(bounds, radius=16, fill=255)
    shadow_alpha = mask.filter(ImageFilter.GaussianBlur(6)).point(lambda n: round(n * 0.22))
    shadow = Image.new("RGBA", (size, size), rgba(palette["shadow"]))
    shadow.putalpha(shadow_alpha)
    panel = Image.new("RGBA", (size, size))
    panel.alpha_composite(shadow)
    fill_alpha = 244 if mode == "light" else 239
    face = Image.new("RGBA", (size, size), rgba(palette["surfaceContainer"], fill_alpha))
    face.putalpha(mask.point(lambda n: round(n * fill_alpha / 255)))
    panel.alpha_composite(face)
    ImageDraw.Draw(panel).rounded_rectangle(bounds, radius=16, outline=rgba(palette["outlineVariant"], 120), width=1)
    blur_mask = Image.new("RGBA", (size, size))
    blur_mask.putalpha(mask)
    return panel, blur_mask


def highlight_image(palette: dict[str, str]) -> Image.Image:
    image = Image.new("RGBA", (48, 48))
    ImageDraw.Draw(image).rounded_rectangle((3, 3, 45, 45), radius=10,
                                            fill=rgba(palette["primaryContainer"], 252))
    return image


def arrow_image(colour: str, forward: bool) -> Image.Image:
    image = Image.new("RGBA", (20, 20))
    points = [(7, 5), (12, 10), (7, 15)] if forward else [(13, 5), (8, 10), (13, 15)]
    ImageDraw.Draw(image).line(points, fill=rgba(colour), width=2, joint="curve")
    return image


def theme_conf(palette: dict[str, str]) -> str:
    c = lambda key: "#" + palette[key].lower()
    return f"""[Metadata]
Name=Caelestia Mozc
Version=1
Description=Caelestia colours for the Fcitx5 Classic UI

[InputPanel]
NormalColor={c('onSurface')}
HighlightColor={c('onPrimaryContainer')}
HighlightBackgroundColor={c('primaryContainer')}
HighlightCandidateColor={c('onPrimaryContainer')}
LabelTextSizeFactor=90
CandidateLabelColor={c('onSurfaceVariant')}
HighlightCandidateLabelColor={c('onPrimaryContainer')}
CommentTextSizeFactor=85
CandidateCommentColor={c('onSurfaceVariant')}
HighlightCandidateCommentColor={c('onPrimaryContainer')}
EnableBlur=True
BlurMask=blur-mask.png
FullWidthHighlight=True
PageButtonAlignment=Center

[InputPanel/ContentMargin]
Left=26
Right=26
Top=22
Bottom=22

[InputPanel/TextMargin]
Left=9
Right=9
Top=6
Bottom=6

[InputPanel/Background]
Image=panel.png

[InputPanel/Background/Margin]
Left=32
Right=32
Top=32
Bottom=32

[InputPanel/Highlight]
Image=highlight.png

[InputPanel/Highlight/Margin]
Left=14
Right=14
Top=14
Bottom=14

[InputPanel/PrevPage]
Image=prev.png

[InputPanel/NextPage]
Image=next.png

[Menu]
NormalColor={c('onSurface')}
HighlightCandidateColor={c('onPrimaryContainer')}
Spacing=2
EnableBlur=True
BlurMask=blur-mask.png

[Menu/Background]
Image=panel.png

[Menu/Background/Margin]
Left=32
Right=32
Top=32
Bottom=32

[Menu/Highlight]
Image=highlight.png

[Menu/Highlight/Margin]
Left=14
Right=14
Top=14
Bottom=14

[Menu/Separator]
Color={c('outlineVariant')}

[Menu/ContentMargin]
Left=25
Right=25
Top=22
Bottom=22

[Menu/TextMargin]
Left=8
Right=8
Top=6
Bottom=6
"""


def render(destination: Path, scheme: Path, fallback_mode: str) -> bool:
    mode, palette, fallback = load_palette(scheme, fallback_mode)
    if destination.is_symlink():
        raise RuntimeError("refusing a symlinked theme directory")
    destination.mkdir(parents=True, exist_ok=True)
    panel, blur_mask = card_image(palette, mode)
    images = {
        "panel.png": panel, "blur-mask.png": blur_mask,
        "highlight.png": highlight_image(palette),
        "prev.png": arrow_image(palette["onSurfaceVariant"], False),
        "next.png": arrow_image(palette["onSurfaceVariant"], True),
    }
    for filename, image in images.items():
        with tempfile.NamedTemporaryFile(dir=destination, suffix=".png", delete=False) as tmp:
            staged = Path(tmp.name)
        try:
            image.save(staged, format="PNG")
            staged.replace(destination / filename)
        finally:
            staged.unlink(missing_ok=True)
    atomic_write(destination / "theme.conf", theme_conf(palette).encode())
    return fallback


def atomic_write(path: Path, content: bytes, mode: int | None = None) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.is_symlink():
        raise RuntimeError("refusing to overwrite a symlink")
    with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as tmp:
        staged = Path(tmp.name)
        tmp.write(content)
        tmp.flush()
        os.fsync(tmp.fileno())
    try:
        if mode is not None:
            staged.chmod(mode)
        elif path.exists():
            staged.chmod(path.stat().st_mode & 0o777)
        staged.replace(path)
    finally:
        staged.unlink(missing_ok=True)


def config_values(content: str) -> dict[str, str | None]:
    values: dict[str, str | None] = dict.fromkeys(MANAGED_KEYS)
    section = None
    for line in content.splitlines():
        stripped = line.strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            section = stripped[1:-1]
        elif section is None and "=" in line and not stripped.startswith(("#", ";")):
            key, value = line.split("=", 1)
            if key.strip() in values:
                values[key.strip()] = value.strip()
    return values


def patch_config(content: str, values: dict[str, str | None]) -> str:
    lines = content.splitlines(keepends=True)
    result: list[str] = []
    found = set()
    section = None
    for line in lines:
        stripped = line.strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            section = stripped[1:-1]
        if section is None and "=" in line and not stripped.startswith(("#", ";")):
            key = line.split("=", 1)[0].strip()
            if key in values:
                if key in found:
                    raise RuntimeError(f"duplicate {key} setting")
                found.add(key)
                if values[key] is not None:
                    result.append(f"{key}={values[key]}\n")
                continue
        result.append(line)
    missing = [f"{key}={value}\n" for key, value in values.items() if key not in found and value is not None]
    if missing:
        first_section = next((i for i, line in enumerate(result) if line.strip().startswith("[")), len(result))
        if first_section and not result[first_section - 1].endswith("\n"):
            result[first_section - 1] += "\n"
        result[first_section:first_section] = missing
    return "".join(result)


def install(scheme: Path, fallback_mode: str) -> None:
    target, state, config = theme_path(), install_state(), config_path()
    if target.exists() or target.is_symlink() or state.exists() or state.is_symlink():
        raise RuntimeError("theme or install record already exists; refusing to overwrite")
    if config.is_symlink():
        raise RuntimeError("refusing a symlinked Classic UI configuration")
    original = config.read_bytes() if config.exists() else b""
    current = original.decode("utf-8")
    previous = config_values(current)
    state.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    state.parent.chmod(0o700)
    backup = state.parent / "classicui.conf.before-install"
    if backup.exists() or backup.is_symlink():
        raise RuntimeError("backup already exists; refusing to overwrite")
    atomic_write(backup, original, 0o600)
    target.mkdir(parents=True)
    try:
        fallback = render(target, scheme, fallback_mode)
        atomic_write(target / ".managed-by-caelestia-fcitx5-theme", b"1\n")
        atomic_write(state, json.dumps({"config_existed": config.exists(), "previous": previous}).encode(), 0o600)
        atomic_write(config, patch_config(current, MANAGED_KEYS).encode(), 0o600 if not config.exists() else None)
    except Exception:
        shutil.rmtree(target)
        state.unlink(missing_ok=True)
        backup.unlink(missing_ok=True)
        raise
    print("Installed user-local theme. Fcitx5 has not been reloaded.")
    if fallback:
        print("Caelestia scheme unavailable; fallback colours were used.")


def uninstall() -> None:
    target, state, config = theme_path(), install_state(), config_path()
    marker = target / ".managed-by-caelestia-fcitx5-theme"
    if not marker.is_file() or target.is_symlink() or not state.is_file() or state.is_symlink():
        raise RuntimeError("managed installation was not found")
    if config.is_symlink():
        raise RuntimeError("refusing a symlinked Classic UI configuration")
    record = json.loads(state.read_text())
    current = config.read_text() if config.exists() else ""
    if config_values(current) != MANAGED_KEYS:
        raise RuntimeError("Classic UI theme selection changed; restore it manually before uninstalling")
    restored = patch_config(current, record["previous"])
    if record["config_existed"]:
        atomic_write(config, restored.encode())
    elif restored.strip():
        atomic_write(config, restored.encode())
    else:
        config.unlink(missing_ok=True)
    shutil.rmtree(target)
    state.unlink()
    (state.parent / "classicui.conf.before-install").unlink(missing_ok=True)
    print("Restored previous theme selection and removed managed theme. Fcitx5 has not been reloaded.")


def reload_fcitx() -> None:
    if shutil.which("fcitx5-remote"):
        subprocess.run(["fcitx5-remote", "-r"], check=False, stdout=subprocess.DEVNULL,
                       stderr=subprocess.DEVNULL)


def watch(scheme: Path, fallback_mode: str, interval: float) -> None:
    target = theme_path()
    if not (target / ".managed-by-caelestia-fcitx5-theme").is_file():
        raise RuntimeError("install the theme before starting the watcher")
    last = object()
    while True:
        try:
            stat = scheme.stat()
            signature = (stat.st_mtime_ns, stat.st_size)
        except OSError:
            signature = None
        if signature != last:
            render(target, scheme, fallback_mode)
            reload_fcitx()
            last = signature
        time.sleep(interval)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("render", "install", "uninstall", "watch"))
    parser.add_argument("--output", type=Path, help="render destination; required for render")
    parser.add_argument("--scheme", type=Path, default=scheme_path())
    parser.add_argument("--fallback-mode", choices=("light", "dark"), default="dark")
    parser.add_argument("--interval", type=float, default=2.0, help="watch poll interval in seconds")
    args = parser.parse_args()
    try:
        if args.command == "render":
            if args.output is None:
                parser.error("render requires --output")
            fallback = render(args.output, args.scheme, args.fallback_mode)
            print("Rendered theme" + (" using fallback colours" if fallback else ""))
        elif args.command == "install":
            install(args.scheme, args.fallback_mode)
        elif args.command == "uninstall":
            uninstall()
        else:
            if args.interval < 0.5:
                parser.error("--interval must be at least 0.5 seconds")
            watch(args.scheme, args.fallback_mode, args.interval)
    except (OSError, ValueError, RuntimeError, UnicodeError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
