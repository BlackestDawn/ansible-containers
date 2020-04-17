# Dockerfile for building Ansible runtime image
#
# @see https://launchpad.net/~ansible/+archive/ubuntu/ansible
#

# Base image
FROM ubuntu:18.04

# Labels and other metadata
LABEL maintainer="Alexander <blacke4dawn@gmail.com>"
ENV DEBIAN_FRONTEND=noninteractive
ENV PACKER_VERSION=1.5.5

# All the different layers
RUN echo "===> Updating system and installing necessary tools..." && \
  apt-get update && \
  apt-get dist-upgrade -y && \
  apt-get install -y software-properties-common gnupg2 sshpass openssh-client wget python3 python3-pip python3-wheel curl apt-utils

RUN echo "===> Adding on extra APT repos and installing extra tools..." && \
  curl -o ./key-file https://packages.microsoft.com/keys/microsoft.asc && \
  apt-key add ./key-file && \
  curl -o /etc/apt/sources.list.d/microsoft.list https://packages.microsoft.com/config/ubuntu/18.04/prod.list && \
  apt-get update && \
  apt-get install -y ansible powershell p7zip-full cpio gzip genisoimage whois pwgen wget fakeroot isolinux xorriso unzip && \
  pip3 install --upgrade pywinrm pyvmomi jmespath netaddr ansible

RUN echo "====> Setting up Powershell and PowerCLI..." && \
  pwsh -noni -c "& {Install-Module -Name VMware.PowerCLI -Force}" && \
  pwsh -noni -c "& {Set-PowerCLIConfiguration -Scope User -Confirm:\$false -InvalidCertificateAction Ignore -ParticipateInCEIP \$false }"
  
RUN echo "===> Installing Packer..." && \
  wget https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip && \
  unzip packer_${PACKER_VERSION}_linux_amd64.zip && \
  install -m 0755 -t /usr/local/bin/ packer

RUN echo "===> Cleaning up..." && \
  rm -rf /var/lib/apt/lists/* /etc/apt/sources.list.d/ansible.list packer_${PACKER_VERSION}_linux_amd64.zip ./key-file && \
  apt-get clean -y
  
RUN echo "===> Setting some Ansible options for convenience..." && \
  echo 'localhost:' > /etc/ansible/hosts

ENV ANSIBLE_CALLBACK_WHITELIST=timer,profile_tasks
ENV PROFILE_TASKS_TASK_OUTPUT_LIMIT=5
ENV ANSIBLE_INVENTORY_ENABLED=host_list,script,yaml,auto,vmware_vm_inventory,netbox
ENV ANSIBLE_SSH_ARGS="-o ControlMaster=auto -o ControlPersist=10m -o UserKnownHostsFile=/dev/null"
ENV HOST_KEY_CHECKING=false
ENV DEFAULT_REMOTE_USER=ubuntu
ENV ANSIBLE_PYTHON_INTERPRETER=/usr/bin/python3

# default command: display Ansible version
CMD [ "ansible-playbook", "--version" ]
