# Linux Users, Groups and Permissions Lab

## Objective

The objective of this laboratory was to practise Linux user and group management, file ownership, permissions and access control inside an isolated Ubuntu Docker container.

The laboratory was executed inside a temporary container so that no real users, groups or permissions on the host system were modified.

## Laboratory environment

The container was started with:

```bash
docker run --rm -it --name linux-permissions-lab ubuntu:24.04 bash
```

Because the `--rm` option was used, the container and all the files created inside it were automatically deleted after exiting.

## Users and groups

Three users were created:

- `analyst`
- `responder`
- `developer`

A group called `security` was also created.

The users `analyst` and `responder` were added to the `security` group, while `developer` was not.

The final configuration was:

```text
analyst   -> analyst, security
responder -> responder, security
developer -> developer
```

This configuration allowed `analyst` and `responder` to collaborate on security reports while preventing `developer` from accessing them.

## Directory structure

The following structure was created:

```text
/srv/cyberlab/
├── private/
├── public/
└── reports/
```

Each directory had a different security purpose:

- `private`: files accessible only by `analyst`.
- `public`: information readable by all users.
- `reports`: security reports shared by members of the `security` group.

## Ownership

Linux files and directories have both an owner and an associated group.

Ownership can be modified with:

```bash
chown user:group file
```

For example:

```bash
chown analyst:security summary.txt
```

This command makes `analyst` the owner of the file and assigns the file to the `security` group.

## Permissions

Linux permissions are divided into three categories:

- Owner
- Group
- Other users

The basic permissions are:

- `r`: read
- `w`: write
- `x`: execute, or access in the case of a directory

Their numeric values are:

```text
r = 4
w = 2
x = 1
```

The following permission modes were used during the laboratory:

```text
400 = r-- --- ---
600 = rw- --- ---
640 = rw- r-- ---
644 = rw- r-- r--
660 = rw- rw- ---
700 = rwx --- ---
755 = rwx r-x r-x
2770 = rwx rwx --- with setgid enabled
```

## Final directory permissions

The private directory was configured as:

```text
drwx------ analyst analyst
```

This corresponds to mode `700`, meaning that only `analyst` can access it.

The reports directory was configured as:

```text
drwxrws--- analyst security
```

This corresponds to mode `2770`.

The owner and members of the `security` group have full access, while other users have no access.

The `s` in the group permissions indicates that the setgid bit is enabled.

The public directory was configured as:

```text
drwxr-xr-x root root
```

This corresponds to mode `755`, allowing all users to access and read the directory, but only the owner to modify it.

## Exercise A

The file `summary.txt` required:

- Owner: read and write
- Group: read only
- Others: no access

The selected mode was:

```text
640 = rw- r-- ---
```

The ownership and permissions were configured with:

```bash
chown analyst:security /srv/cyberlab/reports/summary.txt
chmod 640 /srv/cyberlab/reports/summary.txt
```

The final result was:

```text
-rw-r----- analyst security summary.txt
```

## Exercise B

The file `private-key.pem` required:

- Owner: read only
- Group: no access
- Others: no access

The selected mode was:

```text
400 = r-- --- ---
```

The ownership and permissions were configured with:

```bash
chown analyst:analyst /srv/cyberlab/private/private-key.pem
chmod 400 /srv/cyberlab/private/private-key.pem
```

The final result was:

```text
-r-------- analyst analyst private-key.pem
```

## Exercise C

The file `readme.txt` required:

- Owner: read and write
- Group: read only
- Others: read only
- No execution permissions

The selected mode was:

```text
644 = rw- r-- r--
```

The ownership and permissions were configured with:

```bash
chown analyst:analyst /srv/cyberlab/public/readme.txt
chmod 644 /srv/cyberlab/public/readme.txt
```

The final result was:

```text
-rw-r--r-- analyst analyst readme.txt
```

## Setgid directories

The reports directory was configured with:

```bash
chmod 2770 /srv/cyberlab/reports
```

The leading `2` enables the setgid bit.

When setgid is enabled on a directory, new files created inside it inherit the directory group. In this laboratory, files created inside the reports directory inherited the `security` group.

This is useful in shared directories where several users from the same team need to collaborate.

## Umask

The initial permissions of a newly created file are affected by the user's `umask`.

The setgid bit determines group inheritance, but it does not determine all the permissions of the new file.

One of the report files initially had permissions equivalent to `664`:

```text
-rw-rw-r--
```

This allowed users outside the `security` group to read it.

The permissions were corrected with:

```bash
chmod 660 /srv/cyberlab/reports/incident-002.txt
```

The final result was:

```text
-rw-rw---- analyst security incident-002.txt
```

This showed that setgid and umask solve different problems:

- setgid controls group inheritance;
- umask influences the initial permissions of new files.

## Why chmod 777 is dangerous

Using the following command would be insecure:

```bash
chmod -R 777 /srv/cyberlab
```

It would grant read, write and execute permissions to every user over every file and directory.

This violates the principle of least privilege because users would receive more permissions than necessary.

Any user could modify, delete or replace reports and private files. Unauthorized users could also introduce malicious content or alter security evidence.

A safer solution is to configure specific owners, groups and permissions according to the responsibilities of each user.

## Security relevance

This laboratory demonstrated how Linux permissions can enforce access control between users.

The `analyst` and `responder` users could collaborate through the `security` group, while `developer` was prevented from accessing restricted reports.

Private files were protected using restrictive permissions such as `600` and `400`.

These mechanisms support the principle of least privilege and reduce the risk of unauthorized access, modification or deletion.

## Lessons learned

- Linux permissions are applied separately to the owner, group and other users.
- `chown` changes ownership, while `chmod` changes permissions.
- Groups allow several users to share controlled access to files.
- The setgid bit helps preserve group ownership inside shared directories.
- The umask influences the initial permissions assigned to new files.
- Permissions such as `777` should be avoided because they grant excessive access.
- Access controls should be designed according to each user's responsibilities.