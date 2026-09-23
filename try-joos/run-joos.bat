@echo off
REM ============================================================
REM  JoOS — Test Runner for Windows 11 (QEMU + WHPX)
REM  Boots the JoOS ISO in a window, exactly like "Try Omarchy
REM  for Windows". Requires Windows 11.
REM ============================================================
setlocal enabledelayedexpansion

cd /d "%~dp0"

REM ---- 1. Locate QEMU (PATH ou pastas padrao do winget) ---------------------
set "QEMUBIN="
where qemu-system-x86_64 >nul 2>nul && (
  for /f "delims=" %%i in ('where qemu-system-x86_64') do set "QEMUBIN=%%i"
  goto :qemu_found
)
for %%P in ("%ProgramFiles%\qemu" "%ProgramW6432%\qemu" "%LOCALAPPDATA%\Programs\qemu" "%ProgramFiles(x86)%\qemu") do (
  if exist "%%~P\qemu-system-x86_64.exe" (
    set "QEMUBIN=%%~P\qemu-system-x86_64.exe"
    goto :qemu_found
  )
)

echo QEMU nao encontrado. Vou tentar instalar via winget...
where winget >nul 2>nul
if errorlevel 1 (
  echo ERRO: winget nao existe. Instale o QEMU em https://www.qemu.org e rode de novo.
  pause
  exit /b 1
)
winget install --id SoftwareFreedomConservancy.QEMU -e --accept-source-agreements --accept-package-agreements
if exist "%ProgramFiles%\qemu\qemu-system-x86_64.exe" (
  set "QEMUBIN=%ProgramFiles%\qemu\qemu-system-x86_64.exe"
  goto :qemu_found
)
echo ERRO: nao achei o QEMU apos a instalacao. Abra uma nova janela e rode de novo.
pause
exit /b 1

:qemu_found
echo QEMU: %QEMUBIN%

REM ---- 2. Ache o ISO ---------------------------------------------------------
set "ISO=joos.iso"
if not exist "%ISO%" (
  echo Nao achei %ISO% nesta pasta.
  echo   -> Baixe o ISO: GitHub Actions ^> artifact "joos-iso", extraia e renomeie.
  echo   -> Ou rode com o caminho:  run-joos.bat C:\caminho\joos.iso
  echo.
  if "%~1"=="" (
    pause
    exit /b 1
  )
  set "ISO=%~1"
)
if not exist "%ISO%" (
  echo ISO nao existe: %ISO%
  pause
  exit /b 1
)

REM ---- 3. Aceleracao (WHPX se habilitado; senao uses software TCG) ----------
set "ACCEL=-machine q35 -cpu max -accel tcg,thread=multi"
powershell -NoProfile -Command "if ((Get-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform).State -eq 'Enabled') { '[whpx]' }" >nul 2>nul
if "%ERRORLEVEL%"=="0" (
  for /f "delims=" %%s in ('powershell -NoProfile -Command "if ((Get-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform).State -eq 'Enabled') { echo OK }"') do if "%%s"=="OK" set "ACCEL=-machine q35,accel=whpx -cpu max -accel whpx"
)
echo Aceleracao: %ACCEL%

REM ---- 4. Disco virtual de trabalho ------------------------------------------
if not exist joos-disk.qcow2 (
  where qemu-img >nul 2>nul && qemu-img create -f qcow2 joos-disk.qcow2 32G >nul 2>nul
  if not exist joos-disk.qcow2 (
    if exist "%ProgramFiles%\qemu\qemu-img.exe" "%ProgramFiles%\qemu\qemu-img.exe" create -f qcow2 joos-disk.qcow2 32G >nul 2>nul
  )
)

REM ---- 5. Boot! --------------------------------------------------------------
echo.
echo ==^> Iniciando JoOS (QEMU) — uso basico dentro:
echo     Super+Espaco  menu de apps     Super+Alt+Espaco  menu controle
echo     Super+Enter   terminal         Super+P           screenshot
echo     Ctrl+Alt+G    solta o mouse da janela
echo ===================================================================
echo.

"%QEMUBIN%" %ACCEL% ^
  -m 4096 ^
  -smp 4 ^
  -display sdl,window-close=off ^
  -boot d ^
  -cdrom "%ISO%" ^
  -drive file=joos-disk.qcow2,if=virtio,format=qcow2 ^
  -netdev user,id=n1,hostfwd=tcp::2222-:22 ^
  -device virtio-net-pci,netdev=n1 ^
  -device virtio-gpu-pci ^
  -audiodev sdl,id=snd0 ^
  -device intel-hda -device hda-duplex,audiodev=snd0

echo.
echo JoOS encerrado.
pause
exit /b 0