#!/bin/bash

for (( times=0; times<7; times++ )); do
    kubectl apply -f emqx-deployment.yaml
    sleep 2
    kubectl apply -f runner-service.yaml
    sleep 2
    kubectl apply -f runner1-deployment.yaml
    sleep 2
    kubectl apply -f runner2-deployment.yaml
    sleep 2
    for ((i=3600; i>0; i--)); do
        printf "\r%3d" $i
        sleep 1
    done
    bash ./pull.sh $times
    sleep 2
    kubectl delete -f emqx-deployment.yaml
    sleep 2
    kubectl delete -f runner-service.yaml
    sleep 2
    kubectl delete -f runner1-deployment.yaml
    sleep 2
    kubectl delete -f runner2-deployment.yaml
    sleep 60
done