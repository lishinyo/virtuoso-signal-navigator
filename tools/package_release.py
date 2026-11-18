#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""Audit and package the explicit public source tree. Standard library only."""
import argparse
import hashlib
from pathlib import Path
import re
import zipfile

ROOT_FILES = {
    "README.md", "README.zh-CN.md", "LICENSE", "VERSION", "CHANGELOG.md",
    "CONTRIBUTING.md", "RELEASE.md", ".gitignore", ".gitattributes",
}
PUBLIC_DIRS = {"src", "docs", "examples", "tests", "tools"}
TEXT_SUFFIXES = {".il", ".md", ".py", ".tf"}
PRIVATE_SUFFIXES = {".oa", ".gds", ".gdsii", ".oasis", ".oas", ".db", ".mph"}


def check_skill_balance(text, name):
    """Catch unclosed delimiters/strings; this is not a SKILL parser."""
    stack = []
    quote = False
    escaped = False
    comment = False
    line = 1
    pairs = {")": "(", "]": "["}
    for char in text:
        if char == "\n":
            line += 1
            comment = False
        if comment:
            continue
        if quote:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                quote = False
            continue
        if char == ";":
            comment = True
        elif char == '"':
            quote = True
        elif char in "([":
            stack.append((char, line))
        elif char in ") ]".replace(" ", ""):
            if not stack or stack[-1][0] != pairs[char]:
                raise ValueError("Unbalanced delimiter in " + name + ":" + str(line))
            stack.pop()
    if quote or stack:
        raise ValueError("Unclosed string/delimiter in " + name + ": " + str(stack[-1:] ))


def public_files(root):
    files = []
    for name in sorted(ROOT_FILES):
        path = root / name
        if path.is_symlink():
            raise ValueError("Refusing symlink in public tree: " + str(path))
        if not path.is_file():
            raise ValueError("Missing required root file: " + name)
        files.append(path)
    for directory in sorted(PUBLIC_DIRS):
        for path in sorted((root / directory).rglob("*")):
            if path.is_symlink():
                raise ValueError("Refusing symlink in public tree: " + str(path))
            if not path.is_file():
                continue
            if "__pycache__" in path.parts:
                continue
            if path.name.lower().endswith(".local.il"):
                raise ValueError("Keep personal *.local.il outside public directories: " + str(path))
            if path.suffix.lower() not in TEXT_SUFFIXES:
                raise ValueError("Unexpected file in public directory: " + str(path))
            files.append(path)
    return sorted(set(files))


def audit(root, files):
    errors = []
    required = ["src/signal_navigator.il", "tests/config_smoke.il", "tests/demo_fixture.il",
                "docs/INSTALL.md", "docs/USER_GUIDE.md", "docs/PORTING.md",
                "docs/COMPATIBILITY.md", "docs/TESTING.md", "docs/VALIDATION.md",
                "docs/PAD_CONNECTION.md", "docs/PAD_PORTING.md", "docs/MAINTAINER_HANDOFF.md",
                "examples/site_config.template.il", "examples/design_targets.template.il",
                "tools/verify_release.py", "RELEASE.md"]
    for rel in required:
        if not (root / rel).is_file():
            errors.append("Missing required file: " + rel)
    version = (root / "VERSION").read_text(encoding="utf-8").strip()
    source = (root / "src/signal_navigator.il").read_text(encoding="utf-8")
    if 'lsnVersion="' + version + '"' not in source:
        errors.append("VERSION and runtime lsnVersion disagree")
    release = (root / "RELEASE.md").read_text(encoding="utf-8")
    frozen_version = re.search(r"^runtime-version: (\S+)$", release, re.MULTILINE)
    frozen_hash = re.search(r"^runtime-sha256-lf: ([a-f0-9]{64})$", release, re.MULTILINE)
    if not frozen_version or frozen_version.group(1) != version:
        errors.append("RELEASE.md and VERSION disagree")
    if not frozen_hash or hashlib.sha256(source.encode("utf-8")).hexdigest() != frozen_hash.group(1):
        errors.append("Frozen runtime changed; use a new version and update RELEASE.md deliberately")
    runtime_forbidden = ["dbSave(", "dbCreate", "dbDelete", "ddDelete", "techSave", "system("]
    for token in runtime_forbidden:
        if token in source:
            errors.append("Unexpected database-write/shell API in runtime: " + token)
    for path in files:
        relative = path.relative_to(root).as_posix()
        if path.suffix.lower() in PRIVATE_SUFFIXES or path.name.startswith(".env"):
            errors.append("Private data type: " + relative)
        content = path.read_text(encoding="utf-8")
        if path.suffix == ".il":
            check_skill_balance(content, relative)
        # These regexes detect concrete workstation paths, not placeholder
        # examples such as /path/to/... or a normal /tmp demo directory.
        for pattern in [r"/home/(?!user(?:/|\b)|username(?:/|\b))[A-Za-z0-9._-]+/",
                        r"/mnt/[a-z]/", r"[A-Za-z]:[\\/]Users[\\/][^\s\"']+[\\/]",
                        r"(?i)(?:api[_-]?key|access[_-]?token|password)\s*=\s*[\"'][^\"']{12,}"]:
            if re.search(pattern, content):
                errors.append("Possible private path/credential in " + relative)
        if path.suffix == ".md":
            for link in re.findall(r"\]\(([^\n)]+)\)", content):
                target = link.strip("<>").split("#", 1)[0]
                if not target or "://" in target or target.startswith("mailto:"):
                    continue
                # No spaces are used in the project's internal link targets.
                if not (path.parent / target).exists():
                    errors.append("Broken local link: " + relative + " -> " + target)
    if errors:
        raise ValueError("\n".join(errors))
    return version


def build(root, files, version, output):
    output = output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    if output.exists() or Path(str(output) + ".sha256").exists():
        raise ValueError("Refusing to overwrite an existing release or checksum: " + str(output))
    archive_root = "virtuoso-signal-navigator-" + version + "/"
    entries = []
    for path in files:
        data = path.read_text(encoding="utf-8").replace("\r\n", "\n").encode("utf-8")
        entries.append((path.relative_to(root).as_posix(), data))
    manifest = "".join(hashlib.sha256(data).hexdigest() + "  " + name + "\n"
                       for name, data in entries).encode("utf-8")
    with zipfile.ZipFile(output, "x", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as package:
        for name, data in entries + [("SHA256SUMS", manifest)]:
            info = zipfile.ZipInfo(archive_root + name, date_time=(2026, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            package.writestr(info, data)
    digest = hashlib.sha256(output.read_bytes()).hexdigest()
    Path(str(output) + ".sha256").write_text(digest + "  " + output.name + "\n", encoding="utf-8")
    return digest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check-only", action="store_true")
    parser.add_argument("--output", type=Path,
                        help="New ZIP path; default: project-root/dist/virtuoso-signal-navigator-VERSION.zip")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    try:
        files = public_files(root)
        version = audit(root, files)
    except ValueError as error:
        parser.exit(1, str(error) + "\n")
    print("Audit passed:", len(files), "public text files; version", version)
    if not args.check_only:
        output = args.output or root / "dist" / ("virtuoso-signal-navigator-" + version + ".zip")
        try:
            digest = build(root, files, version, output)
        except ValueError as error:
            parser.exit(1, str(error) + "\n")
        print("Archive:", output.resolve())
        print("SHA-256:", digest)


if __name__ == "__main__":
    main()
