# Kubernetes Cluster Setup (Scripts Included)

Short and sweet: this repo contains simple scripts to bring up (and tear down) a Kubernetes cluster.  
No deep docs here—your scripts do the real work. This README just tells you what to run and what to expect.

---

## What’s in this repo
- `k8s-install-master.sh` — sets up the master (control plane)
- `k8s-install-worker.sh` — sets up worker nodes
- `k8s-uninstall.sh` — removes the cluster if needed

---

## How to Run

### On a master node
```bash
chmod +x k8s-install-master.sh
sudo ./k8s-install-master.sh
```

### On worker node(s)
```bash
chmod +x k8s-install-worker.sh
sudo ./k8s-install-worker.sh
```

> Tip: Run the master script first, then add workers.

---

## What success looks like

When the master node finishes, you’ll see a line like this on the screen.  
Copy it and run it on each worker node:

```bash
sudo kubeadm join <master_node_IP>:6443 --token <your_token> \         
        --discovery-token-ca-cert-hash <your discovery-token-ca-cert-hash>
```

Keep this join command handy—you’ll use it for every worker you add.

---

## Uninstall (If needed)

On a master node:
```bash
chmod +x k8s-uninstall.sh
sudo ./k8s-uninstall.sh
```
