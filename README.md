# kubernetes on openstack

Openstack image that is kubeadm ready for user-data.

Take advantage of Glance to build images to launch kubernetes quicky!

## How to use

### Create a base OS image (examples prepared use ubuntu)
1. Get an ubuntu image `wget https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img`
2. Convert to raw `qemu-img convert -f qcow2 -O raw ./bionic-server-cloudimg-amd64.img.2 ./bionic-server-cloudimg-amd64.raw`
3. Create the image `openstack image create --disk-format raw --container-format bare --file ./bionic-server-cloudimg-amd64.raw ubuntu-18.04`

### Genereate the base k8s image
1. `cd packer/k8s-base`
2. Adjust the config.json's `source_image` property to the image ID generated from the `ubuntu-18.04` image
3. Adjust the config.json's other properties to match your cloud, such as the identity endpoint
4. Set and auth variables within file or as env vars in accordance with the [documentation](https://www.packer.io/docs/builders/openstack.html#optional-)
5. run `packer build config.json`

### Genereate YOUR k8s image
This will include your cloud-config authentication file. Make sure to keep the `private` option in the image type. 
1. `cd packer/k8s-configured`
2. Adjust the config.json's `source_image` property to the image ID generated from the `Kubernetes-1.16.2-containerd-1.3.0-runc-1.0.0-rc9` image
3. Adjust the config.json's other properties to match your cloud, such as the identity endpoint
4. Adjust the cloud-config's properties to match your cloud, such as the identity endpoint. See [provider configuration](https://github.com/kubernetes/cloud-provider-openstack/blob/master/docs/provider-configuration.md#global) for additional details
4. Set any auth variables within file or as env vars in accordance with the [documentation](https://www.packer.io/docs/builders/openstack.html#optional-)
5. run `packer build config.json`

### You're set!
Your environment is ready!
>Tip, you can set userdata for your master/worker nodes for quick launches, such as `kubeadm init` and `kubeadm join`. Note the `bootstrapTokens` in the `kubeadm-config.yaml` file. 



##TODO

- Dynamically configure everything via terraform
- kubectl plugin for quick installs/boostrap
- include/incorperate git version control of cluster such as fluxctl