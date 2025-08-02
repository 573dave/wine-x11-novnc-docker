# syntax=docker/dockerfile:1
##############################################
# Base image & environment
##############################################
FROM ubuntu:22.04
ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8 \
    LC_ALL=C.UTF-8 \
    WINEDEBUG=-all

##############################################
# 1) Core & WineHQ setup
##############################################
RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates gnupg2 software-properties-common \
      wget cabextract curl \
 && mkdir -p /etc/apt/keyrings \
 && wget --timeout=30 --tries=3 -qO- https://dl.winehq.org/wine-builds/winehq.key \
      | gpg --dearmor > /etc/apt/keyrings/winehq-archive-keyring.gpg \
 && echo "deb [signed-by=/etc/apt/keyrings/winehq-archive-keyring.gpg] \
      https://dl.winehq.org/wine-builds/ubuntu/ jammy main" \
      > /etc/apt/sources.list.d/winehq.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      winehq-staging libvulkan1 vulkan-tools winetricks \
      python3 xvfb x11vnc xdotool supervisor net-tools fluxbox \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

##############################################
# 2) Create wineuser & directories
##############################################
RUN useradd -m -s /bin/bash wineuser \
 && mkdir -p /home/wineuser/{prefix32,novnc,novnc/utils/websockify,.fluxbox} \
 && chown -R wineuser:wineuser /home/wineuser

##############################################
# 3) Supervisor configs & Fluxbox setup
##############################################
COPY supervisord.conf /etc/supervisor/conf.d/
RUN printf 'session.screen0.toolbar: false\n' \
     > /home/wineuser/.fluxbox/init \
 && chown wineuser:wineuser /home/wineuser/.fluxbox/init

##############################################
# 4) Precache fonts for faster startup
##############################################
RUN fc-cache -fv

##############################################
# 5) Fetch noVNC & websockify (v1.6.0 & v0.13.0)
##############################################
USER wineuser
WORKDIR /home/wineuser
RUN mkdir -p novnc novnc/utils/websockify \
 && wget --timeout=30 --tries=3 -qO /tmp/noVNC.tar.gz \
      https://github.com/novnc/noVNC/archive/refs/tags/v1.6.0.tar.gz \
 && tar xzf /tmp/noVNC.tar.gz --strip-components=1 -C novnc \
 && rm /tmp/noVNC.tar.gz \
 && wget --timeout=30 --tries=3 -qO /tmp/websockify.tar.gz \
      https://github.com/novnc/websockify/archive/refs/tags/v0.13.0.tar.gz \
 && tar xzf /tmp/websockify.tar.gz --strip-components=1 -C novnc/utils/websockify \
 && rm /tmp/websockify.tar.gz

##############################################
# 6) Enable DXVK in Win32 prefix (with error handling)
##############################################
ENV WINEPREFIX=/home/wineuser/prefix32 \
    WINEARCH=win32 \
    DISPLAY=:0

# Initialize wine prefix first, then install DXVK
RUN wineboot --init \
 && winetricks -q --force dxvk || echo "DXVK installation failed, continuing..."

##############################################
# 7) Expose port & health check
##############################################
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/vnc.html || exit 1

##############################################
# 8) Create VNC password script
##############################################
USER root
RUN cat > /usr/local/bin/setup-vnc-password.sh << 'EOF'
#!/bin/bash
# Generate random 6-digit password
VNC_PASSWORD=$(shuf -i 100000-999999 -n 1)
echo "===========================================" 
echo "VNC PASSWORD: $VNC_PASSWORD"
echo "==========================================="
echo "Access noVNC at: http://localhost:8080/vnc.html"
echo "==========================================="

# Create VNC password file
mkdir -p /home/wineuser/.vnc
echo "$VNC_PASSWORD" | vncpasswd -f > /home/wineuser/.vnc/passwd
chmod 600 /home/wineuser/.vnc/passwd
chown wineuser:wineuser /home/wineuser/.vnc/passwd

# Start supervisord
exec supervisord -n
EOF

RUN chmod +x /usr/local/bin/setup-vnc-password.sh

##############################################
# 9) Set entrypoint
##############################################
USER wineuser
CMD ["/usr/local/bin/setup-vnc-password.sh"]
