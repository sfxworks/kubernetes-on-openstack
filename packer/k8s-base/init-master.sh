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

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f https://raw.githubusercontent.com/kubernetes/cloud-provider-openstack/master/cluster/addons/rbac/cloud-controller-manager-roles.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/cloud-provider-openstack/master/cluster/addons/rbac/cloud-controller-manager-role-bindings.yaml

cat <<EOF | sudo tee $HOME/openstack-cloud-controller-manager-ds.yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cloud-controller-manager
  namespace: kube-system
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  labels:
    k8s-app: openstack-cloud-controller-manager
  name: openstack-cloud-controller-manager
  namespace: kube-system
spec:
  selector:
    matchLabels:
      k8s-app: openstack-cloud-controller-manager
  template:
    metadata:
      labels:
        k8s-app: openstack-cloud-controller-manager
    spec:
      containers:
      - args:
        - /bin/openstack-cloud-controller-manager
        - --v=1
        - --cloud-config=$(CLOUD_CONFIG)
        - --cloud-provider=openstack
        - --use-service-account-credentials=true
        - --address=127.0.0.1
        - --allocate-node-cidrs=true
        - --cluster-cidr=$CLUSTER_CIDR
        env:
        - name: CLOUD_CONFIG
          value: /etc/config/cloud.conf
        image: docker.io/k8scloudprovider/openstack-cloud-controller-manager:latest
        imagePullPolicy: Always
        name: openstack-cloud-controller-manager
        resources:
          requests:
            cpu: 200m
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /etc/kubernetes/pki
          name: k8s-certs
          readOnly: true
        - mountPath: /etc/ssl/certs
          name: ca-certs
          readOnly: true
        - mountPath: /etc/config
          name: cloud-config-volume
          readOnly: true
        - mountPath: /usr/libexec/kubernetes/kubelet-plugins/volume/exec
          name: flexvolume-dir
      dnsPolicy: ClusterFirst
      hostNetwork: true
      nodeSelector:
        node-role.kubernetes.io/master: ""
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext:
        runAsUser: 1001
      serviceAccount: cloud-controller-manager
      serviceAccountName: cloud-controller-manager
      terminationGracePeriodSeconds: 30
      tolerations:
      - effect: NoSchedule
        key: node.cloudprovider.kubernetes.io/uninitialized
        value: "true"
      - effect: NoSchedule
        key: node-role.kubernetes.io/master
      volumes:
      - hostPath:
          path: /usr/libexec/kubernetes/kubelet-plugins/volume/exec
          type: DirectoryOrCreate
        name: flexvolume-dir
      - hostPath:
          path: /etc/kubernetes/pki
          type: DirectoryOrCreate
        name: k8s-certs
      - hostPath:
          path: /etc/ssl/certs
          type: DirectoryOrCreate
        name: ca-certs
      - name: cloud-config-volume
        secret:
          defaultMode: 420
          secretName: cloud-config
  updateStrategy:
    rollingUpdate:
      maxUnavailable: 1
    type: RollingUpdate
EOF

sudo cp /etc/kubernetes/cloud-config $HOME/cloud.conf
kubectl create secret generic -n kube-system cloud-config --from-file=$HOME/cloud.conf

kubectl apply -f $HOME/openstack-cloud-controller-manager-ds.yaml
kubectl apply -f https://raw.githubusercontent.com/sfxworks/kubernetes-on-openstack/dev/00-CCM/cillium.yaml


#Cinder
kubectl apply -f https://raw.githubusercontent.com/kubernetes/cloud-provider-openstack/master/manifests/cinder-csi-plugin/cinder-csi-controllerplugin-rbac.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/cloud-provider-openstack/master/manifests/cinder-csi-plugin/cinder-csi-controllerplugin.yaml 
kubectl apply -f https://raw.githubusercontent.com/kubernetes/cloud-provider-openstack/master/manifests/cinder-csi-plugin/cinder-csi-nodeplugin-rbac.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/cloud-provider-openstack/master/manifests/cinder-csi-plugin/cinder-csi-nodeplugin.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/cloud-provider-openstack/master/manifests/cinder-csi-plugin/csi-cinder-driver.yaml
kubectl apply -f https://raw.githubusercontent.com/sfxworks/kubernetes-on-openstack/dev/10-CSI/storage-class.yaml
