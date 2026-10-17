# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.7.0] - 2026-10-17

Full Changelog: https://github.com/dnlhrth01/rvsdesk/compare/v1.6.0...v1.7.0

### Added

- RVDesk rebrand installer support: `installer/RVSDesk.iss` gained guarded defines
  `AppName`, `AppExeName`, and `PrivReq` (branding-independent defaults `RVSDesk`,
  `RVSDesk.exe`, `admin`) alongside the pre-existing `OutputBase` guard, so one
  script builds both the RVSDesk and RVDesk setup exes.
- `installer/build_installer.ps1` gained `-AppName`, `-AppExeName`, and
  `-OutputBaseOverride` parameters (passed to ISCC as `/D` defines) plus a staged
  payload presence check: when the required exe is missing the build stops with
  exit 3.
- Reverse-engineering writeup `docs/RVDesk-Installer-RE.md`: root cause that
  `dist\RVSDesk.exe` shipped in the installer was the stock RustDesk 1.5.0 engine
  with a resources-only rebrand (section hashes identical to the official base,
  dangling certificate table), plus the corrected signed RVDesk rebuild pipeline.
- `re_work/` research corpus behind the writeup (commit `5a24cdf1`, subject `[P]`):
  innoextract 1.9 and the innox/Go wrapper with toolchain fixtures, extracted 1.6.0
  installer contents, PE resource dumps and section-hash evidence, UAC/WMI
  automation captures, rebrand and smoke-build outputs, and
  `re_work/payload_rvdesk/` (RVDesk.exe, RVSDesk_Authority.cer,
  Setup_Trust_RVSDesk.bat).
- `$schema` key in `.kilo/kilo.jsonc` (commit `1764c870`, message mentions a CI
  workflow, but only this file changed).

### Changed

- `installer/RVSDesk.iss` substitutes `{#AppName}`, `{#AppExeName}`, and `{#PrivReq}`
  throughout `[Setup]`, `[Icons]`, and `[Run]` (display name, Start menu/desktop
  shortcuts, uninstall entry/icon, launch task, privilege requirement) instead of
  hard-coded RVSDesk strings.
- `installer/build_installer.ps1` builds the ISCC argument list programmatically
  with the optional `/DAppName`, `/DAppExeName`, `/DOutputBase` defines and derives
  the expected setup exe name from `-OutputBaseOverride`.
- Repository history now carries the installer RE tooling and evidence tree under
  `re_work/` (~18,200 files added by `5a24cdf1`; range total 18,221 files changed,
  4,389,556 insertions, 12 deletions).

### Fixed

- Branded builds can no longer package the wrong payload: `build_installer.ps1`
  verifies the staged payload contains the exe named by `-AppExeName` (hard
  exit 3) before ISCC runs; the previous check only looked for a hard-coded
  `RVSDesk.exe`.
- The mis-signed 1.6.0 RVDesk payload is root-caused and documented
  (`docs/RVDesk-Installer-RE.md`) so the corrected pipeline re-signs the rebranded
  binary instead of shipping the stock engine.

## [1.6.0] - 2026-10-16

### Added

- Inno Setup 6 installer project: `installer/RVSDesk.iss`, `installer/VERSION`,
  `installer/build_installer.ps1`, and README install documentation.
- CI builds the installer and publishes the setup exe to the GitHub Release on
  `v*` tags (and appends to the `latest` release on `main` pushes).

### Fixed

- Single-quoted expression literals in the installer workflow (`if:`/`${{ }}`
  validation failure).
- VERSION resolution guard: refs that are not `x.y.z` keep the committed
  `installer/VERSION`.
- Cert resolution and signtool verify are gated off when signing is disabled, so
  unsigned CI builds succeed.

## [1.5.0]

- Baseline release of the original 1.5.0-era RVSDesk.

[1.7.0]: https://github.com/dnlhrth01/rvsdesk/compare/v1.6.0...v1.7.0
[1.6.0]: https://github.com/dnlhrth01/rvsdesk/compare/v1.5.0...v1.6.0
[1.5.0]: https://github.com/dnlhrth01/rvsdesk/releases/tag/v1.5.0