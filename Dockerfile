FROM ubuntu:22.04 AS base

FROM base AS image

ARG UNAME=ubuntu \
    GID=1000 \
    UID=1000 \
    SSH_KEY=
ARG HOMEDIR="/home/${UNAME}"

RUN apt-get -y update && apt-get -y upgrade &&\
    echo "y" | unminimize &&\
    apt-get -y install sudo openssh-server supervisor

RUN groupadd -g "${GID}" -o "${UNAME}" &&\
    mkdir -p "/home/${UNAME}" &&\
    useradd -m -u "${UID}" -g "${GID}" -G sudo -o -s /bin/bash -d "${HOMEDIR}" "${UNAME}" &&\
    echo "$UNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers &&\
    mkdir -p "/home/${UNAME}/.ssh" &&\
    echo "${SSH_KEY}" > "/home/${UNAME}/.ssh/authorized_keys" &&\
    chmod 700 "/home/${UNAME}/.ssh" &&\
    chmod 600 "/home/${UNAME}/.ssh/authorized_keys" &&\
    chown -R "${UID}:${GID}" "${HOMEDIR}" &&\
    { \
    echo "[supervisord]"; \
    echo "nodaemon=true"; \
    } >> /etc/supervisor/supervisord.conf &&\
    { \
    echo "[program:sshd]"; \
    echo "command=/usr/sbin/sshd -D"; \
    } > /etc/supervisor/conf.d/sshd.conf &&\
    mkdir -p /run/sshd &&\
    mkdir -p /var/log/supervisor &&\
    ssh-keygen -A

EXPOSE 22
CMD ["/usr/bin/supervisord"]
WORKDIR "${HOMEDIR}"