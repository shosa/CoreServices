@echo off
echo ============================================
echo Stopping CoreServices
echo ============================================
echo.
echo WARNING: This will stop shared services used by ALL Core* applications!
echo.
set /p confirm="Are you sure? (y/n): "
if /i "%confirm%"=="y" (
    docker-compose -p coreservices down
    echo.
    echo CoreServices stopped!
) else (
    echo Operation cancelled.
)
