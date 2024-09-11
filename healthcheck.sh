#!/bin/bash

curl -k -f -X POST "https://127.0.0.1:${SERVERGAMEPORT}/api/v1" \
-H "Content-Type: application/json" \
-d '{"function":"HealthCheck","data":{"clientCustomData":""}}' \
| jq -e '.data.health == "healthy"'
