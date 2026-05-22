#!/bin/bash

kubectl port-forward svc/backend 5000:80 -n wanderlust > backend.log 2>&1 &
kubectl port-forward svc/frontend 5173:80 -n wanderlust > frontend.log 2>&1 &
kubectl port-forward svc/mongo 27017:27017 -n wanderlust > mongo.log 2>&1 &
kubectl port-forward svc/redis 6379:6379 -n wanderlust > redis.log 2>&1 &

echo "Port forwards started. Logs saved to *.log"
