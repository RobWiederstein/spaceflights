ARG BASE_IMAGE=python:3.9-slim
FROM $BASE_IMAGE AS runtime-environment

RUN apt-get update && \
    apt-get install -y tree && \
    rm -rf /var/lib/apt/lists/*

# Install eza 
ENV EZA_VERSION="0.21.3"
ENV EZA_ARCHIVE_FILENAME="eza_x86_64-unknown-linux-musl.tar.gz" 

RUN apt-get update && \
    # Install curl for downloading, tar and gzip for extraction
    # gzip is usually present, tar might be. Adding explicitly is safe.
    apt-get install -y curl tar gzip file && \
    echo "Downloading from URL: https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/${EZA_ARCHIVE_FILENAME}" && \
    # Use -f to fail on server error, -L to follow redirects, -S to show errors, -o to output to file
    curl -fLSo /tmp/eza.tar.gz "https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/${EZA_ARCHIVE_FILENAME}" && \
    echo "--- Downloaded archive type: ---" && \
    file /tmp/eza.tar.gz && \
    echo "---------------------------" && \
    echo "Extracting eza from /tmp/eza.tar.gz to /tmp" && \
    # The binary 'eza' is usually directly inside this tarball
    tar -xzf /tmp/eza.tar.gz -C /tmp && \
    echo "Moving eza binary to /usr/local/bin and making it executable" && \
    mv /tmp/eza /usr/local/bin/eza && \
    chmod +x /usr/local/bin/eza && \
    echo "Verifying eza installation" && \
    eza --version && \
    echo "Cleaning up downloaded files" && \
    rm -f /tmp/eza.tar.gz && \
    echo "Purging temporary build dependencies and cleaning apt cache" && \
    apt-get purge -y --auto-remove curl file && \
    rm -rf /var/lib/apt/lists/* && \
    echo "eza installation complete."

# update pip and install uv
RUN python -m pip install -U "pip>=21.2"
RUN pip install uv

# install project requirements
COPY requirements.txt /tmp/requirements.txt
RUN uv pip install --system --no-cache-dir -r /tmp/requirements.txt && rm -f /tmp/requirements.txt

# add kedro user
ARG KEDRO_UID=999
ARG KEDRO_GID=0
RUN groupadd -f -g ${KEDRO_GID} kedro_group && \
    useradd -m -d /home/kedro_docker -s /bin/bash -g ${KEDRO_GID} -u ${KEDRO_UID} kedro_docker

# Add custom aliases for the kedro_docker user
# Add custom aliases for the kedro_docker user
RUN echo "# Enhanced ls with eza" >> /home/kedro_docker/.bashrc && \
    echo "alias l='eza -albhF --git --icons --color=always --group-directories-first'" >> /home/kedro_docker/.bashrc && \
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

WORKDIR /home/kedro_docker
USER kedro_docker

FROM runtime-environment

# copy the whole project except what is in .dockerignore
ARG KEDRO_UID=999
ARG KEDRO_GID=0
COPY --chown=${KEDRO_UID}:${KEDRO_GID} . .

EXPOSE 8888

ENV KEDRO_DISABLE_TELEMETRY=True
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    # Refined filter for the namespace deprecation warning
    PYTHONWARNINGS="ignore:'kedro run' flag '--namespace' is deprecated:DeprecationWarning"

CMD ["kedro", "run"]
