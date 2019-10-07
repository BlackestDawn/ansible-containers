# Dockerfile for building Ansible image for Ubuntu 18.04 (Bionical), with as few additional software as possible.
#
# @see https://launchpad.net/~ansible/+archive/ubuntu/ansible
#
# Version  0.1
#

# Base image
FROM ubuntu:18.04

# Labels and other metadata
LABEL maintainer="Alexander <blacke4dawn@gmail.com>"
ENV DEBIAN_FRONTEND=noninteractive
ENV PACKER_VERSION=1.4.4
ENV VSPHERE_ISO_VERSION=2.3

# All the different layers
RUN echo "===> Adding on extra APT repos..." && \
  apt-get update && \
  apt-get install -y software-properties-common && \
  add-apt-repository ppa:ansible/ansible-2.8 && \
  curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add && \
  curl -o /etc/apt/sources.list.d/microsoft.list https://packages.microsoft.com/config/ubuntu/18.04/prod.list

RUN echo "===> Updating system and installing extra tools..." && \
  apt-get update && \
  apt-get dist-upgrade -y && \
  apt-get install -y gnupg2 sshpass openssh-client wget python3 python3-pip python3-wheel p7zip-full cpio gzip genisoimage whois pwgen wget fakeroot isolinux xorriso unzip ansible powershell

RUN echo "====> Setting up Powershell and PowerCLI..." && \
  powershell -noni -c "& {Set-PowerCLIConfiguration -Scope User -Confirm:$false -InvalidCertificateAction Ignore -ParticipateInCEIP $false }" && \
  powershell -noni -c "& {Install-Module -Name VMware.PowerCLI -Force}"
  
RUN echo "===> Installing Packer and addons..." && \
  wget https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip && \
  wget https://github.com/jetbrains-infra/packer-builder-vsphere/releases/download/v${VSPHERE_ISO_VERSION}/packer-builder-vsphere-iso.linux && \
  unzip packer_${PACKER_VERSION}_linux_amd64.zip && \
  install -m 0755 -t /usr/local/bin/ packer packer-builder-vsphere-iso.linux

RUN echo "===> Installing Python modules..." && \
  pip3 install --upgrade pywinrm pyvmomi jmespath netaddr
  
RUN echo "===> Cleaning up..." && \
  rm -rf /var/lib/apt/lists/* /etc/apt/sources.list.d/ansible.list packer_${PACKER_VERSION}_linux_amd64.zip packer-builder-vsphere-iso.linux && \
  apt-get clean -y
  
RUN echo "===> Setting some Ansible options for convenience..." && \
  echo 'localhost' > /etc/ansible/hosts

ENV ANSIBLE_CALLBACK_WHITELIST=timer,profile_tasks
ENV PROFILE_TASKS_TASK_OUTPUT_LIMIT=5
ENV ANSIBLE_INVENTORY_ENABLED=host_list,script,yaml,auto,vmware_vm_inventory,netbox
ENV ANSIBLE_SSH_ARGS="-o ControlMaster=auto -o ControlPersist=10m -o UserKnownHostsFile=/dev/null"
ENV HOST_KEY_CHECKING=false
ENV DEFAULT_REMOTE_USER=ubuntu

# default command: display Ansible version
CMD [ "ansible-playbook", "--version" ]
