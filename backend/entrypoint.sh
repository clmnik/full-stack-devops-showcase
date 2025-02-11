set -e
if [ -f /vault/secrets/database-creds ]; then
  echo "Lade Vault Secrets..."
  source /vault/secrets/database-creds
fi
exec python app.py
