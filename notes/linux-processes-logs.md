# Linux Processes, Services and Logs Lab

## Objective

The objective of this laboratory was to understand Linux processes, background jobs, signals, system services and logs.

The first part of the lab was performed inside an isolated Ubuntu Docker container. The second part was performed on the host system in order to inspect real services and Docker container logs.

## Laboratory environment

The process laboratory was started with:

```bash
docker run --rm -it --name linux-processes-lab ubuntu:24.04 bash
```

Inside the container, the following tools were installed:

```bash
apt update
apt install -y procps psmisc
```

The `--rm` option ensured that the container was deleted automatically after exiting.

## Processes

A process is a running instance of a program. Each process has a unique identifier called PID.

The main command used to inspect processes was:

```bash
ps aux
```

Important columns in `ps aux`:

- `USER`: user that owns the process.
- `PID`: process identifier.
- `%CPU`: CPU usage.
- `%MEM`: memory usage.
- `STAT`: process state.
- `COMMAND`: command executed by the process.

Inside the container, there were very few processes because the container was only running a Bash shell and the commands executed during the lab.

## Background processes

Several `sleep` processes were created in the background:

```bash
sleep 300 &
sleep 400 &
sleep 500 &
```

The `&` symbol runs a command in the background, allowing the terminal to continue accepting new commands.

The processes were inspected with:

```bash
ps aux | grep sleep
pgrep sleep
pstree -p
```

`pgrep sleep` was useful because it returned only the PIDs of processes matching the name `sleep`.

## grep behaviour

When running:

```bash
ps aux | grep sleep
```

the output may include the `grep sleep` command itself.

Example:

```text
root 170 ... grep --color=auto sleep
```

This does not mean that a `sleep` process is still running. It only means that the `grep` command matched itself because its command line contains the word `sleep`.

A cleaner alternative is:

```bash
pgrep sleep
```

If it returns no output, then there are no active `sleep` processes.

Another alternative is:

```bash
ps aux | grep '[s]leep'
```

## Signals

Processes can be controlled using signals.

The `kill` command sends a signal to a process:

```bash
kill PID
```

By default, `kill` sends `SIGTERM`, which asks the process to terminate gracefully.

The remaining `sleep` processes were terminated with:

```bash
pkill sleep
```

`pkill` sends a signal to all processes matching a given name.

The lab also covered `SIGKILL`:

```bash
kill -9 PID
```

`SIGKILL` forces a process to terminate immediately. It should only be used when a process does not respond to a normal termination signal, because it does not allow the process to clean up resources or save state.

## Foreground and background jobs

A process can run in the foreground or in the background.

This command runs in the foreground:

```bash
sleep 600
```

While it is running, the terminal is blocked.

Pressing `Ctrl+C` interrupts and usually terminates the foreground process.

Pressing `Ctrl+Z` suspends the foreground process instead of terminating it.

Suspended jobs can be inspected with:

```bash
jobs
```

A suspended job can be resumed in the background with:

```bash
bg
```

This demonstrated the difference between terminating, suspending and backgrounding processes.

## Mini challenge

The mini challenge consisted of:

1. Creating three `sleep` processes.
2. Listing their PIDs.
3. Terminating only one process using `kill`.
4. Checking that the other two were still running.
5. Terminating the remaining processes with `pkill`.
6. Verifying that no `sleep` processes remained.

Useful commands:

```bash
sleep 300 &
sleep 400 &
sleep 500 &
pgrep sleep
kill PID
pkill sleep
pgrep sleep
```

The challenge confirmed that individual processes can be managed by PID, while groups of processes can be managed by name.

## Services

A service is usually a background process managed by the operating system.

On Ubuntu, services are commonly managed by `systemd`.

The Docker service was inspected on the host system with:

```bash
systemctl status docker --no-pager
systemctl is-active docker
systemctl is-enabled docker
```

The Docker service was active and enabled.

This means that the Docker daemon was running and configured to start automatically when the system boots.

A list of running services was inspected with:

```bash
systemctl list-units --type=service --state=running --no-pager
```

## Journal logs

System logs managed by `systemd` were inspected using `journalctl`.

Docker service logs were checked with:

```bash
journalctl -u docker --no-pager -n 30
```

Logs from the current day were checked with:

```bash
journalctl -u docker --since today --no-pager
```

Errors from the current boot were checked with:

```bash
journalctl -p err -b --no-pager
```

Useful `journalctl` options:

```text
-u docker      filter by service/unit
-n 30          show the last 30 lines
--since today  show logs since today
-p err         show only error-priority logs
-b             show logs from the current boot
--no-pager     print directly to the terminal
```

`journalctl` is useful for troubleshooting services and investigating system behaviour.

## Docker logs

A temporary Nginx container was started to generate application logs:

```bash
docker run -d --name nginx-log-lab -p 8080:80 nginx:alpine
```

The container was checked with:

```bash
docker ps
```

HTTP traffic was generated with:

```bash
curl http://localhost:8080
curl http://localhost:8080/no-existe
```

The container logs were inspected with:

```bash
docker logs nginx-log-lab
docker logs --tail 5 nginx-log-lab
```

The logs showed the Nginx startup sequence, worker process initialization and HTTP access logs.

A successful request appeared as:

```text
"GET / HTTP/1.1" 200
```

The `200` status code means that the request was successful.

A failed request appeared as:

```text
"GET /no-existe HTTP/1.1" 404
```

The `404` status code means that the requested resource did not exist.

The logs also showed an internal Nginx error message:

```text
open() "/usr/share/nginx/html/no-existe" failed
```

This demonstrates how application logs can provide evidence of both normal and failed activity.

The temporary container was removed with:

```bash
docker stop nginx-log-lab
docker rm nginx-log-lab
```

## Security relevance

Processes, services and logs are fundamental in cybersecurity.

Process inspection can help detect suspicious activity, such as unknown commands, unexpected users or abnormal resource usage.

Service inspection helps understand what is running on a system and whether important daemons are active.

Logs are essential for incident response because they provide evidence of system activity, errors, access attempts and application behaviour.

Examples of security-relevant observations:

- Unexpected processes may indicate compromise.
- Repeated failed requests may indicate scanning or enumeration.
- Service logs can show daemon failures or suspicious restarts.
- Container logs can reveal application errors, access attempts and HTTP status codes.
- Process PIDs allow analysts to isolate or terminate suspicious activity.

## Lessons learned

- A process is a running program with a unique PID.
- `ps aux`, `pgrep` and `pstree` are useful for inspecting processes.
- The `&` symbol runs a command in the background.
- `Ctrl+C` terminates a foreground process, while `Ctrl+Z` suspends it.
- `kill` sends signals to processes.
- `SIGTERM` requests graceful termination.
- `SIGKILL` forces immediate termination and should be used carefully.
- Services are managed by `systemd` on Ubuntu.
- `journalctl` is used to inspect system and service logs.
- `docker logs` is used to inspect container output.
- Logs are important evidence for troubleshooting and incident response.