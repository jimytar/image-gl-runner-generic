# Start from Debian slim image
FROM debian:12.7-slim

# Set noninteractive mode for apt-get
ENV DEBIAN_FRONTEND=noninteractive

# Define arguments for versions and user
ARG USER=runner
ARG NODE=20.17.0
ARG TERRAFORM=1.9.6
ARG KUBECTL=1.30.6
ARG HELM=3.16.2
ARG PACKER=1.11.2

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    curl \
    wget \
    git \
    unzip \
    jq \
    rclone \
    tree \
    rsync \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Set up runner user
RUN adduser --disabled-password --gecos "" --uid 1001 ${USER} \
    && groupadd docker --gid 123 \
    && usermod -aG sudo ${USER} \
    && usermod -aG docker ${USER} \
    && echo "%sudo   ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers \
    && echo "Defaults env_keep += \"DEBIAN_FRONTEND\"" >> /etc/sudoers

WORKDIR /home/${USER}

# Install Docker CLI
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
    $(source /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y --no-install-recommends docker-ce-cli docker-buildx-plugin docker-compose-plugin && \
    rm -rf /var/lib/apt/lists/*

# Switch to the runner user
USER ${USER}

# Install asdf and configure the environment
RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.1 \
    && echo ". $HOME/.asdf/asdf.sh" >> ~/.bashrc \
    && echo ". $HOME/.asdf/completions/asdf.bash" >> ~/.bashrc

ENV ASDF_DIR="/home/${USER}/.asdf"
ENV PATH="$ASDF_DIR/bin:$ASDF_DIR/shims:$PATH"

# Install Node.js
RUN asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git \
    && asdf install nodejs ${NODE} \
    && asdf global nodejs ${NODE}

# Install Terraform
RUN asdf plugin add terraform https://github.com/asdf-community/asdf-hashicorp.git \
    && asdf install terraform ${TERRAFORM} \
    && asdf global terraform ${TERRAFORM}

# Install kubectl
RUN asdf plugin add kubectl https://github.com/asdf-community/asdf-kubectl.git \
&& asdf install kubectl ${KUBECTL} \
&& asdf global kubectl ${KUBECTL}

# Install Packer
RUN asdf plugin add packer https://github.com/asdf-community/asdf-hashicorp.git \
&& asdf install packer ${PACKER} \
&& asdf global packer ${PACKER}

# Install Helm
RUN asdf plugin add helm https://github.com/Antiarchitect/asdf-helm.git \
&& asdf install helm ${HELM} \
&& asdf global helm ${HELM}
