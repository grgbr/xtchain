ARG DOCKIMG
FROM $DOCKIMG

ARG DEBSRCDEPS
ARG XTCHAIN_UID
ARG XTCHAIN_USER
ARG XTCHAIN_GID
ARG XTCHAIN_GROUP
ARG XTCHAIN_HOME

USER root

# Install basic tools
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get --yes update
# Some docker minimize env by removing doc and doc tools. Force unminimize it
# for test inside docker (like perl)
RUN if [ -f /usr/local/sbin/unminimize ]; then yes | /usr/local/sbin/unminimize; fi
RUN apt-get --yes install sudo util-linux make locales $DEBSRCDEPS
RUN apt-get --yes clean
RUN echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen && locale-gen
# Make the xtchain group a system group to prevent from GID space conflict with
# $XTCHAIN_GID user group created by scripts/dock_start.sh
RUN addgroup --system xtchain
RUN umask 0337 && \
    echo '%xtchain ALL=(ALL:ALL) NOPASSWD: /usr/bin/apt, /usr/bin/apt-get, /usr/bin/make' \
    > /etc/sudoers.d/xtchain

RUN addgroup --gid $XTCHAIN_GID $XTCHAIN_GROUP >/dev/null
RUN adduser --uid $XTCHAIN_UID \
            --gid $XTCHAIN_GID \
            --home $XTCHAIN_HOME \
            --no-create-home \
            --disabled-password \
            --gecos '' \
            $XTCHAIN_USER >/dev/null
RUN adduser $XTCHAIN_USER xtchain >/dev/null
RUN adduser $XTCHAIN_USER sudo >/dev/null

ENV USER=$XTCHAIN_USER
USER $XTCHAIN_USER
