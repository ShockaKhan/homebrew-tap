#!/usr/bin/env python3
"""Install a tap cask, verify what it put on disk, optionally launch it, then uninstall.

Usage: check_cask.py CASK [--smoke]   (--smoke needs DISPLAY, e.g. under xvfb-run)
"""

import json
import os
import re
import shlex
import signal
import subprocess
import sys
import tempfile
import time
from pathlib import Path

TAP = os.environ.get("TAP", "shockakhan/tap")


def brew(*args, capture=False):
    result = subprocess.run(["brew", *args], check=True, text=True,
                            stdout=subprocess.PIPE if capture else None)
    return result.stdout


def targets(token):
    """Absolute paths the cask links or copies into place, from its artifact list."""
    casks = json.loads(brew("info", "--cask", "--json=v2", f"{TAP}/{token}", capture=True))["casks"]
    return [Path(a["target"]) for a in casks[0]["artifacts"] if "target" in a]


def desktop_exec(path):
    for line in path.read_text().splitlines():
        if line.startswith("Exec="):
            return shlex.split(re.sub(r"%[a-zA-Z]", "", line[5:]))
    raise SystemExit(f"{path}: no Exec= line")


def verify_installed(paths):
    for path in paths:
        if not path.exists():  # follows symlinks, so dangling links fail too
            raise SystemExit(f"missing after install: {path}")
        if path.suffix == ".desktop":
            command = desktop_exec(path)
            if not os.access(command[0], os.X_OK):
                raise SystemExit(f"{path}: Exec target is not executable: {command[0]}")
            if not any(line.startswith("Icon=") for line in path.read_text().splitlines()):
                raise SystemExit(f"{path}: no Icon= line")
    print(f"verified {len(paths)} installed paths")


def named_windows():
    tree = subprocess.run(["xwininfo", "-root", "-tree"], text=True,
                          capture_output=True, check=True).stdout
    return len(re.findall(r'^\s+0x[0-9a-f]+ "[^"]+"', tree, re.MULTILINE))


def smoke(paths):
    """Launch the app with throwaway XDG dirs; require a window that survives 5 s."""
    desktops = [p for p in paths if p.suffix == ".desktop"]
    if not desktops:
        raise SystemExit("--smoke requested but the cask installs no .desktop entry")
    command = desktop_exec(desktops[0])
    with tempfile.TemporaryDirectory(prefix="smoke-") as home:
        env = {**os.environ, "GDK_BACKEND": "x11"}
        env.pop("ELECTRON_RUN_AS_NODE", None)
        for key, name in (("XDG_CONFIG_HOME", "config"), ("XDG_CACHE_HOME", "cache"),
                          ("XDG_DATA_HOME", "data")):
            env[key] = f"{home}/{name}"
        baseline = named_windows()
        log = Path(home) / "launch.log"
        with log.open("w") as out:
            process = subprocess.Popen(command, env=env, stdout=out, stderr=subprocess.STDOUT,
                                       start_new_session=True)
        try:
            deadline = time.monotonic() + 90
            while time.monotonic() < deadline:
                if process.poll() is not None:
                    raise SystemExit(f"{command[0]} exited early ({process.returncode})")
                if named_windows() > baseline:
                    time.sleep(5)
                    if process.poll() is None and named_windows() > baseline:
                        print(f"{command[0]} opened a window and stayed up")
                        return
                time.sleep(1)
            raise SystemExit(f"{command[0]} opened no window within 90 s")
        finally:
            print(log.read_text()[-4000:])
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    token, do_smoke = sys.argv[1], "--smoke" in sys.argv[2:]
    brew("install", "--cask", f"{TAP}/{token}")
    paths = targets(token)
    verify_installed(paths)
    if do_smoke:
        smoke(paths)
    brew("uninstall", "--cask", f"{TAP}/{token}")
    left = [p for p in paths if p.exists() or p.is_symlink()]
    if left:
        raise SystemExit(f"left behind after uninstall: {', '.join(map(str, left))}")
    print("uninstall left nothing behind")


if __name__ == "__main__":
    main()
