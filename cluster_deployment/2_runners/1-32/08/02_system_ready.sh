#!/bin/bash

manage=$(awk NR==1 node_list)

git clone https://github.com/CKHuangGH/mqtt
git clone https://github.com/DAMSlabUMBC/PS-Bench.git
mv PS-Bench ps-bench
rm -rf /home/chuang/.ssh/known_hosts

for j in $(cat node_list)
do
    scp /home/chuang/.ssh/id_rsa root@$j:/root/.ssh
    scp -r ./mqtt root@$j:/root/
    # scp -r /home/chuang/bench_ctrl root@$j:/root/
    scp -r ./ps-bench root@$j:/root/
    scp -r /home/chuang/images-broker root@$j:/root/mqtt/package/images-broker
    scp -r /home/chuang/images-runner root@$j:/root/mqtt/package/images-runner
done

echo "wait for 30 secs"
sleep 30

i=0
for j in $(cat node_list)
do
ssh -o StrictHostKeyChecking=no root@$j scp -o StrictHostKeyChecking=no /root/.kube/config root@$manage:/root/.kube/cluster$i
ssh -o StrictHostKeyChecking=no root@$j chmod 777 -R /root/mqtt/

i=$((i+1))
done

scp node_list root@$manage:/root/mqtt/package/node_list

echo "management node is $manage"