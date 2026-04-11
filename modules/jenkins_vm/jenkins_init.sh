#!/bin/bash
    set -euxo pipefail
    LOG=/var/log/jenkins-init.log
    exec > >(tee -a $LOG) 2>&1
    echo "=== Jenkins Init Start ==="
    apt-get update -y && apt-get upgrade -y
    apt-get install -y openjdk-17-jdk
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | gpg --dearmor -o /usr/share/keyrings/jenkins-keyring.asc
    echo 'deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/' | tee /etc/apt/sources.list.d/jenkins.list
    apt-get update -y && apt-get install -y jenkins
    systemctl enable --now jenkins
    curl -fsSL https://get.docker.com | bash
    usermod -aG docker jenkins
    systemctl enable --now docker
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash
    curl -LO https://dl.k8s.io/release/v1.29.0/bin/linux/amd64/kubectl
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    apt-get install -y gnupg software-properties-common
    curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo 'deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com jammy main' | tee /etc/apt/sources.list.d/hashicorp.list
    apt-get update -y && apt-get install -y terraform
    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
    curl -s https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh | bash && mv kustomize /usr/local/bin/
    apt-get install -y maven jq
    echo "=== Jenkins Init Complete ==="