#!/bin/sh
set -e

sudo su <<HERE
set -e
mkdir -p /etc/kubernetes
mkdir -p /var/lib/kubelet

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
kubernetesVersion: stable
controlPlaneEndpoint: $ENDPOINT:6443
controllerManager:
  extraVolumes:
  - name: "cloud-config"
    hostPath: "/etc/kubernetes/cloud-config"
    mountPath: "/etc/kubernetes/cloud-config"
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


cat <<EOF | sudo tee /etc/default/kubelet
KUBELET_EXTRA_ARGS="--cloud-provider=external"
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
#public-network-name=$NET_PUBLIC
internal-network-name=$NET_INTERNAL
ipv6-support-disabled=false

EOF

systemctl daemon-reload
systemctl restart kubelet

kubeadm init --config /etc/kubernetes/kubeadm-config.yaml --upload-certs

echo Kubeadm post init
export ADMIN_CONFIG=$(cat /etc/kubernetes/admin.conf | base64)
echo $ADMIN_CONFIG

wc_notify --data-binary '{"status": "SUCCESS"}'

HERE

export ADMIN_CONFIG=$(cat /etc/kubernetes/admin.conf | base64 -w 0)
wc_notify --data-binary '{"status": "SUCCESS", "reason": "config", "id": "config", "data": "'"$ADMIN_CONFIG"'"}'

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

sudo cp /etc/kubernetes/cloud-config $HOME/cloud.conf
kubectl create secret generic -n kube-system cloud-config --from-file=$HOME/cloud.conf

kubectl apply -f https://raw.githubusercontent.com/kubernetes/cloud-provider-openstack/master/cluster/addons/rbac/cloud-controller-manager-roles.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/cloud-provider-openstack/master/cluster/addons/rbac/cloud-controller-manager-role-bindings.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/cloud-provider-openstack/master/manifests/controller-manager/openstack-cloud-controller-manager-ds.yaml

kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"


kubectl rollout status ds/openstack-cloud-controller-manager -n kube-system
wc_notify --data-binary '{"status": "SUCCESS", "reason": "Cloud Control Manager"}'


#Cinder
kubectl create -f https://raw.githubusercontent.com/kubernetes/cloud-provider-openstack/master/manifests/cinder-csi-plugin/cinder-csi-controllerplugin-rbac.yaml
kubectl create -f https://raw.githubusercontent.com/kubernetes/cloud-provider-openstack/master/manifests/cinder-csi-plugin/cinder-csi-controllerplugin.yaml 
kubectl create -f https://raw.githubusercontent.com/kubernetes/cloud-provider-openstack/master/manifests/cinder-csi-plugin/cinder-csi-nodeplugin-rbac.yaml
kubectl create -f https://raw.githubusercontent.com/kubernetes/cloud-provider-openstack/master/manifests/cinder-csi-plugin/cinder-csi-nodeplugin.yaml
kubectl create -f https://raw.githubusercontent.com/kubernetes/cloud-provider-openstack/master/manifests/cinder-csi-plugin/csi-cinder-driver.yaml
kubectl create -f https://raw.githubusercontent.com/sfxworks/kubernetes-on-openstack/dev/10-CSI/storage-class.yaml
