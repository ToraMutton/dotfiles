import json
import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from PIL import Image

import theme


SAMPLE = {
    "mode": "light",
    "colours": {
        "surfaceContainer": "e9eef4",
        "onSurface": "20272d",
        "onSurfaceVariant": "4b545b",
        "primaryContainer": "b7ddf3",
        "onPrimaryContainer": "123b50",
        "outlineVariant": "bac5cc",
        "shadow": "000000",
    },
}


class ThemeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        root = Path(self.temp.name)
        env = {
            "XDG_CONFIG_HOME": str(root / "config"),
            "XDG_DATA_HOME": str(root / "data"),
            "XDG_STATE_HOME": str(root / "state"),
        }
        env_patch = patch.dict(os.environ, env)
        env_patch.start()
        self.addCleanup(env_patch.stop)
        self.root = root
        self.scheme = root / "sample.json"
        self.scheme.write_text(json.dumps(SAMPLE))

    def test_render_uses_scheme_and_creates_rounded_assets(self):
        out = self.root / "rendered"
        self.assertFalse(theme.render(out, self.scheme, "dark"))
        conf = (out / "theme.conf").read_text()
        self.assertIn("NormalColor=#20272d", conf)
        self.assertIn("CandidateCommentColor=#4b545b", conf)
        self.assertIn("EnableBlur=True", conf)
        with Image.open(out / "panel.png") as panel:
            self.assertEqual(panel.size, (96, 96))
            self.assertEqual(panel.getpixel((0, 0))[3], 0)
            self.assertGreater(panel.getpixel((48, 48))[3], 230)
        with Image.open(out / "blur-mask.png") as mask:
            self.assertEqual(mask.getpixel((48, 48))[3], 255)
            self.assertEqual(mask.getpixel((0, 0))[3], 0)

    def test_invalid_scheme_uses_fallback(self):
        self.scheme.write_text('{"mode":"dark","colours":{"surfaceContainer":"zzzzzz"}}')
        out = self.root / "fallback"
        self.assertTrue(theme.render(out, self.scheme, "dark"))
        self.assertIn("NormalColor=#f0f3f6", (out / "theme.conf").read_text())

    def test_fallback_text_remains_readable_without_blur(self):
        def luminance(hex_colour):
            values = [v / 255 for v in bytes.fromhex(hex_colour)]
            linear = [v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4
                      for v in values]
            return sum(a * b for a, b in zip(linear, (0.2126, 0.7152, 0.0722)))

        def contrast(a, b):
            light, dark = sorted((luminance(a), luminance(b)), reverse=True)
            return (light + 0.05) / (dark + 0.05)

        for mode, palette in theme.FALLBACK.items():
            base = bytes.fromhex(palette["surfaceContainer"])
            alpha = 244 / 255 if mode == "light" else 239 / 255
            for backdrop in (0, 255):
                composite = bytes(round(channel * alpha + backdrop * (1 - alpha))
                                  for channel in base).hex()
                self.assertGreaterEqual(contrast(palette["onSurface"], composite), 7)
                self.assertGreaterEqual(contrast(palette["onSurfaceVariant"], composite), 4.5)
            self.assertGreaterEqual(contrast(palette["onPrimaryContainer"],
                                             palette["primaryContainer"]), 4.5)

    def test_install_and_uninstall_preserve_unrelated_settings(self):
        config = theme.config_path()
        config.parent.mkdir(parents=True)
        original = "# personal key bindings stay here\nTheme=old-theme\n[Other]\nKeep=True\n"
        config.write_text(original)
        theme.install(self.scheme, "dark")
        self.assertEqual(theme.config_values(config.read_text()), theme.MANAGED_KEYS)
        self.assertTrue((theme.theme_path() / "panel.png").is_file())
        self.assertEqual((theme.install_state().parent / "classicui.conf.before-install").read_text(), original)
        config.write_text(config.read_text() + "# a later unrelated edit\n")
        theme.uninstall()
        self.assertIn("Theme=old-theme", config.read_text())
        self.assertNotIn("DarkTheme=caelestia-mozc", config.read_text())
        self.assertIn("# a later unrelated edit", config.read_text())
        self.assertFalse(theme.theme_path().exists())

    def test_existing_theme_is_never_overwritten(self):
        target = theme.theme_path()
        target.mkdir(parents=True)
        (target / "theme.conf").write_text("other theme")
        with self.assertRaises(RuntimeError):
            theme.install(self.scheme, "dark")
        self.assertEqual((target / "theme.conf").read_text(), "other theme")
        self.assertFalse(theme.config_path().exists())

    def test_uninstall_refuses_theme_choice_changed_after_install(self):
        theme.install(self.scheme, "dark")
        config = theme.config_path()
        config.write_text(config.read_text().replace("Theme=caelestia-mozc", "Theme=another", 1))
        with self.assertRaises(RuntimeError):
            theme.uninstall()
        self.assertTrue(theme.theme_path().exists())


if __name__ == "__main__":
    unittest.main()
