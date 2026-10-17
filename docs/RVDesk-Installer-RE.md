# RVDesk Installer RE & Rebuild (RustDesk 1.5.0 rebrand)

Reverse-engineering of the shipping RVSDesk Inno Setup installer, root-cause of its
wrong-binary payload, and the corrected rebrand + signing + packaging pipeline that
produces `RVDesk-Setup-1.5.0.exe`. All hashes and paths below were verified against
the files on disk; evidence ids are REA Evidence records.

## 1. Investigation targets

- `Output\t.exe` (2,096,757 B, SHA f5821b50ab3f836a120532bb4d78c7979b61fbf898e4982d59b467e7eb4234d3):
  Inno Setup 6.7.0 test installer "T" v1.0, installs to `{tmp}`,
  FileEntries=1 with NO data (0 bytes, location 0xFFFFFFFF) - installs nothing
  (empty/wrong-source build; a decoy, not the shipping installer).
- `C:\Users\User\Downloads\RVSDesk-Setup-1.6.0.exe`
  (52,793,376 B, SHA e17dd26a6fa0b7d48621ebcf7b326e26170b6e894e51d42d1477a786723da177):
  the project's Inno installer ("RVSDesk" 1.6.0,
  AppId {3D92DD6B-C0B8-464B-BC15-795B5425B4D0}) - THE installer under investigation.

## 2. Stage-by-stage method and findings

- Stage 1 - dump/inventory: REA PE resource parser (Evidence ev_8f8c6cd5 for t.exe,
  ev_c9392085 stock engine_base, ev_a60c178c dist RVSDesk.exe); REA artifact summary
  (ev_54e08c2b); `extract_artifact` unsupported for PE; binwalk provider Linux-only -
  so extraction went to innoextract 1.9 + Go "innox" wrapper (innoextract 1.9 cannot
  read Inno 6.7 data: "Unexpected setup loader revision: 2 / Could not determine setup
  data version"). Tools in `re_work\tools`.
- Stage 2 - unpack: `innox info/list/extract` of RVSDesk-Setup-1.6.0.exe -> 6 files into
  `{app}` (`re_work\extract_setup16`, `re_work\setup16_inventory.txt`).
  Setup metadata (`re_work\setup16_info.txt`): AppName RVSDesk, AppVersion 1.6.0,
  DefaultDir {autopf}\RVSDesk. Extracted RVSDesk.exe == dist\RVSDesk.exe (310bd9f4db59...)
  and extracted engine_base.exe == stock (855577721551...) byte-for-byte.
- Stage 3 - root cause (see section 3 below) with section-level SHA proof in
  `re_work\section_compare.txt`.
- Stage 4 - stock binary + resource set: stock = `dist\engine_base.exe` ==
  `Downloads\rustdesk-1.5.0-x86_64.exe`
  (25,887,600 B, SHA 8555777215510d83d2d61c9dc984e4fcc838bd7e79f9d18a42585431f5e8bb47,
  PURSLANE/EV-signed, Product RustDesk 1.5.0); REA resource inventory: 8 resources
  (icons 16/32/48/64/128, VERSIONINFO 680 B, MANIFEST 1371 B).
- Stage 5 - rebrand: `re_work\rebrand\build.log` - copy stock -> strip signature (dd#4
  zeroed at file offset 416, truncated 25,887,600 -> 25,879,040) -> rcedit (icon
  `assets\rvsdesk.ico`, file/product version 1.5.0.0, CompanyName "RithV Services",
  ProductName "RVDesk", FileDescription "RVDesk Remote Desktop",
  InternalName/OriginalFilename RVDesk(.exe),
  LegalCopyright "Copyright (c) 2026 Purslane Tech Pte. Ltd. and contributors;
  RVDesk by RithV Services (AGPL-3.0)", Comments "Based on RustDesk ... AGPL-3.0" -
  original credits retained). Section verify: only `.rsrc` changed (38,300 vs stock
  102,224); .text/.rdata/.data/.pdata/.fptable/.reloc byte-identical to stock.
- Stage 6 - repackage: `installer\RVSDesk.iss` gained guarded defines
  AppName/AppExeName/OutputBase/PrivReq (+ `build_installer.ps1` params -AppName
  -AppExeName -OutputBaseOverride and payload presence check, exit 3); build command:

      installer\build_installer.ps1 -Version 1.5.0 -AppName RVDesk -AppExeName RVDesk.exe -OutputBaseOverride RVDesk-Setup-1.5.0 -PayloadSource re_work\payload_rvdesk -OutputDir re_work\rvdesk_out -SkipPayloadSigning -CertThumb B1D369A99A35F7B7EE5FBEA1333A861B1EC5D02D

  -> `re_work\rvdesk_out\RVDesk-Setup-1.5.0.exe` (27,468,928 B,
  SHA F9532756E1292BA611E5DB59CE3570B367F235EF2A6BAF583484B1BD62985B7D,
  Authenticode Valid, DigiCert RFC3161 TSA).
- Stage 7 - clean install: UAC consent runs on the secure desktop and cannot be
  automated from these sessions, so verification used an equivalent low-privilege test
  build (`/DPrivReq=lowest`, same payload) installed non-elevated to a temp dir:
  `re_work\clean_install2.log` - 16/16 assertions PASS (installed RVDesk.exe SHA ==
  63AE4E1C...1AB40; cer+bat present; engine_base ABSENT; VersionInfo RithV Services/
  RVDesk/copyright retains Purslane credit; signtool verify /pa exit 0; silent uninstall
  exit 0, dir removed). Evidence copy: `re_work\cleaninstall_evidence\RVDesk-installed.exe`.
  The shipped installer remains PrivilegesRequired=admin (runs normally with a UAC prompt
  on an interactive desktop).
- Stage 8 - signing: `signtool sign /fd SHA256 /sha1 B1D369...` (self-signed
  CN=RVSDesk Security Authority, existing project certificate; RustDesk's own PURSLANE
  private key is not obtainable, so its signature cannot be replicated - documented
  alternative) `/tr http://timestamp.digicert.com /td SHA256 /d "RVDesk Remote Desktop"`
  -> SHA 63AE4E1C4FD205305ADEDF9FDAB8B4537FCE0B1CC3650B611845992BC1A1AB40; cert imported
  to CurrentUser Root + TrustedPublisher; `signtool verify /pa` exit 0 with DigiCert
  timestamp. (REA process-scenario execution was unavailable in this harness; REA tools
  were used for all artifact/resource evidence instead.)

## 3. Root cause (exact point)

The installer pulls the wrong binary at PAYLOAD STAGING: `build_installer.ps1` stages
`dist\*` verbatim (its "==> Staging payload" step) and `RVSDesk.iss` `[Files]`
`Source: "{#PayloadDir}\*" -> {app}` installs it as `{app}\RVSDesk.exe` (the primary app
in [Icons]/[Run]/UninstallDisplayIcon). But `dist\RVSDesk.exe` (310bd9f4db59...) is NOT a
rebranded build: section-level comparison proves every code/data section is byte-identical
to the stock PURSLANE-signed rustdesk-1.5.0 engine - only `.rsrc` was rewritten (product
strings/icons), the Authenticode table was stripped and its directory entry left dangling
(VA 25879040 > EOF 25815040, size 8560 stale) which is why it also fails signing
(0x800700C1). The fresh branding pipeline (`scripts/apply_branding.py` in CI) never writes
a truly rebranded binary into `dist\`, and `dist\engine_base.exe` shipped alongside is the
byte-identical stock official binary (855577721551...). Therefore a clean install executes
stock RustDesk code with only Explorer-visible strings saying RVSDesk; in-app UI remains
stock. Contributing factors: stale hand-patched payload committed to dist; no build-time
verification that payload branding matches expectations; (secondary) t.exe's empty-entry
build pattern shows the same source-path hygiene gap.

The fix: payload must be the freshly rebranded+signed RVDesk.exe (Stage 5-6 pipeline),
never a committed dist binary - and engine_base.exe must not be shipped.

## 4. Build steps (reproduce)

1. Rebrand (copy stock, strip signature, rcedit):

       powershell -File re_work\rebrand\_build.ps1

   (dd#4 zeroed at file offset 416; 25,887,600 -> 25,879,040 -> rcedit ->
   `re_work\rebrand\RVDesk.exe`; section verify logged in `re_work\rebrand\build.log`.)
2. Sign the rebranded exe:

       signtool sign /fd SHA256 /sha1 B1D369A99A35F7B7EE5FBEA1333A861B1EC5D02D /tr http://timestamp.digicert.com /td SHA256 /d "RVDesk Remote Desktop" re_work\rebrand\RVDesk.exe

   -> 25,822,600 B, SHA 63AE4E1C4FD205305ADEDF9FDAB8B4537FCE0B1CC3650B611845992BC1A1AB40.
3. Payload dir layout: `re_work\payload_rvdesk\` containing exactly `RVDesk.exe` (signed),
   `RVSDesk_Authority.cer` (844 B), `Setup_Trust_RVSDesk.bat` (1,199 B).
4. Build the installer:

       installer\build_installer.ps1 -Version 1.5.0 -AppName RVDesk -AppExeName RVDesk.exe -OutputBaseOverride RVDesk-Setup-1.5.0 -PayloadSource re_work\payload_rvdesk -OutputDir re_work\rvdesk_out -SkipPayloadSigning -CertThumb B1D369A99A35F7B7EE5FBEA1333A861B1EC5D02D

5. Low-privilege test build only (never ship): compile the same script/defines with
   `ISCC.exe /DPrivReq=lowest ...` (unsigned; `re_work\clean_install2.log`) ->
   `re_work\rvdesk_out2\RVDesk-Setup-1.5.0-lowpriv.exe`. The shipped installer keeps
   PrivilegesRequired=admin.

## 5. Finished installer layout

Artifact: `re_work\rvdesk_out\RVDesk-Setup-1.5.0.exe` - 27,468,928 B,
SHA F9532756E1292BA611E5DB59CE3570B367F235EF2A6BAF583484B1BD62985B7D, Authenticode Valid
(DigiCert RFC3161 TSA).

Internal file list from innox:

| file | size | sha256 |
| --- | --- | --- |
| RVDesk.exe | 25,822,600 | 63AE4E1C4FD205305ADEDF9FDAB8B4537FCE0B1CC3650B611845992BC1A1AB40 |
| RVSDesk_Authority.cer | 844 | a7cdc575e4b24287041ddd50db2b4c67d25b9627c6d8b30afe3f6f4c2751782a |
| Setup_Trust_RVSDesk.bat | 1,199 | 4a396f565f2429db5a15ab0c05668587574566627afd794a61086c17565f4706 |

Plus unins000.exe/unins000.dat generated at install.

Installed layout: default dir `{autopf}\RVSDesk` (test run: `...\RVDeskTest`) contains
RVDesk.exe, RVSDesk_Authority.cer, Setup_Trust_RVSDesk.bat, unins000.exe/dat;
Start menu + optional desktop shortcut "RVDesk"; uninstall entry DisplayName RVDesk;
launch target RVDesk.exe; AppId GUID {3D92DD6B-C0B8-464B-BC15-795B5425B4D0} unchanged
so it upgrades/replaces prior RVSDesk installs.

Distribution notes: end users run Setup_Trust_RVSDesk.bat once (or check the trust task)
so the self-signed chain validates; AGPL-3.0 obligation: keep Purslane/RustDesk credits
(present in LegalCopyright/Comments) and offer source (this repo).

## 6. Evidence index

`re_work\`: section_compare.txt, setup16_inventory.txt, setup16_info.txt, t_info.txt,
dump_t\*, rebrand\build.log, clean_install2.log, cleaninstall_evidence\, tools\.

REA evidence ids:

- ev_8f8c6cd50ebf467dd19739f3be2126d754c5dbb0a267f79b844a1d0ea45f4a61 (t.exe resources)
- ev_c93920855d1573988de13757e6d67eb60e09eb93929074f4026bc0ff75b7c7cd (stock engine resources)
- ev_a60c178ce27a67d3e406bc733fd657cb52cf9ae2f6a0cbe74468d09490940ffd (dist RVSDesk.exe resources)
- ev_54e08c2b1981416d0c48c27f7fcb3da7822ea73260c548b70b2bdc22212182fe (t.exe artifact summary)
- ev_1801236ff5c6279c8f3eadf9727d321bd97372afb301fa06698a52ee5fb8aa3d (installed signed
  RVDesk.exe: `re_work\cleaninstall_evidence\RVDesk-installed.exe`, SHA 63ae4e1c...,
  9 resources incl. rebranded VERSIONINFO)