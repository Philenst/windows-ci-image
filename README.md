# windows-ci-image

A small Windows container image for Windows PowerShell 5.1 CI jobs on self-hosted runners that start every job in a
fresh container (for example ephemerd with Hyper-V isolated Windows containers).

`ghcr.io/philenst/windows-ci-image:ltsc2022` (plus dated tags `ltsc2022-YYYYMMDD`) =
Windows Server Core LTSC 2022 (`mcr.microsoft.com/windows/servercore:ltsc2022`) with:

- Git: MinGit in `C:\MinGit` (on `PATH`, `core.longpaths = true`)
- Pester and PSScriptAnalyzer in `C:\Program Files\WindowsPowerShell\Modules` (all users)

Windows PowerShell 5.1 is part of Server Core. Versions and checksums are pinned in `versions.env`; every download is
verified before use.

## How it is built

`.github/workflows/build.yml` runs on GitHub's Linux runners. It assembles the files (`scripts/assemble-layer.sh`) and
uses [crane](https://github.com/google/go-containerregistry) to append them as a Windows layer to Microsoft's base
image, so no Windows machine or Docker is needed. It runs on every push to `main`, on demand, and monthly (2nd of the
month) to pick up the base image's security updates.

To update a tool: change its version and hash in `versions.env` and push.

## Use in a workflow

```yaml
jobs:
  tests:
    runs-on: [self-hosted, Windows, X64]
    container:
      image: ghcr.io/philenst/windows-ci-image:ltsc2022
```
