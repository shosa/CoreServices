#!/bin/bash

echo "============================================"
echo "Setup Database per Nginx Proxy Manager"
echo "============================================"
echo ""

echo "Creazione database 'corenpm'..."
docker exec core-mysql mysql -uroot -prootpassword -e "CREATE DATABASE IF NOT EXISTS corenpm;"

echo "Creazione utente 'corenpm'..."
docker exec core-mysql mysql -uroot -prootpassword -e "CREATE USER IF NOT EXISTS 'corenpm'@'%' IDENTIFIED BY 'corenpm';"

echo "Assegnazione privilegi..."
docker exec core-mysql mysql -uroot -prootpassword -e "GRANT ALL PRIVILEGES ON corenpm.* TO 'corenpm'@'%';"

echo "Flush privilegi..."
docker exec core-mysql mysql -uroot -prootpassword -e "FLUSH PRIVILEGES;"

echo ""
echo "Verifica database creato:"
docker exec core-mysql mysql -uroot -prootpassword -e "SHOW DATABASES LIKE 'core%';"

echo ""
echo "✓ Database corenpm creato con successo!"
echo ""
