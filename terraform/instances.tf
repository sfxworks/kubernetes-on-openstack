resource "openstack_compute_servergroup_v2" "master_sg" {
    name     = "master_sg"
    policies = ["anti-affinity"]
}
resource "openstack_compute_servergroup_v2" "worker_sg" {
    name     = "worker_sg"
    policies = ["soft-anti-affinity"]
}



resource "openstack_compute_instance_v2" "master_1" {
    name            = "master-1"
    image_id        = ""
    flavor_id       = ""
    key_pair        = ""
    user_data       = "#/bin/sin\nkubeadm init --config "
    security_groups = ["${openstack_networking_secgroup_v2.sec_k8s.name}"]
    scheduler_hints {
        group       = "${openstack_compute_servergroup_v2.master_sg.id}"
    }
    network {
        name        = "${openstack_networking_network_v2.network_k8s_nodes.name}"
    }
}

resource "openstack_compute_instance_v2" "worker_1" {
    name            = "worker-1"
    image_id        = ""
    flavor_id       = ""
    key_pair        = ""
    security_groups = ["${openstack_networking_secgroup_v2.sec_k8s.name}"]
    scheduler_hints {
        group       = "${openstack_compute_servergroup_v2.worker_sg.id}"
    }
    network {
        name        = "${openstack_networking_network_v2.network_k8s_nodes.name}"
    }
}

resource "openstack_compute_instance_v2" "worker_2" {
    name            = "worker-2"
    image_id        = ""
    flavor_id       = ""
    key_pair        = ""
    security_groups = ["${openstack_networking_secgroup_v2.sec_k8s.name}"]
    scheduler_hints {
        group       = "${openstack_compute_servergroup_v2.worker_sg.id}"
    }
    network {
        name        = "${openstack_networking_network_v2.network_k8s_nodes.name}"
    }
}

resource "openstack_compute_instance_v2" "worker_3" {
    name            = "worker-3"
    image_id        = ""
    flavor_id       = ""
    key_pair        = ""
    security_groups = ["${openstack_networking_secgroup_v2.sec_k8s.name}"]
    scheduler_hints {
        group       = "${openstack_compute_servergroup_v2.worker_sg.id}"
    }
    network {
        name        = "${openstack_networking_network_v2.network_k8s_nodes.name}"
    }
}

resource "openstack_compute_instance_v2" "worker_sys3" {
    name            = ""
    image_id        = ""
    flavor_id       = ""
    key_pair        = ""
    security_groups = ["${openstack_networking_secgroup_v2.sec_k8s.name}"]
    scheduler_hints {
        group       = "${openstack_compute_servergroup_v2.worker_sg.id}"
    }
    network {
        name        = "${openstack_networking_network_v2.network_k8s_nodes.name}"
    }
}


resource "openstack_compute_floatingip_associate_v2" "master_fip" {
  floating_ip = "${openstack_networking_floatingip_v2.master_ip.address}"
  instance_id = "${openstack_compute_instance_v2.master_1.id}"
}

