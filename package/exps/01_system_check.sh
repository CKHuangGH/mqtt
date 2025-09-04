kubectl get pod -A --field-selector=status.phase!=Running

cp ../node_ip_all node_list
cp ../node_ip_all ./script/node_ip_all

echo "screen -S mysession"