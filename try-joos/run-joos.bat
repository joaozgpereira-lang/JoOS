@echo off
REM ============================================================
REM  JoOS — Test Runner for Windows 11 (QEMU + WHPX)
REM  Boots the JoOS ISO in a window, exactly like "Try Omarchy
REM  for Windows". Requires Windows 11 (WHPX) and winget.
REM ============================================================
setlocal enabledelayedexpansion

cd /d "%~dp0"

where winget >nul 2>nul
if errorlevel 1 (
  echo ERRO: winget nao encontrado. Use Windows 11 atualizado.
  pause
  exit /b 1
)

REM ---- 1. Install QEMU via winget if missing -------------------------------
where qemu-system-x86_64 >nul 2>nul
if errorlevel 1 (
  echo ==^> Instalando QEMU (winget)...
  winget install --id SoftwareFreedomConservancy.QEMU -e --accept-source-agreements --accept-package-agreements
)

REM ---- 2. Enable Windows Hypervisor Platform ------------------------------
call :ensure_whpx
if errorlevel 1 exit /b 1

REM ---- 3. Locate the JoOS ISO -----------------------------------------------
set "ISO=joos.iso"
if not exist "%ISO%" (
  echo Nao achei %ISO% nesta pasta.
  echo   -> Baixe o ISO no GitHub Actions (aba "Artifacts") e coloque aqui.
  echo      Ou rode com o caminho:  run-joos.bat C:\caminho\joos.iso
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

REM ---- 4. Where's QEMU? -----------------------------------------------------
set "QEMU=qemu-system-x86_64"
for /f "delims=" %%i in ('where qemu-system-x86_64') do set "QEMUBIN=%%i"

REM ---- 5. Boot! --------------------------------------------------------------
echo.
echo ==^> Iniciando JoOS (QEMU + WHPX) — uso basico dentro:
echo     Super+Espaco  menu de apps     Super+Alt+Espaco  menu controle
echo     Super+Enter   terminal         Super+P           screenshot
echo     Ctrl+Alt+G    tirar o mouse de dentro da janela
echo ===================================================================
echo.

"%QEMUBIN%" ^
  -machine q35,accel=whpx ^
  -accel whpx ^
  -cpu max ^
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

:ensure_whpx
REM WHPX is a Windows optional feature; enable if missing (needs admin).
powershell -NoProfile -Command "Get-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform | Select-Object -ExpandProperty State" >nul 2>nul
if errorlevel 1 (
  echo WHPX nao habilitado. Abra um prompt como ADMINISTRADOR e rode:
  echo   DISM /Online /Enable-Feature /FeatureName:HypervisorPlatform /All
  echo Depois reinicie o PC e rode este script de novo.
  pause
  exit /b 1
)
for /f "delims=" %%s in ('powershell -NoProfile -Command "(Get-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform).State"') do set "WHXP_STATE=%%s"
if /i not "%WHXP_STATE%"=="Enabled" (
  echo WHPX nao habilitado. Abra um prompt como ADMINISTRADOR e rode:
  echo   DISM /Online /Enable-Feature /FeatureName:HypervisorPlatform /All
  echo Depois reinicie o PC e rode este script de novo.
  pause
  exit /b 1
)
exit /b 0