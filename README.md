## wine-x11-novnc-docker

![Docker Image Size (tag)](https://img.shields.io/docker/image-size/solarkennedy/wine-x11-novnc-docker/latest)
![Docker Pulls](https://img.shields.io/docker/pulls/solarkennedy/wine-x11-novnc-docker)

**Containerized Wine desktop** in your browser—no GUI on your host required.

This container runs:
- **Xvfb** – in-memory X11 server
- **x11vnc** – VNC server scraping Xvfb  
- **noVNC** – HTML5 VNC client (access at http://localhost:8080)  
- **Fluxbox** – minimal window manager  
- **Explorer.exe** – demo Windows app via Wine  

**Trusted build** on Docker Hub.

#### Run it

    # Start the container
    ```
    docker run --rm -p 8080:8080 solarkennedy/wine-x11-novnc-docker
    ```

    # Show the container ID (this is the VNC password)
    ```
    docker ps
    ```

    # Open VNC in your web browser
    ```
    xdg-open http://localhost:8080
    ```


In your web browser, type the container ID as password, and then you should see the default application, explorer.exe:

![Explorer Screenshot](https://raw.githubusercontent.com/solarkennedy/wine-x11-novnc-docker/master/screenshot.png)

## Modifying

This is a base image. You should fork or use this base image to run your own wine programs?

## Issues

* Wine could be optimized a bit
* Fluxbox could be skinned or reduced
