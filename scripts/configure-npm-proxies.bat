@echo off
setlocal enabledelayedexpansion

echo ============================================
echo Configurazione Proxy Hosts su Nginx Proxy Manager
echo ============================================
echo.

echo ATTENZIONE: Devi aver fatto il primo login su NPM e cambiato la password!
echo.
set /p email="Inserisci email admin NPM (default: admin@example.com): "
if "%email%"=="" set email=admin@example.com

set /p password="Inserisci password admin NPM: "
if "%password%"=="" (
    echo Errore: Password obbligatoria!
    pause
    exit /b 1
)

echo.
echo [1/4] Login su NPM...

REM Crea file temporanei
set TEMP_LOGIN=%TEMP%\npm_login.json
set TEMP_TOKEN=%TEMP%\npm_token.txt

REM Login e ottieni token
curl -s -X POST "http://localhost:8181/api/tokens" -H "Content-Type: application/json" -d "{\"identity\":\"%email%\",\"secret\":\"%password%\"}" > "%TEMP_LOGIN%"

REM Estrai token usando PowerShell
powershell -Command "(Get-Content '%TEMP_LOGIN%' | ConvertFrom-Json).token" > "%TEMP_TOKEN%"
set /p TOKEN=<"%TEMP_TOKEN%"

if "%TOKEN%"=="" (
    echo Errore: Login fallito! Verifica credenziali.
    type "%TEMP_LOGIN%"
    del "%TEMP_LOGIN%" "%TEMP_TOKEN%" 2>nul
    pause
    exit /b 1
)

echo ✓ Login effettuato con successo!
echo.

echo [2/4] Creazione Proxy Host per CoreMachine (porta 80)...

REM Crea proxy host per CoreMachine
curl -s -X POST "http://localhost:8181/api/nginx/proxy-hosts" -H "Authorization: Bearer %TOKEN%" -H "Content-Type: application/json" -d "{\"domain_names\":[\"localhost\"],\"forward_scheme\":\"http\",\"forward_host\":\"coremachine-frontend\",\"forward_port\":3000,\"access_list_id\":0,\"certificate_id\":0,\"ssl_forced\":0,\"caching_enabled\":1,\"block_exploits\":1,\"advanced_config\":\"client_max_body_size 100M;\",\"meta\":{\"letsencrypt_agree\":false,\"dns_challenge\":false},\"allow_websocket_upgrade\":1,\"http2_support\":0,\"hsts_enabled\":0,\"hsts_subdomains\":0,\"locations\":[{\"path\":\"/api\",\"forward_scheme\":\"http\",\"forward_host\":\"coremachine-backend\",\"forward_port\":3001}]}" > "%TEMP%\npm_coremachine.json"

powershell -Command "if ((Get-Content '%TEMP%\npm_coremachine.json' | ConvertFrom-Json).id) { exit 0 } else { exit 1 }" 2>nul
if %errorlevel% equ 0 (
    echo ✓ CoreMachine configurato su porta 80
) else (
    echo ✗ Errore nella creazione del proxy host CoreMachine
    type "%TEMP%\npm_coremachine.json"
)

echo.
echo [3/4] Creazione Proxy Host per CoreDocument (porta 81)...

REM Crea proxy host per CoreDocument (con custom listening port 81)
curl -s -X POST "http://localhost:8181/api/nginx/proxy-hosts" -H "Authorization: Bearer %TOKEN%" -H "Content-Type: application/json" -d "{\"domain_names\":[\"_\"],\"forward_scheme\":\"http\",\"forward_host\":\"coredocument-frontend\",\"forward_port\":3000,\"access_list_id\":0,\"certificate_id\":0,\"ssl_forced\":0,\"caching_enabled\":1,\"block_exploits\":1,\"advanced_config\":\"listen 81;\\nclient_max_body_size 100M;\",\"meta\":{\"letsencrypt_agree\":false,\"dns_challenge\":false},\"allow_websocket_upgrade\":1,\"http2_support\":0,\"hsts_enabled\":0,\"hsts_subdomains\":0,\"locations\":[{\"path\":\"/api\",\"forward_scheme\":\"http\",\"forward_host\":\"coredocument-backend\",\"forward_port\":3003}]}" > "%TEMP%\npm_coredocument.json"

powershell -Command "if ((Get-Content '%TEMP%\npm_coredocument.json' | ConvertFrom-Json).id) { exit 0 } else { exit 1 }" 2>nul
if %errorlevel% equ 0 (
    echo ✓ CoreDocument configurato su porta 81
) else (
    echo ✗ Errore nella creazione del proxy host CoreDocument
    type "%TEMP%\npm_coredocument.json"
)

echo.
echo [4/4] Verifica configurazione...

REM Lista proxy hosts
curl -s -X GET "http://localhost:8181/api/nginx/proxy-hosts" -H "Authorization: Bearer %TOKEN%" > "%TEMP%\npm_hosts.json"

echo.
echo Proxy Hosts configurati:
powershell -Command "$hosts = Get-Content '%TEMP%\npm_hosts.json' | ConvertFrom-Json; $hosts | ForEach-Object { Write-Host \"$($_.id) - $($_.domain_names[0]) -^> $($_.forward_host):$($_.forward_port)\" }"

echo.
echo ============================================
echo ✓ Configurazione completata!
echo ============================================
echo.
echo Testa gli accessi:
echo - CoreMachine: http://localhost
echo - CoreDocument: http://localhost:81
echo - NPM Admin: http://localhost:8181
echo.

REM Pulizia file temporanei
del "%TEMP_LOGIN%" "%TEMP_TOKEN%" "%TEMP%\npm_coremachine.json" "%TEMP%\npm_coredocument.json" "%TEMP%\npm_hosts.json" 2>nul

pause
