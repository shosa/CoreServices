#!/bin/bash

echo "============================================"
echo "Configurazione Proxy Hosts su Nginx Proxy Manager"
echo "============================================"
echo ""

echo "ATTENZIONE: Devi aver fatto il primo login su NPM e cambiato la password!"
echo ""
read -p "Inserisci email admin NPM (default: admin@example.com): " email
email=${email:-admin@example.com}

read -sp "Inserisci password admin NPM: " password
echo ""

if [ -z "$password" ]; then
    echo "Errore: Password obbligatoria!"
    exit 1
fi

echo ""
echo "[1/4] Login su NPM..."

# Login e ottieni token
TOKEN=$(curl -s -X POST "http://localhost:8181/api/tokens" \
  -H "Content-Type: application/json" \
  -d "{\"identity\":\"$email\",\"secret\":\"$password\"}" \
  | jq -r '.token')

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
    echo "Errore: Login fallito! Verifica credenziali."
    exit 1
fi

echo "✓ Login effettuato con successo!"
echo ""

echo "[2/4] Creazione Proxy Host per CoreMachine (porta 80)..."

# Crea proxy host per CoreMachine
RESPONSE=$(curl -s -X POST "http://localhost:8181/api/nginx/proxy-hosts" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "domain_names": ["localhost"],
    "forward_scheme": "http",
    "forward_host": "coremachine-frontend",
    "forward_port": 3000,
    "access_list_id": 0,
    "certificate_id": 0,
    "ssl_forced": 0,
    "caching_enabled": 1,
    "block_exploits": 1,
    "advanced_config": "client_max_body_size 100M;",
    "meta": {
      "letsencrypt_agree": false,
      "dns_challenge": false
    },
    "allow_websocket_upgrade": 1,
    "http2_support": 0,
    "hsts_enabled": 0,
    "hsts_subdomains": 0,
    "locations": [
      {
        "path": "/api",
        "forward_scheme": "http",
        "forward_host": "coremachine-backend",
        "forward_port": 3001
      }
    ]
  }')

if echo "$RESPONSE" | jq -e '.id' > /dev/null 2>&1; then
    echo "✓ CoreMachine configurato su porta 80"
else
    echo "✗ Errore nella creazione del proxy host CoreMachine"
    echo "$RESPONSE"
fi

echo ""
echo "[3/4] Creazione Proxy Host per CoreDocument (porta 81)..."

# Crea proxy host per CoreDocument (con custom listening port 81)
RESPONSE=$(curl -s -X POST "http://localhost:8181/api/nginx/proxy-hosts" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "domain_names": ["_"],
    "forward_scheme": "http",
    "forward_host": "coredocument-frontend",
    "forward_port": 3000,
    "access_list_id": 0,
    "certificate_id": 0,
    "ssl_forced": 0,
    "caching_enabled": 1,
    "block_exploits": 1,
    "advanced_config": "listen 81;\nclient_max_body_size 100M;",
    "meta": {
      "letsencrypt_agree": false,
      "dns_challenge": false
    },
    "allow_websocket_upgrade": 1,
    "http2_support": 0,
    "hsts_enabled": 0,
    "hsts_subdomains": 0,
    "locations": [
      {
        "path": "/api",
        "forward_scheme": "http",
        "forward_host": "coredocument-backend",
        "forward_port": 3003
      }
    ]
  }')

if echo "$RESPONSE" | jq -e '.id' > /dev/null 2>&1; then
    echo "✓ CoreDocument configurato su porta 81"
else
    echo "✗ Errore nella creazione del proxy host CoreDocument"
    echo "$RESPONSE"
fi

echo ""
echo "[4/4] Verifica configurazione..."

# Lista proxy hosts
curl -s -X GET "http://localhost:8181/api/nginx/proxy-hosts" \
  -H "Authorization: Bearer $TOKEN" \
  | jq -r '.[] | "\(.id) - \(.domain_names[0]) -> \(.forward_host):\(.forward_port)"'

echo ""
echo "============================================"
echo "✓ Configurazione completata!"
echo "============================================"
echo ""
echo "Testa gli accessi:"
echo "- CoreMachine: http://localhost"
echo "- CoreDocument: http://localhost:81"
echo "- NPM Admin: http://localhost:8181"
echo ""
