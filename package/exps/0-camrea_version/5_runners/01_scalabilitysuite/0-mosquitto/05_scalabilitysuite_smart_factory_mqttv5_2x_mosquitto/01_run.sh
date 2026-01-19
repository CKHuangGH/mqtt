#!/bin/bash

for (( times=0; times<7; times++ )); do
    kubectl create configmap mosquitto-config  --from-file=mosquitto.conf=mosquitto.conf
    sleep 2
    kubectl apply -f mosquitto-deployment.yaml
    sleep 2
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
    sleep 2
    for ((i=3750; i>0; i--)); do
        printf "\r%3d" $i
        sleep 1
    done
    bash ./pull.sh $times
    sleep 2
    kubectl delete configmap mosquitto-config
    sleep 2
    kubectl delete -f mosquitto-deployment.yaml
    sleep 2
    kubectl delete -f runner-service.yaml
    sleep 2
    kubectl delete -f runner1-deployment.yaml
    sleep 2
    kubectl delete -f runner2-deployment.yaml
    sleep 2
    kubectl delete -f runner3-deployment.yaml
    sleep 2
    kubectl delete -f runner4-deployment.yaml
    sleep 2
    kubectl delete -f runner5-deployment.yaml
    sleep 60
done