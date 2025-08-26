kubectl create configmap mosquitto-config  --from-file=mosquitto.conf=/root/ps_bench/ps_bench/mosquitto.conf

kubectl apply -f test.yaml