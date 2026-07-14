# atlasflow cli

Public distribution home for the [Atlasflow](https://atlasflow.com) CLI.

This repo hosts GitHub Releases (binaries + checksums) and the install script.

## Install

**Linux / macOS** (amd64 / arm64):

```sh
curl -fsSL https://raw.githubusercontent.com/atlasflowlabs/cli/main/install.sh | bash
```

Install a specific version:

```sh
curl -fsSL https://raw.githubusercontent.com/atlasflowlabs/cli/main/install.sh | bash -s -- --version v0.1.0
```

The installer downloads the release archive for your OS/arch, verifies the
SHA256 checksum against `checksums.txt`, and installs the binary to
`/usr/local/bin/atlasflow`.

### Environment overrides

| Variable     | Default                       | Description                          |
| ------------ | ----------------------------- | ------------------------------------ |
| `VERSION`    | `latest`                      | Release tag to install               |
| `INSTALL_DIR`| `/usr/local/bin`              | Where to install the `atlasflow` bin |

## Verify a release

Every release publishes a `checksums.txt` (SHA256). After downloading an
archive manually:

```sh
sha256sum -c --ignore-missing checksums.txt
```

## Usage

```sh
atlasflow --version
atlasflow --help
```

See [atlasflow.com](https://atlasflow.com) for full docs.
