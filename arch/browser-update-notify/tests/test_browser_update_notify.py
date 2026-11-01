"""End-to-end tests for browser-update-notify.

The real script runs with a PATH that contains only fake pacman / checkupdates /
paru / yay / notify-send / busctl commands, so nothing here can touch the real
package database, the network or the desktop. State goes to a temporary XDG dir.

Run:  python3 -m unittest discover -s tests -v   (from the package directory)
"""

import json
import os
import stat
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parent.parent / ".local/bin/browser-update-notify"

# A fake command: prints the canned reply of the first rule whose "match" words
# all appear in argv, and records every invocation in calls.log.
STUB = """#!{python}
import json, os, sys
here = os.path.dirname(os.path.abspath(__file__))
name = os.path.basename(__file__)
with open(os.path.join(here, "calls.log"), "a") as log:
    log.write(json.dumps([name] + sys.argv[1:]) + "\\n")
reply = {{"rc": 0, "stdout": "", "stderr": ""}}
for rule in json.load(open(os.path.join(here, name + ".json"))):
    if all(word in sys.argv[1:] for word in rule.get("match", [])):
        reply = rule
        break
sys.stdout.write(reply.get("stdout", ""))
sys.stderr.write(reply.get("stderr", ""))
sys.exit(reply.get("rc", 0))
"""

CHROME = "google-chrome 156.0.1-1 -> 157.0.2-1\n"
CHROMIUM = "chromium 156.0.1-1 -> 157.0.2-1\n"


class Environment:
    def __init__(self, root):
        self.root = Path(root)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.state = self.root / "state"
        self.config = self.root / "config"
        self.reset_fakes()

    def stub(self, name, *rules):
        path = self.bin / name
        path.write_text(STUB.format(python=sys.executable))
        path.chmod(path.stat().st_mode | stat.S_IXUSR)
        (self.bin / f"{name}.json").write_text(json.dumps(rules))

    def remove(self, name):
        (self.bin / name).unlink()

    def reset_fakes(self):
        """Both browsers installed (chromium from the repo, chrome from the AUR), no updates."""
        self.stub("pacman",
                  {"match": ["-Qmq"], "stdout": "google-chrome\n"},
                  {"match": ["-Q"], "stdout": "google-chrome 156.0.1-1\nchromium 156.0.1-1\n"})
        self.stub("checkupdates", {"rc": 2})
        self.stub("paru", {"rc": 1})
        self.stub("yay", {"rc": 1})
        self.stub("notify-send")
        self.stub("busctl", {"stdout": 's "quickshell" "quickshell" "" "1.2"\n'})

    def run(self, *args):
        env = {
            "PATH": str(self.bin),
            "HOME": str(self.root),
            "XDG_STATE_HOME": str(self.state),
            "XDG_CONFIG_HOME": str(self.config),
        }
        return subprocess.run([sys.executable, "-I", str(SCRIPT), *args],
                              env=env, capture_output=True, text=True, timeout=60)

    def calls(self, name):
        log = self.bin / "calls.log"
        rows = [json.loads(line) for line in log.read_text().splitlines()] if log.exists() else []
        return [row for row in rows if row[0] == name]

    def notifications(self):
        return self.calls("notify-send")

    def state_file(self, name="state.json"):
        return self.state / "browser-update-notify" / name

    def read_state(self, name="state.json"):
        return json.loads(self.state_file(name).read_text())


class CheckTests(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.env = Environment(self._tmp.name)

    def check(self, *args):
        return self.env.run("check", *args)

    # --- detection -------------------------------------------------------

    def test_no_updates_means_no_notification(self):
        result = self.check()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.env.notifications(), [])
        self.assertEqual(self.env.read_state()["last_check"]["result"], "ok")

    def test_detects_chromium_from_repo_and_chrome_from_aur(self):
        self.env.stub("checkupdates", {"stdout": CHROMIUM})
        self.env.stub("paru", {"stdout": CHROME})
        result = self.check()
        self.assertEqual(result.returncode, 0, result.stderr)
        (call,) = self.env.notifications()
        body = call[-1]
        self.assertIn("Google Chrome\n156.0.1-1 → 157.0.2-1", body)
        self.assertIn("Chromium\n156.0.1-1 → 157.0.2-1", body)
        self.assertIn("ブラウザのアップデートがあります", call[-2])
        self.assertEqual(self.env.read_state()["notified"],
                         {"google-chrome": "157.0.2-1", "chromium": "157.0.2-1"})

    def test_only_one_browser_updated(self):
        self.env.stub("paru", {"stdout": CHROME})
        self.check()
        (call,) = self.env.notifications()
        self.assertIn("Google Chrome", call[-1])
        self.assertNotIn("Chromium", call[-1])

    def test_unwatched_packages_are_ignored(self):
        self.env.stub("checkupdates", {"stdout": "firefox 1-1 -> 2-1\nlinux 1-1 -> 2-1\n"})
        self.check()
        self.assertEqual(self.env.notifications(), [])

    def test_uninstalled_watched_package_is_not_queried(self):
        # chrome only: the repo source must not be consulted at all
        self.env.stub("pacman",
                      {"match": ["-Qmq"], "stdout": "google-chrome\n"},
                      {"match": ["-Q"], "stdout": "google-chrome 156.0.1-1\n"})
        self.check()
        self.assertEqual(self.env.calls("checkupdates"), [])
        self.assertEqual(len(self.env.calls("paru")), 1)

    def test_yay_is_used_when_paru_is_missing(self):
        self.env.remove("paru")
        self.env.stub("yay", {"stdout": CHROME})
        self.check()
        self.assertEqual(len(self.env.notifications()), 1)
        self.assertEqual(self.env.calls("yay")[0][1:], ["-Qua"])

    def test_package_list_is_configurable(self):
        conf = self.env.config / "browser-update-notify"
        conf.mkdir(parents=True)
        (conf / "packages.conf").write_text("# comment\nfirefox   Mozilla Firefox\nBad Name!\n")
        self.env.stub("pacman",
                      {"match": ["-Qmq"], "stdout": ""},
                      {"match": ["-Q"], "stdout": "firefox 1-1\n"})
        self.env.stub("checkupdates", {"stdout": "firefox 1-1 -> 2-1\n"})
        self.check()
        (call,) = self.env.notifications()
        self.assertIn("Mozilla Firefox\n1-1 → 2-1", call[-1])

    # --- de-duplication ----------------------------------------------------

    def test_same_update_is_notified_only_once(self):
        self.env.stub("paru", {"stdout": CHROME})
        for _ in range(3):
            self.assertEqual(self.check().returncode, 0)
        self.assertEqual(len(self.env.notifications()), 1)

    def test_new_target_version_notifies_again(self):
        self.env.stub("paru", {"stdout": CHROME})
        self.check()
        self.env.stub("paru", {"stdout": "google-chrome 156.0.1-1 -> 158.0.0-1\n"})
        self.check()
        self.assertEqual(len(self.env.notifications()), 2)
        self.assertIn("158.0.0-1", self.env.notifications()[1][-1])

    def test_additional_package_notifies_again(self):
        self.env.stub("paru", {"stdout": CHROME})
        self.check()
        self.env.stub("checkupdates", {"stdout": CHROMIUM})
        self.check()
        self.assertEqual(len(self.env.notifications()), 2)

    def test_state_is_cleaned_after_upgrade(self):
        self.env.stub("paru", {"stdout": CHROME})
        self.check()
        self.env.stub("paru", {"rc": 1})  # upgraded by the user
        self.check()
        self.assertEqual(self.env.read_state()["notified"], {})
        # a later update of the same package is announced again
        self.env.stub("paru", {"stdout": CHROME})
        self.check()
        self.assertEqual(len(self.env.notifications()), 2)

    # --- failures ----------------------------------------------------------

    def test_network_error_is_reported_but_never_notifies(self):
        self.env.stub("paru", {"rc": 1, "stderr": "error: error sending request: Connection refused\n"})
        result = self.check()
        self.assertEqual(result.returncode, 75)
        self.assertIn("could not fetch updates", result.stderr)
        self.assertEqual(self.env.notifications(), [])
        last = self.env.read_state()["last_check"]
        self.assertEqual(last["result"], "error")
        self.assertIsNone(self.env.read_state()["last_success"])

    def test_yay_style_network_error_is_detected(self):
        self.env.stub("paru", {"rc": 1, "stderr": ' -> request failed: Get "https://aur.archlinux.org/rpc": dial tcp\n'})
        self.assertEqual(self.check().returncode, 75)

    def test_warnings_alone_do_not_count_as_failure(self):
        self.env.stub("paru", {"rc": 1, "stderr": "warning: foo is not present in AUR -- skipping\n"})
        self.assertEqual(self.check().returncode, 0)

    def test_checkupdates_error_is_a_failure_not_no_updates(self):
        self.env.stub("checkupdates", {"rc": 1, "stderr": "error: failed retrieving file\n"})
        self.assertEqual(self.check().returncode, 75)

    def test_no_aur_helper_is_a_failure(self):
        self.env.remove("paru")
        self.env.remove("yay")
        self.assertEqual(self.check().returncode, 75)

    def test_partial_failure_still_notifies_and_keeps_state(self):
        self.env.stub("paru", {"stdout": CHROME})
        self.check()
        # AUR becomes unreachable while a repo update shows up
        self.env.stub("paru", {"rc": 1, "stderr": "error: timeout\n"})
        self.env.stub("checkupdates", {"stdout": CHROMIUM})
        self.assertEqual(self.check().returncode, 75)
        self.assertEqual(len(self.env.notifications()), 2)
        # chrome must not be forgotten, or it would be announced again on recovery
        self.assertIn("google-chrome", self.env.read_state()["notified"])
        self.env.stub("paru", {"stdout": CHROME})
        self.assertEqual(self.check().returncode, 0)
        self.assertEqual(len(self.env.notifications()), 2)

    def test_failed_notification_is_not_recorded_and_retried(self):
        self.env.stub("paru", {"stdout": CHROME})
        self.env.stub("notify-send", {"rc": 1, "stderr": "boom"})
        result = self.check()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.env.read_state()["notified"], {})
        self.env.stub("notify-send")
        self.check()
        self.assertEqual(self.env.read_state()["notified"], {"google-chrome": "157.0.2-1"})
        self.assertEqual(len(self.env.notifications()), 2)

    def test_missing_notification_server_is_not_fatal(self):
        self.env.stub("paru", {"stdout": CHROME})
        self.env.stub("busctl", {"rc": 1, "stderr": "Failed to connect"})
        result = self.check()
        self.assertEqual(result.returncode, 0)
        self.assertEqual(self.env.notifications(), [])
        self.assertEqual(self.env.read_state()["notified"], {})
        self.assertIn("no notification server", result.stderr)

    def test_corrupt_state_is_recovered(self):
        self.env.stub("paru", {"stdout": CHROME})
        self.env.state_file().parent.mkdir(parents=True)
        self.env.state_file().write_text("{ this is not json")
        result = self.check()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(self.env.state_file("state.json.corrupt").exists())
        self.assertEqual(self.env.read_state()["notified"], {"google-chrome": "157.0.2-1"})

    def test_wrongly_shaped_state_is_recovered(self):
        self.env.state_file().parent.mkdir(parents=True)
        self.env.state_file().write_text('{"notified": ["x"]}')
        self.assertEqual(self.check().returncode, 0)
        self.assertEqual(self.env.read_state()["notified"], {})

    # --- mock mode & helpers ----------------------------------------------

    def test_mock_updates_notify_without_touching_real_state_or_pacman(self):
        mock = Path(self._tmp.name) / "mock.txt"
        mock.write_text(CHROME + CHROMIUM)
        first = self.check("--mock-updates", str(mock))
        self.assertEqual(first.returncode, 0, first.stderr)
        self.check("--mock-updates", str(mock))
        self.assertEqual(len(self.env.notifications()), 1)  # de-duplicated too
        self.assertFalse(self.env.state_file().exists())
        self.assertTrue(self.env.state_file("mock-state.json").exists())
        for name in ("pacman", "checkupdates", "paru", "yay"):
            self.assertEqual(self.env.calls(name), [])

    def test_no_notify_flag_detects_only(self):
        self.env.stub("paru", {"stdout": CHROME})
        self.check("--no-notify")
        self.assertEqual(self.env.notifications(), [])
        self.assertEqual(self.env.read_state()["notified"], {})

    def test_notify_test_command(self):
        result = self.env.run("notify-test")
        self.assertEqual(result.returncode, 0, result.stderr)
        (call,) = self.env.notifications()
        self.assertIn("テスト通知", call[-1])

    def test_reset_forgets_notified_updates(self):
        self.env.stub("paru", {"stdout": CHROME})
        self.check()
        self.assertEqual(self.env.run("reset").returncode, 0)
        self.check()
        self.assertEqual(len(self.env.notifications()), 2)

    def test_status_runs(self):
        self.check()
        result = self.env.run("status")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("google-chrome", result.stdout)
        self.assertIn("Notification server: quickshell", result.stdout)

    def test_never_runs_anything_that_upgrades(self):
        self.env.stub("paru", {"stdout": CHROME})
        self.env.stub("checkupdates", {"stdout": CHROMIUM})
        self.check()
        # only read-only queries are allowed: pacman -Q / -Qmq, paru|yay -Qua, checkupdates
        allowed = {"pacman": {"-Q", "-Qmq"}, "paru": {"-Qua"}, "yay": {"-Qua"}, "checkupdates": set()}
        for name, flags in allowed.items():
            for call in self.env.calls(name):
                self.assertTrue(set(call[1:2]) <= flags, f"unexpected command: {call}")


if __name__ == "__main__":
    unittest.main()
