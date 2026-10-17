# RVSDesk 1.7.0

Released 2026-10-17. Full changelog: https://github.com/dnlhrth01/rvsdesk/compare/v1.6.0...v1.7.0

## What's new since v1.6.0

- **RVDesk rebrand installer support** - `installer/RVSDesk.iss` gained guarded
  branding defines (`AppName`, `AppExeName`, `PrivReq`, alongside the existing
  `OutputBase`) with branding-independent defaults, so one script builds both the
  RVSDesk and RVDesk setup exes.
- **Branded build parameters** - `build_installer.ps1` gained `-AppName`,
  `-AppExeName`, and `-OutputBaseOverride` (passed to ISCC as `/D` defines) plus a
  staged-payload presence check that fails with exit 3 when the required exe is
  missing, so a wrong payload can never be packaged.
- **Reverse-engineering writeup** - `docs/RVDesk-Installer-RE.md` documents the
  root cause of the bad 1.6.0 RVDesk payload (`dist\RVSDesk.exe` was the stock
  RustDesk engine with a resources-only rebrand) and the corrected signed RVDesk
  pipeline.
- **Research corpus** - the `re_work/` tree behind the writeup: innoextract/innox
  tooling, PE and section-hash evidence, UAC capture logs, and the RVDesk payload
  with `RVSDesk_Authority.cer` and `Setup_Trust_RVSDesk.bat`.
- **Kilo config** - `.kilo/kilo.jsonc` now carries a `$schema` entry.

## Install and verify

Both setup exes are signed with the self-signed RVSDesk authority, so Windows
shows a SmartScreen/unknown-publisher prompt on first use. Run
`Setup_Trust_RVSDesk.bat` once as Administrator (ships beside the setup / in
`re_work/payload_rvdesk/`) to trust `RVSDesk_Authority.cer`, then install
normally. SHA-256 checksums (fill in after the build):

- RVSDesk-Setup-1.7.0.exe: `TBD`
- RVDesk-Setup-1.7.0.exe: `TBD`
- RVSDesk-Portable.exe: `TBD`
- RVSDesk-Portable.zip: `TBD`

## Artifacts

- `RVSDesk-Setup-1.7.0.exe` - RVSDesk-branded Inno Setup installer.
- `RVDesk-Setup-1.7.0.exe` - RVDesk-branded Inno Setup installer (`-AppName RVDesk
  -AppExeName RVDesk.exe -OutputBaseOverride RVDesk-Setup-1.7.0`).
- `RVSDesk-Portable.exe` - CI-attached single-file portable build.
- `RVSDesk-Portable.zip` - CI-attached portable package (exe + launcher + cert).