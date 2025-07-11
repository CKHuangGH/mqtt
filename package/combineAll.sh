number=$1

mkdir /var/log/ntpsec
pip3 install kubernetes --break-system-packages
sudo apt install tcpdump -y
sudo systemctl stop ntp
sudo ntpd -gq
sudo systemctl start ntp

for i in {1..252}; do
  new_ip=$(echo "$ip" | sed "s/\.[0-9]*$/.${i}/")
  echo "$new_ip" >> node_ip_all
done

kubectl taint nodes --all node-role.kubernetes.io/control-plane-

helm repo update
helm install cilium cilium/cilium --version 1.17.5 --wait --wait-for-jobs --namespace kube-system --set operator.replicas=1

sleep 30