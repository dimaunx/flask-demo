PROJECTNAME := flask-demo
BUILD := $(shell git rev-parse --short HEAD)
USER := $(shell id -u)
OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
BASEDIR := $(shell pwd)
LOCALBINDIR := $(BASEDIR)/bin
$(shell mkdir -p $(LOCALBINDIR))
CONFIGDIR := $(BASEDIR)/configs
SRCDIR := $(BASEDIR)/src
TERRAFORM_VERSION := 0.12.18
KUBECTL_VERSION := 1.16.0
PACKER_VERSION := 1.5.0
KIND_VERSION := 0.6.1
TERRAFORM :=$(LOCALBINDIR)/terraform
KUBECTL := $(LOCALBINDIR)/kubectl
PACKER :=$(LOCALBINDIR)/packer
KIND :=$(LOCALBINDIR)/kind

$(TERRAFORM):
	curl -LO https://releases.hashicorp.com/terraform/$(TERRAFORM_VERSION)/terraform_$(TERRAFORM_VERSION)_$(OS)_amd64.zip
	unzip -p terraform_$(TERRAFORM_VERSION)_$(OS)_amd64.zip terraform > $(LOCALBINDIR)/terraform
	chmod a+x $(LOCALBINDIR)/terraform
	rm -rf terraform_$(TERRAFORM_VERSION)_$(OS)_amd64.zip

$(KUBECTL):
	curl -Lo $(LOCALBINDIR)/kubectl https://storage.googleapis.com/kubernetes-release/release/v$(KUBECTL_VERSION)/bin/$(OS)/amd64/kubectl
	chmod a+x $(LOCALBINDIR)/kubectl

$(PACKER):
	curl -LO https://releases.hashicorp.com/packer/$(PACKER_VERSION)/packer_$(PACKER_VERSION)_$(OS)_amd64.zip
	unzip -p packer_$(PACKER_VERSION)_$(OS)_amd64.zip packer > $(LOCALBINDIR)/packer
	chmod a+x $(LOCALBINDIR)/packer
	rm -rf packer_$(PACKER_VERSION)_$(OS)_amd64.zip

$(KIND):
	curl -Lo $(LOCALBINDIR)/kind https://github.com/kubernetes-sigs/kind/releases/download/v$(KIND_VERSION)/kind-$(OS)-amd64
	chmod a+x $(LOCALBINDIR)/kind

build: $(PACKER)
	$(LOCALBINDIR)/packer validate -var 'project_name=$(PROJECTNAME)' -var 'configdir=$(CONFIGDIR)' $(CONFIGDIR)/packer.json
	$(LOCALBINDIR)/packer build -var 'project_name=$(PROJECTNAME)' -var 'build=$(BUILD)' -var 'configdir=$(CONFIGDIR)' -var 'srcdir=$(SRCDIR)' $(CONFIGDIR)/packer.json

cluster: $(KIND)
	@echo "Creating local kubernetes cluster ..."
	-$(LOCALBINDIR)/kind create cluster --name cluster1 --config $(CONFIGDIR)/kind-config.yaml --kubeconfig $(CONFIGDIR)/cluster1-kubeconfig

ingress: $(KUBECTL)
	$(LOCALBINDIR)/kubectl --kubeconfig $(CONFIGDIR)/cluster1-kubeconfig apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml
	$(LOCALBINDIR)/kubectl --kubeconfig $(CONFIGDIR)/cluster1-kubeconfig rollout status deployment/nginx-ingress-controller -n ingress-nginx

load_image: build cluster
	$(LOCALBINDIR)/kind load docker-image $(PROJECTNAME):$(BUILD) --name cluster1

deploy: load_image ingress $(TERRAFORM)
	cd ./tf && $(LOCALBINDIR)/terraform init && \
	$(LOCALBINDIR)/terraform plan -var 'project_name=$(PROJECTNAME)' -var 'kube_config_path=$(CONFIGDIR)/cluster1-kubeconfig' -var 'docker_image=$(PROJECTNAME):$(BUILD)' && \
	$(LOCALBINDIR)/terraform apply --auto-approve -var 'project_name=$(PROJECTNAME)' -var 'kube_config_path=$(CONFIGDIR)/cluster1-kubeconfig' -var 'docker_image=$(PROJECTNAME):$(BUILD)' && \
	$(LOCALBINDIR)/kubectl --kubeconfig $(CONFIGDIR)/cluster1-kubeconfig rollout status ds/$(PROJECTNAME) -n $(PROJECTNAME)

test:
	@for i in {1..10};do curl "http://127.0.0.1/echo?ping=test&something=else";done

clean:
	-$(LOCALBINDIR)/kind delete cluster --name cluster1
	-rm -rf $(CONFIGDIR)/cluster1-kubeconfig $(LOCALBINDIR) tf/*terraform* tf/.terraform
	-docker ps -qf status=exited | xargs docker rm -f
	-docker ps -qaf name=$(PROJECTNAME)- | xargs docker rm -f
	-docker images -qf dangling=true | xargs docker rmi -f
	-docker volume ls -qf dangling=true | xargs docker volume rm -f
	-docker rmi $(PROJECTNAME):$(VERSION)

.PHONY: build cluster ingress load_image deploy test clean
