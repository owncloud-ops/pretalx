FROM python:3.10-slim@sha256:cc91315c3561d0b87d0525cb814d430cfbc70f10ca54577def184da80e87c1db

LABEL maintainer="ownCloud DevOps <devops@owncloud.com>"
LABEL org.opencontainers.image.authors="ownCloud DevOps <devops@owncloud.com>"
LABEL org.opencontainers.image.title="Pretalx conference management system"
LABEL org.opencontainers.image.url="https://github.com/owncloud-ops/pretalx"
LABEL org.opencontainers.image.source="https://github.com/owncloud-ops/pretalx"
LABEL org.opencontainers.image.documentation="https://github.com/owncloud-ops/pretalx"

ARG BUILD_VERSION
ARG GOMPLATE_VERSION
ARG WAIT_FOR_VERSION
ARG CONTAINER_LIBRARY_VERSION

# renovate: datasource=github-releases depName=pretalx/pretalx
ENV PRETALX_VERSION="${BUILD_VERSION:-v2023.1.0}"
# renovate: datasource=github-releases depName=hairyhenderson/gomplate
ENV GOMPLATE_VERSION="${GOMPLATE_VERSION:-v3.11.5}"
# renovate: datasource=github-releases depName=thegeeklab/wait-for
ENV WAIT_FOR_VERSION="${WAIT_FOR_VERSION:-v0.4.2}"
# renovate: datasource=github-releases depName=owncloud-ops/container-library
ENV CONTAINER_LIBRARY_VERSION="${CONTAINER_LIBRARY_VERSION:-v0.1.0}"

ENV LANG=C.UTF-8
ENV LANGUAGE=C.UTF-8
ENV LC_ALL=C.UTF-8

ADD overlay /

RUN addgroup --gid 1001 --system pretalx && \
    adduser --system --disabled-password --no-create-home --home /pretalx --uid 1001 --shell /sbin/nologin --ingroup pretalx --gecos pretalx pretalx && \
    apt-get update && apt-get install --no-install-recommends -y wget curl apt-transport-https ca-certificates git gettext libmariadb-dev libpq-dev \
        libmemcached-dev pkg-config build-essential locales && \
    curl -SsfL -o /usr/local/bin/gomplate "https://github.com/hairyhenderson/gomplate/releases/download/${GOMPLATE_VERSION}/gomplate_linux-amd64" && \
    curl -SsfL -o /usr/local/bin/wait-for "https://github.com/thegeeklab/wait-for/releases/download/${WAIT_FOR_VERSION}/wait-for" && \
    curl -SsfL "https://github.com/owncloud-ops/container-library/releases/download/${CONTAINER_LIBRARY_VERSION}/container-library.tar.gz" | tar xz -C / && \
    chmod 755 /usr/local/bin/gomplate && \
    chmod 755 /usr/local/bin/wait-for && \
    dpkg-reconfigure locales && \
    locale-gen C.UTF-8 && \
    /usr/sbin/update-locale LANG=C.UTF-8 && \
    mkdir -p /pretalx /etc/pretalx /data && \
    PRETALX_VERSION="${PRETALX_VERSION##v}" && \
    echo "Setup Pretalx 'v${PRETALX_VERSION}' ..." && \
    curl -SsfL "https://github.com/pretalx/pretalx/archive/v${PRETALX_VERSION}.tar.gz" | \
        tar -xzf - -C /pretalx/src --strip-components=2 "pretalx-${PRETALX_VERSION}/src" && \
    pip install -e /pretalx/src/ && \
    pip install django-redis pylibmc mysqlclient psycopg2-binary redis==3.3.1 && \
    pip install gunicorn && \
    python -m pretalx makemigrations && \
    python -m pretalx migrate && \
    python -m pretalx rebuild && \
    rm -f /pretalx/src/pretalx.cfg && \
    rm -f /pretalx/src/data/.secret && \
    chmod 750 /etc/pretalx && \
    chmod 750 /data && \
    chown -R pretalx:pretalx /etc/pretalx /pretalx /data && \
    apt-get remove -y --purge curl build-essential && \
    apt-get clean all && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

VOLUME /data

EXPOSE 8000

USER pretalx

ENTRYPOINT ["/usr/bin/entrypoint"]
WORKDIR /data
CMD []
