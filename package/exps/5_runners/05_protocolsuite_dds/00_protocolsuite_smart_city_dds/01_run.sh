#!/bin/bash

for (( times=0; times<1; times++ )); do
    kubectl apply -f runner-service.yaml
    sleep 2
    kubectl apply -f runner1-deployment.yaml
    sleep 2
    kubectl apply -f runner2-deployment.yaml
    sleep 2
    kubectl apply -f runner3-deployment.yaml
    sleep 2
    kubectl apply -f runner4-deployment.yaml
    sleep 2
    kubectl apply -f runner5-deployment.yaml
done