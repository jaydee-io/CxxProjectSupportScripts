#!/bin/bash

UPLOADER_SCRIPT_URL="https://codecov.io/bash"
UPLOADER_SCRIPT_NAME="codecov"
SHASUM_BASE_URL="https://raw.githubusercontent.com/codecov/codecov-bash"

# Download uploader
curl -s "${UPLOADER_SCRIPT_URL}" > "${UPLOADER_SCRIPT_NAME}"

# Get uploader version
VERSION=$(grep -o 'VERSION=\"[0-9\.]*\"' "${UPLOADER_SCRIPT_NAME}" | cut -d '"' -f 2)
echo -e "==> Codecov.io uploader version '\033[33m${VERSION}\033[0m'"

# Verify checksums
echo -e "==> Verifying SHA1 / SHA256 / SHA512 checksum..."
for i in 1 256 512 ; do
  shasum -a $i -c --ignore-missing <(curl -s "${SHASUM_BASE_URL}/${VERSION}/SHA${i}SUM") ||
  shasum -a $i -c <(curl -s                  "${SHASUM_BASE_URL}/${VERSION}/SHA${i}SUM")
done
echo -e "==> Verifying SHA1 / SHA256 / SHA512 checksum... [\033[32mSUCCESS\033[0m]"

# Run uploader
echo -e "==> Run uploader"
chmod +x "${UPLOADER_SCRIPT_NAME}"
./${UPLOADER_SCRIPT_NAME} "$@"