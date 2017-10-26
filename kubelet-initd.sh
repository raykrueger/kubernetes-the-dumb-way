#!/bin/sh
# Include the helper functions
. /etc/init.d/tc-functions

case "$1" in
  start)
    /usr/local/bin/kubelet \
      --allow-privileged=true \
      --anonymous-auth=false \
      --authorization-mode=Webhook \
      --client-ca-file=/var/lib/kubernetes/ca.pem \
      --cluster-dns=10.32.0.10 \
      --cluster-domain=cluster.local \
      --container-runtime=remote \
      --container-runtime-endpoint=unix:///var/run/cri-containerd.sock \
      --image-pull-progress-deadline=2m \
      --kubeconfig=/var/lib/kubelet/kubeconfig \
      --network-plugin=cni \
      --pod-cidr=${POD_CIDR} \
      --register-node=true \
      --runtime-request-timeout=15m \
      --tls-cert-file=/var/lib/kubelet/${HOSTNAME}.pem \
      --tls-private-key-file=/var/lib/kubelet/${HOSTNAME}-key.pem \
      --v=2
    ;;
  stop)
    ;;
  restart)
    ;;
  *)
    echo "Usage: kubelet {start|stop}" >&2
    exit 3
    ;;
esac
