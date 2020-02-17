#!/bin/sh

set -e
sudo apt update -y 
sudo apt upgrade -y

#install 5.4 kernel
#wget -c https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4/linux-headers-5.4.0-050400_5.4.0-050400.201911242031_all.deb
#wget -c https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4/linux-headers-5.4.0-050400-generic_5.4.0-050400.201911242031_amd64.deb
#wget -c https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4/linux-image-unsigned-5.4.0-050400-generic_5.4.0-050400.201911242031_amd64.deb
#wget -c https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4/linux-modules-5.4.0-050400-generic_5.4.0-050400.201911242031_amd64.deb
#sudo dpkg -i *.deb
#Use Ubutnu Focal 20.04

#Install kubernetes
sudo su <<HERE
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

echo br_netfilter >> /etc/modules
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
echo '1' > /proc/sys/net/ipv4/ip_forward
modprobe br_netfilter
echo 'KUBELET_EXTRA_ARGS="--fail-swap-on=false --cgroup-driver=systemd --cloud-provider=external"' > /etc/default/kubelet
HERE


#install containerd

sudo mkdir -p \
  /etc/cni/net.d \
  /opt/cni/bin \
  /etc/containerd

wget https://github.com/containernetworking/plugins/releases/download/v0.8.3/cni-plugins-linux-amd64-v0.8.3.tgz
wget https://github.com/containerd/containerd/releases/download/v1.3.2/containerd-1.3.2.linux-amd64.tar.gz
wget https://storage.googleapis.com/gvisor/releases/nightly/latest/runsc
wget https://github.com/opencontainers/runc/releases/download/v1.0.0-rc9/runc.amd64

sudo mv runc.amd64 /usr/bin/runc
sudo chmod +x /usr/bin/runc

sudo tar -xvf cni-plugins-linux-amd64-v0.8.3.tgz -C /opt/cni/bin/
sudo tar -xvf containerd-1.3.2.linux-amd64.tar.gz -C /

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


sudo chmod a+x runsc
sudo mv runsc /usr/local/bin

# Install gvisor-containerd-shim
LATEST_RELEASE=$(wget -qO - https://api.github.com/repos/google/gvisor-containerd-shim/releases | grep -oP '(?<="browser_download_url": ")https://[^"]*gvisor-containerd-shim.linux-amd64' | head -1)
wget -O gvisor-containerd-shim ${LATEST_RELEASE}
chmod +x gvisor-containerd-shim
sudo mv gvisor-containerd-shim /usr/local/bin/gvisor-containerd-shim

# Create the gvisor-containerd-shim.toml
cat <<EOF | sudo tee /etc/containerd/gvisor-containerd-shim.toml
# This is the path to the default runc containerd-shim.
runc_shim = "/bin/containerd-shim"
EOF

# Create containerd config.toml
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






sudo systemctl enable kubelet
sudo systemctl enable containerd

sudo systemctl start containerd
sudo swapoff -a