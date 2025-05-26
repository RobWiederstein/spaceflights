ARG BASE_IMAGE=python:3.9-slim
FROM $BASE_IMAGE AS runtime-environment

#ARG BASE_IMAGE=python:3.13-slim
#FROM $BASE_IMAGE AS runtime-environment

ARG TARGETARCH

# Install essential OS packages needed for tree, eza download, quarto download,
# and general utilities. ca-certificates is good for curl https.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    python3-dev \
    curl \
    tar \
    gzip \
    file \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Install eza
ENV EZA_VERSION="0.21.3"
RUN set -e && \
   EZA_ARCHIVE_PART="" && \
    if [ "${TARGETARCH}" = "amd64" ]; then \
        EZA_ARCHIVE_PART="x86_64-unknown-linux-musl"; \
    elif [ "${TARGETARCH}" = "arm64" ]; then \
        EZA_ARCHIVE_PART="aarch64-unknown-linux-gnu"; \ 
    else \
        echo "Unsupported architecture for eza: ${TARGETARCH}" && exit 1; \
    fi && \
    EZA_ARCHIVE_FILENAME="eza_${EZA_ARCHIVE_PART}.tar.gz" && \
    echo "Downloading eza (arch: ${TARGETARCH}) using ${EZA_ARCHIVE_FILENAME}" && \
    curl -fLSo /tmp/eza.tar.gz "https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/${EZA_ARCHIVE_FILENAME}" && \
    file /tmp/eza.tar.gz && \
    tar -xzf /tmp/eza.tar.gz -C /tmp && \
    mv /tmp/eza /usr/local/bin/eza && \
    chmod +x /usr/local/bin/eza && \
    eza --version && \
    rm -f /tmp/eza.tar.gz && \
    echo "eza installation complete."

# Install Quarto CLI
ENV QUARTO_VERSION="1.7.31"
RUN set -e && \
    QUARTO_DEB_ARCH_SUFFIX="" && \
    if [ "${TARGETARCH}" = "amd64" ]; then \
        QUARTO_DEB_ARCH_SUFFIX="amd64"; \
    elif [ "${TARGETARCH}" = "arm64" ]; then \
        QUARTO_DEB_ARCH_SUFFIX="arm64"; \
    else \
        echo "Unsupported architecture for Quarto .deb: ${TARGETARCH}" && exit 1; \
    fi && \
    QUARTO_DEB_FILENAME="quarto-${QUARTO_VERSION}-linux-${QUARTO_DEB_ARCH_SUFFIX}.deb" && \
    echo "Downloading Quarto (arch: ${TARGETARCH}) using ${QUARTO_DEB_FILENAME}" && \
    curl -fLSo /tmp/quarto.deb "https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/${QUARTO_DEB_FILENAME}" && \
    file /tmp/quarto.deb && \
    # apt-get update (already run above, and should be okay before local deb install)
    apt-get install -y --no-install-recommends /tmp/quarto.deb && \
    rm -f /tmp/quarto.deb && \
    quarto --version && \
    echo "Quarto installation complete."

RUN echo "Checking quarto version and installation" && \
    quarto check && \
    echo "Quarto verification complete."

# We keep tar, gzip as they are small and generally useful. eza and quarto are now installed.
RUN apt-get purge -y --auto-remove curl file && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# update pip, setuptools, wheel and install uv (Python build tools)
RUN python -m pip install -U "pip>=21.2" "setuptools>=60" "wheel"
RUN python -m pip install uv

# install project requirements
COPY requirements.txt /tmp/requirements.txt
RUN uv pip install --system --no-cache-dir -r /tmp/requirements.txt && rm -f /tmp/requirements.txt

# add kedro user
ARG KEDRO_UID=999
ARG KEDRO_GID=0
RUN groupadd -f -g ${KEDRO_GID} kedro_group && \
    useradd -m -d /home/kedro_docker -s /bin/bash -g ${KEDRO_GID} -u ${KEDRO_UID} kedro_docker

# Add custom aliases and print them on shell startup
RUN echo "# Enhanced ls with eza" >> /home/kedro_docker/.bashrc && \
    echo "alias ll='eza -albhF --git --icons --color=always --group-directories-first'" >> /home/kedro_docker/.bashrc && \
    echo "" >> /home/kedro_docker/.bashrc && \
    echo "# Kedro specific aliases" >> /home/kedro_docker/.bashrc && \
    echo "alias krun='kedro run'" >> /home/kedro_docker/.bashrc && \
    echo "alias kinit='kedro ipython'" >> /home/kedro_docker/.bashrc && \
    echo "" >> /home/kedro_docker/.bashrc && \
    echo "# eza-powered tree aliases" >> /home/kedro_docker/.bashrc && \
    echo "alias t1='eza -L 1 -a --tree --git --icons --color=always --group-directories-first'" >> /home/kedro_docker/.bashrc && \
    echo "alias t2='eza -L 2 -a --tree --git --icons --color=always --group-directories-first'" >> /home/kedro_docker/.bashrc && \
    echo "alias t3='eza -L 3 -a --tree --git --icons --color=always --group-directories-first'" >> /home/kedro_docker/.bashrc && \
    echo "alias t4='eza -L 4 -a --tree --git --icons --color=always --group-directories-first'" >> /home/kedro_docker/.bashrc && \
    echo "" >> /home/kedro_docker/.bashrc && \
    echo "# Print defined aliases on shell startup" >> /home/kedro_docker/.bashrc && \
    echo "echo '--- Custom Aliases Loaded ---'" >> /home/kedro_docker/.bashrc && \
    echo "alias" >> /home/kedro_docker/.bashrc && \
    echo "echo '---------------------------'" >> /home/kedro_docker/.bashrc

# This structure implies 'runtime-environment' is effectively the final stage setup
# The WORKDIR and USER set here will be inherited by the next stage if it's just 'FROM runtime-environment'
WORKDIR /home/kedro_docker
USER kedro_docker

# This pattern from your `cat Dockerfile` output makes the previous stage the base for the final image.
# All layers from runtime-environment are included.
FROM runtime-environment

# Project files are copied here, into the WORKDIR set above (/home/kedro_docker)
# and will be owned by the USER set above (kedro_docker), thanks to --chown
ARG KEDRO_UID=999 
ARG KEDRO_GID=0
COPY --chown=${KEDRO_UID}:${KEDRO_GID} . .


# copy shell file into container
COPY --chown=kedro_docker:kedro_group run_and_render.sh /home/kedro_docker/run_and_render.sh
RUN chmod +x /home/kedro_docker/run_and_render.sh

# Expose port (e.g., for kedro viz or jupyter)
EXPOSE 8888

# Set runtime environment variables
ENV KEDRO_DISABLE_TELEMETRY=True
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
# PYTHONWARNINGS to suppress specific Kedro deprecation warning
ENV PYTHONWARNINGS="ignore:'kedro run' flag '--namespace' is deprecated:DeprecationWarning"

# Default command
CMD ["kedro", "run"]
