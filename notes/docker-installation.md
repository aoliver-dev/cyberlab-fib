# Docker Installation

## Host environment

* Operating system: Ubuntu 24.04.4 LTS
* Architecture: x86_64
* Logical CPUs: 16
* Memory: 15 GiB
* Available disk space: 365 GB
* Python: 3.12.3
* Git: 2.43.0
* Docker Engine: installed

## Installation verification

The Docker service was verified with:

```bash
sudo systemctl status docker
```

The service was active and running.

The installation was also tested using the official `hello-world` image:

```bash
docker run --rm hello-world
```

Docker successfully:

1. Connected the Docker client to the Docker daemon.
2. Downloaded the image from Docker Hub.
3. Created and executed a container.
4. Returned the container output to the terminal.
5. Removed the container after execution.

## First interactive container

An Ubuntu 24.04 container was executed using:

```bash
docker run --rm -it ubuntu:24.04 bash
```

Inside the container, the following commands were tested:

```bash
whoami
hostname
cat /etc/os-release
pwd
ls /
ps aux
```

The container:

* Used `root` as its internal user.
* Had its own hostname.
* Had an isolated filesystem.
* Contained only the processes required for the interactive Bash session.
* Was automatically deleted after exiting because the `--rm` option was used.

## Key concepts learned

* A Docker image is a template used to create containers.
* A container is an isolated process running from an image.
* Containers have their own filesystem, hostname and process space.
* Containers are ephemeral unless persistent storage is configured.
* The `--rm` option deletes the container after it stops.
* The `-it` options provide an interactive terminal.

## Security consideration

Users in the `docker` group have highly privileged access to the host system. Only trusted images and Docker Compose configurations should be executed.
