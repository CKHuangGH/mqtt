#!/bin/bash

for (( times=0; times<5; times++ )); do
    kubectl create configmap mosquitto-config  --from-file=mosquitto.conf=mosquitto.conf
    kubectl apply -f mosquitto-deployment.yaml
    kubectl apply -f runner-service.yaml
    
    kubectl apply -f runner-deployment.yaml
done