# syntax=docker/dockerfile:1

# 1) Use a newer LTS and slimmer image
FROM ubuntu:22.04 AS base

# 2) Build args / env
ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8 \
    LC_ALL=C.UTF-8

# 3) Install core dependencies (no-install-recommends to slim down)
RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
    ca-certificates \
    gnupg2 \
    software-properties-common \
    python3 \
    xvfb \
    x11vnc \
    xdotool \
    wget \
    supervisor \
    net-tools \
    fluxbox \
 && rm -rf /var/lib/apt/lists/*

# 4) Add WineHQ key with 'signed-by=' (apt-key is deprecated)
RUN mkdir -p /etc/apt/keyrings \
 && wget -qO- https://dl.winehq.org/wine-builds/winehq.key \
    | gpg --dearmor > /etc/apt/keyrings/winehq-archive-keyring.gpg \
 && echo \
    "deb [signed-by=/etc/apt/keyrings/winehq-archive-keyring.gpg] \
     https://dl.winehq.org/wine-builds/ubuntu/ jammy main" \
    > /etc/apt/sources.list.d/winehq.list

# 5) Install Wine (latest stable, no pin)
RUN apt-get update \
 && apt-get install -y --no-install-recommends winehq-stable \
 && rm -rf /var/lib/apt/lists/*

# 6) Create an unprivileged user for running X/VNC/Wine
ENV WINEPREFIX=/home/wineuser/prefix32 \
    WINEARCH=win32 \
    DISPLAY=:0
RUN useradd -m -s /bin/bash wineuser \
 && mkdir -p /home/wineuser/{prefix32,novnc,novnc/utils/websockify} \
 && chown -R wineuser:wineuser /home/wineuser

# 7) Set up x11vnc password script
RUN echo 'echo -n $HOSTNAME' \
     > /home/wineuser/x11vnc_password.sh \
 && chmod +x /home/wineuser/x11vnc_password.sh \
 && chown wineuser:wineuser /home/wineuser/x11vnc_password.sh

# 8) Copy Supervisor configs
COPY supervisord.conf /etc/supervisor/conf.d/

WORKDIR /home/wineuser

# 9) Fetch noVNC & websockify (pin or update to latest)
RUN wget -qO- https://github.com/novnc/noVNC/archive/v1.5.0.tar.gz \
    | tar xz --strip-components=1 -C /home/wineuser/novnc \
 && wget -qO- https://github.com/novnc/websockify/archive/v0.12.0.tar.gz \
    | tar xz --strip-components=1 -C /home/wineuser/novnc/utils/websockify \
 && chown -R wineuser:wineuser /home/wineuser/novnc

EXPOSE 8080

# 10) Drop root privileges
USER wineuser

# 11) Run Supervisor in foreground
CMD ["supervisord", "-n"]
