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
ENV PACKER_VERSION=1.4.2
ENV VSPHERE_ISO_VERSION=2.3
ENV DEBIAN_FRONTEND=noninteractive

# All the different layers
RUN echo "===> Updating system and installing base tools..." && \
  apt-get update && \
  apt-get dist-upgrade -y && \
  apt-get install -y gnupg2 software-properties-common sshpass openssh-client wget python3 python3-pip

RUN echo "===> Installing Ansible..." && \
  add-apt-repository ppa:ansible/ansible-2.8 && \
  apt-get update && \
  apt-get install -y ansible
  
RUN echo "===> Installing Python modules..." && \
  pip3 install --upgrade pywinrm pyvmomi jmespath netaddr
  
RUN echo "===> Installing ISO remastering and Packer tools..." && \
  apt-get install -y p7zip-full cpio gzip genisoimage whois pwgen wget unzip fakeroot isolinux xorriso && \
  wget https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip && \
  wget https://github.com/jetbrains-infra/packer-builder-vsphere/releases/download/v${VSPHERE_ISO_VERSION}/packer-builder-vsphere-iso.linux && \
  unzip packer_${PACKER_VERSION}_linux_amd64.zip && \
  install -m 0755 -t /usr/local/bin/ packer packer-builder-vsphere-iso.linux

RUN echo "===> Cleaning up..." && \
  rm -rf /var/lib/apt/lists/* /etc/apt/sources.list.d/ansible.list && \
  apt-get clean -y && \
  rm -f packer_${PACKER_VERSION}_linux_amd64.zip
  
RUN echo "===> Setting some Ansible options for convenience..." && \
  echo 'localhost' > /etc/ansible/hosts && \
  sed -i 's/#remote_user.*/remote_user = ubuntu/g' /etc/ansible/ansible.cfg && \
  sed -i 's/#host_key_checking.*/host_key_checking = False/g' /etc/ansible/ansible.cfg && \
  sed -i 's/#ssh_args.*/ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=\/dev\/null/g' /etc/ansible/ansible.cfg

# default command: display Ansible version
CMD [ "ansible-playbook", "--version" ]
