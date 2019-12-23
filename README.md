# flask-demo 

Deploy a simple flask-demo web application to local a k8s cluster.
This automated flow enables continues development workflow of building and deploying latest code to a local k8s cluster.

## Prerequisites

- [ansible]
- [docker]
- curl

All other required dependencies will be downloaded to local **./bin/** folder.

## Build and deploy the application

```bash
git clone https://github.com/dimaunx/flask-demo.git
cd flask-demo
make deploy
```

Deploy can be run in recurring fashion to deploy the latest local code. After each commit a new version of the code will
be deployed.

The above command will perform the following actions:

1. Build docker image with packer and ansible.
2. Create local [kind] k8s cluster with one master and three worker nodes.
3. Load the flask-demo application docker image in to the cluster directly. This simplifies the flow and removes the 
need to push/pull the image from external docker repository.
4. Deploy nginx ingress controller to act as a load balancer.
5. Deploy the flask-demo application to all worker nodes and nginx ingress service/rules with terraform to a local cluster.

After a successful deploy you should see **daemon set "flask-demo" successfully rolled out** in the output.

### Testing

After **make deploy** finishes successfully.

```bash
make test
```

The result should contain responses from the flask-demo pods with the requested parameters and a server ip that returned 
the initial response, all in json format. Additionally application can tested in browser 
http://localhost/echo?ping=test&something=else.

### Troubleshooting

Export the kubeconfig for the cluster from inside the git repository.

```bash
export KUBECONFIG=$(git rev-parse --show-toplevel)/configs/cluster1-kubeconfig
```

Get cluster nodes 

```bash
./bin/kubectl get nodes -o wide
```

Get the flask-demo pods.

```bash
./bin/kubectl get pods -n flask-demo -o wide
```

Get the flask-demo pods logs.

```bash
./bin/kubectl logs -f -l app=flask-demo -n flask-demo
```

Get the nginx ingress controller logs.

```bash
./bin/kubectl logs -f -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

## Cleanup

```bash
make clean
```

<!--links-->
[ansible]: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html
[docker]: https://docs.docker.com/install/
[kind]: https://github.com/kubernetes-sigs/kind