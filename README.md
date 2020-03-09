# kubernetes on openstack

Openstack image that is kubeadm ready for user-data.

Take advantage of Glance to build images to launch kubernetes quicky!

## How to use

### Create a base OS image (examples prepared use ubuntu)
1. Get an ubuntu image `wget https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img`
2. Convert to raw `qemu-img convert -f qcow2 -O raw ./bionic-server-cloudimg-amd64.img.2 ./bionic-server-cloudimg-amd64.raw`
3. Create the image `openstack image create --disk-format raw --container-format bare --file ./bionic-server-cloudimg-amd64.raw ubuntu-18.04`

### Genereate the k8s images
1. `cd packer/k8s-base`
2. Adjust the config.json's `source_image` property to the image ID generated from the `ubuntu-18.04` image
3. Adjust the config.json's other properties to match your cloud, such as the identity endpoint
4. Set and auth variables within file or as env vars in accordance with the [documentation](https://www.packer.io/docs/builders/openstack.html#optional-)
5. run `packer build config.json`

### Deploy with terraform (WIP)
1. Call the template at https://github.com/sfxworks/kubernetes-on-openstack/blob/master/terraform
2. Fill in all values
3. Launch the deployment

### You're set!
Your environment is ready!
>Tip, you can set userdata for your master/worker nodes for quick launches, such as `kubeadm init` and `kubeadm join`. Note the `bootstrapTokens` in the `kubeadm-config.yaml` file. 



##TODO

- Dynamically configure everything via terraform ~heat~
- kubectl plugin for quick installs/boostrap
- include/incorperate git version control of cluster such as fluxctl
