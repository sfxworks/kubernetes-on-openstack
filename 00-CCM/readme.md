# Openstack Cloud Controller Manager

_Context:_
```
root@kubenet-1:~# kubectl get pods,nodes -o wide
NAME                                    READY   STATUS    RESTARTS   AGE   IP           NODE        NOMINATED NODE   READINESS GATES
pod/alpine                              1/1     Running   15         15h   10.0.1.69    kubenet-2   <none>           <none>
pod/nginx-deployment-54f57cf6bf-69mwb   1/1     Running   0          14h   10.0.0.127   kubenet-1   <none>           <none>
pod/nginx-deployment-54f57cf6bf-zdt79   1/1     Running   0          14h   10.0.1.23    kubenet-2   <none>           <none>

NAME             STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP     OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
node/kubenet-1   Ready    master   15h   v1.16.2   <none>        192.168.0.88    Ubuntu 18.04.3 LTS   4.15.0-65-generic   containerd://1.3.0
node/kubenet-2   Ready    <none>   15h   v1.16.2   <none>        192.168.0.117   Ubuntu 18.04.3 LTS   4.15.0-65-generic   containerd://1.3.0
```


# The CCM
Arguments were amended for kubenet. Change them at line XX. Other than that, pull from the same specs.

```
kubectl create -f
```


# Hippity Hoppity
There's an argument to me made somewhere about hops
```
root@kubenet-1:~# kubectl exec -it alpine -- ping 10.0.0.127
PING 10.0.0.127 (10.0.0.127): 56 data bytes
64 bytes from 10.0.0.127: seq=2 ttl=59 time=0.887 ms
64 bytes from 10.0.0.127: seq=3 ttl=59 time=0.820 ms
64 bytes from 10.0.0.127: seq=4 ttl=59 time=0.838 ms
```

```

root@kubenet-1:~# ping 192.168.0.117
PING 192.168.0.117 (192.168.0.117) 56(84) bytes of data.
64 bytes from 192.168.0.117: icmp_seq=1 ttl=64 time=0.651 ms
64 bytes from 192.168.0.117: icmp_seq=2 ttl=64 time=1.13 ms
64 bytes from 192.168.0.117: icmp_seq=3 ttl=64 time=0.577 ms
64 bytes from 192.168.0.117: icmp_seq=4 ttl=64 time=0.670 ms
```

But eh.