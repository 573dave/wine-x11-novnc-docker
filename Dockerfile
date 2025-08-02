# syntax=docker/dockerfile:1

##############################################
# Base image & env
##############################################
FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8 \
    LC_ALL=C.UTF-8 \
    WINEDEBUG=-all

##############################################
# 1) Install prerequisites & WineHQ repo
##############################################
RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
    ca-certificates gnupg2 software-properties-common wget \
    cabextract \
 && mkdir -p /etc/apt/keyrings \
 && wget -qO- https://dl.winehq.org/wine-builds/winehq.key \
       | gpg --dearmor > /etc/apt/keyrings/winehq-archive-keyring.gpg \
 && echo "deb [signed-by=/etc/apt/keyrings/winehq-archive-keyring.gpg] \
       https://dl.winehq.org/wine-builds/ubuntu/ jammy main" \
       > /etc/apt/sources.list.d/winehq.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
    winehq-staging \
    libvulkan1 vulkan-tools winetricks \
    python3 xvfb x11vnc xdotool supervisor net-tools fluxbox \
 && rm -rf /var/lib/apt/lists/*

##############################################
# 2) Create non‐root user & dirs
##############################################
RUN useradd -m -s /bin/bash wineuser \
 && mkdir -p /home/wineuser/{prefix32,novnc,novnc/utils/websockify,.fluxbox} \
 && chown -R wineuser:wineuser /home/wineuser

##############################################
# 3) Pre-cache fonts to avoid startup lag
##############################################
RUN fc-cache -fv

##############################################
# 4) Enable DXVK in the 32-bit prefix
##############################################
USER wineuser
ENV WINEPREFIX=/home/wineuser/prefix32 \
    WINEARCH=win32 \
    DISPLAY=:0
RUN winetricks -q dxvk

##############################################
# 5) Minimal Fluxbox config (no toolbar)
##############################################
RUN printf 'session.screen0.toolbar: false\n' \
    > /home/wineuser/.fluxbox/init

##############################################
# 6) Supervisor config
##############################################
USER root
COPY supervisord.conf /etc/supervisor/conf.d/

##############################################
# 7) Fetch noVNC & websockify
##############################################
WORKDIR /home/wineuser
RUN wget -qO- https://github.com/novnc/noVNC/archive/v1.5.0.tar.gz \
      | tar xz --strip-components=1 -C /home/wineuser/novnc \
 && wget -qO- https://github.com/novnc/websockify/archive/v0.12.0.tar.gz \
      | tar xz --strip-components=1 -C /home/wineuser/novnc/utils/websockify \
 && chown -R wineuser:wineuser /home/wineuser/novnc

##############################################
# 8) Expose & entrypoint
##############################################
EXPOSE 8080
USER wineuser
CMD ["supervisord", "-n"]
