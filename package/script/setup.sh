mkdir /var/log/ntpsec
sudo apt install tcpdump -y
sudo systemctl stop ntp
sudo ntpd -gq
sudo systemctl start ntp

ip=$(cat node_list)

> node_ip_all

for i in {2..5}; do
  new_ip=$(echo "$ip" | sed "s/\.[0-9]*$/.${i}/")
  echo "$new_ip" >> node_ip_all
done

while IFS= read -r ip_address; do
  scp -o StrictHostKeyChecking=no /root/mqtt/package/node_ip_all root@$ip_address:/root/
  scp -o StrictHostKeyChecking=no /root/mqtt/package/script/ntp.sh root@$ip_address:/root/
done < "node_ip_all"

while IFS= read -r ip_address; do
  ssh -n -o StrictHostKeyChecking=no root@"$ip_address" mkdir -p /var/log/ntpsec
  ssh -n -o StrictHostKeyChecking=no root@"$ip_address" "nohup bash /root/ntp.sh > /var/log/ntpsec/ntp.log 2>&1 &"
done < node_ip_all

wait

kubectl taint nodes --all node-role.kubernetes.io/control-plane-

helm repo update
helm install cilium cilium/cilium --version 1.17.5 --wait --wait-for-jobs --namespace kube-system --set operator.replicas=1
sleep 30