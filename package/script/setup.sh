mkdir /var/log/ntpsec
pip3 install kubernetes --break-system-packages
sudo apt install tcpdump -y
sudo systemctl stop ntp
sudo ntpd -gq
sudo systemctl start ntp

for i in {2..5}; do
  new_ip=$(echo "$ip" | sed "s/\.[0-9]*$/.${i}/")
  echo "$new_ip" >> node_ip_all
done

kubectl taint nodes --all node-role.kubernetes.io/control-plane-

helm repo update
helm install cilium cilium/cilium --version 1.17.5 --wait --wait-for-jobs --namespace kube-system --set operator.replicas=1
sleep 30

kubectl create ns monitoring
helm install --version 75.9.0 prometheus-community/kube-prometheus-stack --generate-name --set grafana.enabled=false --set alertmanager.enabled=false --set prometheus.service.type=NodePort --set prometheus.prometheusSpec.scrapeInterval="5s" --set prometheus.prometheusSpec.enableAdminAPI=true --namespace monitoring --values /root/sec2025/federation_framework/scenario1/karmada-pull/scenario1/script/values.yaml --set prometheus.prometheusSpec.resources.requests.cpu="1000m" --set prometheus.prometheusSpec.resources.requests.memory="1024Mi"

