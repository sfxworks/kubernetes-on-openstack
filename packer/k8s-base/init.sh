#!/bin/sh

set -e

sudo su <<HERE
set -e
#install kubernetes

apt-get update && apt-get install -y apt-transport-https curl ipset
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

#install containerd

sudo mkdir -p \
  /etc/cni/net.d \
  /opt/cni/bin \
  /etc/containerd

wget -nv https://github.com/containernetworking/plugins/releases/download/v0.8.2/cni-plugins-linux-amd64-v0.8.2.tgz
wget -nv https://github.com/containerd/containerd/releases/download/v1.3.0/containerd-1.3.0.linux-amd64.tar.gz
wget -nv https://storage.googleapis.com/gvisor/releases/nightly/latest/runsc
wget -nv https://github.com/opencontainers/runc/releases/download/v1.0.0-rc9/runc.amd64

mv runc.amd64 /usr/bin/runc
chmod +x /usr/bin/runc

mv runsc /usr/local/bin/runsc
chmod +x /usr/local/bin/runsc

cat <<EOF | sudo tee /etc/systemd/system/containerd.service
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target
[Service]
ExecStartPre=/sbin/modprobe overlay
ExecStart=/bin/containerd
Restart=always
RestartSec=5
Delegate=yes
KillMode=process
OOMScoreAdjust=-999
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity
[Install]
WantedBy=multi-user.target
EOF

tar -xvf cni-plugins-linux-amd64-v0.8.2.tgz -C /opt/cni/bin/
tar -xvf containerd-1.3.0.linux-amd64.tar.gz -C /


#install gvisor-containerd-shim
wget -nv -O gvisor-containerd-shim https://github.com/google/gvisor-containerd-shim/releases/download/v0.0.3/gvisor-containerd-shim.linux-amd64
chmod +x gvisor-containerd-shim
sudo mv gvisor-containerd-shim /usr/local/bin/gvisor-containerd-shim

#configure containerd
cat <<EOF | sudo tee /etc/containerd/gvisor-containerd-shim.toml
# This is the path to the default runc containerd-shim.
runc_shim = "/usr/local/bin/containerd-shim"
EOF

cat <<EOF | sudo tee /etc/containerd/config.toml
disabled_plugins = ["restart"]
[plugins.linux]
  shim = "/usr/local/bin/gvisor-containerd-shim"
  shim_debug = true
[plugins.cri.containerd.runtimes.runsc]
  runtime_type = "io.containerd.runtime.v1.linux"
  runtime_engine = "/usr/local/bin/runsc"
  runtime_root = "/run/containerd/runsc"
EOF


echo br_netfilter >> /etc/modules
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
echo '1' > /proc/sys/net/ipv4/ip_forward
modprobe br_netfilter


systemctl enable kubelet
systemctl enable containerd

systemctl start containerd
swapoff -a

sudo mkdir -p /etc/kubernetes
sudo mkdir -p /var/lib/kubelet

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
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: "1.16.2"
controlPlaneEndpoint: $ENDPOINT:6443
controllerManager:
  extraArgs:
    allocate-node-cidrs: true
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

kubeadm config images pull --cri-socket=/var/run/containerd/containerd.sock --v=5



HERE
