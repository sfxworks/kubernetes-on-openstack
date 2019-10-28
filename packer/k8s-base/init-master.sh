#!/bin/sh
set -e

sudo su <<HERE
set -e
mkdir -p /etc/kubernetes
mkdir -p /var/lib/kubelet
mkdir -p /etc/default/kubelet


cat <<EOF | sudo tee /etc/kubernetes/kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
nodeRegistration:
  kubeletExtraArgs:
    cloud-provider: "external"
bootstrapTokens:
- token: $BOOTSTRAP_TOKEN
  description: kubeadm bootstrap token
  ttl: 1h
certificateKey: $CERTIFICATE_KEY
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: "1.16.2"
controlPlaneEndpoint: $ENDPOINT:6443
controllerManager:
  extraArgs:
    allocate-node-cidrs: "true"
    cluster-cidr: $CLUSTER_CIDR
  extraVolumes:
  - name: cloud-config
    hostPath: /etc/kubernetes/cloud-config
    mountPath: /etc/kubernetes/cloud-config
    readOnly: true
    pathType: FileOrCreate
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: ipvs
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: JoinConfiguration
discovery:
  bootstrapToken:
    apiServerEndpoint: $ENDPOINT:6443
    token: $BOOTSTRAP_TOKEN
    unsafeSkipCAVerification: true
  timeout: 5m0s
EOF


cat <<EOF | sudo tee /etc/default/kubelet/kubelet-extra-args.env
KUBELET_EXTRA_ARGS="--cloud-provider=external --network-plugin=kubenet --non-masquerade-cidr=$CLUSTER_CIDR"
EOF

cat <<EOF | sudo tee /etc/kubernetes/cloud-config
[Global]
auth-url=$OS_AUTH_URL
application-credential-id=$OS_APPLICATION_CREDENTIAL_ID
application-credential-secret=$OS_APPLICATION_CREDENTIAL_SECRET
region=$OS_REGION_NAME

[LoadBalancer]
subnet-id=$LB_SUBNET_ID
floating-network-id=$LB_FLOATING_NETWORK_ID
create-monitor=true
use-octavia=true
lb-version=v2
monitor-delay=10s
monitor-max-retries=10
monitor-timeout=10s
internal-lb=true

[BlockStorage]
bs-version=v2
node-volume-attach-limit=128

[Networking]
public-network-name=$NET_PUBLIC
internal-network-name=$NET_INTERNAL
ipv6-support-disabled=false
EOF


kubeadm init --config /etc/kubernetes/kubeadm-config.yaml --upload-certs

echo Kubeadm post init
cat /etc/kubernetes/admin.conf
export ADMIN_CONFIG=$(cat /etc/kubernetes/admin.conf | base64)
echo $ADMIN_CONFIG

wc_notify --data-binary '{"status": "SUCCESS"}'

echo Running command
echo wc_notify --data-binary '{"status": "SUCCESS", "reason": "config", "id": "config", "data": "'"$ADMIN_CONFIG"'"}'

HERE

export ADMIN_CONFIG=$(cat /etc/kubernetes/admin.conf | base64 -w 0)
wc_notify --data-binary '{"status": "SUCCESS", "reason": "config", "id": "config", "data": "'"$ADMIN_CONFIG"'"}'