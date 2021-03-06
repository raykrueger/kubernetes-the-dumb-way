#!/usr/bin/env bash

KUBERNETES_PUBLIC_ADDRESS=$(docker-machine ip controller-0)

kubectl config set-cluster kubernetes-the-dumb-way \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443

kubectl config set-cluster kubernetes-the-dumb-way \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443

kubectl config set-credentials admin \
  --client-certificate=admin.pem \
  --client-key=admin-key.pem

kubectl config set-context kubernetes-the-dumb-way \
  --cluster=kubernetes-the-dumb-way \
  --user=admin

kubectl config use-context kubernetes-the-dumb-way

kubectl get componentstatuses,nodes

echo "Hopefully you see healthy stuff above :)"
