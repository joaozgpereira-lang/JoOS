@echo off
REM ============================================================
REM  JoOS — create a reusable virtual disk (once)
REM  Creates joos-disk.qcow2 in this folder. Run before joos
REM  run-joos.bat if you want to install the system to a disk.
REM  Usage: make-joos-disk.bat  [tamanho em GB, default 32]
REM ============================================================
setlocal

cd /d "%~dp0"

set "SIZE=%~1"
if "%SIZE%"=="" set "SIZE=32"

where qemu-img >nul 2>nul
if errorlevel 1 (
  echo qemu-img nao encontrado. Instale o QEMU primeiro:
  echo   winget install --id SoftwareFreedomConservancy.QEMU -e
  pause
  exit /b 1
)

if exist joos-disk.qcow2 (
  echo O disco joos-disk.qcow2 ja existe. Apague-o se quiser recriar.
  pause
  exit /b 0
)

echo ==^> Criando joos-disk.qcow2 (%SIZE%GB)...
qemu-img create -f qcow2 joos-disk.qcow2 "%SIZE%G"
echo Pronto.
pause