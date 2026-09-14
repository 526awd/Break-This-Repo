# Chaos Observatory / 混沌观测站

This is a tiny field station for observing a repository that refuses to be one
thing. It treats filenames as fossils, extensions as species, and directory
depth as geological pressure.

这是一个观察仓库生态的微型站点：文件名是化石，扩展名是物种，目录深度是地质压力。

The observatory is deliberately read-only. It does not open file contents,
follow symbolic links, import code from the observed repository, or use the
network. It only examines directory entries and file metadata.

## Take an observation

From this directory:

```sh
python3 observe.py ..
python3 weather.py ..
```

Scanning stops after 100,000 files by default, because an observatory should
study chaos rather than become part of it. Change the limit explicitly when
you mean it:

```sh
python3 observe.py .. --max-files 250000
```

Every reading ends with the same scientifically defensible conclusion:

> The site remains in an active state of formation.

## Safety boundary

- read names and metadata only;
- never follow symlinks;
- never enter `.git` or common dependency/cache directories;
- never execute, import, parse, or upload observed files;
- collect no personal information and make no network requests.

Future researchers may append observations to `FIELD_NOTES.md`. Please record
what you saw, not who you think caused it.
