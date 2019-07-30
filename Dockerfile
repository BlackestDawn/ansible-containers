# Dockerfile for building Ansible image for Ubuntu 18.04 (Bionical), with as few additional software as possible.
#
# @see https://launchpad.net/~ansible/+archive/ubuntu/ansible
#
# Version  1.0
#

# pull base image
FROM ubuntu:18.04

# Labels and other metadata
LABEL maintainer="Alexander <blacke4dawn@gmail.com>"
ENV PACKER_VERSION=1.4.2
ENV VSPHERE_ISO_VERSION=2.3

RUN echo "===> Adding gnupg2..." && \
    apt-get update && \
    apt-get install -y gnupg2 software-properties-common && \
    echo "===> Adding Ansible's PPA..."  && \
    add-apt-repository ppa:ansible/ansible-2.8    && \
    DEBIAN_FRONTEND=noninteractive  apt-get update  && \
    \
    echo "===> Installing basic tools and programs..." && \
    apt-get install -y sshpass openssh-client unzip wget python3 python3-pip && \
    \
    echo "===> Installing Ansible..."  && \
    apt-get install -y ansible  && \
    \
    \
    echo "===> Installing Packer and addons..." && \
    wget https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip && \
    wget https://github.com/jetbrains-infra/packer-builder-vsphere/releases/download/v${VSPHERE_ISO_VERSION}/packer-builder-vsphere-iso.linux && \
    unzip packer_${PACKER_VERSION}_linux_amd64.zip && \
    install -m 0755 -t /usr/local/bin/ packer packer-builder-vsphere-iso.linux && \
    rm -f packer_${PACKER_VERSION}_linux_amd64.zip && \
    \
    echo "===> Installing ISO remastering tools..." && \
    apt-get install -y p7zip-full cpio gzip genisoimage whois pwgen wget fakeroot isolinux xorriso && \
    \
    echo "===> Installing Python modules..."  && \
    pip3 install --upgrade pywinrm pyvmomi jmespath netaddr && \
    \
    \
    echo "===> Cleanigg up..."  && \
    rm -rf /var/lib/apt/lists/*  /etc/apt/sources.list.d/ansible.list  && \
    apt-get clean -y && \
    \
    \
    echo "===> Adding hosts to Ansible for convenience..."  && \
    echo 'localhost' > /etc/ansible/hosts

RUN sed -i 's/#remote_user.*/remote_user = ubuntu/g' /etc/ansible/ansible.cfg && \
    sed -i 's/#host_key_checking.*/host_key_checking = False/g' /etc/ansible/ansible.cfg && \
    sed -i 's/#ssh_args.*/ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=\/dev\/null/g' /etc/ansible/ansible.cfg

# default command: display Ansible version
CMD [ "ansible-playbook", "--version" ]
