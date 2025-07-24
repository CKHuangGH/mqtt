docker save -o bench_ctrl.tar bench_ctrl-bench_ctrl:latest
docker save -o bench_ctr-pub.tar bench_ctrl-pub:latest

mkdir images

mv bench_ctrl.tar ./images/bench_ctrl.tar
mv bench_ctr-pub.tar ./images/bench_ctr-pub.tar

> node_ip

tail -n +2 node_ip_all > node_ip

while IFS= read -r ip_address; do
  echo "Send to $ip_address..."
  scp -o StrictHostKeyChecking=no -r ./images/ root@$ip_address:/root/
done < "node_ip"

while IFS= read -r ip_address; do
  echo "Import to $ip_address..."
  ssh -o StrictHostKeyChecking=no root@$ip_address bash -c "'
    for image in ./images/*.tar; do
      ctr -n k8s.io images import \"\$image\"  &
    done
    wait
  '" </dev/null &
done < "node_ip"