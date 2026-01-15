time=$1
mkdir -p results
for i in 1 2 3 4 5; do
  pod=$(kubectl get pods -o name | grep "^pod/runnermqtt${i}-" | head -n1 | cut -d/ -f2)
  if [ -z "$pod" ]; then
    echo "!! Pod for runnermqtt${i} not found, skipping"
    continue
  fi

  echo ">>> Copying $pod ..."
  # kubectl cp -c runnermqtt${i} "$pod":/app/out     "results/"
  kubectl cp -c runnermqtt${i} "$pod":/app/results "results/"
done
broker=$(kubectl get pods -o name | grep "^pod/emqx-" | head -n1 | cut -d/ -f2)
mkdir -p results/brokerlog
kubectl cp -c emqx "$broker":/opt/emqx/log "results/brokerlog"
echo "==== kubectl get pod -o wide ====" >> results/cluster_info.txt
kubectl get pod -o wide >> results/cluster_info.txt

echo -e "\n==== kubectl get node -o wide ====" >> results/cluster_info.txt
kubectl get node -o wide >> results/cluster_info.txt

echo -e "\n==== kubectl describe node ====" >> results/cluster_info.txt
kubectl describe node >> results/cluster_info.txt

echo -e "\n==== kubectl get svc -o wide ====" >> results/cluster_info.txt
kubectl get svc -o wide >> results/cluster_info.txt

echo -e "\n==== kubectl get pvc -o wide ====" >> results/cluster_info.txt
kubectl get pvc -o wide >> results/cluster_info.txt

sleep 5

NAMESPACE="default"
LINES=200   # You can change this to 500, 2000, or remove it to fetch full logs

OUT_DIR="./results/pod_logs"
mkdir -p "$OUT_DIR"

# Get all Pod names in the namespace
PODS=$(kubectl get pods -n $NAMESPACE --no-headers -o custom-columns=":metadata.name")

for pod in $PODS; do
    echo "Fetching logs from $pod ..."
    kubectl logs -n $NAMESPACE --tail=$LINES $pod > "$OUT_DIR/${pod}.log" 2>&1
done

sudo systemctl status chrony >> results/chrony.txt
echo "=====Control Plane=====" >> results/chrony.txt
chronyc tracking >> results/chrony.txt

while IFS= read -r ip_address; do
  echo "===== $ip_address =====" >> results/chrony.txt
  ssh -n -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@"$ip_address" chronyc tracking >> results/chrony.txt
  ssh -n -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@"$ip_address" sudo systemctl status chrony >> results/chrony.txt
done < node_ip_workers

sleep 5

ssh -o StrictHostKeyChecking=no chuang@172.16.111.106 "mkdir -p /home/chuang/qossuite_smart_home_mqttv5_high/"
tar -I 'gzip -9' -cf results-$time.tar.gz results/
scp -o StrictHostKeyChecking=no results-$time.tar.gz chuang@172.16.111.106:/home/chuang/qossuite_smart_home_mqttv5_high/
ssh -o StrictHostKeyChecking=no chuang@172.16.111.106 "mkdir -p /home/chuang/qossuite_smart_home_mqttv5_high/$time/deployment_files/"
scp -o StrictHostKeyChecking=no ./runner1-deployment.yaml chuang@172.16.111.106:/home/chuang/qossuite_smart_home_mqttv5_high/$time/deployment_files/runner1-deployment.yaml
scp -o StrictHostKeyChecking=no ./runner2-deployment.yaml chuang@172.16.111.106:/home/chuang/qossuite_smart_home_mqttv5_high/$time/deployment_files/runner2-deployment.yaml
scp -o StrictHostKeyChecking=no ./runner3-deployment.yaml chuang@172.16.111.106:/home/chuang/qossuite_smart_home_mqttv5_high/$time/deployment_files/runner3-deployment.yaml
scp -o StrictHostKeyChecking=no ./runner4-deployment.yaml chuang@172.16.111.106:/home/chuang/qossuite_smart_home_mqttv5_high/$time/deployment_files/runner4-deployment.yaml
scp -o StrictHostKeyChecking=no ./runner5-deployment.yaml chuang@172.16.111.106:/home/chuang/qossuite_smart_home_mqttv5_high/$time/deployment_files/runner5-deployment.yaml
rm -rf results/