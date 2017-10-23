#!/usr/bin/env bash


for instance in controller-0 controller-1 controller-2; do

  docker-machine ssh ${instance} "wget https://storage.googleapis.com/kubernetes-release/release/v1.8.1/bin/linux/amd64/kubectl && chmod +x kubectl && sudo mv kubectl /usr/local/bin/."

  docker-machine ssh ${instance} "sudo mkdir -p /var/lib/kubernetes /var/log/kubernetes ; sudo chmod a+w /var/log/kubernetes"
  docker-machine ssh ${instance} sudo cp ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem encryption-config.yaml /var/lib/kubernetes/

  INTERNAL_IP=$(docker-machine ip ${instance})

  docker-machine ssh ${instance} \
    docker run -d --name kube-apiserver --restart always \
      -p 6443:6443 -p 8080:8080 \
      -v /var/lib/kubernetes:/var/lib/kubernetes \
      -v /var/log/kubernetes:/var/log \
      gcr.io/google_containers/kube-apiserver-amd64:v1.8.1 /usr/local/bin/kube-apiserver \
      --admission-control=Initializers,NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \
      --advertise-address=${INTERNAL_IP} \
      --allow-privileged=true \
      --apiserver-count=3 \
      --audit-log-maxage=30 \
      --audit-log-maxbackup=3 \
      --audit-log-maxsize=100 \
      --audit-log-path=/var/log/audit.log \
      --authorization-mode=Node,RBAC \
      --bind-address=0.0.0.0 \
      --client-ca-file=/var/lib/kubernetes/ca.pem \
      --enable-swagger-ui=true \
      --etcd-cafile=/var/lib/kubernetes/ca.pem \
      --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \
      --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \
      --etcd-servers=https://$(docker-machine ip controller-0):2379,https://$(docker-machine ip controller-1):2379,https://$(docker-machine ip controller-2):2379 \
      --event-ttl=1h \
      --experimental-encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \
      --insecure-bind-address=0.0.0.0 \
      --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \
      --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \
      --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \
      --kubelet-https=true \
      --runtime-config=api/all \
      --service-account-key-file=/var/lib/kubernetes/ca-key.pem \
      --service-cluster-ip-range=10.32.0.0/24 \
      --service-node-port-range=30000-32767 \
      --tls-ca-file=/var/lib/kubernetes/ca.pem \
      --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \
      --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \
      --v=2

  docker-machine ssh ${instance} \
    docker run -d --name kube-controller-manager --restart always \
      -v /var/lib/kubernetes:/var/lib/kubernetes \
      -v /var/log/kubernetes:/var/log \
      --net container:kube-apiserver \
      gcr.io/google_containers/kube-controller-manager-amd64:v1.8.1 /usr/local/bin/kube-controller-manager \
        --address=0.0.0.0 \
        --cluster-cidr=10.200.0.0/16 \
        --cluster-name=kubernetes \
        --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \
        --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \
        --leader-elect=true \
        --master=http://127.0.0.1:8080 \
        --root-ca-file=/var/lib/kubernetes/ca.pem \
        --service-account-private-key-file=/var/lib/kubernetes/ca-key.pem \
        --service-cluster-ip-range=10.32.0.0/24 \
        --v=2

  docker-machine ssh ${instance} \
    docker run -d --name kube-scheduler --restart always \
      -v /var/lib/kubernetes:/var/lib/kubernetes \
      -v /var/log/kubernetes:/var/log \
      --net container:kube-apiserver \
      gcr.io/google_containers/kube-scheduler-amd64:v1.8.1 /usr/local/bin/kube-scheduler \
        --leader-elect=true \
        --master=http://127.0.0.1:8080 \
        --v=2

done

cat <<EOF | docker-machine ssh controller-0 kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:kube-apiserver-to-kubelet
rules:
  - apiGroups:
      - ""
    resources:
      - nodes/proxy
      - nodes/stats
      - nodes/log
      - nodes/spec
      - nodes/metrics
    verbs:
      - "*"
EOF

cat <<EOF | docker-machine ssh controller-0 kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: system:kube-apiserver
  namespace: ""
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-apiserver-to-kubelet
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: kubernetes
EOF
