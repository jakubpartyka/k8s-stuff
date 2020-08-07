#!/bin/bash

####
# this script installs Docker, Kubectl and Minikube to prepare Kubernetes enviroment
####

# install Docker and add allow it to run without sudo prefix

echo "running apt-get update"
sudo apt-get update

echo "installing docker"
sudo apt-get install -y docker docker.io

echo "adding Docker to sudo group"
sudo groupadd docker
sudo usermod -aG docker $USER

echo
echo "docker installed with version:"
sudo docker version

#install minikube
echo "downloading minikube...";
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 \
  && chmod +x minikube;

sudo mkdir -p /usr/local/bin/;
sudo install minikube /usr/local/bin/;


echo "downloading kubectl";
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl";

echo "installing kubectl";

chmod +x ./kubectl;
sudo mv ./kubectl /usr/local/bin/kubectl;
kubectl version --client;

echo "starting minikube";
minikube start;

kubectl get ns;
echo "all looks fine now";
