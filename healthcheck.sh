#!/bin/bash

curl -k -f -X POST https://127.0.0.1:7777/api/v1 \
-H "Content-Type: application/json" \
-d '{"function":"HealthCheck","data":{"clientCustomData":""}}' \
| grep -q '{"data":{"health":"healthy"'
