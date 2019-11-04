#!/bin/sh
set -e

sudo su <<HERE
set -e
mkdir -p /etc/kubernetes
mkdir -p /var/lib/kubelet


cat <<EOF | sudo tee /etc/kubernetes/kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta2
kind: JoinConfiguration
discovery:
  bootstrapToken:
    apiServerEndpoint: $ENDPOINT:6443
    token: $BOOTSTRAP_TOKEN
    unsafeSkipCAVerification: true
  timeout: 5m0s
EOF

cat <<EOF | sudo tee /etc/default/kubelet
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

[Route]
router-id=$ROUTER_ID
EOF

systemctl daemon-reload
systemctl restart kubelet
sleep 180

kubeadm join --config /etc/kubernetes/kubeadm-config.yaml
HERE