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