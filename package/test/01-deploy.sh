kubectl create configmap mosquitto-config   --from-file=mosquitto.conf=/root/bench_ctrl/mosquitto.conf

kubectl apply -f test.yaml