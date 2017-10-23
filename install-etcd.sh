#!/usr/bin/env bash


for instance in controller-0 controller-1 controller-2; do
  INTERNAL_IP=$(docker-machine ip ${instance})
  docker-machine ssh ${instance} sudo mkdir -p /etc/etcd/certs /var/lib/etcd
  docker-machine ssh ${instance} sudo cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/certs/

  docker-machine ssh ${instance} \
    docker run -d --restart always -v /etc/etcd/certs:/etc/etcd/certs -v /var/lib/etcd:/var/lib/etcd -p 4001:4001 -p 2380:2380 -p 2379:2379 --name etcd quay.io/coreos/etcd:latest \
    /usr/local/bin/etcd \
    --name ${instance} \
    --cert-file=/etc/etcd/certs/kubernetes.pem \
    --key-file=/etc/etcd/certs/kubernetes-key.pem \
    --peer-cert-file=/etc/etcd/certs/kubernetes.pem \
    --peer-key-file=/etc/etcd/certs/kubernetes-key.pem \
    --trusted-ca-file=/etc/etcd/certs/ca.pem \
    --peer-trusted-ca-file=/etc/etcd/certs/ca.pem \
    --peer-client-cert-auth \
    --client-cert-auth \
    --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \
    --listen-peer-urls https://0.0.0.0:2380 \
    --listen-client-urls https://0.0.0.0:2379 \
    --advertise-client-urls https://${INTERNAL_IP}:2379 \
    --initial-cluster-token etcd-cluster-0 \
    --initial-cluster controller-0=https://$(docker-machine ip controller-0):2380,controller-1=https://$(docker-machine ip controller-1):2380,controller-2=https://$(docker-machine ip controller-2):2380 \
    --initial-cluster-state new \
    --data-dir=/var/lib/etcd
done
