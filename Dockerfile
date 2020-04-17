# Dockerfile for building Ansible runtime image
#
# @see https://launchpad.net/~ansible/+archive/ubuntu/ansible
#

# Base image
FROM alpine:3.11

# Labels and environment
LABEL maintainer="Alexander <blacke4dawn@gmail.com>"
ENV PACKER_VERSION=1.5.5
ENV ANSIBLE_VERSION=2.9.6
ENV ANSIBLE_CALLBACK_WHITELIST=timer,profile_tasks
ENV PROFILE_TASKS_TASK_OUTPUT_LIMIT=5
ENV ANSIBLE_INVENTORY_ENABLED=host_list,script,yaml,auto,vmware_vm_inventory,netbox
ENV ANSIBLE_SSH_ARGS="-o ControlMaster=auto -o ControlPersist=10m -o UserKnownHostsFile=/dev/null"
ENV HOST_KEY_CHECKING=false
ENV DEFAULT_REMOTE_USER=ubuntu
ENV ANSIBLE_PYTHON_INTERPRETER=/usr/bin/python3

# All the different layers
RUN echo "===> Updating system and installing necessary tools..." && \
  apk update && \
  apk upgrade -U -a && \
  apk add gnupg sshpass openssh-client wget python3 curl python3-dev gcc musl-dev libffi-dev openssl-dev p7zip cpio gzip cdrkit whois pwgen fakeroot syslinux xorriso unzip && \
  python3 -m pip install -U pip wheel setuptools && \
  pip3 install -U ansible==${ANSIBLE_VERSION} pyvmomi>=6.7.1.2018.12 jmespath>=0.9.4 pynetbox>=3.4.7

# RUN echo "====> Setting up Powershell and PowerCLI..." && \
#   pwsh -noni -c "& {Install-Module -Name VMware.PowerCLI -Force}" && \
#   pwsh -noni -c "& {Set-PowerCLIConfiguration -Scope User -Confirm:\$false -InvalidCertificateAction Ignore -ParticipateInCEIP \$false }"
  
RUN echo "===> Installing Packer..." && \
  wget https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip && \
  unzip packer_${PACKER_VERSION}_linux_amd64.zip && \
  install -m 0755 -t /usr/local/bin/ packer

RUN echo "===> Cleaning up..." && \
  apk del python3-dev gcc musl-dev libffi-dev openssl-dev && \
  rm -rf packer_${PACKER_VERSION}_linux_amd64.zip ./key-file
  
RUN echo "===> Setting some Ansible options for convenience..." && \
  mkdir /etc/ansible && \
  echo 'localhost:' > /etc/ansible/hosts

# default command: display Ansible version
CMD [ "ansible-playbook", "--version" ]
