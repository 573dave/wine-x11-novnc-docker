[supervisord]
nodaemon=true
logfile=/dev/null
logfile_maxbytes=0
pidfile=/tmp/supervisord.pid

[supervisorctl]
serverurl=unix:///tmp/supervisor.sock

;———— Xvfb (Virtual Display) ————
[program:xvfb]
command=/usr/bin/Xvfb :0 -screen 0 1024x768x24 -nolisten tcp
user=wineuser
priority=10
startsecs=3
autorestart=true
stopasgroup=true
killasgroup=true
stdout_logfile=/dev/fd/1
stdout_logfile_maxbytes=0
stderr_logfile=/dev/fd/2
stderr_logfile_maxbytes=0

;———— x11vnc (VNC Server) ————
[program:x11vnc]
command=/usr/bin/x11vnc -display :0 -forever -shared -noxrecord -noxfixes -noxdamage -rfbport 5900 -passwd /home/wineuser/.vnc/passwd
user=wineuser
priority=20
startsecs=5
autorestart=true
stopasgroup=true
killasgroup=true
stdout_logfile=/dev/fd/1
stdout_logfile_maxbytes=0
stderr_logfile=/dev/fd/2
stderr_logfile_maxbytes=0

;———— noVNC (Web VNC Client) ————
[program:novnc]
command=python3 /home/wineuser/novnc/utils/websockify/websockify.py --web /home/wineuser/novnc 8080 localhost:5900
user=wineuser
priority=30
startsecs=5
autorestart=true
stopasgroup=true
killasgroup=true
stdout_logfile=/dev/fd/1
stdout_logfile_maxbytes=0
stderr_logfile=/dev/fd/2
stderr_logfile_maxbytes=0

;———— Fluxbox (Window Manager) ————
[program:fluxbox]
command=/usr/bin/fluxbox
user=wineuser
environment=DISPLAY=":0"
priority=40
startsecs=5
autorestart=true
stopasgroup=true
killasgroup=true
stdout_logfile=/dev/fd/1
stdout_logfile_maxbytes=0
stderr_logfile=/dev/fd/2
stderr_logfile_maxbytes=0

;———— Wine Explorer (Optional) ————
[program:explorer]
command=wine explorer.exe
directory=/home/wineuser/prefix32/drive_c/windows
environment=DISPLAY=":0",WINEPREFIX="/home/wineuser/prefix32",WINEARCH="win32"
user=wineuser
priority=50
startsecs=10
autorestart=true
autostart=false
stopasgroup=true
killasgroup=true
stdout_logfile=/dev/fd/1
stdout_logfile_maxbytes=0
stderr_logfile=/dev/fd/2
stderr_logfile_maxbytes=0
