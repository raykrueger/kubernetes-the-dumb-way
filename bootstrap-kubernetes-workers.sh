#!/usr/bin/env bash

install_kube_thing() {
  instance=$1
  binary=$2

  if [ ! -f "bin/${binary}" ]; then
    mkdir -p bin
    curl -L -o bin/${binary} https://storage.googleapis.com/kubernetes-release/release/v1.8.2/bin/linux/amd64/${binary}
  fi
  
  docker-machine scp bin/${binary} ${instance}:/tmp/${binary}

  # docker-machine instances have very small root partitions, so install the
  # binaries to the much larger /mnt/sda1 location and symlink to that
  docker-machine ssh ${instance} "chmod +x /tmp/${binary} && \
    sudo mv /tmp/${binary} /mnt/sda1/bin/. && \
    sudo ln -sf /mnt/sda1/bin/${binary} /usr/local/bin/${binary}"
}

for i in {0..2}; do
  instance=worker-$i
  instance_ip=$(docker-machine ip ${instance})

  docker-machine ssh ${instance} "sudo swapoff -a && tce-load -wi socat iptables bridge-utils && \
    sudo ln -sf /usr/local/sbin/iptables* /usr/local/bin/."

  docker-machine ssh ${instance} "sudo mkdir -p \
    /etc/cni/net.d \
    /opt/cni/bin \
    /var/lib/kubelet \
    /var/lib/kube-proxy \
    /var/lib/kubernetes \
    /var/run/kubernetes \
    /mnt/sda1/bin"

  docker-machine ssh ${instance} rm -f kubelet kubeproxy kubectl

  install_kube_thing ${instance} kubelet
  install_kube_thing ${instance} kube-proxy
  install_kube_thing ${instance} kubectl

  docker-machine ssh ${instance} "sudo cp ${instance}-key.pem ${instance}.pem /var/lib/kubelet/ && \
    sudo cp ${instance}.kubeconfig /var/lib/kubelet/kubeconfig && \
    sudo cp ca.pem /var/lib/kubernetes/"

  docker-machine ssh ${instance} "wget https://github.com/containernetworking/plugins/releases/download/v0.6.0/cni-plugins-amd64-v0.6.0.tgz && \
    sudo tar -xvf cni-plugins-amd64-v0.6.0.tgz -C /opt/cni/bin/"

cat <<EOF | docker-machine ssh ${instance} "cat > 10-bridge.conf"
{
    "cniVersion": "0.3.1",
    "name": "bridge",
    "type": "bridge",
    "bridge": "cnio0",
    "isGateway": true,
    "ipMasq": true,
    "ipam": {
        "type": "host-local",
        "ranges": [
          [{"subnet": "10.200.${i}.0/24"}]
        ],
        "routes": [{"dst": "0.0.0.0/0"}]
    }
}
EOF

cat <<EOF | docker-machine ssh ${instance} "cat > 99-loopback.conf"
{
    "cniVersion": "0.3.1",
    "type": "loopback"
}
EOF

  docker-machine ssh ${instance} sudo mv 10-bridge.conf 99-loopback.conf /etc/cni/net.d/

  docker run --rm -v $(pwd)/bin:/target jpetazzo/nsenter && \
  docker-machine scp bin/nsenter ${instance}:. && \
  docker-machine ssh ${instance} "chmod +x nsenter && sudo mv nsenter /usr/local/bin/nsenter"

  echo "/usr/local/bin/kubelet \
    --address=${instance_ip} \
    --node-ip=${instance_ip} \
    --allow-privileged=true \
    --anonymous-auth=false \
    --authorization-mode=Webhook \
    --client-ca-file=/var/lib/kubernetes/ca.pem \
    --cluster-dns=10.32.0.10 \
    --cluster-domain=cluster.local \
    --image-pull-progress-deadline=2m \
    --kubeconfig=/var/lib/kubelet/kubeconfig \
    --network-plugin=cni \
    --pod-cidr=10.200.${i}.0/24 \
    --register-node=true \
    --runtime-request-timeout=15m \
    --tls-cert-file=/var/lib/kubelet/${instance}.pem \
    --tls-private-key-file=/var/lib/kubelet/${instance}-key.pem \
    --v=2" | docker-machine ssh ${instance} "cat > start-kubelet.sh"

  docker-machine scp kubelet.init ${instance}:.
  
  docker-machine ssh ${instance} "chmod +x start-kubelet.sh kubelet.init && \
    sudo mv start-kubelet.sh /usr/local/bin/. && \
    sudo mv kubelet.init /etc/init.d/kubelet && \
    sudo /etc/init.d/kubelet start"

  docker-machine scp kube-proxy.kubeconfig ${instance}:.

  docker-machine ssh ${instance} "sudo mv kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig"
  
  docker-machine scp kube-proxy.init ${instance}:.

  docker-machine ssh ${instance} "chmod +x kube-proxy.init && \
    sudo mv kube-proxy.init /etc/init.d/kube-proxy && \
    sudo /etc/init.d/kube-proxy start"
done
