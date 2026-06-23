#!/usr/bin/env bash
# Atlasflow CLI installer.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/atlasflowlabs/atlasflow-cli/main/install.sh | sh
#
# Pin a version:
#   curl -fsSL .../install.sh | sh -s -- --version v0.1.0
#
# Environment overrides:
#   VERSION=latest                     Release tag (or "latest")
#   INSTALL_DIR=/usr/local/bin         Where to install the binary
set -euo pipefail

REPO="atlasflowlabs/atlasflow-cli"
VERSION="${VERSION:-latest}"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

# Parse --version <v> from argv (overrides VERSION env).
while [ $# -gt 0 ]; do
  case "$1" in
    --version)
      VERSION="$2"
      shift 2
      ;;
    --version=*)
      VERSION="${1#*=}"
      shift
      ;;
    *)
      echo "unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

# --- detect OS / arch -------------------------------------------------------

os="$(uname -s | tr '[:upper:]' '[:lower:]')"
arch_raw="$(uname -m)"

case "$os" in
  linux)  os="linux"   ;;
  darwin) os="darwin"  ;;
  *)
    echo "error: unsupported OS: $os" >&2
    exit 1
    ;;
esac

case "$arch_raw" in
  x86_64|amd64)  arch="amd64" ;;
  aarch64|arm64) arch="arm64" ;;
  *)
    echo "error: unsupported architecture: $arch_raw" >&2
    exit 1
    ;;
esac

# --- resolve version --------------------------------------------------------

if [ "$VERSION" = "latest" ]; then
  release_tag="$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
    | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -1)"
  if [ -z "$release_tag" ]; then
    echo "error: could not resolve latest release from ${REPO}" >&2
    exit 1
  fi
  VERSION="$release_tag"
fi

echo ">> installing atlasflow ${VERSION} for ${os}/${arch}"

# --- download ---------------------------------------------------------------

download_base="https://github.com/${REPO}/releases/download/${VERSION}"

archive_name="atlasflow_${VERSION#v}_${os}_${arch}.tar.gz"
checksums_name="checksums.txt"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

archive_url="${download_base}/${archive_name}"
checksums_url="${download_base}/${checksums_name}"

echo ">> downloading ${archive_url}"
curl -fsSL -o "${tmpdir}/${archive_name}" "$archive_url"

echo ">> downloading ${checksums_url}"
curl -fsSL -o "${tmpdir}/${checksums_name}" "$checksums_url"

# --- verify checksum --------------------------------------------------------

cd "$tmpdir"

if command -v sha256sum >/dev/null 2>&1; then
  sha_cmd="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
  sha_cmd="shasum -a 256"
else
  echo "error: neither sha256sum nor shasum is available" >&2
  exit 1
fi

expected="$(grep " ${archive_name}\$" "${checksums_name}" | awk '{print $1}')"
if [ -z "$expected" ]; then
  echo "error: no checksum entry for ${archive_name} in ${checksums_name}" >&2
  exit 1
fi

actual="$($sha_cmd "${archive_name}" | awk '{print $1}')"
if [ "$actual" != "$expected" ]; then
  echo "error: checksum mismatch for ${archive_name}" >&2
  echo "  expected: ${expected}" >&2
  echo "  actual:   ${actual}" >&2
  exit 1
fi
echo ">> checksum OK"

# --- extract & install ------------------------------------------------------

tar -xzf "${archive_name}"

if [ ! -d "$INSTALL_DIR" ]; then
  echo ">> creating ${INSTALL_DIR}"
  mkdir -p "$INSTALL_DIR"
fi

install_target="${INSTALL_DIR}/atlasflow"
if [ -w "$INSTALL_DIR" ]; then
  install -m 0755 atlasflow "$install_target"
else
  echo ">> ${INSTALL_DIR} is not writable, using sudo"
  sudo install -m 0755 atlasflow "$install_target"
fi

echo ">> installed ${install_target}"

# --- verify -----------------------------------------------------------------

"${install_target}" --version || true

echo
echo "atlasflow ${VERSION} installed to ${install_target}"
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$INSTALL_DIR"; then
  echo "warning: ${INSTALL_DIR} is not in your PATH" >&2
fi
