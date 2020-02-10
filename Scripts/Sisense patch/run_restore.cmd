echo off
cls
set NodePath=%ProgramW6432%\Sisense\app\configuration-service\node.exe
pushd %~DP0
"%NodePath%" restoreSameSiteNone.js "%ProgramW6432%\Sisense"
popd

echo Press Enter to restart services
pause
net stop "Sisense.Identity"
net start "Sisense.Identity"
net stop "Sisense.Gateway"
net start "Sisense.Gateway"

echo Done. Press Enter to exit.
pause
