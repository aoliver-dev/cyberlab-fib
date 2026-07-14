# Week 1 Summary — Linux Foundations

## Objective

The objective of this week was to build a practical Linux foundation for future cybersecurity work.

The work focused on command-line usage, users, groups, permissions, processes, services, logs, Bash scripting and basic incident triage.

## Topics covered

- Linux filesystem navigation
- File inspection and text processing
- Users and groups
- Ownership and permissions
- `chmod`, `chown` and `setgid`
- Process inspection
- Signals and background jobs
- Services with `systemctl`
- Logs with `journalctl`
- Docker container logs
- Bash scripting
- Basic log analysis
- Incident triage
- IOC identification
- Timeline reconstruction
- Incident reporting

## Scripts created

### `scripts/system-info.sh`

Collects basic host information such as:

- current user;
- hostname;
- operating system;
- kernel;
- CPU;
- memory;
- disk usage;
- uptime.

### `scripts/analyze-logs.sh`

Analyzes simulated authentication and web logs.

It can:

- validate input files;
- detect log type;
- count failed SSH attempts;
- identify source IPs;
- detect simple SSH brute-force patterns;
- count web requests by IP;
- detect suspicious web paths.

## Labs completed

### Linux users, groups and permissions

Practised:

- creating users and groups;
- assigning ownership;
- configuring permissions;
- using `setgid`;
- understanding `umask`;
- applying least privilege.

### Linux processes, services and logs

Practised:

- inspecting processes with `ps`, `pgrep` and `pstree`;
- using foreground and background jobs;
- sending signals with `kill` and `pkill`;
- inspecting services with `systemctl`;
- reading logs with `journalctl`;
- inspecting Docker logs.

### Linux filesystem and text processing

Practised:

- navigating directories;
- reading files;
- searching with `grep`;
- using pipes and redirection;
- finding files;
- performing basic log analysis with `cut`, `sort`, `uniq` and `wc`.

### Linux incident triage

Performed an initial investigation of a simulated Linux compromise.

The investigation included:

- authentication analysis;
- web activity analysis;
- suspicious process identification;
- IOC extraction;
- suspicious file analysis;
- persistence analysis;
- event correlation;
- timeline reconstruction;
- containment recommendations.

## Security lessons learned

- Logs are essential evidence during incident response.
- Repeated failed authentication followed by a successful login should be investigated.
- Permissions such as `777` are dangerous because they grant excessive access.
- Executables in `/tmp` should be treated with suspicion.
- Hidden files and autostart configurations can be used for persistence.
- The same IOC appearing in several sources increases confidence.
- Incident reports must distinguish confirmed evidence from reasonable inference.

## Commands I should remember

```bash
pwd
ls -la
cd
cat
head
tail
grep
find
chmod
chown
ps aux
pgrep
kill
pkill
systemctl
journalctl
docker logs
git status
git add
git commit
git push
git pull

Personal reflection

This week helped me move from using Linux as a student to using it as a technical investigation environment.

The most useful part was learning how small command-line tools can be combined to inspect files, analyze logs and identify suspicious activity.

The main area to keep improving is Bash scripting, especially loops, conditions and parsing more complex inputs.