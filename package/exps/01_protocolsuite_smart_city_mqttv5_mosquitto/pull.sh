time=$1
mkdir -p results
for i in 1 2 3 4 5; do
  pod=$(kubectl get pods -o name | grep "^pod/runnermqtt${i}-" | head -n1 | cut -d/ -f2)
  if [ -z "$pod" ]; then
    echo "!! Pod for runnermqtt${i} not found, skipping"
    continue
  fi

  echo ">>> Copying $pod ..."
  # kubectl cp -c runnermqtt${i} "$pod":/app/out     "results/runnermqtt${i}-out"
  kubectl cp -c runnermqtt${i} "$pod":/app/results "results/"
done

sleep 5

ssh -o StrictHostKeyChecking=no chuang@172.16.79.101 "mkdir -p /home/chuang/protocolsuite_smart_city_mqttv5-mosquitto/"
scp -o StrictHostKeyChecking=no -r ./results chuang@172.16.79.101:/home/chuang/protocolsuite_smart_city_mqttv5-mosquitto/$time

rm -rf results/