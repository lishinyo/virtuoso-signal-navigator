#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""Verify a release ZIP, its exact file manifest and frozen runtime. No extraction."""
import argparse
import hashlib
from pathlib import Path, PurePosixPath
import re
import zipfile


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def verify(path):
    sidecar = Path(str(path) + ".sha256")
    if sidecar.exists():
        fields = sidecar.read_text(encoding="utf-8").strip().split(None, 1)
        if len(fields) != 2 or fields[1] != path.name or fields[0] != sha256(path.read_bytes()):
            raise ValueError("ZIP checksum mismatch")
    with zipfile.ZipFile(path) as z:
        names = z.namelist()
        if len(names) != len(set(names)) or not names:
            raise ValueError("Empty archive or duplicate member names")
        for name in names:
            parts = PurePosixPath(name).parts
            if (not parts or name.startswith("/") or "\\" in name or ":" in name
                    or ".." in parts or name.endswith("/")
                    or (z.getinfo(name).external_attr >> 16) & 0o170000 == 0o120000):
                raise ValueError("Unsafe or unexpected ZIP member: " + name)
        roots = {PurePosixPath(n).parts[0] for n in names}
        if len(roots) != 1:
            raise ValueError("Expected a single project root")
        prefix = roots.pop() + "/"
        contents = {n[len(prefix):]: z.read(n) for n in names}
    if "SHA256SUMS" not in contents:
        raise ValueError("Missing SHA256SUMS")
    manifest = {}
    for line in contents["SHA256SUMS"].decode("utf-8").splitlines():
        match = re.fullmatch(r"([a-f0-9]{64})  (.+)", line)
        if not match or match[2] in manifest:
            raise ValueError("Invalid or duplicate manifest record")
        manifest[match[2]] = match[1]
    if set(manifest) != set(contents) - {"SHA256SUMS"}:
        raise ValueError("Manifest and archive file sets disagree")
    for name, digest in manifest.items():
        if sha256(contents[name]) != digest:
            raise ValueError("File checksum mismatch: " + name)
    version = contents["VERSION"].decode("utf-8").strip()
    if prefix != "virtuoso-signal-navigator-" + version + "/":
        raise ValueError("Archive root and VERSION disagree")
    release = contents["RELEASE.md"].decode("utf-8")
    frozen = re.search(r"^runtime-sha256-lf: ([a-f0-9]{64})$", release, re.MULTILINE)
    frozen_version = re.search(r"^runtime-version: (\S+)$", release, re.MULTILINE)
    runtime = contents["src/signal_navigator.il"]
    if (not frozen or not frozen_version or frozen_version[1] != version
            or sha256(runtime) != frozen[1]
            or 'lsnVersion="' + version + '"' not in runtime.decode("utf-8")):
        raise ValueError("Frozen runtime/version mismatch")
    if b"MIT License" not in contents["LICENSE"]:
        raise ValueError("MIT license missing")
    return version, len(manifest), sidecar.exists()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path)
    args = parser.parse_args()
    try:
        version, count, sidecar = verify(args.archive)
    except (ValueError, OSError, KeyError, UnicodeError, zipfile.BadZipFile) as error:
        parser.exit(1, str(error) + "\n")
    print("Verified:", version, ";", count, "files; frozen runtime matches")
    print("ZIP sidecar:", "verified" if sidecar else "not supplied; internal manifest verified only")


if __name__ == "__main__":
    main()
