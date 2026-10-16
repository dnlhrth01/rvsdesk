@echo off
:: ============================================================================
:: RVSDesk Signed Installer
:: Elevated installer: stages SOURCE_ROOT to WORK_DIR, deploys to INSTALL_DIR,
:: code-signs every .exe/.dll/.ocl with signtool (SHA-256 + RFC3161 timestamp),
:: verifies each binary with "signtool verify /pa", then launches RVSDesk.exe.
:: Usage: Install_RVSDesk.bat [/dry-run] [/no-launch] [/dir="D:\Path"]
:: Exit codes: 0=pass 2=admin/UAC 3=config/source 4=cert 5=signtool
::             6=sign/verify 7=stage/deploy
:: Log: LOG_DIR\RVSDesk_Install_<stamp>.log
:: ============================================================================
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
set "SCRIPT_PATH=%~f0"
set "SCRIPT_NAME=%~nx0"

if not defined INSTALL_DIR set "INSTALL_DIR=C:\Program Files\RVSDesk"
if not defined SOURCE_ROOT set "SOURCE_ROOT=%~dp0"
if not defined WORK_DIR set "WORK_DIR=%TEMP%\RVSDesk_Install"
if not defined STAGING_DIR set "STAGING_DIR=%WORK_DIR%\staging"
if not defined BACKUP_DIR set "BACKUP_DIR=%WORK_DIR%\backup"
if not defined LOG_DIR set "LOG_DIR=%ProgramData%\RVSDesk\logs"
if not defined PRIMARY_APP set "PRIMARY_APP=RVSDesk.exe"
if not defined LAUNCH_APP set "LAUNCH_APP=1"
if not defined CERT_SUBJECT set "CERT_SUBJECT=CN=RVSDesk Code Signing, O=RVS Software, C=US"
if not defined CERT_VALIDITY_YEARS set "CERT_VALIDITY_YEARS=3"
if not defined CERT_THUMB set "CERT_THUMB="
if not defined EXPECTED_SUBJECT set "EXPECTED_SUBJECT="
rem EXPECTED_SUBJECT empty = auto-set from the resolved certificate subject
if not defined SIGNTOOL_EXE set "SIGNTOOL_EXE="
if not defined SIGN_DESCRIPTION set "SIGN_DESCRIPTION=RVSDesk installer package - Authenticode signed"
if not defined TIMESTAMP_URLS set "TIMESTAMP_URLS=http://timestamp.digicert.com http://timestamp.sectigo.com http://timestamp.globalsign.com/tsa/rfc3161"
if not defined TIMESTAMP_ATTEMPTS set "TIMESTAMP_ATTEMPTS=2"
if not defined REQUIRE_TIMESTAMP set "REQUIRE_TIMESTAMP=1"
if not defined BINARY_EXTS set "BINARY_EXTS=.exe .dll .ocl"
if not defined DRY_RUN set "DRY_RUN=0"
if not defined REQUIRE_ADMIN set "REQUIRE_ADMIN=1"
if not defined ALLOW_SELF_ELEVATE set "ALLOW_SELF_ELEVATE=1"
set "WARN_ARGS="

:parseArgs
if "%~1"=="" goto :parseArgsDone
if /i "%~1"=="/dry-run" (set "DRY_RUN=1" & set "REQUIRE_ADMIN=0" & goto :parseArgsNext)
if /i "%~1"=="-dry-run" (set "DRY_RUN=1" & set "REQUIRE_ADMIN=0" & goto :parseArgsNext)
if /i "%~1"=="/no-launch" (set "LAUNCH_APP=0" & goto :parseArgsNext)
set "ARGSTR=%~1"
if /i "!ARGSTR:~0,5!"=="/dir=" (set "INSTALL_DIR=!ARGSTR:~5!" & goto :parseArgsNext)
set "WARN_ARGS=!WARN_ARGS! [%~1]"
:parseArgsNext
shift
goto :parseArgs
:parseArgsDone
set "ELEV_FILE=%SCRIPT_PATH%"
set "ELEV_ARGS=%*"
set "FAILED=0"
set "LAST_ERROR=0"
set /a STAGED_COUNT=0
set /a DEPLOY_NEW=0
set /a DEPLOY_OVER=0
set /a SKIP_COPY=0
set /a BIN_COUNT=0
set /a SIGN_NOW=0
set /a SIGN_SKIP=0
set /a VERIFY_OK=0
set /a VERIFY_FAIL=0
set "CERT_MODE=none"
set "TS_SERVER=none"
set "CURRENT_LOC=:main-admin"
call :ensureAdmin
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" (
    echo [FAIL] Elevation check failed with code !RC!.
    exit /b !RC!
)
goto :phaseLogInit


:ensureAdmin
set "CURRENT_LOC=%~0"

powershell -NoProfile -ExecutionPolicy Bypass -Command "$i=[Security.Principal.WindowsIdentity]::GetCurrent(); $p=New-Object Security.Principal.WindowsPrincipal($i); if($p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){exit 0}else{exit 1}"
set "RC=!ERRORLEVEL!"
if "!RC!"=="0" (
    echo [i] Running elevated as Administrator.
    exit /b 0
)
if "!DRY_RUN!"=="1" (
    echo [i] Dry-run: elevation not required.
    exit /b 0
)
if "!REQUIRE_ADMIN!"=="0" (
    echo [i] Non-elevated run allowed because REQUIRE_ADMIN is 0.
    exit /b 0
)
if not "!ALLOW_SELF_ELEVATE!"=="1" (
    echo [!] Administrator rights required.
    exit /b 2
)
echo [*] Requesting elevation (UAC)...
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $a=$env:ELEV_ARGS; if([string]::IsNullOrWhiteSpace($a)){$p=Start-Process -FilePath $env:ELEV_FILE -Verb RunAs -Wait -PassThru}else{$p=Start-Process -FilePath $env:ELEV_FILE -ArgumentList $a -Verb RunAs -Wait -PassThru}; exit $p.ExitCode } catch { exit 9 }"
set "RC=!ERRORLEVEL!"
if "!RC!"=="9" (
    echo [!] UAC declined by user.
    exit /b 2
)
exit /b !RC!

:phaseLogInit
set "CURRENT_LOC=:main-loginit"
if not exist "%LOG_DIR%" (
    mkdir "%LOG_DIR%" 2>nul
    if not exist "%LOG_DIR%" (
        set "LOG_DIR=%TEMP%\RVSDesk_Install\logs"
        mkdir "!LOG_DIR!" 2>nul
    )
)
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "LOG_STAMP=%%i"
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set "LOG_DATE=%%i"
rem %%s becomes %s for PowerShell inside for /f (unix epoch seconds)
for /f %%i in ('powershell -NoProfile -Command "[int][double]::Parse((Get-Date -Uformat %%s))"') do set "START_EPOCH=%%i"
set "LOG_FILE=%LOG_DIR%\RVSDesk_Install_!LOG_STAMP!.log"
echo === RVSDesk Signed Installer ===
>>"!LOG_FILE!" echo === RVSDesk Signed Installer ===
echo Script: %SCRIPT_PATH%
>>"!LOG_FILE!" echo Script: %SCRIPT_PATH%
echo Started: !LOG_DATE! !TIME!
>>"!LOG_FILE!" echo Started: !LOG_DATE! !TIME!
echo Args: "%*"
>>"!LOG_FILE!" echo Args: "%*"
echo InstallDir: "%INSTALL_DIR%"
>>"!LOG_FILE!" echo InstallDir: "%INSTALL_DIR%"
echo SourceRoot: "%SOURCE_ROOT%"
>>"!LOG_FILE!" echo SourceRoot: "%SOURCE_ROOT%"
echo DryRun: !DRY_RUN!
>>"!LOG_FILE!" echo DryRun: !DRY_RUN!
if defined WARN_ARGS (
    echo Warnings: !WARN_ARGS!
    >>"!LOG_FILE!" echo Warnings: !WARN_ARGS!
)
goto :phasePreflight


rem LOG CONVENTION: message text must contain no > < | & percent-sign or exclamation-mark characters
:log
>>"%LOG_FILE%" echo [%LOG_DATE%] [%TIME%] [%~1] %~2
echo [%LOG_DATE%] [%TIME%] [%~1] %~2
exit /b 0

:logRaw
>>"%LOG_FILE%" echo [%LOG_DATE%] [%TIME%] %~1
exit /b 0

:error
set "CURRENT_LOC_CHECK=%CURRENT_LOC%"
set "_LINE="
for /f "tokens=1 delims=:" %%n in ('findstr /b /n "%CURRENT_LOC%" "%SCRIPT_PATH%" 2^>nul') do if not defined _LINE set "_LINE=%%n"
if not defined _LINE (
    for /f "tokens=1 delims=:" %%n in ('findstr /n "%CURRENT_LOC%" "%SCRIPT_PATH%" 2^>nul') do if not defined _LINE set "_LINE=%%n"
)
if not defined _LINE set "_LINE=?"
call :log FAIL "%SCRIPT_PATH% line %_LINE% [%~2] exit=%~1 :: %~3"
set "FAILED=1"
set "LAST_ERROR=%~1"
exit /b %~1

:phasePreflight
set "CURRENT_LOC=:main-preflight"
if not exist "%SOURCE_ROOT%\" (
    call :error 3 "preflight" "SOURCE_ROOT not found: %SOURCE_ROOT%"
    goto :fail
)
if not exist "%SOURCE_ROOT%\%PRIMARY_APP%" (
    call :error 3 "preflight" "PRIMARY_APP not found in source: %SOURCE_ROOT%\%PRIMARY_APP%"
    goto :fail
)
call :log INFO "Preflight OK. Source=%SOURCE_ROOT% App=%PRIMARY_APP%"
if not exist "%WORK_DIR%\" mkdir "%WORK_DIR%" 2>nul
if not defined START_EPOCH set "START_EPOCH=0"
if "!DRY_RUN!"=="1" (
    call :log INFO "Dry-run: skipping stage and deploy phases."
    goto :phaseCert
)
if not exist "%WORK_DIR%\" mkdir "%WORK_DIR%" 2>nul
if exist "%STAGING_DIR%\" rmdir /s /q "%STAGING_DIR%" 2>nul
if exist "%BACKUP_DIR%\" rmdir /s /q "%BACKUP_DIR%" 2>nul
mkdir "%STAGING_DIR%" 2>nul
mkdir "%BACKUP_DIR%" 2>nul
del /q "%WORK_DIR%\manifest.txt" 2>nul
call :log INFO "Work dirs ready. Staging=%STAGING_DIR%"
goto :phaseStage

:phaseStage
set "CURRENT_LOC=:main-stage"
call :log INFO "Staging source to staging directory"
robocopy "%SOURCE_ROOT%" "%STAGING_DIR%" /E /XF "%SCRIPT_NAME%" /R:2 /W:2 /NP /NJH /NDL >>"%LOG_FILE%" 2>&1
set "RC=!ERRORLEVEL!"
if !RC! GEQ 8 (
    call :error 7 "stage" "robocopy failed with code !RC!"
    goto :fail
)
for /r "%STAGING_DIR%" %%F in (*) do set /a STAGED_COUNT+=1
call :log INFO "Staged !STAGED_COUNT! file(s). robocopy exit=!RC!"
goto :phaseCert

:phaseDeploy
set "CURRENT_LOC=:main-deploy"
if "!DRY_RUN!"=="1" goto :phaseSigntool
if not exist "%INSTALL_DIR%\" (
    mkdir "%INSTALL_DIR%" 2>nul
    set "INSTALL_DIR_CREATED=1"
    call :log INFO "Created install dir"
) else (
    set "INSTALL_DIR_CREATED=0"
)
call :log INFO "Deploying staged files to install dir"
for /r "%STAGING_DIR%" %%F in (*) do (
    set "REL=%%F"
    set "REL=!REL:%STAGING_DIR%\=!"
    call :deployFile "%%F" "!REL!"
    if errorlevel 1 goto :fail
)
call :log INFO "Deploy done. new=!DEPLOY_NEW! over=!DEPLOY_OVER! skip=!SKIP_COPY!"
goto :phaseSigntool

:payloadMatches
set "CURRENT_LOC=%~0"
set "MATCH_SRC=%~1"
set "MATCH_DST=%~2"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$g={param($p) try{ $b=[IO.File]::ReadAllBytes($p); if($b.Length -lt 64){ return $null }; $pe=[BitConverter]::ToInt32($b,60); if($pe -lt 0 -or ($pe+24) -gt $b.Length -or [BitConverter]::ToUInt32($b,$pe) -ne 0x4550){ return $null }; $opt=$pe+24; $magic=[BitConverter]::ToUInt16($b,$opt); $dd=$opt+$(if($magic -eq 0x20b){112}else{96}); $off=[BitConverter]::ToUInt32($b,$dd+32); if($off -ne 0 -and $off -le $b.Length){ $len=[int]$off } else { $len=$b.Length }; $m=New-Object byte[] $len; [Array]::Copy($b,$m,$len); for($i=0;$i -lt 4;$i++){ $m[$opt+64+$i]=[byte]0 }; for($i=0;$i -lt 8;$i++){ $m[$dd+32+$i]=[byte]0 }; return $m } catch { return $null } }; $o=[byte[]](& $g $env:MATCH_SRC); $p=[byte[]](& $g $env:MATCH_DST); if($null -eq $o -or $null -eq $p){ exit 1 }; if($o.Length -lt 1 -or $p.Length -lt 1){ exit 1 }; $n=[Math]::Min($o.Length,$p.Length); $sha=[Security.Cryptography.SHA256]::Create(); $h1=[BitConverter]::ToString($sha.ComputeHash($o,0,$n)) -replace '-',''; $h2=[BitConverter]::ToString($sha.ComputeHash($p,0,$n)) -replace '-',''; if($h1 -ne $h2){ exit 1 }; $long= if($o.Length -gt $n){$o}else{$p}; for($i=$n;$i -lt $long.Length;$i++){ if($long[$i] -ne 0){ exit 1 } }; exit 0" 2>>"%LOG_FILE%"
set "RC=!ERRORLEVEL!"
exit /b !RC!

:deployFile
set "CURRENT_LOC=%~0"
set "DST_FILE=%INSTALL_DIR%\%~2"
if exist "%DST_FILE%" (
    fc /b "%~1" "%DST_FILE%" >nul 2>&1
    if not errorlevel 1 (
        set /a SKIP_COPY+=1
        exit /b 0
    )
    call :payloadMatches "%~1" "%DST_FILE%"
    if not errorlevel 1 (
        call :sigStatus "%DST_FILE%"
        if "!SIG_STATUS!"=="Valid" if "!SIG_SIGNER!"=="%EXPECTED_SUBJECT%" (
            set /a SKIP_COPY+=1
            exit /b 0
        )
    )
    for %%D in ("%BACKUP_DIR%\%~2") do if not exist "%%~dpD" mkdir "%%~dpD"
    copy /y "%DST_FILE%" "%BACKUP_DIR%\%~2" >nul
    >>"%WORK_DIR%\manifest.txt" echo O^|%~2
    set /a DEPLOY_OVER+=1
) else (
    for %%D in ("%DST_FILE%") do if not exist "%%~dpD" mkdir "%%~dpD"
    >>"%WORK_DIR%\manifest.txt" echo C^|%~2
    set /a DEPLOY_NEW+=1
)
copy /y "%~1" "%DST_FILE%" >nul
if errorlevel 1 (
    call :error 7 "deploy" "copy failed for %~2"
    exit /b 1
)
exit /b 0


:trustCertForVerification
set "CURRENT_LOC=%~0"
if "!DRY_RUN!"=="1" exit /b 0
powershell -NoProfile -ExecutionPolicy Bypass -Command "$t=$env:CERT_THUMB; $cert=Get-ChildItem Cert:\CurrentUser\My\$t -ErrorAction SilentlyContinue; if(-not $cert){ $cert=Get-ChildItem Cert:\LocalMachine\My\$t -ErrorAction SilentlyContinue }; if(-not $cert){ exit 2 }; if($cert.Subject -ne $cert.Issuer){ exit 1 }; $cer=Join-Path $env:WORK_DIR 'rvsdesk_signing.cer'; [System.IO.File]::WriteAllBytes($cer,$cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)); $n=0; try{ Import-Certificate -FilePath $cer -CertStoreLocation Cert:\LocalMachine\Root -ErrorAction Stop | Out-Null; $n++ }catch{}; try{ Import-Certificate -FilePath $cer -CertStoreLocation Cert:\CurrentUser\Root -ErrorAction Stop | Out-Null; $n++ }catch{}; try{ Import-Certificate -FilePath $cer -CertStoreLocation Cert:\LocalMachine\TrustedPublisher -ErrorAction Stop | Out-Null }catch{}; try{ Import-Certificate -FilePath $cer -CertStoreLocation Cert:\CurrentUser\TrustedPublisher -ErrorAction Stop | Out-Null }catch{}; if($n -gt 0){ exit 0 } else { exit 2 }" > "%WORK_DIR%\cert_trust.txt" 2>&1
set "RC=!ERRORLEVEL!"
if "!RC!"=="0" (
    call :log INFO "Self-signed certificate imported to trust stores for verification"
)
if "!RC!"=="1" (
    call :log INFO "Issued certificate: chain validation uses system roots"
)
if "!RC!"=="2" (
    call :log WARN "Trust import did not complete; signature verification may fail"
)
exit /b 0

:phaseCert
set "CURRENT_LOC=:main-cert"
if defined CERT_THUMB goto :phaseCertPreset
powershell -NoProfile -ExecutionPolicy Bypass -Command "$cut=(Get-Date).AddDays(1); $now=Get-Date; $best=$null; $bestStore=''; foreach($st in @('Cert:\CurrentUser\My','Cert:\LocalMachine\My')){ foreach($cert in (Get-ChildItem $st -ErrorAction SilentlyContinue)){ if($cert.HasPrivateKey -and $cert.NotAfter -gt $cut -and $cert.NotBefore -le $now -and ($cert.EnhancedKeyUsageList.ObjectId -contains '1.3.6.1.5.5.7.3.3')){ if(-not $best -or $cert.NotAfter -gt $best.NotAfter){ $best=$cert; $bestStore=$st } } } }; if($best){ $best.Thumbprint+'|'+$bestStore+'|'+$best.Subject+'|'+$best.NotAfter.ToString('s') } else { 'NONE' }" > "%WORK_DIR%\cert_info.txt" 2>nul
set "CERT_INFO=NONE"
for /f "usebackq tokens=1,2,3,4 delims=|" %%a in ("%WORK_DIR%\cert_info.txt") do if not defined CERT_PARSED (
    set "CERT_INFO=%%a"
    set "CERT_STORE=%%b"
    set "CERT_SUBJECT_FOUND=%%c"
    set "CERT_PARSED=1"
)
if "!CERT_INFO!"=="NONE" goto :phaseCertCreate
set "CERT_THUMB=!CERT_INFO!"
set "CERT_MODE=existing"
if not defined EXPECTED_SUBJECT set "EXPECTED_SUBJECT=!CERT_SUBJECT_FOUND!"
call :log INFO "Using existing code signing certificate"
call :trustCertForVerification
goto :phaseCertDone

:phaseCertPreset
set "CERT_MODE=preset"
set "CERT_THUMB_TARGET=%CERT_THUMB%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$t=$env:CERT_THUMB_TARGET; foreach($st in @('Cert:\CurrentUser\My','Cert:\LocalMachine\My')){ $cert=Get-ChildItem ($st+'\'+$t) -ErrorAction SilentlyContinue; if($cert -and $cert.HasPrivateKey -and ($cert.EnhancedKeyUsageList.ObjectId -contains '1.3.6.1.5.5.7.3.3')){ 'FOUND|'+$cert.Subject+'|'+$st; break } }" > "%WORK_DIR%\cert_preset.txt" 2>nul
set "PRESET_OK=0"
for /f "usebackq tokens=1,2,3 delims=|" %%a in ("%WORK_DIR%\cert_preset.txt") do if /i "%%a"=="FOUND" (
    set "CERT_SUBJECT_FOUND=%%b"
    set "CERT_STORE=%%c"
    set "PRESET_OK=1"
)
if not "!PRESET_OK!"=="1" (
    call :error 4 "cert" "preset certificate thumbprint not found or not code signing"
    goto :fail
)
if not defined EXPECTED_SUBJECT set "EXPECTED_SUBJECT=!CERT_SUBJECT_FOUND!"
call :log INFO "Using preset certificate thumbprint from configuration"
call :trustCertForVerification
goto :phaseCertDone

:phaseCertCreate
set "CURRENT_LOC=:main-certgen"
if "!DRY_RUN!"=="1" (
    call :log INFO "Dry-run: no certificate found; one would be generated"
    set "CERT_THUMB=DRYRUN"
    set "CERT_MODE=generated-dry"
    goto :phaseCertDone
)
call :log INFO "Generating self-signed code signing certificate"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$c=New-SelfSignedCertificate -Type CodeSigningCert -Subject $env:CERT_SUBJECT -CertStoreLocation Cert:\LocalMachine\My -HashAlgorithm SHA256 -KeyLength 2048 -KeyExportPolicy Exportable -KeySpec Signature -NotAfter (Get-Date).AddYears([int]$env:CERT_VALIDITY_YEARS); $c.Thumbprint" > "%WORK_DIR%\cert_created.txt" 2>nul
set "CERT_THUMB="
for /f "usebackq delims=" %%a in ('findstr /r /x /c:"[0-9A-F][0-9A-F]*" "%WORK_DIR%\cert_created.txt" 2^>nul') do if not defined CERT_THUMB set "CERT_THUMB=%%a"
if not defined CERT_THUMB (
    call :error 4 "certgen" "certificate generation failed"
    goto :fail
)
set "CERT_MODE=generated"
call :log INFO "Certificate generated and installed to LocalMachine My store"
set "CERT_SUBJECT_FOUND=%CERT_SUBJECT%"
set "CERT_STORE=Cert:\LocalMachine\My"
if not defined EXPECTED_SUBJECT set "EXPECTED_SUBJECT=%CERT_SUBJECT%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$t=$env:CERT_THUMB; $cert=Get-ChildItem Cert:\LocalMachine\My\$t -ErrorAction Stop; $cer=Join-Path $env:WORK_DIR 'rvsdesk_signing.cer'; [System.IO.File]::WriteAllBytes($cer,$cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)); Import-Certificate -FilePath $cer -CertStoreLocation Cert:\LocalMachine\Root | Out-Null; Import-Certificate -FilePath $cer -CertStoreLocation Cert:\LocalMachine\TrustedPublisher | Out-Null; Import-Certificate -FilePath $cer -CertStoreLocation Cert:\CurrentUser\TrustedPublisher | Out-Null; 'IMPORTED'" > "%WORK_DIR%\cert_import.txt" 2>nul
findstr /c:"IMPORTED" "%WORK_DIR%\cert_import.txt" >nul 2>&1
if errorlevel 1 (
    call :error 4 "certgen" "certificate trust import failed"
    goto :fail
)
call :log INFO "Certificate public part imported to Root and TrustedPublisher stores"

:phaseCertDone
call :log INFO "Certificate resolution complete"
goto :phaseDeploy

:phaseSigntool
set "CURRENT_LOC=:main-signtool"
set "SIGNTOOL="
set "K10X86=%ProgramFiles(x86)%\Windows Kits\10\bin"
set "K10=%ProgramFiles%\Windows Kits\10\bin"
set "K81=%ProgramFiles(x86)%\Windows Kits\8.1\bin\x86"
set "K80=%ProgramFiles(x86)%\Windows Kits\8.0\bin\x86"
set "MSDK10=%ProgramFiles(x86)%\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8 Tools"
set "MSDK7=%ProgramFiles(x86)%\Microsoft SDKs\Windows\v7.1A\Bin"
if defined SIGNTOOL_EXE (
    if exist "%SIGNTOOL_EXE%" (
        set "SIGNTOOL=%SIGNTOOL_EXE%"
        call :log INFO "Signtool found via configured override"
        goto :phaseSigntoolDone
    )
    call :error 5 "signtool" "SIGNTOOL_EXE override path does not exist"
    goto :fail
)
for /f "delims=" %%s in ('where signtool.exe 2^>nul') do if not defined SIGNTOOL set "SIGNTOOL=%%s"
if defined SIGNTOOL (
    call :log INFO "Signtool found on PATH"
    goto :phaseSigntoolDone
)
for /f "delims=" %%V in ('dir /b /o-n "!K10X86!" 2^>nul') do if not defined SIGNTOOL if exist "!K10X86!\%%V\x64\signtool.exe" set "SIGNTOOL=!K10X86!\%%V\x64\signtool.exe"
if defined SIGNTOOL (
    call :log INFO "Signtool found in Windows Kits 10 x64"
    goto :phaseSigntoolDone
)
for /f "delims=" %%V in ('dir /b /o-n "!K10X86!" 2^>nul') do if not defined SIGNTOOL if exist "!K10X86!\%%V\x86\signtool.exe" set "SIGNTOOL=!K10X86!\%%V\x86\signtool.exe"
if defined SIGNTOOL (
    call :log INFO "Signtool found in Windows Kits 10 x86"
    goto :phaseSigntoolDone
)
for /f "delims=" %%V in ('dir /b /o-n "!K10!" 2^>nul') do if not defined SIGNTOOL if exist "!K10!\%%V\x64\signtool.exe" set "SIGNTOOL=!K10!\%%V\x64\signtool.exe"
if defined SIGNTOOL (
    call :log INFO "Signtool found in Program Files Windows Kits 10 x64"
    goto :phaseSigntoolDone
)
for /f "delims=" %%V in ('dir /b /o-n "!K10!" 2^>nul') do if not defined SIGNTOOL if exist "!K10!\%%V\x86\signtool.exe" set "SIGNTOOL=!K10!\%%V\x86\signtool.exe"
if defined SIGNTOOL (
    call :log INFO "Signtool found in Program Files Windows Kits 10 x86"
    goto :phaseSigntoolDone
)
if exist "!K81!\signtool.exe" set "SIGNTOOL=!K81!\signtool.exe"
if defined SIGNTOOL (
    call :log INFO "Signtool found in Windows Kits 8.1"
    goto :phaseSigntoolDone
)
if exist "!K80!\signtool.exe" set "SIGNTOOL=!K80!\signtool.exe"
if defined SIGNTOOL (
    call :log INFO "Signtool found in Windows Kits 8.0"
    goto :phaseSigntoolDone
)
if exist "!MSDK10!\signtool.exe" set "SIGNTOOL=!MSDK10!\signtool.exe"
if defined SIGNTOOL (
    call :log INFO "Signtool found in Microsoft SDKs NETFX 4.8 Tools"
    goto :phaseSigntoolDone
)
if exist "!MSDK7!\signtool.exe" set "SIGNTOOL=!MSDK7!\signtool.exe"
if defined SIGNTOOL (
    call :log INFO "Signtool found in Microsoft SDKs v7.1A"
    goto :phaseSigntoolDone
)
call :error 5 "signtool" "signtool.exe not found - install Windows SDK or WDK"
goto :fail

:phaseSigntoolDone
call :log INFO "Signtool resolution complete"
goto :phaseSignVerify

:phaseSignVerify
set "CURRENT_LOC=:main-signverify"
set "EXT_GLOB=%BINARY_EXTS:.=*.%"
if not exist "%INSTALL_DIR%\" (
    call :log INFO "Install dir not present; no binaries to process"
    goto :phaseSummary
)
call :log INFO "Scanning deployed binaries"
for /r "%INSTALL_DIR%" %%F in (!EXT_GLOB!) do (
    set /a BIN_COUNT+=1
    call :sigStatus "%%F"
    if "!DRY_RUN!"=="1" (
        set "OKSIGNED=0"
        if "!SIG_STATUS!"=="Valid" if "!SIG_SIGNER!"=="%EXPECTED_SUBJECT%" set "OKSIGNED=1"
        if "!OKSIGNED!"=="1" (
            call :log INFO "Dry-run: already correctly signed: %%~nxF"
        ) else (
            call :log INFO "Dry-run: would sign and verify: %%~nxF"
        )
    ) else (
        call :processBinary "%%F"
        if errorlevel 1 goto :fail
    )
)
call :log INFO "Binary processing complete"
goto :phaseSummary

:processBinary
set "CURRENT_LOC=%~0"
if "!SIG_STATUS!"=="Valid" if "!SIG_SIGNER!"=="%EXPECTED_SUBJECT%" (
    set /a SIGN_SKIP+=1
    call :log INFO "Skip: already signed by expected subject: %~nx1"
    call :verifyFile "%~1"
    exit /b !ERRORLEVEL!
)
call :signFile "%~1"
if errorlevel 1 exit /b 1
set /a SIGN_NOW+=1
call :verifyFile "%~1"
exit /b !ERRORLEVEL!

:sigStatus
set "CURRENT_LOC=%~0"
set "SIG_TARGET=%~1"
set "SIG_STATUS=NONE"
set "SIG_SIGNER=NONE"
set "SIG_TS=NO-TIMESTAMP"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=Get-AuthenticodeSignature -LiteralPath $env:SIG_TARGET -ErrorAction SilentlyContinue; if(-not $s){ 'STATUS=ERROR'; 'SIGNER=NONE'; 'TIMESTAMP=NO-TIMESTAMP' } else { 'STATUS='+$s.Status; if($s.SignerCertificate){ 'SIGNER='+$s.SignerCertificate.Subject } else { 'SIGNER=NONE' }; if($s.TimeStamperCertificate){ 'TIMESTAMP=TIMESTAMPED' } else { 'TIMESTAMP=NO-TIMESTAMP' } }" > "%WORK_DIR%\sig_status.txt" 2>nul
for /f "usebackq tokens=1,* delims==" %%a in ("%WORK_DIR%\sig_status.txt") do (
    if /i "%%a"=="STATUS" set "SIG_STATUS=%%b"
    if /i "%%a"=="SIGNER" set "SIG_SIGNER=%%b"
    if /i "%%a"=="TIMESTAMP" set "SIG_TS=%%b"
)
exit /b 0

:signFile
set "CURRENT_LOC=%~0"
set "SIGNED_OK=0"
set "TS_TRY=none"
if "!CERT_THUMB!"=="DRYRUN" (
    call :error 6 "sign" "dry-run certificate placeholder cannot sign"
    exit /b 1
)
call :log INFO "Signing binary: %~nx1"
for %%U in (%TIMESTAMP_URLS%) do (
    if "!SIGNED_OK!"=="0" (
        for /l %%A in (1,1,%TIMESTAMP_ATTEMPTS%) do (
            if "!SIGNED_OK!"=="0" (
                "%SIGNTOOL%" sign /fd SHA256 /sha1 %CERT_THUMB% /tr "%%U" /td SHA256 /d "%SIGN_DESCRIPTION%" "%~1" >>"%LOG_FILE%" 2>&1
                set "RC=!ERRORLEVEL!"
                if "!RC!"=="0" (
                    set "SIGNED_OK=1"
                    set "TS_TRY=%%U"
                ) else (
call :log WARN "Sign attempt failed: %%U rc=!RC!"
                )
            )
        )
    )
)
if "!SIGNED_OK!"=="1" (
    set "TS_SERVER=!TS_TRY!"
    call :log INFO "Binary signed with RFC3161 timestamp"
    exit /b 0
)
if not "!REQUIRE_TIMESTAMP!"=="1" (
    "%SIGNTOOL%" sign /fd SHA256 /sha1 %CERT_THUMB% /d "%SIGN_DESCRIPTION%" "%~1" >>"%LOG_FILE%" 2>&1
    set "RC=!ERRORLEVEL!"
    if "!RC!"=="0" (
        call :log WARN "Signed without timestamp because REQUIRE_TIMESTAMP is 0"
        exit /b 0
    )
    call :error 6 "sign" "signtool sign failed without timestamp"
    exit /b 1
)
call :error 6 "sign" "signtool sign failed after all timestamp attempts; last rc=!RC!"
exit /b 1

:verifyFile
set "CURRENT_LOC=%~0"
call :log INFO "Verifying signature: %~nx1"
"%SIGNTOOL%" verify /pa /v "%~1" > "%WORK_DIR%\verify_out.txt" 2>&1
set "RC=!ERRORLEVEL!"
>>"%LOG_FILE%" echo ----- signtool verify /pa output: %~nx1 -----
>>"%LOG_FILE%" type "%WORK_DIR%\verify_out.txt"
call :sigStatus "%~1"
set "V_FAIL=0"
if not "!RC!"=="0" set "V_FAIL=1"
if not "!SIG_STATUS!"=="Valid" set "V_FAIL=1"
if not "!SIG_SIGNER!"=="%EXPECTED_SUBJECT%" set "V_FAIL=1"
if "!REQUIRE_TIMESTAMP!"=="1" if not "!SIG_TS!"=="TIMESTAMPED" set "V_FAIL=1"
if "!V_FAIL!"=="1" (
    set /a VERIFY_FAIL+=1
    call :log FAIL "Verification result: status=!SIG_STATUS! signer=!SIG_SIGNER! timestamp=!SIG_TS! signtool=!RC!"
    call :error 6 "verify" "signature verification failed for %~nx1"
    exit /b 1
)
set /a VERIFY_OK+=1
call :log INFO "Verification result: status=!SIG_STATUS! timestamp=!SIG_TS!"
exit /b 0

:phaseSummary
set "CURRENT_LOC=:main-summary"
if "!FAILED!"=="1" goto :fail
call :printSummary PASS
if "!DRY_RUN!"=="1" (
    call :log INFO "Dry-run complete. No files were changed."
    exit /b 0
)
if not "!LAUNCH_APP!"=="1" (
    call :log INFO "Launch skipped because LAUNCH_APP is 0"
    exit /b 0
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -LiteralPath $env:INSTALL_DIR -Recurse -File -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue"
call :log INFO "Removed zone marks from deployed files"
if not exist "%INSTALL_DIR%\%PRIMARY_APP%" (
    call :error 3 "launch" "primary app missing after deploy"
    goto :fail
)
start "" "%INSTALL_DIR%\%PRIMARY_APP%"
call :log INFO "Primary application launched"
exit /b 0

:printSummary
if not defined START_EPOCH set "START_EPOCH=0"
for /f %%i in ('powershell -NoProfile -Command "[int][double]::Parse((Get-Date -Uformat %%s))"') do set "END_EPOCH=%%i"
set /a DURATION=!END_EPOCH!-!START_EPOCH!
if not defined SIGNTOOL set "SIGNTOOL=not-resolved"
if not defined CERT_THUMB set "CERT_THUMB=none"
if not defined CERT_STORE set "CERT_STORE=none"
echo ============================================================
echo   RVSDesk Installer Summary: %~1
echo ============================================================
echo   Exit code: !LAST_ERROR!
echo   Files staged: !STAGED_COUNT!   deployed new: !DEPLOY_NEW!   overwritten: !DEPLOY_OVER!   identical skips: !SKIP_COPY!
echo   Binaries: !BIN_COUNT!   signed now: !SIGN_NOW!   already signed skips: !SIGN_SKIP!
echo   Verified OK: !VERIFY_OK!   verify failed: !VERIFY_FAIL!
echo   Certificate: !CERT_MODE! thumb=!CERT_THUMB! store=!CERT_STORE!
echo   Signtool: !SIGNTOOL!
echo   Timestamp server: !TS_SERVER!
echo   Install dir: "%INSTALL_DIR%"
echo   Duration: !DURATION! seconds
echo   Log file: "%LOG_FILE%"
echo ============================================================
>>"%LOG_FILE%" echo   RVSDesk Installer Summary: %~1
>>"%LOG_FILE%" echo   Exit code: !LAST_ERROR!
>>"%LOG_FILE%" echo   staged=!STAGED_COUNT! new=!DEPLOY_NEW! over=!DEPLOY_OVER! identical=!SKIP_COPY!
>>"%LOG_FILE%" echo   binaries=!BIN_COUNT! signed=!SIGN_NOW! alreadysigned=!SIGN_SKIP!
>>"%LOG_FILE%" echo   verifyOK=!VERIFY_OK! verifyFAIL=!VERIFY_FAIL!
>>"%LOG_FILE%" echo   certmode=!CERT_MODE! thumb=!CERT_THUMB! store=!CERT_STORE!
>>"%LOG_FILE%" echo   signtool=!SIGNTOOL!
>>"%LOG_FILE%" echo   tsserver=!TS_SERVER!
>>"%LOG_FILE%" echo   installdir="%INSTALL_DIR%" duration=!DURATION!s
>>"%LOG_FILE%" echo   log="%LOG_FILE%"
exit /b 0

:fail
set "CURRENT_LOC=:main-fail"
if not defined LAST_ERROR set "LAST_ERROR=1"
if not "!LAST_ERROR!"=="0" if "!FAILED!"=="0" set "FAILED=1"
call :log FAIL "Install failed. Cleaning up partially deployed files."
if exist "%WORK_DIR%\manifest.txt" (
    for /f "usebackq tokens=1,* delims=|" %%a in ("%WORK_DIR%\manifest.txt") do (
        if /i "%%a"=="C" (
            if exist "%INSTALL_DIR%\%%b" (
                del /q "%INSTALL_DIR%\%%b" >nul 2>&1
                call :log INFO "Cleanup removed: %%b"
            )
        )
        if /i "%%a"=="O" (
            if exist "%BACKUP_DIR%\%%b" (
                for %%D in ("%INSTALL_DIR%\%%b") do if not exist "%%~dpD" mkdir "%%~dpD"
                copy /y "%BACKUP_DIR%\%%b" "%INSTALL_DIR%\%%b" >nul
                call :log INFO "Cleanup restored: %%b"
            )
        )
    )
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "if(Test-Path -LiteralPath $env:INSTALL_DIR){ Get-ChildItem -LiteralPath $env:INSTALL_DIR -Recurse -Directory -ErrorAction SilentlyContinue | Where-Object { @(Get-ChildItem -LiteralPath $_.FullName -Recurse -File -Force -ErrorAction SilentlyContinue).Count -eq 0 } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue; if($env:INSTALL_DIR_CREATED -eq '1' -and @(Get-ChildItem -LiteralPath $env:INSTALL_DIR -Force -ErrorAction SilentlyContinue).Count -eq 0){ Remove-Item -LiteralPath $env:INSTALL_DIR -Force -ErrorAction SilentlyContinue } }"
if exist "%STAGING_DIR%\" rmdir /s /q "%STAGING_DIR%" 2>nul
if exist "%BACKUP_DIR%\" rmdir /s /q "%BACKUP_DIR%" 2>nul
del /q "%WORK_DIR%\sig_status.txt" 2>nul
del /q "%WORK_DIR%\verify_out.txt" 2>nul
del /q "%WORK_DIR%\cert_info.txt" 2>nul
del /q "%WORK_DIR%\cert_created.txt" 2>nul
del /q "%WORK_DIR%\cert_import.txt" 2>nul
del /q "%WORK_DIR%\cert_preset.txt" 2>nul
del /q "%WORK_DIR%\cert_trust.txt" 2>nul
call :log INFO "Cleanup finished"
call :printSummary FAIL
exit /b !LAST_ERROR!