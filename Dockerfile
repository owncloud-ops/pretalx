FROM docker.io/pretalx/standalone:v2.3.2@sha256:bedafcb43859e7cccd9191aba6e80910327a1856fe6a0e4685d35f7b097d6d16

LABEL maintainer="ownCloud DevOps <devops@owncloud.com>"
LABEL org.opencontainers.image.authors="ownCloud DevOps <devops@owncloud.com>"
LABEL org.opencontainers.image.title="Pretalx conference management system"
LABEL org.opencontainers.image.url="https://github.com/owncloud-ops/pretalx"
LABEL org.opencontainers.image.source="https://github.com/owncloud-ops/pretalx"
LABEL org.opencontainers.image.documentation="https://github.com/owncloud-ops/pretalx"

ARG GOMPLATE_VERSION
ARG CONTAINER_LIBRARY_VERSION

# renovate: datasource=github-releases depName=hairyhenderson/gomplate
ENV GOMPLATE_VERSION="${GOMPLATE_VERSION:-v3.11.5}"
# renovate: datasource=github-releases depName=owncloud-ops/container-library
ENV CONTAINER_LIBRARY_VERSION="${CONTAINER_LIBRARY_VERSION:-v0.1.0}"

ENV LANG=C.UTF-8
ENV LANGUAGE=C.UTF-8
ENV LC_ALL=C.UTF-8

ADD overlay /

USER 0

RUN apt-get update && apt-get install -y curl apt-transport-https ca-certificates && \
    SUDO_FORCE_REMOVE=yes apt-get remove --purge -y sudo supervisor && \
    curl -SsfL -o /usr/local/bin/gomplate "https://github.com/hairyhenderson/gomplate/releases/download/${GOMPLATE_VERSION}/gomplate_linux-amd64" && \
    curl -SsfL "https://github.com/owncloud-ops/container-library/releases/download/${CONTAINER_LIBRARY_VERSION}/container-library.tar.gz" | tar xz -C / && \
    chmod 755 /usr/local/bin/gomplate && \
    pip3 install -e /pretalx/src/ && \
    python3 -m pretalx makemigrations && \
    python3 -m pretalx migrate && \
    python3 -m pretalx rebuild && \
    chmod 750 /etc/pretalx && \
    chmod 750 /data && \
    chown -R pretalxuser:pretalxuser /etc/pretalx /pretalx /data && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

VOLUME /data

EXPOSE 80

USER pretalxuser

ENTRYPOINT ["/usr/bin/entrypoint"]
WORKDIR /data
CMD []
