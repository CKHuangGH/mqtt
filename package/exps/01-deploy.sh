kubectl create configmap mosquitto-config  --from-file=mosquitto.conf=mosquitto.conf
kubectl apply -f mosquitto-deployment.yaml
kubectl apply -f runner-deployment.yaml