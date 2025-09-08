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

ssh -o StrictHostKeyChecking=no chuang@172.16.111.106 "mkdir -p /home/chuang/scalabilitysuite_smart_factory_mqttv5_10x_mosquitto/"
scp -o StrictHostKeyChecking=no -r ./results chuang@172.16.111.106:/home/chuang/scalabilitysuite_smart_factory_mqttv5_10x_mosquitto/$time
ssh -o StrictHostKeyChecking=no chuang@172.16.111.106 "mkdir -p /home/chuang/scalabilitysuite_smart_factory_mqttv5_10x_mosquitto/$time/deployment_files/"
scp -o StrictHostKeyChecking=no ./runner1-deployment.yaml chuang@172.16.111.106:/home/chuang/scalabilitysuite_smart_factory_mqttv5_10x_mosquitto/$time/deployment_files/runner1-deployment.yaml
scp -o StrictHostKeyChecking=no ./runner2-deployment.yaml chuang@172.16.111.106:/home/chuang/scalabilitysuite_smart_factory_mqttv5_10x_mosquitto/$time/deployment_files/runner2-deployment.yaml
scp -o StrictHostKeyChecking=no ./runner3-deployment.yaml chuang@172.16.111.106:/home/chuang/scalabilitysuite_smart_factory_mqttv5_10x_mosquitto/$time/deployment_files/runner3-deployment.yaml
scp -o StrictHostKeyChecking=no ./runner4-deployment.yaml chuang@172.16.111.106:/home/chuang/scalabilitysuite_smart_factory_mqttv5_10x_mosquitto/$time/deployment_files/runner4-deployment.yaml
scp -o StrictHostKeyChecking=no ./runner5-deployment.yaml chuang@172.16.111.106:/home/chuang/scalabilitysuite_smart_factory_mqttv5_10x_mosquitto/$time/deployment_files/runner5-deployment.yaml
rm -rf results/