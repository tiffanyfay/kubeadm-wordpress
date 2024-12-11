# Instructions

## SSH key
Create SSH key
ssh-keygen



## Create nodes
```bash
./infra/digitalocean/create-droplets.sh cp1 wn1
```

## kubeadm
```bash
CP_HOST=cp1
WN_HOST=wn1

CP_IP=$(doctl compute droplet get ${CP_HOST} --format PublicIPv4 --no-header)
WN_IP=$(doctl compute droplet get ${WN_HOST} --format PublicIPv4 --no-header)

echo "cp: ssh -i digitalocean root@${CP_IP}"
echo "wn: ssh -i digitalocean root@${WN_IP}"
```

Get repo and run kubeadm setup:
```bash
git clone https://github.com/tiffanyfay/kubeadm-wordpress.git
chmod +x ./kubeadm-wordpress/kubeadm/kubeadm-setup.sh
./kubeadm-wordpress/kubeadm/kubeadm-setup.sh
```

Init:
```bash
kubeadm init
```

Control plane
```bash
mkdir -p $HOME/.kube;
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config;
sudo chown $(id -u):$(id -g) $HOME/.kube/config;

kubeadm init
```

Install CNI:
TODO: replace with Calico or something that is still maintained
```bash
kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s-1.11.yaml
```

Worker
Run kubeadm join command



## CSI
```bash
scp -i ~/digitalocean -r root@$CP_IP:~/.kube/config ~/.kube/${CP_HOST}-config
```
DigitalOcean CSI driver to create volumes

```bash
cat <<EOF | envsubst | kubectl --kubeconfig  ~/.kube/${CP_HOST}-config apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: digitalocean
  namespace: kube-system
stringData:
  access-token: "\$DO_TOKEN"
EOF
```

## Certs
Generate certs on control plane
```bash
chmod +x ./kubeadm-wordpress/access/scripts/generate-certs-kubeconfig-cp.sh
./kubeadm-wordpress/access/scripts/generate-certs-kubeconfig-cp.sh
```

## RBAC
```
kubectl create ns wordpress
kubectl apply -f kubeadm-wordpress/access
```
```
scp -i ~/digitalocean -r root@$CP_IP:~/.kube/config-deploy-app-user ~/.kube/${CP_HOST}-config-deploy-app-user
scp -i ~/digitalocean -r root@$CP_IP:~/.kube/config-port-forward-user ~/.kube/${CP_HOST}-config-port-forward-user
```


## Wordpress
##

Install wordpress as `deploy-app-user`:
```
helm install wordpress ./wordpress -n wordpress --kubeconfig ~/.kube/wordpress/config-deploy-app-user
```