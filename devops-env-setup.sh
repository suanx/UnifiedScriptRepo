#!/bin/bash
set -euo pipefail

export PATH=$PATH:/snap/bin

echo "== Updating system packages =="
sudo apt-get update -y && sudo apt-get upgrade -y

# -------------------------------
# Jenkins Setup
# -------------------------------
if ! dpkg -s jenkins &> /dev/null; then
  echo "== Installing Jenkins =="
  sudo rm -f /etc/apt/keyrings/jenkins-keyring.asc || true
  sudo apt-get install -y curl gnupg apt-transport-https ca-certificates

  if [ ! -f /etc/apt/keyrings/jenkins-keyring.asc ]; then
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /etc/apt/keyrings/jenkins-keyring.asc > /dev/null
    echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
  fi
  sudo apt-get update -y
  sudo apt-get install -y fontconfig openjdk-17-jre jenkins
else
  echo "Jenkins already installed, skipping."
fi

sudo systemctl enable jenkins
sudo systemctl start jenkins

# -------------------------------
# Docker Setup (docker.io for Debian bookworm)
# -------------------------------
if ! command -v docker &> /dev/null; then
  echo "== Installing Docker (docker.io) =="
  sudo apt-get install -y docker.io
else
  echo "Docker already installed, skipping."
fi

sudo systemctl enable docker
sudo systemctl start docker

# Add current user to docker group if not already added
if ! groups $USER | grep -qw docker; then
  echo "== Adding $USER to docker group =="
  sudo usermod -aG docker $USER
  echo "Run 'newgrp docker' or logout/login to apply docker group permissions."
else
  echo "$USER already in docker group."
fi

# -------------------------------
# Snapd and MicroK8s Setup
# -------------------------------
if ! command -v snap &> /dev/null; then
  echo "== Installing snapd =="
  sudo apt-get install -y snapd
fi

# Refresh core snap and install microk8s if not installed
echo "== Installing and refreshing snap core =="
sudo snap install core || true
sudo snap refresh core

if ! snap list microk8s &> /dev/null; then
  echo "== Installing MicroK8s =="
  sudo snap install microk8s --classic
else
  echo "MicroK8s already installed, skipping."
fi

# Add user to microk8s group if not already
if ! groups $USER | grep -qw microk8s; then
  echo "== Adding $USER to microk8s group =="
  sudo usermod -aG microk8s $USER
else
  echo "$USER already in microk8s group."
fi

sudo chown -f -R $USER ~/.kube || true

# Add aliases if not already present
if ! grep -q "alias kubectl='microk8s kubectl'" ~/.bashrc; then
  echo "alias kubectl='microk8s kubectl'" >> ~/.bashrc
  echo "alias k='microk8s kubectl'" >> ~/.bashrc
fi

echo "== Activating new groups in current shell =="
newgrp docker <<EOF
newgrp microk8s <<EONG
echo "Docker and MicroK8s groups activated."
EONG
EOF

echo "== Waiting for MicroK8s to be ready =="
microk8s status --wait-ready

# -------------------------------
# SonarQube Docker Container Setup
# -------------------------------
if [ "$(docker ps -aq -f name=sonarqube)" ]; then
  echo "== Removing existing SonarQube container =="
  docker rm -f sonarqube
fi

echo "== Pulling latest SonarQube image =="
docker pull sonarqube

echo "== Starting SonarQube container =="
docker run -d \
  --name sonarqube \
  -p 9000:9000 \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  -e JAVA_OPTS="-Xms1G -Xmx2G" \
  sonarqube

echo "== Waiting for SonarQube to become healthy (this may take 1-2 minutes)..."
until curl -s http://localhost:9000 | grep -q "SonarQube"; do
  sleep 5
  echo -n "."
done
echo -e "\nSonarQube is up and running at http://localhost:9000"

# -------------------------------
# Show Jenkins Initial Admin Password
# -------------------------------
if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
  echo -e "\nJenkins Initial Admin Password:"
  sudo cat /var/lib/jenkins/secrets/initialAdminPassword
else
  echo -e "\nJenkins password file not found!"
fi

# -------------------------------
# Print Installed Versions and Service Status
# -------------------------------
echo -e "\n== Installed Versions Summary =="
echo -n "Docker: " && docker --version
echo -n "Java: " && java -version 2>&1 | head -n 1
echo -n "Jenkins: " && systemctl is-active jenkins && systemctl status jenkins | grep 'Active:'
echo -n "MicroK8s: " && microk8s version
echo -n "kubectl client version: " && microk8s kubectl version --client
echo -n "SonarQube container status: " && docker ps -f name=sonarqube --format "{{.Status}}"

echo -e "\n== Service Status =="
for svc in docker jenkins snapd; do
  echo -n "$svc: " && systemctl is-active $svc
done

echo -n "SonarQube HTTP Check: "
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:9000
