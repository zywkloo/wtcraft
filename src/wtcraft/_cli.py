"""
Entry point for pip / pipx installations.

Locates the bundled shell script and templates, injects WTCRAFT_TEMPLATE_DIR
into the environment, then exec-replaces itself with bash.
"""

import os
import shutil
import sys


def main() -> None:
    pkg_dir = os.path.dirname(os.path.abspath(__file__))

    shell_path = os.path.join(pkg_dir, "_shell.sh")
    tmpl_dir = os.path.join(pkg_dir, "templates")

    # Editable / source installs: fall back to the repo layout
    if not os.path.isfile(shell_path):
        shell_path = os.path.join(pkg_dir, "..", "..", "scripts", "wtcraft")
    if not os.path.isdir(tmpl_dir):
        tmpl_dir = os.path.join(pkg_dir, "..", "..", "templates")

    shell_path = os.path.realpath(shell_path)
    tmpl_dir = os.path.realpath(tmpl_dir)

    if not os.path.isfile(shell_path):
        print(f"wtcraft: cannot locate shell script at {shell_path}", file=sys.stderr)
        sys.exit(1)
    if not os.path.isdir(tmpl_dir):
        print(f"wtcraft: cannot locate templates at {tmpl_dir}", file=sys.stderr)
        sys.exit(1)

    env = os.environ.copy()
    env["WTCRAFT_TEMPLATE_DIR"] = tmpl_dir

    # Stamp the resolved package version so the shell reports it even when no
    # manifest sits beside the installed script (the pip/pipx layout). The value
    # comes from the installed package metadata, the single source of truth.
    if "WTCRAFT_VERSION" not in env:
        try:
            from importlib.metadata import PackageNotFoundError, version

            try:
                env["WTCRAFT_VERSION"] = version("wtcraft")
            except PackageNotFoundError:
                pass
        except ImportError:  # Python < 3.8: leave it to the shell's fallback
            pass

    bash = shutil.which("bash") or r"C:\Program Files\Git\bin\bash.exe"
    os.execve(bash, [bash, shell_path] + sys.argv[1:], env)


if __name__ == "__main__":
    main()
