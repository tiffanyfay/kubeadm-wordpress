#!/bin/bash
set -e

echo '=======================ENABLE IPV4 PACKET FORWARDING======================='
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

echo '=======================INSTALL CONTAINERD======================='
wget https://github.com/containerd/containerd/releases/download/v1.7.24/containerd-1.7.24-linux-amd64.tar.gz
tar Cxzvf /usr/local containerd-1.7.24-linux-amd64.tar.gz
   
wget -P /usr/local/lib/systemd/system/ https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
if [ ! -f /usr/local/lib/systemd/system/containerd.service ]; then
    echo "/usr/local/lib/systemd/system/containerd.service not found!"
    exit 1
fi
systemctl daemon-reload
systemctl enable --now containerd

echo '=======================INSTALL RUNC======================='
wget https://github.com/opencontainers/runc/releases/download/v1.2.2/runc.amd64
if [ ! -f runc.amd64 ]; then
    echo "runc.amd64 not found!"
    exit 1
fi
install -m 755 runc.amd64 /usr/local/sbin/runc

echo '=======================INSTALL CNI PLUGINS======================='
wget https://github.com/containernetworking/plugins/releases/download/v1.6.1/cni-plugins-linux-amd64-v1.6.1.tgz
mkdir -p /opt/cni/bin
tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.6.1.tgz

echo '=======================CGROUP CONFIG FOR SYSTEMD======================='
echo 'cgroup config for systemd: create /etc/containerd and config.toml'
mkdir /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd

echo '=======================INSTALL KUBEADM, KUBELET, KUBECTL======================='
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl