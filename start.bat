@echo off
echo ============================================
echo Starting CoreServices
echo ============================================
echo.
docker-compose -p coreservices up -d
echo.
echo ============================================
echo CoreServices started!
echo ============================================
echo.
echo Services available at:
echo   - MySQL:       localhost:3306
echo   - PHPMyAdmin:  http://localhost:8080
echo   - MinIO API:   localhost:9000
echo   - MinIO UI:    http://localhost:9001
echo   - Meilisearch: http://localhost:7700
echo.
docker-compose -p coreservices ps
