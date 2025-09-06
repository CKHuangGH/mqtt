mkdir /var/log/ntpsec
sudo apt-get install tcpdump -y
sudo apt-get install ntp -y
sudo systemctl stop ntp
sudo ntpd -gq
sudo systemctl start ntp
export DEBIAN_FRONTEND=noninteractive

ip=$(cat node_list)
> node_ip_all

for i in {2..8}; do
  new_ip=$(echo "$ip" | sed "s/\.[0-9]*$/.${i}/")
  echo "$new_ip" >> node_ip_all
done

part2=$(echo "$ip" | cut -d '.' -f2)
part3=$(echo "$ip" | cut -d '.' -f3)

while IFS= read -r ip_address; do
  scp -o StrictHostKeyChecking=no /root/mqtt/package/node_ip_all root@$ip_address:/root/
  scp -o StrictHostKeyChecking=no /root/mqtt/package/script/ntp.sh root@$ip_address:/root/
done < "node_ip_all"

while IFS= read -r ip_address; do
  ssh -n -o StrictHostKeyChecking=no root@"$ip_address" sudo apt-get install ntp -y
  ssh -n -o StrictHostKeyChecking=no root@"$ip_address" mkdir -p /var/log/ntpsec
  ssh -n -o StrictHostKeyChecking=no root@"$ip_address" "nohup bash /root/ntp.sh > /var/log/ntpsec/ntp.log 2>&1 &"
done < node_ip_all

wait

# kubectl taint nodes --all node-role.kubernetes.io/control-plane-

helm repo add cilium https://helm.cilium.io/
helm repo update
helm install cilium cilium/cilium \
  --version 1.18.1 \
  --namespace kube-system \
  --set operator.replicas=1 \
  --set operator.nodeSelector."node-role\.kubernetes\.io/control-plane"="" \
  --set operator.tolerations[0].key=node-role.kubernetes.io/control-plane \
  --set operator.tolerations[0].operator=Exists \
  --set operator.tolerations[0].effect=NoSchedule

for ((i=30; i>0; i--)); do
    printf "\r%3d" $i
    sleep 1
done
kubectl -n kube-system patch deploy coredns --type=merge -p '{
  "spec": { "template": { "spec": {
    "nodeSelector": { "node-role.kubernetes.io/control-plane": "" },
    "tolerations": [
      { "key":"node-role.kubernetes.io/control-plane","operator":"Exists","effect":"NoSchedule" }
    ]
  } } }
}'

for ((i=30; i>0; i--)); do
    printf "\r%3d" $i
    sleep 1
done

# helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
# helm repo update
# helm install prometheus prometheus-community/kube-prometheus-stack \
#   --version 75.18.1 \
#   --namespace monitoring --create-namespace \
#   --wait \
#   --set grafana.enabled=false \
#   --set alertmanager.enabled=false \
#   --set prometheus.service.type=NodePort \
#   --set prometheus.prometheusSpec.scrapeInterval="5s" \
#   --set prometheus.prometheusSpec.enableAdminAPI=true \
#   \
#   --set prometheus.prometheusSpec.nodeSelector."node-role\.kubernetes\.io/control-plane"="" \
#   --set prometheus.prometheusSpec.tolerations[0].key=node-role.kubernetes.io/control-plane \
#   --set prometheus.prometheusSpec.tolerations[0].operator=Exists \
#   --set prometheus.prometheusSpec.tolerations[0].effect=NoSchedule \
#   \
#   --set prometheusOperator.nodeSelector."node-role\.kubernetes\.io/control-plane"="" \
#   --set prometheusOperator.tolerations[0].key=node-role.kubernetes.io/control-plane \
#   --set prometheusOperator.tolerations[0].operator=Exists \
#   --set prometheusOperator.tolerations[0].effect=NoSchedule \
#   \
#   --set kube-state-metrics.nodeSelector."node-role\.kubernetes\.io/control-plane"="" \
#   --set kube-state-metrics.tolerations[0].key=node-role.kubernetes.io/control-plane \
#   --set kube-state-metrics.tolerations[0].operator=Exists \
#   --set kube-state-metrics.tolerations[0].effect=NoSchedule


# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  -o Dpkg::Options::="--force-confold" \
  docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# cd /root/bench_ctrl
cd /root/ps-bench/ps_bench
docker build -t ps_bench-runner:latest .
docker build -t mosquitto-with-exporter:latest -f Dockerfile.mosquitto .
docker build -t emqx-with-exporter:latest -f Dockerfile.emqx .

cd /root/mqtt/package
docker save -o ps_bench-runner.tar ps_bench-runner:latest
docker save -o mosquitto-with-exporter.tar mosquitto-with-exporter:latest
docker save -o emqx-with-exporter.tar emqx-with-exporter:latest

mkdir images

mv ps_bench-runner.tar ./images/ps_bench-runner.tar
mv mosquitto-with-exporter.tar ./images/mosquitto-with-exporter.tar
mv emqx-with-exporter.tar ./images/emqx-with-exporter.tar

while IFS= read -r ip_address; do
  echo "Send to $ip_address..."
  scp -o StrictHostKeyChecking=no -r ./images/ root@$ip_address:/root/
done < "node_ip_all"

while IFS= read -r ip_address; do
  echo "Import to $ip_address..."
  ssh -o StrictHostKeyChecking=no root@$ip_address bash -c "'
    for image in ./images/*.tar; do
      ctr -n k8s.io images import \"\$image\"  &
    done
    wait
  '" </dev/null &
done < "node_ip_all"

kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml

i=1
for node in virtual-$part2-$part3-{3..8}; do
  echo "Labeling $node as worker=$i"
  kubectl label node $node worker=$i --overwrite
  i=$((i+1))
done