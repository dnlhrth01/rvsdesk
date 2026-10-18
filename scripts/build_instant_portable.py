#!/usr/bin/env python3
r"""DEPRECATED - do not use this script to produce distributables.

The old "instant portable" path downloaded a stock RustDesk binary from GitHub
and rcedit-branded it as RVSDesk.exe. That is retired: the RVDesk line must be
built from the local engine input and branded by the supported pipeline.

Supported RVDesk build pipeline:

    powershell -File scripts\build_rvdesk_payload.ps1
    powershell -File installer\build_installer.ps1

Stage 1 builds the RVDesk payload (strip Authenticode, rcedit resource rebrand
of dist\engine_base.exe, stage RVDesk_Authority.cer + Setup_Trust_RVDesk.bat).
Stage 2 stages that payload, signs it and compiles RVDesk-Setup-<version>.exe
with Inno Setup (installer\RVSDesk.iss).
"""

import sys


def main() -> int:
    print("scripts/build_instant_portable.py is DEPRECATED and produces nothing.")
    print("It must not be used to produce distributables.")
    print("")
    print("Use the RVDesk build pipeline instead:")
    print("  1) powershell -File scripts\\build_rvdesk_payload.ps1")
    print("  2) powershell -File installer\\build_installer.ps1")
    return 1


if __name__ == "__main__":
    sys.exit(main())
