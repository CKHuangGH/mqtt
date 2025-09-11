cilium config set multicast-enabled true
for ((i=30; i>0; i--)); do
    printf "\r%3d" $i
    sleep 1
done
cilium multicast add --group-ip 239.255.0.1