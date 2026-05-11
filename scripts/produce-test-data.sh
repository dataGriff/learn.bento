#!/usr/bin/env bash
# Quickly fill the local WarpStream `orders` topic with N synthetic events.
#
# Usage:  ./scripts/produce-test-data.sh [count]
#         ./scripts/produce-test-data.sh 100

set -euo pipefail

COUNT="${1:-50}"
TOPIC="${TOPIC:-orders}"

echo "Producing ${COUNT} synthetic orders to topic '${TOPIC}' ..."

for i in $(seq 1 "${COUNT}"); do
  CUSTOMER="customer-$(( RANDOM % 5 + 1 ))"
  cat <<EOF
{"order_id":"o-${i}","customer_id":"${CUSTOMER}","sku":"S-$(( RANDOM % 10 ))","qty":$(( RANDOM % 5 + 1 )),"price":$(( RANDOM % 200 + 1 )),"zip":"$(( RANDOM % 90000 + 10000 ))"}
EOF
done | docker compose exec -T kafka-tools rpk topic produce "${TOPIC}" --brokers warpstream:9092

echo "Done."
