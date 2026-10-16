# RVSDesk Installer

## Purpose

Standard Windows `.exe` setup for RVSDesk built with Inno Setup 6, replacing the hand-rolled
batch installer for end users: versioned, upgradable, maintainable.

## Why Inno Setup

Inno Setup is free, script-based (the `.iss` lives in git, so the installer definition versions
and reviews with the code), and emits a single self-contained setup `.exe` with a built-in
uninstaller. Upgrades are in-place: a fixed `AppId` makes a new setup silently remove the old
version first, while a `[Code]` downgrade guard blocks older releases, and `ISCC.exe` is easy to
drive from PowerShell or CI. NSIS (older, more manual), WiX (MSI-oriented, heavier for one desktop
exe), and Advanced Installer (commercial) were all heavier or paid for this use case.

## Files in this folder

- `RVSDesk.iss` - installer definition (Inno Setup 6 script).
- `VERSION` - single source of truth for the version, format `x.y.z`.
- `build_installer.ps1` - build, sign, and verify pipeline.
- `Output\\` - build artifacts (`RVSDesk-Setup-<version>.exe`, ISCC log); gitignore-able.
- `build\\` - payload staging directory; gitignored.

## Prerequisites

- Windows 10 or later; the script is Windows PowerShell 5.1 compatible.
- Inno Setup 6.3+ (required for the `x64compatible` architecture identifiers): `choco install innosetup` or innosetup.org. `ISCC.exe` is auto-discovered,
  override with `ISCC_PATH`.
- `signtool.exe` from the Windows SDK or WDK (auto-discovered in the newest installed kit),
  override with `SIGNTOOL_EXE`.
- A code-signing certificate (EKU `1.3.6.1.5.5.7.3.3`) with a private key in
  `Cert:\CurrentUser\My` or `Cert:\LocalMachine\My`; newest valid is auto-discovered, pin with
  `CERT_THUMB`.

## Build

PowerShell, from the repo root or the `installer` folder:

```powershell
powershell -ExecutionPolicy Bypass -File installer\build_installer.ps1
```

Result: `installer\Output\RVSDesk-Setup-<version>.exe`.
Useful switches and environment variables:

- `-Version 1.7.0` override `VERSION` for this run.
- `-SkipPayloadSigning`, `-SkipSetupSigning`, `-SkipVerify` skip those pipeline stages.
- `CERT_THUMB`, `SIGNTOOL_EXE`, `ISCC_PATH` pin the certificate and tool locations; `-CertThumb` is the CLI parameter alternative to the `CERT_THUMB` env var.
- `REQUIRE_TIMESTAMP=0` allow signing without an RFC 3161 timestamp if all servers are down.
Exit codes: `1` bad args/version, `2` ISCC not found, `3` payload staging failed, `4` cert/signtool
missing or payload signing failed, `5` compile failed, `6` setup signing/verification failed.

## Shipping a new version

1. Rebuild the app binaries into `dist\` (existing CI/build pipeline).
2. Bump `installer\VERSION` (semver `x.y.z`).
3. Run `build_installer.ps1`.
4. Smoke-test the setup on a clean VM: install, upgrade-over-old, uninstall.
5. Publish `RVSDesk-Setup-<version>.exe` as a GitHub Release.

Nothing else needs redoing: only `VERSION` and the binaries change - the `.iss` never changes for
routine releases. The fixed `AppId` means installing the new setup automatically uninstalls the
previous version (settings preserved via `UsePreviousAppDir`), and installing an OLDER setup over
a newer install is blocked by the `[Code]` downgrade guard.

## Versioning scheme

- `VERSION` holds the user-facing version as `x.y.z`.
- The build derives `x.y.z.0` (padded to 4 parts) for the Windows `VersionInfo*` fields.
- The output filename embeds the version: `RVSDesk-Setup-<version>.exe`.

## Signing

- Payload binaries (`*.exe`, `*.dll`, `*.ocl`) are signed before packaging; the setup exe is
  signed after the ISCC compile; both are verified with `signtool verify /pa`.
- RFC 3161 timestamp servers are retried in order (`timestamp.digicert.com`,
  `timestamp.sectigo.com`, `timestamp.globalsign.com`).
- Strict by default: a payload that cannot be signed fails the build. Known issue: a stale
  `dist\RVSDesk.exe` produces `ERROR_BAD_EXE_FORMAT 0x800700C1` (corrupt PE) - rebuild the exe
  or temporarily use `-SkipPayloadSigning`.

## CI

`.github/workflows/build-installer.yml` builds `RVSDesk-Setup-<version>.exe` and publishes it to a
GitHub Release:

- On a `v*` tag push: builds `RVSDesk-Setup-<tag-version>.exe` (tag minus the leading `v`) and
  appends it to that version's Release, next to the `RVSDesk-Portable.exe` that
  `build-rvsdesk.yml` publishes there.
- On manual `workflow_dispatch`: builds with the input version, or the committed `installer\VERSION`
  when the input is empty, and publishes to the rolling prerelease tagged `latest`.
- The setup exe is signed only when the repo secrets `SIGNING_PFX_B64` (base64-encoded PFX) and
  `SIGNING_PFX_PASSWORD` (its password) are configured; otherwise it falls back to an unsigned
  build.
- Payload signing stays off in CI until the committed `dist\` binaries are signable; the
  release-critical full signing run remains local via `build_installer.ps1` on the maintainer
  machine.
- The `gh` CLI creates the release if missing and uploads with `--clobber`, so both workflows can
  share one release (distinct asset names, no clash).

## Uninstall and upgrade behavior for end users

- Standard Add/Remove Programs entry named `RVSDesk`, desktop icon optional (unchecked by default).
- Upgrade in place: run the newer setup, the old version is removed automatically and the install
  directory is reused.
- Uninstall removes program files; `UninstallDelete` cleans the `logs` folder and `*.log`.
- Logs also live in `%ProgramData%\RVSDesk\logs` (written by the app/batch tooling, not the
  installer).
